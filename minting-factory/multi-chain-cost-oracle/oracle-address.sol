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
  constructor()  {
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

    address private costOracleRinkeby = 0x255eB4D2C937586b3dE6f1cA41954263028ae41b;//4
    address private costOracleETH = 0x3285b253b0F82A4447344843086E4DD8F0aB154f;
    address private costOracleBSC = 0xE27FED0434c12a7DE946465D96C2F401590E897d;
    address private costOraclePOLY = 0x7F53931318d995b03ea665e83c04B6B4D803Aa74;
    address private costOracleXDAI = 0x76b294D4708B61891F36Ee12a2c9339BE2a61279;
    address private costOracleRSK = 0x255eB4D2C937586b3dE6f1cA41954263028ae41b; //not yet activated
    address private costOracleAVAX = 0x255eB4D2C937586b3dE6f1cA41954263028ae41b; //not activated

    constructor ()  {
        owner = msg.sender;
    }

    function getOracle(uint _id) public view returns(address) {
        if (_id == 4){
            return costOracleRinkeby;
        }
        if (_id == 1){
            return costOracleETH;
        }
        if (_id == 56){
            return costOracleBSC;
        }
        if (_id == 137){
            return costOraclePOLY;
        }
        if (_id == 30){
            return costOracleRSK;
        }
        if (_id == 43114){
            return costOracleAVAX;
        }
        if (_id == 100){
            return costOracleXDAI;
        }

        return costOracleXDAI;

    }

    function setETH(address _costOracleETH) public onlyOwner {
        costOracleETH = _costOracleETH;
    }

    function setBSC(address _costOracleBSC) public onlyOwner {
        costOracleBSC = _costOracleBSC;
    }

    function setPOLY(address _costOraclePOLY) public onlyOwner {
        costOraclePOLY = _costOraclePOLY;
    }

    function setXDAI(address _costOracleXDAI) public onlyOwner {
        costOracleXDAI = _costOracleXDAI;
    }

    function setRSK(address _costOracleRSK) public onlyOwner {
        costOracleRSK = _costOracleRSK;
    }

    function setAVAX(address _costOracleAVAX) public onlyOwner {
        costOracleAVAX = _costOracleAVAX;
    }


}
