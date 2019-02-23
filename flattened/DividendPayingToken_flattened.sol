pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Dividend Paying Token
//
// NOTE: This token contract allows the owner to mint and burn tokens for any
// account, and is used for testing
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2019.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        owner = _owner;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
// ----------------------------------------------------------------------------
// End - Owned contract
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    function max(uint a, uint b) internal pure returns (uint c) {
        c = a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint c) {
        c = a <= b ? a : b;
    }
}
// ----------------------------------------------------------------------------
// End - Safe maths
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ApproveAndCall Fallback
// ----------------------------------------------------------------------------
contract ApproveAndCallFallback {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}
// ----------------------------------------------------------------------------
// End - ApproveAndCall Fallback
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}
// ----------------------------------------------------------------------------
// End - ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// MintableToken Interface = ERC20 + symbol + name + decimals + mint + burn
// + approveAndCall
// ----------------------------------------------------------------------------
contract MintableTokenInterface is ERC20Interface {
    function symbol() public view returns (string memory);
    function name() public view returns (string memory);
    function decimals() public view returns (uint8);
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success);
    function mint(address tokenOwner, uint tokens) public returns (bool success);
    function burn(address tokenOwner, uint tokens) public returns (bool success);
}
// ----------------------------------------------------------------------------
// End - MintableToken Interface
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// DividendPayingToken = ERC20 + symbol + name + decimals + mint + burn
//                     + dividend payment
//
// NOTE: This token contract allows the owner to mint and burn tokens for any
// account, and is used for testing
// ----------------------------------------------------------------------------
contract DividendPayingToken is MintableTokenInterface, Owned {
    using SafeMath for uint;

    string _symbol;
    string  _name;
    uint8 _decimals;
    uint _totalSupply;

    uint _totalDividendPoints;
    uint _unclaimedDividends;

    address public dividendToken;

    uint public constant pointMultiplier = 10e18;

    struct Account {
      uint balance;
      uint lastDividendPoints;
    }
    mapping(address => Account) accounts;
    mapping(address => mapping(address => uint)) allowed;

    event LogInfo(string topic, uint number, bytes32 data, string note, address addr);

/*




function disburse(uint amount) {
  totalDividendPoints += (amount * pointsMultiplier / totalSupply);
  totalSupply += amount;
  unclaimedDividends += amount;
}*/



    function totalDividendPoints() public view returns (uint) {
        return _totalDividendPoints;
    }
    function unclaimedDividends() public view returns (uint) {
        return _unclaimedDividends;
    }

    function dividendsOwing(address account) public view returns (uint) {
        uint newDividendPoints = _totalDividendPoints - accounts[account].lastDividendPoints;
        return (accounts[account].balance * newDividendPoints) / pointMultiplier;
    }
    modifier updateAccount(address account) {
        uint owing = dividendsOwing(account);
        if (owing > 0) {
            _unclaimedDividends -= owing;
            accounts[account].balance += owing;
            accounts[account].lastDividendPoints = _totalDividendPoints;
        }
        _ ;
    }

    function depositDividends(address token, uint dividends) public {
        emit LogInfo("depositDividends: token", 0, 0x0, "", token);
        emit LogInfo("depositDividends: dividends", dividends, 0x0, "", address(0));
        emit LogInfo("depositDividends: pointMultiplier", pointMultiplier, 0x0, "", address(0));
        emit LogInfo("depositDividends: _totalSupply", _totalSupply, 0x0, "", address(0));
        _totalDividendPoints += (dividends * pointMultiplier / _totalSupply);
        _unclaimedDividends += dividends;
        emit LogInfo("depositDividends: _totalDividendPoints", _totalDividendPoints, 0x0, "", address(0));
        emit LogInfo("depositDividends: _unclaimedDividends", _unclaimedDividends, 0x0, "", address(0));
        ERC20Interface(token).transferFrom(msg.sender, address(this), dividends);
    }

    constructor(string memory symbol, string memory name, uint8 decimals, address tokenOwner, uint initialSupply, address _dividendToken) public {
        initOwned(msg.sender);
        _symbol = symbol;
        _name = name;
        _decimals = decimals;
        accounts[tokenOwner].balance = initialSupply;
        _totalSupply = initialSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
        dividendToken = _dividendToken;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(accounts[address(0)].balance);
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallback(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }
    function mint(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }
    function burn(address tokenOwner, uint tokens) public onlyOwner returns (bool success) {
        accounts[tokenOwner].balance = accounts[tokenOwner].balance.sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }
}
// ----------------------------------------------------------------------------
// End - Dividend Paying Token
// ----------------------------------------------------------------------------
