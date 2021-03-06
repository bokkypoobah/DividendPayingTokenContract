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

import "Owned.sol";
import "SafeMath.sol";
import "ApproveAndCallFallback.sol";
import "MintableTokenInterface.sol";


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
    function updateAccount(address account) internal {
        uint owing = dividendsOwing(account);
        emit LogInfo("depositDividends: owing", owing, 0x0, "", account);
        if (owing > 0) {
            emit LogInfo("depositDividends: _unclaimedDividends before", _unclaimedDividends, 0x0, "", account);
            _unclaimedDividends = _unclaimedDividends.sub(owing);
            emit LogInfo("depositDividends: _unclaimedDividends after", _unclaimedDividends, 0x0, "", account);
            emit LogInfo("depositDividends: accounts[account].balance", accounts[account].balance, 0x0, "", account);
            accounts[account].balance = accounts[account].balance.add(owing);
            emit LogInfo("depositDividends: accounts[account].balance", accounts[account].balance, 0x0, "", account);
            emit LogInfo("depositDividends: accounts[account].lastDividendPoints before", accounts[account].lastDividendPoints, 0x0, "", account);
            accounts[account].lastDividendPoints = _totalDividendPoints;
             emit LogInfo("depositDividends: accounts[account].lastDividendPoints after", accounts[account].lastDividendPoints, 0x0, "", account);
        }
    }

    function depositDividends(address token, uint dividends) public {
        emit LogInfo("depositDividends: token", 0, 0x0, "", token);
        emit LogInfo("depositDividends: dividends", dividends, 0x0, "", address(0));
        emit LogInfo("depositDividends: pointMultiplier", pointMultiplier, 0x0, "", address(0));
        emit LogInfo("depositDividends: _totalSupply", _totalSupply, 0x0, "", address(0));
        _totalDividendPoints = _totalDividendPoints.add((dividends * pointMultiplier / _totalSupply));
        _unclaimedDividends = _unclaimedDividends.add(dividends);
        emit LogInfo("depositDividends: _totalDividendPoints", _totalDividendPoints, 0x0, "", address(0));
        emit LogInfo("depositDividends: _unclaimedDividends", _unclaimedDividends, 0x0, "", address(0));
        ERC20Interface(token).transferFrom(msg.sender, address(this), dividends);
    }

    function withdrawDividends(address token) public returns (uint withdrawn) {
        updateAccount(msg.sender);
        withdrawn = 0;
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
        updateAccount(msg.sender);
        updateAccount(to);
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
        updateAccount(from);
        updateAccount(to);
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
