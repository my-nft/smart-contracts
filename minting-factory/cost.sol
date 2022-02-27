pragma solidity 0.6.12;

// SPDX-License-Identifier: BSD-3-Clause

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Cost is Ownable {


    uint256 public eth = 1e17;
    uint256 public bsc = 1e18;
    uint256 public poly = 5e18;
    uint256 public rsk = 200e18;
    uint256 public avax = 200e18;

    constructor () public {
        owner = msg.sender;
    }

    function setETH(uint _eth) public onlyOwner {
        eth = _eth;
    }

    function setBSC(uint _bsc) public onlyOwner {
        bsc = _bsc;
    }

    function setPOLY(uint _poly) public onlyOwner {
        poly = _poly;
    }

    function setRSK(uint _rsk) public onlyOwner {
        rsk = _rsk;
    }

    function setAVAX(uint _avax) public onlyOwner {
        avax = _avax;
    }

}
