pragma solidity^0.4.21;
pragma experimental ABIEncoderV2;

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

contract CDPer is DSStop, DSMath {

    ///Main Net\\\
    // uint public slippage = 2*10**16;//2%
    // TubInterface public constant tub = TubInterface(0x448a5065aebb8e423f0896e6c5d525c040f59af3);
    // DSToken public constant dai = DSToken(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);  // Stablecoin
    // DSToken public constant skr = DSToken(0xf53AD2c6851052A81B42133467480961B2321C09);  // Abstracted collateral - PETH
    // WETH public constant gem = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);  // Underlying collateral - WETH
    // DSValue public constant feed = DSValue(0x729D19f657BD0614b4985Cf1D82531c67569197B);  // Price feed
    // OtcInterface public constant otc = OtcInterface(0x14FBCA95be7e99C15Cc2996c6C9d841e54B79425);
    // DSProxyFactory public constant proxyFactory = DSProxyFactory(0x1043fBD15c10A3234664CBdd944A16A204F945E6);
    // ProxyCreationAndExecute public constant proxyCreationAndExecute = ProxyCreationAndExecute(0x793EbBe21607e4F04788F89c7a9b97320773Ec59);
    // address public constant oasisDirectProxy = 0x279594b6843014376a422ebb26a6eab7a30e36f0;

    ///Kovan test net\\\
    uint public slippage = 99*10**16;//99%
    TubInterface public constant tub = TubInterface(0xa71937147b55Deb8a530C7229C442Fd3F31b7db2);
    DSToken public constant dai = DSToken(0xC4375B7De8af5a38a93548eb8453a498222C4fF2);  // Stablecoin
    DSToken public constant skr = DSToken(0xf4d791139cE033Ad35DB2B2201435fAd668B1b64);  // Abstracted collateral - PETH
    DSToken public constant gov = DSToken(0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd);  // MKR Token
    WETH public constant gem = WETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);  // Underlying collateral - WETH
    DSValue public constant feed = DSValue(0xA944bd4b25C9F186A846fd5668941AA3d3B8425F);  // Price feed
    OtcInterface public constant otc = OtcInterface(0x8cf1Cab422A0b6b554077A361f8419cDf122a9F9);
    DSProxyFactory public constant proxyFactory = DSProxyFactory(0x93Ffc328d601c4c5E9cc3C8d257E9AFdAf5b0aC0);
    ProxyCreationAndExecute public constant proxyCreationAndExecute = ProxyCreationAndExecute(0xEE419971E63734Fed782Cfe49110b1544ae8a773);
    address public constant oasisDirectProxy = 0xe635F5F52220A114feA0985AbF7EC8144710507B;

    uint public minETH = WAD / 20; //0.05 ETH
    uint public minDai = WAD * 50; //50 Dai

    function CDPer() public {

    }

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
    }

    uint skRate;

    function createAndJoinCDP() public stoppable payable returns(bytes32 id) {
        // uint startingGem = gem.balanceOf(this);
        // uint startingSkr = skr.balanceOf(this);
        // uint startingDai = dai.balanceOf(this);

        require(msg.value >= minETH);

        gem.deposit.value(msg.value)();
        id = tub.open();

        skRate = tub.ask(WAD);
        _joinCDP(id, msg.value);

        tub.give(id, msg.sender);
    }

    function createAndJoinCDPAllDai() public stoppable returns(bytes32 id) {
        return createAndJoinCDPDai(dai.balanceOf(msg.sender));
    }

    function createAndJoinCDPDai(uint amount) public stoppable returns(bytes32 id) {
        // uint startingGem = gem.balanceOf(this);
        // uint startingSkr = skr.balanceOf(this);
        // uint startingDai = dai.balanceOf(this);

        require(amount >= minDai);
        price = uint(feed.read());

        require(dai.transferFrom(msg.sender, this, amount));
        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));

        id = tub.open();

        skRate = tub.ask(WAD);
        _joinCDP(id, bought);

        tub.give(id, msg.sender);
    }
    
    function _joinCDP(bytes32 id, uint amount) internal {

        
        uint valueSkr = wdiv(amount, skRate);
        tub.join(valueSkr); 

        tub.lock(id, min(valueSkr, skr.balanceOf(this)));
    }

    uint ratio;
    uint price;

    function createCDPLeveraged() public stoppable payable returns(bytes32 id) {

        require(msg.value >= minETH);

        ratio = tub.mat() / 10**9; //liquidation ratio
        price = uint(feed.read());
        skRate = tub.ask(WAD);

        gem.deposit.value(msg.value)();

        id = tub.open();
        
        _joinCDP(id, msg.value);//Initial join
        while(_reinvest(id)) {}

        tub.give(id, msg.sender);
    }

    uint public liquidationPriceWad = 320 * WAD;

    function createCDPLeveragedAllDai() public stoppable returns(bytes32 id) {
        return createCDPLeveragedDai(dai.balanceOf(msg.sender)); 
    }
    
    function createCDPLeveragedDai(uint amount) public stoppable returns(bytes32 id) {

        require(msg.value >= minETH);

        ratio = tub.mat() / 10**9; //liquidation ratio
        price = uint(feed.read());
        skRate = tub.ask(WAD);

        require(dai.transferFrom(msg.sender, this, amount));
        uint bought = otc.sellAllAmount(dai, amount,
            gem, wmul(WAD - slippage, wdiv(amount, price)));

        id = tub.open();
        
        _joinCDP(id, bought);//Initial join
        while(_reinvest(id)) {}

        tub.give(id, msg.sender);
    }


    function _reinvest(bytes32 id) internal returns(bool success) {
        
        // Cup memory cup = tab.cups(id);
        uint debt = tub.tab(id);
        uint ink = tub.ink(id);// locked collateral
        
        require(liquidationPriceWad < price);

        uint maxInvest = wdiv(wmul(liquidationPriceWad, ink), ratio);
        
        if(debt >= maxInvest) {
            return false;
        }
        
        uint leftOver = sub(maxInvest, debt);
        
        if(leftOver >= minDai) {
            tub.draw(id, leftOver);

            uint bought = otc.sellAllAmount(dai, min(leftOver, dai.balanceOf(this)),
                gem, wmul(WAD - slippage, wdiv(leftOver, price)));
            
            _joinCDP(id, bought);

            return true;
        } else {
            return false;
        }
    }

    function shut(uint _id) public auth stoppable {
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

    function shutAndSell(uint _id) public auth stoppable {
        bytes32 id = bytes32(_id);
        uint debt = tub.tab(id);
        if (debt > 0) {
            require(dai.transferFrom(msg.sender, this, debt));
        }
        uint ink = tub.ink(id);// locked collateral
        tub.shut(id);
        uint gemBalance = tub.bid(ink);
        tub.exit(ink);

        price = uint(feed.read());

        uint bought = otc.sellAllAmount(gem, min(gemBalance, gem.balanceOf(this)), 
            dai, wmul(WAD - slippage, wmul(gemBalance, price)));
        
        require(dai.transfer(msg.sender, bought));
    }

    function setSlippage(uint slip) public auth {
        require(slip < WAD);
        slippage = slip;
    }

    function setLiqPrice(uint liq) public auth {
        
        liquidationPriceWad = liq;
    }

    function giveMe(uint id) public auth {
        tub.give(bytes32(id), msg.sender);
    }

    function giveMeWETH() public auth {
        gem.transfer(msg.sender, gem.balanceOf(this));
    }

    function giveMeDai() public auth {
        dai.transfer(msg.sender, dai.balanceOf(this));
    }

    function giveMePETH() public auth {
        skr.transfer(msg.sender, skr.balanceOf(this));
    }

    function giveMeToken(DSToken token) public auth {
        token.transfer(msg.sender, token.balanceOf(this));
    }

    function giveETH() public auth {
        msg.sender.transfer(address(this).balance);
    }

    // // Combines 'self' and 'other' into a single array.
    // // Returns the concatenated arrays:
    // //  [self[0], self[1], ... , self[self.length - 1], other[0], other[1], ... , other[other.length - 1]]
    // // The length of the new array is 'self.length + other.length'
    // function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
    //     bytes memory ret = new bytes(self.length + other.length);
    //     var (src, srcLen) = Memory.fromBytes(self);
    //     var (src2, src2Len) = Memory.fromBytes(other);
    //     var (dest,) = Memory.fromBytes(ret);
    //     var dest2 = dest + src2Len;
    //     Memory.copy(src, dest, srcLen);
    //     Memory.copy(src2, dest2, src2Len);
    //     return ret;
    // }

}