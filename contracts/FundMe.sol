//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
// Brownie can download directly from Github
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded; // Can't go through all keys in a mapping. need to create a seperate array
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 min_USD = 50 * 10**18;
        require(
            get_conversion_rate(msg.value) >= min_USD,
            "You need to spend more Ethereum brah"
        );
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
        // Need ETH to USD conversion rate. no decimals on solidity
        // No chainlink nodes on testnet.
        // Interfaces compile down to ABI. Always need an ABI to interact with a contract
    }

    function get_version() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function get_conversion_rate(uint256 eth_amount)
        public
        view
        returns (uint256)
    {
        uint256 eth_price = getPrice();
        uint256 eth_amount_in_usd = (eth_price * eth_amount) /
            1000000000000000000;
        return eth_amount_in_usd;
        // 0.000001188513010280
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // This means run the rest of the code
    }

    function withdraw() public payable onlyOwner {
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance); // This is a keyword to refer to the contract that you are currently in.
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
