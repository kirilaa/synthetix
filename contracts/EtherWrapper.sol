pragma solidity ^0.5.16;

// Inheritance
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";

// Internal references
import "./Pausable.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IEtherWrapperRewards.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";

// Libraries
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "./SafeDecimalMath.sol";

// https://docs.synthetix.io/contracts/source/contracts/etherwrapper
contract EtherWrapper is Owned, Pausable, MixinResolver, MixinSystemSettings, IEtherWrapper {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== CONSTANTS ============== */

    /* ========== ENCODED NAMES ========== */

    bytes32 internal constant sUSD = "sUSD";
    bytes32 internal constant sETH = "sETH";
    bytes32 internal constant ETH = "ETH";
    bytes32 internal constant SNX = "SNX";

    /* ========== ADDRESS RESOLVER CONFIGURATION ========== */
    bytes32 private constant CONTRACT_SYNTHETIX = "Synthetix";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_SYNTHSETH = "SynthsETH";
    bytes32 private constant CONTRACT_SYNTHSUSD = "SynthsUSD";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";

    // ========== STATE VARIABLES ==========
    IWETH internal _weth;

    // EtherWrapper rewards
    IEtherWrapperRewards public wrapperRewards;

    // sETH debt is tracked in two separate variables, in order to account
    // properly the points at which it is repaid and converted into sUSD debt.
    uint public sETHIssued = 0;
    uint public sETHBurnt = 0;
    uint public sUSDIssued = 0;
    uint public feesEscrowed = 0;

    constructor(
        address _owner,
        address _resolver,
        address payable _WETH
    ) public Owned(_owner) Pausable() MixinSystemSettings(_resolver) {
        _weth = IWETH(_WETH);
    }

    /* ========== VIEWS ========== */
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](5);
        newAddresses[0] = CONTRACT_SYNTHSETH;
        newAddresses[1] = CONTRACT_SYNTHSUSD;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_ISSUER;
        newAddresses[4] = CONTRACT_FEEPOOL;
        addresses = combineArrays(existingAddresses, newAddresses);
        return addresses;
    }

    /* ========== INTERNAL VIEWS ========== */
    function synthsUSD() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSUSD));
    }

    function synthsETH() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTHSETH));
    }

    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }

    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }

    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    // ========== VIEWS ==========

    function capacity() public view returns (uint _capacity) {
        // capacity = max(maxETH - balance, 0)
        uint balance = getReserves();
        if (balance >= maxETH()) {
            return 0;
        }
        return maxETH().sub(balance);
    }

    function getReserves() public view returns (uint) {
        return _weth.balanceOf(address(this));
    }

    function totalIssuedSynths(bytes32 currencyKey) public view returns (uint) {
        // This contract issues two different synths:
        // 1. sETH
        // 2. sUSD
        //
        // The sETH is always backed 1:1 with WETH.
        // The sUSD fees are backed by sETH that is withheld during minting and burning.
        if (currencyKey == sETH) {
            return sETHIssued > sETHBurnt ? sETHIssued.sub(sETHBurnt) : 0;
        }
        if (currencyKey == sUSD) {
            return sUSDIssued;
        }
        return 0;
    }

    function calculateMintFee(uint amount) public view returns (uint) {
        return amount.multiplyDecimalRound(mintFeeRate());
    }

    function calculateBurnFee(uint amount) public view returns (uint) {
        return amount.multiplyDecimalRound(burnFeeRate());
    }

    function maxETH() public view returns (uint256) {
        return getEtherWrapperMaxETH();
    }

    function mintFeeRate() public view returns (uint256) {
        return getEtherWrapperMintFeeRate();
    }

    function burnFeeRate() public view returns (uint256) {
        return getEtherWrapperBurnFeeRate();
    }

    function weth() public view returns (IWETH) {
        return _weth;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mintWithTracking(uint amountIn, address minter) public notPaused {
        require(amountIn <= _weth.allowance(msg.sender, address(this)), "Allowance not high enough");
        require(amountIn <= _weth.balanceOf(msg.sender), "Balance is too low");

        uint currentCapacity = capacity();
        require(currentCapacity > 0, "Contract has no spare capacity to mint");

        amountIn = amountIn < currentCapacity ? amountIn : currentCapacity;
        _mint(amountIn);

        // Enrol minter in rewards for amount minted
        if (address(wrapperRewards) != address(0)) {
            wrapperRewards.enrol(minter, amountIn);
        }
    }

    // Transfers `amountIn` WETH to mint `amountIn - fees` sETH.
    // `amountIn` is inclusive of fees, calculable via `calculateMintFee`.
    function mint(uint amountIn) external notPaused {
        mintWithTracking(amountIn, msg.sender);
    }

    // Burns `amountIn` sETH for `amountIn - fees` WETH.
    // `amountIn` is inclusive of fees, calculable via `calculateBurnFee`.
    function burn(uint amountIn) external notPaused {
        uint reserves = getReserves();
        require(reserves > 0, "Contract cannot burn sETH for WETH, WETH balance is zero");

        // principal = [amountIn / (1 + burnFeeRate)]
        uint principal = amountIn.divideDecimal(SafeDecimalMath.unit().add(burnFeeRate()));

        if (principal < reserves) {
            _burn(principal);
        } else {
            _burn(reserves);
        }
    }

    function claimFees(uint amount) external {
        require(amount <= feesEscrowed, "amount to distribute too large");

        // Normalize fee to sUSD
        require(!exchangeRates().rateIsInvalid(ETH), "Currency rate is invalid");
        uint amount_sUSD = exchangeRates().effectiveValue(ETH, amount, sUSD);

        // Burn sETH.
        synthsETH().burn(address(this), amount);
        // TODO(liamz): Jacko should we be accounting for this burnt sETH as part of
        // the sETH issued by the contract? I'm unsure.
        sETHBurnt = sETHBurnt.add(amount);

        // Issue sUSD to the fee pool
        issuer().synths(sUSD).issue(feePool().FEE_ADDRESS(), amount_sUSD);
        sUSDIssued = sUSDIssued.add(amount_sUSD);

        // Tell the fee pool about this
        feePool().recordFeePaid(amount_sUSD);
    }

    // Set the wrapper rewards contract
    function setWrapperRewards(address _wrapperRewards) external onlyOwner {
        wrapperRewards = IEtherWrapperRewards(_wrapperRewards);
    }

    // ========== RESTRICTED ==========

    /**
     * @notice Fallback function
     */
    function() external payable {
        revert("Fallback disabled, use mint()");
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _mint(uint amountIn) internal {
        // Calculate minting fee.
        uint feeAmountEth = calculateMintFee(amountIn);
        uint principal = amountIn.sub(feeAmountEth);

        // Transfer WETH from user.
        _weth.transferFrom(msg.sender, address(this), amountIn);

        // Mint `amountIn - fees` sETH to user.
        synthsETH().issue(msg.sender, principal);

        // Escrow fee.
        synthsETH().issue(address(this), feeAmountEth);
        feesEscrowed = feesEscrowed.add(feeAmountEth);

        // Add sETH debt.
        sETHIssued = sETHIssued.add(principal).add(feeAmountEth);

        emit Minted(msg.sender, principal, feeAmountEth, amountIn);
    }

    function _burn(uint principal) internal {
        // for burn, amount is inclusive of the fee.
        uint feeAmountEth = calculateBurnFee(principal);
        uint amountIn = principal.add(feeAmountEth);

        require(amountIn <= IERC20(address(synthsETH())).allowance(msg.sender, address(this)), "Allowance not high enough");
        require(amountIn <= IERC20(address(synthsETH())).balanceOf(msg.sender), "Balance is too low");

        // Burn `principal` sETH from user.
        synthsETH().burn(msg.sender, principal);
        // sETH debt is repaid by burning.
        // sETHIssued = sETHIssued.sub(principal);
        sETHBurnt = sETHBurnt.add(principal);

        // Escrow fee.
        IERC20(address(synthsETH())).transferFrom(msg.sender, address(this), feeAmountEth);
        feesEscrowed = feesEscrowed.add(feeAmountEth);

        // Transfer `amount - fees` WETH to user.
        _weth.transfer(msg.sender, principal);

        emit Burned(msg.sender, principal, feeAmountEth, amountIn);
    }

    /* ========== EVENTS ========== */
    event Minted(address indexed account, uint principal, uint fee, uint amountIn);
    event Burned(address indexed account, uint principal, uint fee, uint amountIn);
}