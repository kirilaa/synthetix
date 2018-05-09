/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------
file:       Owned.sol
version:    1.0
author:     Anton Jurisevic
            Dominic Romanowski

date:       2018-2-26

checked:    Mike Spain
approved:   Samuel Brooks

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

pragma solidity 0.4.23;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /*** ABSTRACT FUNCTIONS ***/
    function emitOwnerNominated(address _owner) internal;
    function emitOwnerChanged(address _owner, address _nominatedOwner) internal;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
        public
    {
        owner = _owner;
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateOwner(address _owner)
        external
        optionalProxy_onlyOwner
    {
        nominatedOwner = _owner;
        emitOwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
        optionalProxy
    {
        require(messageSender == nominatedOwner);
        emitOwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(messageSender == owner);
        _;
    }

}
