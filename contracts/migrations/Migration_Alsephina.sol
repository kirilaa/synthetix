
pragma solidity ^0.5.16;

import "../BaseMigration.sol";
import "../AddressResolver.sol";
import "../Proxy.sol";
import "../FeePoolEternalStorage.sol";
import "../ProxyERC20.sol";
import "../ProxyERC20.sol";
import "../TokenState.sol";
import "../SynthetixState.sol";
import "../RewardEscrow.sol";
import "../RewardsDistribution.sol";
import "../FeePool.sol";
import "../Issuer.sol";

interface ISynthetixNamedContract {
    // solhint-disable func-name-mixedcase
    function CONTRACT_NAME() external view returns (bytes32);
}

// solhint-disable contract-name-camelcase
contract Migration_Alsephina is BaseMigration {
    // https://kovan.etherscan.io/address/0x73570075092502472E4b61A7058Df1A4a1DB12f2;
    address public constant OWNER = 0x73570075092502472E4b61A7058Df1A4a1DB12f2;

    // ----------------------------
    // EXISTING SYNTHETIX CONTRACTS
    // ----------------------------

    // https://kovan.etherscan.io/address/0x84f87E3636Aa9cC1080c07E6C61aDfDCc23c0db6
    AddressResolver public constant addressresolver_i = AddressResolver(0x84f87E3636Aa9cC1080c07E6C61aDfDCc23c0db6);
    // https://kovan.etherscan.io/address/0xc43b833F93C3896472dED3EfF73311f571e38742
    Proxy public constant proxyfeepool_i = Proxy(0xc43b833F93C3896472dED3EfF73311f571e38742);
    // https://kovan.etherscan.io/address/0x7bB8B3Cc191600547b9467639aD397c05AF3ce8D
    FeePoolEternalStorage public constant feepooleternalstorage_i = FeePoolEternalStorage(0x7bB8B3Cc191600547b9467639aD397c05AF3ce8D);
    // https://kovan.etherscan.io/address/0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    ProxyERC20 public constant proxyerc20_i = ProxyERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    // https://kovan.etherscan.io/address/0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F
    ProxyERC20 public constant proxysynthetix_i = ProxyERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    // https://kovan.etherscan.io/address/0x46824bFAaFd049fB0Af9a45159A88e595Bbbb9f7
    TokenState public constant tokenstatesynthetix_i = TokenState(0x46824bFAaFd049fB0Af9a45159A88e595Bbbb9f7);
    // https://kovan.etherscan.io/address/0xAfcBC491B67c01B40f6c077EF53488876a0a0D6E
    SynthetixState public constant synthetixstate_i = SynthetixState(0xAfcBC491B67c01B40f6c077EF53488876a0a0D6E);
    // https://kovan.etherscan.io/address/0x8c6680412e914932A9abC02B6c7cbf690e583aFA
    RewardEscrow public constant rewardescrow_i = RewardEscrow(0x8c6680412e914932A9abC02B6c7cbf690e583aFA);
    // https://kovan.etherscan.io/address/0xD29160e4f5D2e5818041f9Cd9192853BA349c47E
    RewardsDistribution public constant rewardsdistribution_i = RewardsDistribution(0xD29160e4f5D2e5818041f9Cd9192853BA349c47E);
    // https://kovan.etherscan.io/address/0x69A9d122654E6FA8BE179462ff4553D6419a60fE
    FeePool public constant feepool_i = FeePool(0x69A9d122654E6FA8BE179462ff4553D6419a60fE);
    // https://kovan.etherscan.io/address/0xa4Ac258D9796f079443be218AAA4428824172851
    Issuer public constant issuer_i = Issuer(0xa4Ac258D9796f079443be218AAA4428824172851);

    // ----------------------------------
    // NEW CONTRACTS DEPLOYED TO BE ADDED
    // ----------------------------------

    // https://kovan.etherscan.io/address/0x65B4D5fBE056b7674c383502f024030f0e65Adf7
        address public constant new_SynthetixDebtShare_contract = 0x65B4D5fBE056b7674c383502f024030f0e65Adf7;
        // https://kovan.etherscan.io/address/0x69A9d122654E6FA8BE179462ff4553D6419a60fE
        address public constant new_FeePool_contract = 0x69A9d122654E6FA8BE179462ff4553D6419a60fE;
        // https://kovan.etherscan.io/address/0xa4Ac258D9796f079443be218AAA4428824172851
        address public constant new_Issuer_contract = 0xa4Ac258D9796f079443be218AAA4428824172851;
        // https://kovan.etherscan.io/address/0xf59A5D8Af09848Cd8bcFBF14A4a5A2323d0dE83c
        address public constant new_Synthetix_contract = 0xf59A5D8Af09848Cd8bcFBF14A4a5A2323d0dE83c;

    constructor() public BaseMigration(OWNER) {}

    function contractsRequiringOwnership() public pure returns (address[] memory contracts) {
        contracts = new address[](10);
        contracts[0]= address(addressresolver_i);
        contracts[1]= address(proxyfeepool_i);
        contracts[2]= address(feepooleternalstorage_i);
        contracts[3]= address(proxyerc20_i);
        contracts[4]= address(tokenstatesynthetix_i);
        contracts[5]= address(synthetixstate_i);
        contracts[6]= address(rewardescrow_i);
        contracts[7]= address(rewardsdistribution_i);
        contracts[8]= address(feepool_i);
        contracts[9]= address(issuer_i);
    }

    function migrate(address currentOwner) external onlyDeployer {
        require(owner == currentOwner, "Only the assigned owner can be re-assigned when complete");

        require(ISynthetixNamedContract(new_SynthetixDebtShare_contract).CONTRACT_NAME() == "SynthetixDebtShare", "Invalid contract supplied for SynthetixDebtShare");
        require(ISynthetixNamedContract(new_FeePool_contract).CONTRACT_NAME() == "FeePool", "Invalid contract supplied for FeePool");
        require(ISynthetixNamedContract(new_Issuer_contract).CONTRACT_NAME() == "Issuer", "Invalid contract supplied for Issuer");
        require(ISynthetixNamedContract(new_Synthetix_contract).CONTRACT_NAME() == "Synthetix", "Invalid contract supplied for Synthetix");

        // ACCEPT OWNERSHIP for all contracts that require ownership to make changes
        acceptAll();

        // MIGRATION
        // Import all new contracts into the address resolver;
        addressresolver_importAddresses_0();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 1;
        addressresolver_rebuildCaches_1();
        // Rebuild the resolver caches in all MixinResolver contracts - batch 2;
        addressresolver_rebuildCaches_2();
        // Ensure the ProxyFeePool contract has the correct FeePool target set;
        proxyfeepool_i.setTarget(Proxyable(new_FeePool_contract));
        // Ensure the FeePool contract can write to its EternalStorage;
        feepooleternalstorage_i.setAssociatedContract(new_FeePool_contract);
        // Ensure the SNX proxy has the correct Synthetix target set;
        proxyerc20_i.setTarget(Proxyable(new_Synthetix_contract));
        // Ensure the SNX proxy has the correct Synthetix target set;
        proxysynthetix_i.setTarget(Proxyable(new_Synthetix_contract));
        // Ensure the Synthetix contract can write to its TokenState contract;
        tokenstatesynthetix_i.setAssociatedContract(new_Synthetix_contract);
        // Ensure that Synthetix can write to its State contract;
        synthetixstate_i.setAssociatedContract(new_Issuer_contract);
        // Ensure the legacy RewardEscrow contract is connected to the Synthetix contract;
        rewardescrow_i.setSynthetix(ISynthetix(new_Synthetix_contract));
        // Ensure the legacy RewardEscrow contract is connected to the FeePool contract;
        rewardescrow_i.setFeePool(IFeePool(new_FeePool_contract));
        // Ensure the RewardsDistribution has Synthetix set as its authority for distribution;
        rewardsdistribution_i.setAuthority(new_Synthetix_contract);
        // Import fee period from existing fee pool at index 0;
        importFeePeriod_0();
        // Import fee period from existing fee pool at index 1;
        importFeePeriod_1();
        // Add synths to the Issuer contract - batch 1;
        issuer_addSynths_18();

        // NOMINATE OWNERSHIP back to owner for aforementioned contracts
        nominateAll();
    }

    function acceptAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            Owned(contracts[i]).acceptOwnership();
        }
    }

    function nominateAll() internal {
        address[] memory contracts = contractsRequiringOwnership();
        for (uint i = 0; i < contracts.length; i++) {
            returnOwnership(contracts[i]);
        }
    }

    
    function addressresolver_importAddresses_0() internal {
        bytes32[] memory addressresolver_importAddresses_names_0_0 = new bytes32[](4);
        addressresolver_importAddresses_names_0_0[0] = bytes32("SynthetixDebtShare");
        addressresolver_importAddresses_names_0_0[1] = bytes32("FeePool");
        addressresolver_importAddresses_names_0_0[2] = bytes32("Issuer");
        addressresolver_importAddresses_names_0_0[3] = bytes32("Synthetix");
        address[] memory addressresolver_importAddresses_destinations_0_1 = new address[](4);
        addressresolver_importAddresses_destinations_0_1[0] = address(new_SynthetixDebtShare_contract);
        addressresolver_importAddresses_destinations_0_1[1] = address(new_FeePool_contract);
        addressresolver_importAddresses_destinations_0_1[2] = address(new_Issuer_contract);
        addressresolver_importAddresses_destinations_0_1[3] = address(new_Synthetix_contract);
        addressresolver_i.importAddresses(addressresolver_importAddresses_names_0_0, addressresolver_importAddresses_destinations_0_1);
    }

    
    function addressresolver_rebuildCaches_1() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_1_0 = new MixinResolver[](20);
        addressresolver_rebuildCaches_destinations_1_0[0] = MixinResolver(new_FeePool_contract);
        addressresolver_rebuildCaches_destinations_1_0[1] = MixinResolver(new_Issuer_contract);
        addressresolver_rebuildCaches_destinations_1_0[2] = MixinResolver(new_SynthetixDebtShare_contract);
        addressresolver_rebuildCaches_destinations_1_0[3] = MixinResolver(0x64ac15AB583fFfA6a7401B83E3aA5cf4Ad1aA92A);
        addressresolver_rebuildCaches_destinations_1_0[4] = MixinResolver(0x52DCF4f0019E16455621De5f792C5e7BE4cdAA81);
        addressresolver_rebuildCaches_destinations_1_0[5] = MixinResolver(0x6B4D3e213e10d9238c1a1A87E493687cc2eb1DD0);
        addressresolver_rebuildCaches_destinations_1_0[6] = MixinResolver(0xB98c6031344EB6007e94A8eDbc0ee28C13c66290);
        addressresolver_rebuildCaches_destinations_1_0[7] = MixinResolver(0x26b814c9fA4C0512D84373f80d4B92408CD13960);
        addressresolver_rebuildCaches_destinations_1_0[8] = MixinResolver(0x880477aE972Ca606cC7D47496E077514e978231B);
        addressresolver_rebuildCaches_destinations_1_0[9] = MixinResolver(0x0D9D97E38d19885441f8be74fE88C3294300C866);
        addressresolver_rebuildCaches_destinations_1_0[10] = MixinResolver(0x16A5ED828fD7F03B0c3F4E261Ea519112c4fa2f4);
        addressresolver_rebuildCaches_destinations_1_0[11] = MixinResolver(0x376684744fb828D67B1659f6D3D754938dc1Ec4b);
        addressresolver_rebuildCaches_destinations_1_0[12] = MixinResolver(0x67FbB70d887e8E493611D273E94aD12fE7a7Da4e);
        addressresolver_rebuildCaches_destinations_1_0[13] = MixinResolver(0xe2d39AB610fEe4C7FC591003553c7557C880eD04);
        addressresolver_rebuildCaches_destinations_1_0[14] = MixinResolver(0x56a8953C03FC8b859140D5C6f7e7f24dD611d419);
        addressresolver_rebuildCaches_destinations_1_0[15] = MixinResolver(0xa2aFD3FaA2b69a334DD5493031fa59B7779a3CBf);
        addressresolver_rebuildCaches_destinations_1_0[16] = MixinResolver(0x7fA8b2D1F640Ac31f08046d0502147Ed430DdAb2);
        addressresolver_rebuildCaches_destinations_1_0[17] = MixinResolver(0x44Af736495544a726ED15CB0EBe2d87a6bCC1832);
        addressresolver_rebuildCaches_destinations_1_0[18] = MixinResolver(0xdFd01d828D34982DFE882B9fDC6DC17fcCA33C25);
        addressresolver_rebuildCaches_destinations_1_0[19] = MixinResolver(0x5AD5469D8A1Eee2cF7c8B8205CbeD95A032cdff3);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_1_0);
    }

    
    function addressresolver_rebuildCaches_2() internal {
        MixinResolver[] memory addressresolver_rebuildCaches_destinations_2_0 = new MixinResolver[](8);
        addressresolver_rebuildCaches_destinations_2_0[0] = MixinResolver(0x9712DdCC43F42402acC483e297eeFf650d18D354);
        addressresolver_rebuildCaches_destinations_2_0[1] = MixinResolver(0x9880cfA7B81E8841e216ebB32687A2c9551ae333);
        addressresolver_rebuildCaches_destinations_2_0[2] = MixinResolver(new_Synthetix_contract);
        addressresolver_rebuildCaches_destinations_2_0[3] = MixinResolver(0x0b6f83DB2dE6cDc3cB57DC0ED79D07267F6fdc2A);
        addressresolver_rebuildCaches_destinations_2_0[4] = MixinResolver(0xD134Db47DDF5A6feB245452af17cCAf92ee53D3c);
        addressresolver_rebuildCaches_destinations_2_0[5] = MixinResolver(0xFa01a0494913b150Dd37CbE1fF775B08f108dEEa);
        addressresolver_rebuildCaches_destinations_2_0[6] = MixinResolver(0x53baE964339e8A742B5b47F6C10bbfa8Ff138F34);
        addressresolver_rebuildCaches_destinations_2_0[7] = MixinResolver(0xBBfAd9112203b943f26320B330B75BABF6e2aF2a);
        addressresolver_i.rebuildCaches(addressresolver_rebuildCaches_destinations_2_0);
    }

    
    function importFeePeriod_0() internal {
        // https://kovan.etherscan.io/address/0xE532C9336934DA37aacc0143D07314d7F9D2a8c0;
        FeePool existingFeePool = FeePool(0xE532C9336934DA37aacc0143D07314d7F9D2a8c0);
        // https://kovan.etherscan.io/address/0x69A9d122654E6FA8BE179462ff4553D6419a60fE;
        FeePool newFeePool = FeePool(0x69A9d122654E6FA8BE179462ff4553D6419a60fE);
        (
                        uint64 feePeriodId_0,
                        uint64 unused_0,
                        uint64 startTime_0,
                        uint feesToDistribute_0,
                        uint feesClaimed_0,
                        uint rewardsToDistribute_0,
                        uint rewardsClaimed_0
                    ) = existingFeePool.recentFeePeriods(0);
        newFeePool.importFeePeriod(
                        0,
                        feePeriodId_0,
                        startTime_0,
                        feesToDistribute_0,
                        feesClaimed_0,
                        rewardsToDistribute_0,
                        rewardsClaimed_0
                    );
    }

    
    function importFeePeriod_1() internal {
        // https://kovan.etherscan.io/address/0xE532C9336934DA37aacc0143D07314d7F9D2a8c0;
        FeePool existingFeePool = FeePool(0xE532C9336934DA37aacc0143D07314d7F9D2a8c0);
        // https://kovan.etherscan.io/address/0x69A9d122654E6FA8BE179462ff4553D6419a60fE;
        FeePool newFeePool = FeePool(0x69A9d122654E6FA8BE179462ff4553D6419a60fE);
        (
                        uint64 feePeriodId_1,
                        uint64 unused_1,
                        uint64 startTime_1,
                        uint feesToDistribute_1,
                        uint feesClaimed_1,
                        uint rewardsToDistribute_1,
                        uint rewardsClaimed_1
                    ) = existingFeePool.recentFeePeriods(1);
        newFeePool.importFeePeriod(
                        1,
                        feePeriodId_1,
                        startTime_1,
                        feesToDistribute_1,
                        feesClaimed_1,
                        rewardsToDistribute_1,
                        rewardsClaimed_1
                    );
    }

    
    function issuer_addSynths_18() internal {
        ISynth[] memory issuer_addSynths_synthsToAdd_18_0 = new ISynth[](11);
        issuer_addSynths_synthsToAdd_18_0[0] = ISynth(0xB98c6031344EB6007e94A8eDbc0ee28C13c66290);
        issuer_addSynths_synthsToAdd_18_0[1] = ISynth(0x26b814c9fA4C0512D84373f80d4B92408CD13960);
        issuer_addSynths_synthsToAdd_18_0[2] = ISynth(0x880477aE972Ca606cC7D47496E077514e978231B);
        issuer_addSynths_synthsToAdd_18_0[3] = ISynth(0x0D9D97E38d19885441f8be74fE88C3294300C866);
        issuer_addSynths_synthsToAdd_18_0[4] = ISynth(0x16A5ED828fD7F03B0c3F4E261Ea519112c4fa2f4);
        issuer_addSynths_synthsToAdd_18_0[5] = ISynth(0x376684744fb828D67B1659f6D3D754938dc1Ec4b);
        issuer_addSynths_synthsToAdd_18_0[6] = ISynth(0x67FbB70d887e8E493611D273E94aD12fE7a7Da4e);
        issuer_addSynths_synthsToAdd_18_0[7] = ISynth(0xe2d39AB610fEe4C7FC591003553c7557C880eD04);
        issuer_addSynths_synthsToAdd_18_0[8] = ISynth(0x56a8953C03FC8b859140D5C6f7e7f24dD611d419);
        issuer_addSynths_synthsToAdd_18_0[9] = ISynth(0xa2aFD3FaA2b69a334DD5493031fa59B7779a3CBf);
        issuer_addSynths_synthsToAdd_18_0[10] = ISynth(0x7fA8b2D1F640Ac31f08046d0502147Ed430DdAb2);
        issuer_i.addSynths(issuer_addSynths_synthsToAdd_18_0);
    }
}
