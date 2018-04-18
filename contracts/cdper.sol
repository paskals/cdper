pragma solidity^0.4.21;

import "./lib/ds-thing/thing.sol";
import "./lib/ds-token/token.sol";
import "./lib/ds-stop/stop.sol";
import "./lib/ds-proxy/proxy.sol";

interface DSValue {
    function peek() external constant returns (bytes32, bool);
    function read() external constant returns (bytes32);
}

contract TubInterface {

    function mat() public view returns(uint);

    // function cups(bytes32 cup) public view returns(Cup);

    function ink(bytes32 cup) public view returns (uint);
    function tab(bytes32 cup) public returns (uint);
    function rap(bytes32 cup) public returns (uint);

    //--Collateral-wrapper----------------------------------------------
    // Wrapper ratio (gem per skr)
    function per() public view returns (uint ray);
    // Join price (gem per skr)
    function ask(uint wad) public view returns (uint);
    // Exit price (gem per skr)
    function bid(uint wad) public view returns (uint);
    function join(uint wad) public;
    function exit(uint wad) public;

    //--CDP-risk-indicator----------------------------------------------
    // Abstracted collateral price (ref per skr)
    function tag() public view returns (uint wad);
    // Returns true if cup is well-collateralized
    function safe(bytes32 cup) public returns (bool);

    //--CDP-operations--------------------------------------------------
    function open() public returns (bytes32 cup);
    function give(bytes32 cup, address guy) public;
    function lock(bytes32 cup, uint wad) public;
    function free(bytes32 cup, uint wad) public;
    function draw(bytes32 cup, uint wad) public;
    function wipe(bytes32 cup, uint wad) public;
    function shut(bytes32 cup) public;
    function bite(bytes32 cup) public;
}

interface OtcInterface {
    function sellAllAmount(address, uint, address, uint) public returns (uint);
    function buyAllAmount(address, uint, address, uint) public returns (uint);
    function getPayAmount(address, address, uint) public constant returns (uint);
}

interface ProxyCreationAndExecute {
    
    function createAndSellAllAmount(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        ERC20 buyToken,
        uint minBuyAmt) public 
        returns (DSProxy proxy, uint buyAmt);

    function createAndSellAllAmountPayEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint minBuyAmt) public payable returns (DSProxy proxy, uint buyAmt);

    function createAndSellAllAmountBuyEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        uint minBuyAmt) public returns (DSProxy proxy, uint wethAmt);

    function createAndBuyAllAmount(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (DSProxy proxy, uint payAmt);

    function createAndBuyAllAmountPayEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt) public payable returns (DSProxy proxy, uint wethAmt);

    function createAndBuyAllAmountBuyEth(
        DSProxyFactory factory, 
        OtcInterface otc, 
        uint wethAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (DSProxy proxy, uint payAmt);
} 

interface OasisDirectInterface {
    
    function sellAllAmount(
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        ERC20 buyToken,
        uint minBuyAmt) public 
        returns (uint buyAmt);

    function sellAllAmountPayEth(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint minBuyAmt) public payable returns (uint buyAmt);

    function sellAllAmountBuyEth(
        OtcInterface otc, 
        ERC20 payToken, 
        uint payAmt, 
        uint minBuyAmt) public returns (uint wethAmt);

    function buyAllAmount(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (uint payAmt);

    function buyAllAmountPayEth(
        OtcInterface otc, 
        ERC20 buyToken, 
        uint buyAmt) public payable returns (uint wethAmt);

    function buyAllAmountBuyEth(
        OtcInterface otc, 
        uint wethAmt, 
        ERC20 payToken, 
        uint maxPayAmt) public returns (uint payAmt);
}

contract WETH is ERC20 {
    function deposit() public payable;
    function withdraw(uint wad) public;
}

/**
    A contract to help creating creating CDPs in MakerDAO's system
    The motivation for this is simply to save time and automate some steps for people who
    want to create CDPs often
*/
contract CDPer is DSStop, DSMath {

    ///Main Net\\\
    // uint public slippage = WAD / 50;//2%
    // TubInterface public tub = TubInterface(0x448a5065aebb8e423f0896e6c5d525c040f59af3);
    // DSToken public dai = DSToken(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);  // Stablecoin
    // DSToken public skr = DSToken(0xf53AD2c6851052A81B42133467480961B2321C09);  // Abstracted collateral - PETH
    // WETH public gem = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  // Underlying collateral - WETH
    // DSToken public gov = DSToken(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);  // MKR Token
    // DSValue public feed = DSValue(0x729D19f657BD0614b4985Cf1D82531c67569197B);  // Price feed
    // OtcInterface public otc = OtcInterface(0x14FBCA95be7e99C15Cc2996c6C9d841e54B79425);

    ///Kovan test net\\\
    ///This is the acceptable price difference when exchanging at the otc. 0.01 * 10^18 == 1% acceptable slippage 
    uint public slippage = 99*10**16;//99%
    TubInterface public tub = TubInterface(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);
    DSToken public dai = DSToken(0xC4375B7De8af5a38a93548eb8453a498222C4fF2);  // Stablecoin
    DSToken public skr = DSToken(0xf4d791139cE033Ad35DB2B2201435fAd668B1b64);  // Abstracted collateral - PETH
    DSToken public gov = DSToken(0xAaF64BFCC32d0F15873a02163e7E500671a4ffcD);  // MKR Token
    WETH public gem = WETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);  // Underlying collateral - WETH
    DSValue public feed = DSValue(0xA944bd4b25C9F186A846fd5668941AA3d3B8425F);  // Price feed
    OtcInterface public otc = OtcInterface(0x8cf1Cab422A0b6b554077A361f8419cDf122a9F9);

    ///You won't be able to create a CDP or trade less than these values
    uint public minETH = WAD / 20; //0.05 ETH
    uint public minDai = WAD * 50; //50 Dai

    //if you recursively want to invest your CDP, this will be the target liquidation price
    uint public liquidationPriceWad = 320 * WAD;

    /// liquidation ratio from Maker tub (can be updated manually)
    uint ratio;

    function CDPer() public {

    }

    /**
     @notice Sets all allowances and updates tub liquidation ratio
     */
    function init() public auth {
        gem.approve(tub, uint(-1));
        skr.approve(tub, uint(-1));
        dai.approve(tub, uint(-1));
        gov.approve(tub, uint(-1));
        
        gem.approve(owner, uint(-1));
        skr.approve(owner, uint(-1));
        dai.approve(owner, uint(-1));
        gov.approve(owner, uint(-1));

        dai.approve(otc, uint(-1));
        gem.approve(otc, uint(-1));

        tubParamUpdate();
    }

    /**
     @notice updates tub liquidation ratio
     */
    function tubParamUpdate() public auth {
        ratio = tub.mat() / 10**9; //liquidation ratio
    }

     /**
     @notice create a CDP and join with the ETH sent to this function
     @dev This function wraps ETH, converts to PETH, creates a CDP, joins with the PETH created and gives the CDP to the sender. Will revert if there's not enough WETH to buy with the acceptable slippage
     */
    function createAndJoinCDP() public stoppable payable returns(bytes32 id) {

        require(msg.value >= minETH);

        gem.deposit.value(msg.value)();
        
        id = _openAndJoinCDPWETH(msg.value);

        tub.give(id, msg.sender);
    }

    /**
     @notice create a CDP from all the Dai in the sender's balance - needs Dai transfer approval
     @dev this function will sell the Dai at otc for weth and then do the same as create and JoinCDP.  Will revert if there's not enough WETH to buy with the acceptable slippage
     */
    function createAndJoinCDPAllDai() public returns(bytes32 id) {
        return createAndJoinCDPDai(dai.balanceOf(msg.sender));
    }

    /**
     @notice create a CDP from the given amount of Dai in the sender's balance - needs Dai transfer approval
     @dev this function will sell the Dai at otc for weth and then do the same as create and JoinCDP.  Will revert if there's not enough WETH to buy with the acceptable slippage
     @param amount - dai to transfer from the sender's balance (needs approval)
     */
    function createAndJoinCDPDai(uint amount) public auth stoppable returns(bytes32 id) {
        require(amount >= minDai);

        uint price = uint(feed.read());

        require(dai.transferFrom(msg.sender, this, amount));

        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));
        
        id = _openAndJoinCDPWETH(bought);
        
        tub.give(id, msg.sender);
    }


    /**
     @notice create a CDP from the ETH sent, and then create Dai and reinvest it in the CDP until the target liquidation price is reached (or the minimum investment amount)
     @dev same as openAndJoinCDP, but then draw and reinvest dai. Will revert if trades are not possible.
     */
    function createCDPLeveraged() public auth stoppable payable returns(bytes32 id) {
        require(msg.value >= minETH);

        uint price = uint(feed.read());

        gem.deposit.value(msg.value)();

        id = _openAndJoinCDPWETH(msg.value);

        while(_reinvest(id, price)) {}

        tub.give(id, msg.sender);
    }

    /**
     @notice create a CDP all the Dai in the sender's balance (needs approval), and then create Dai and reinvest it in the CDP until the target liquidation price is reached (or the minimum investment amount)
     @dev same as openAndJoinCDPDai, but then draw and reinvest dai. Will revert if trades are not possible.
     */
    function createCDPLeveragedAllDai() public returns(bytes32 id) {
        return createCDPLeveragedDai(dai.balanceOf(msg.sender)); 
    }
    
    /**
     @notice create a CDP the given amount of Dai in the sender's balance (needs approval), and then create Dai and reinvest it in the CDP until the target liquidation price is reached (or the minimum investment amount)
     @dev same as openAndJoinCDPDai, but then draw and reinvest dai. Will revert if trades are not possible.
     */
    function createCDPLeveragedDai(uint amount) public auth stoppable returns(bytes32 id) {

        require(amount >= minDai);

        uint price = uint(feed.read());

        require(dai.transferFrom(msg.sender, this, amount));
        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));

        id = _openAndJoinCDPWETH(bought);

        while(_reinvest(id, price)) {}

        tub.give(id, msg.sender);
    }

    /**
     @notice Shuts a CDP and returns the value in the form of ETH. You need to give permission for the amount of debt in Dai, so that the contract will draw it from your account. You need to give the CDP to this contract before using this function. You also need to send a small amount of MKR to this contract so that the fee can be paid.
     @dev this function pays all debt(from the sender's account) and fees(there must be enough MKR present on this account), then it converts PETH to WETH, and then WETH to ETH, finally it sends the balance to the sender
     @param _id id of the CDP to shut - it must be given to this contract
     */
    function shutForETH(uint _id) public auth stoppable {
        bytes32 id = bytes32(_id);
        uint debt = tub.tab(id);
        if (debt > 0) {
            require(dai.transferFrom(msg.sender, this, debt));
        }
        uint ink = tub.ink(id);// locked collateral
        tub.shut(id);
        uint gemBalance = tub.bid(ink);
        tub.exit(ink);

        gem.withdraw(min(gemBalance, gem.balanceOf(this)));
        
        msg.sender.transfer(min(gemBalance, address(this).balance));
    }

    /**
     @notice shuts the CDP and returns all the value in the form of Dai. You need to give permission for the amount of debt in Dai, so that the contract will draw it from your account. You need to give the CDP to this contract before using this function. You also need to send a small amount of MKR to this contract so that the fee can be paid.
     @dev this function pays all debt(from the sender's account) and fees(there must be enough MKR present on this account), then it converts PETH to WETH, then trades WETH for Dai, and sends it to the sender
     @param _id id of the CDP to shut - it must be given to this contract
     */
    function shutForDai(uint _id) public auth stoppable {
        bytes32 id = bytes32(_id);
        uint debt = tub.tab(id);
        if (debt > 0) {
            require(dai.transferFrom(msg.sender, this, debt));
        }
        uint ink = tub.ink(id);// locked collateral
        tub.shut(id);
        uint gemBalance = tub.bid(ink);
        tub.exit(ink);

        uint price = uint(feed.read());

        uint bought = otc.sellAllAmount(gem, min(gemBalance, gem.balanceOf(this)), 
            dai, wmul(WAD - slippage, wmul(gemBalance, price)));
        
        require(dai.transfer(msg.sender, bought));
    }

    /**
     @notice give ownership of a CDP back to the sender
     @param id id of the CDP owned by this contract
     */
    function giveMeCDP(uint id) public auth {
        tub.give(bytes32(id), msg.sender);
    }

    /**
     @notice transfer any token from this contract to the sender
     @param token : token contract address
     */
    function giveMeToken(DSToken token) public auth {
        token.transfer(msg.sender, token.balanceOf(this));
    }

    /**
     @notice transfer all ETH balance from this contract to the sender
     */
    function giveMeETH() public auth {
        msg.sender.transfer(address(this).balance);
    }

    /**
     @notice transfer all ETH balance from this contract to the sender and destroy the contract. Must be stopped
     */
    function destroy() public auth {
        require(stopped);
        selfdestruct(msg.sender);
    }

    /**
     @notice set the acceptable price slippage for trades.
     @param slip E.g: 0.01 * 10^18 == 1% acceptable slippage 
     */
    function setSlippage(uint slip) public auth {
        require(slip < WAD);
        slippage = slip;
    }

    /**
     @notice set the target liquidation price for leveraged CDPs created 
     @param wad E.g. 300 * 10^18 == 300 USD target liquidation price
     */
    function setLiqPrice(uint wad) public auth {        
        liquidationPriceWad = wad;
    }

    /**
     @notice set the minimal ETH for trades (depends on otc)
     @param wad minimal ETH to trade
     */
    function setMinETH(uint wad) public auth {
        minETH = wad;
    }

    /**
     @notice set the minimal Dai for trades (depends on otc)
     @param wad minimal Dai to trade
     */
    function setMinDai(uint wad) public auth {
        minDai = wad;
    }

    function setTub(TubInterface _tub) public auth {
        tub = _tub;
    }

    function setDai(DSToken _dai) public auth {
        dai = _dai;
    }

    function setSkr(DSToken _skr) public auth {
        skr = _skr;
    }
    function setGov(DSToken _gov) public auth {
        gov = _gov;
    }
    function setGem(WETH _gem) public auth {
        gem = _gem;
    }
    function setFeed(DSValue _feed) public auth {
        feed = _feed;
    }
    function setOTC(OtcInterface _otc) public auth {
        otc = _otc;
    }

    function _openAndJoinCDPWETH(uint amount) internal returns(bytes32 id) {
        id = tub.open();

        _joinCDP(id, amount);
    }

    function _joinCDP(bytes32 id, uint amount) internal {

        uint skRate = tub.ask(WAD);
        
        uint valueSkr = wdiv(amount, skRate);

        tub.join(valueSkr); 

        tub.lock(id, min(valueSkr, skr.balanceOf(this)));
    }

    function _reinvest(bytes32 id, uint latestPrice) internal returns(bool ok) {
        
        // Cup memory cup = tab.cups(id);
        uint debt = tub.tab(id);
        uint ink = tub.ink(id);// locked collateral
        
        uint maxInvest = wdiv(wmul(liquidationPriceWad, ink), ratio);
        
        if(debt >= maxInvest) {
            return false;
        }
        
        uint leftOver = sub(maxInvest, debt);
        
        if(leftOver >= minDai) {
            tub.draw(id, leftOver);

            uint bought = otc.sellAllAmount(dai, min(leftOver, dai.balanceOf(this)),
                gem, wmul(WAD - slippage, wdiv(leftOver, latestPrice)));
            
            _joinCDP(id, bought);

            return true;
        } else {
            return false;
        }
    }

}

contract CDPerFactory {
    event Created(address indexed sender, address cdper);
    mapping(address=>bool) public isCDPer;

    // deploys a new CDPer instance
    // sets owner of CDPer to caller
    function build() public returns (CDPer cdper) {
        cdper = build(msg.sender);
    }

    // deploys a new CDPer instance
    // sets custom owner of CDPer
    function build(address owner) public returns (CDPer cdper) {
        cdper = new CDPer();
        emit Created(owner, address(cdper));
        cdper.setOwner(owner);
        isCDPer[cdper] = true;
    }
}