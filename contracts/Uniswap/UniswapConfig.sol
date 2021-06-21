//SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface IjoveProductToken {
    function underlying() external view returns (address);
}

contract UniswapConfig {
    address public owner;

    /// @dev Describe how to interpret the fixedPrice in the TokenConfig.
    enum PriceSource {
        FIXED_ETH, /// implies the fixedPrice is a constant multiple of the ETH price (which varies)
        FIXED_USD, /// implies the fixedPrice is a constant multiple of the USD price (which is 1)
        REPORTER   /// implies the price is set by the reporter
    }

    /// @dev Describe how the USD price should be determined for an asset.
    ///  There should be 1 TokenConfig object for each supported asset, passed in the constructor.
    struct TokenConfig {
        address jToken;
        address underlying;
        bytes32 symbolHash;
        uint256 baseUnit;
        PriceSource priceSource;
        uint256 fixedPrice;
        address uniswapMarket;
        bool isUniswapReversed;
    }

    TokenConfig[] public tokenConfigs;

    mapping(address => uint) public underlyingIndexs;

    mapping(address => uint) public jTokenIndexs;

    mapping(bytes32 => uint) public symbolHashIndexs;

    event AddTokenConfig(address jToken,address underlying,bytes32 symbolHash,uint256 baseUnit,PriceSource priceSource,uint256 fixedPrice,address uniswapMarket,bool isUniswapReversed);

    /**
     * @notice Construct an immutable store of configs into the contract data
     * @param configs The configs for the supported assets
     */
    constructor(TokenConfig[] memory configs) public {
        owner = tx.origin;
        addTokenConfigs(configs);
    }

    function addTokenConfigs(TokenConfig[] memory configs) public returns(uint) {
        require(msg.sender == owner, "Unauthorized");

        uint oldlen = tokenConfigs.length;
        for(uint i=0; i < configs.length; i++) {
            if(jTokenIndexs[configs[i].jToken] == 0) {
                tokenConfigs.push(configs[i]);
                jTokenIndexs[configs[i].jToken] = tokenConfigs.length;
                underlyingIndexs[configs[i].underlying] = tokenConfigs.length;
                symbolHashIndexs[configs[i].symbolHash] = tokenConfigs.length;

                emit AddTokenConfig(configs[i].jToken, configs[i].underlying, configs[i].symbolHash, configs[i].baseUnit, configs[i].priceSource, configs[i].fixedPrice, configs[i].uniswapMarket, configs[i].isUniswapReversed);
            }

        }

        return tokenConfigs.length - oldlen;
    }

    function getJTokenIndex(address jToken) internal view returns (uint) {
        return jTokenIndexs[jToken];
    }

    function getUnderlyingIndex(address underlying) internal view returns (uint) {
        return underlyingIndexs[underlying];
    }

    function getSymbolHashIndex(bytes32 symbolHash) internal view returns (uint) {
        return symbolHashIndexs[symbolHash];
    }

    /**
     * @notice Get the i-th config, according to the order they were passed in originally
     * @param i The index of the config to get
     * @return The config object
     */
    function getTokenConfig(uint i) public view returns (TokenConfig memory) {
        require(i < tokenConfigs.length, "token config not found");

        return tokenConfigs[i];
    }

    /**
     * @notice Get the config for symbol
     * @param symbol The symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbol(string memory symbol) public view returns (TokenConfig memory) {
        return getTokenConfigBySymbolHash(keccak256(abi.encodePacked(symbol)));
    }

    /**
     * @notice Get the config for the symbolHash
     * @param symbolHash The keccack256 of the symbol of the config to get
     * @return The config object
     */
    function getTokenConfigBySymbolHash(bytes32 symbolHash) public view returns (TokenConfig memory) {
        uint index = getSymbolHashIndex(symbolHash);
        if (index != 0) {
            return getTokenConfig(index-1);
        }

        revert("token config not found");
    }

    /**
     * @notice Get the config for the jToken
     * @dev If a config for the jToken is not found, falls back to searching for the underlying.
     * @param jToken The address of the jToken of the config to get
     * @return The config object
     */
    function getTokenConfigByJToken(address jToken) public view returns (TokenConfig memory) {
        uint index = getJTokenIndex(jToken);
        if (index != 0) {
            return getTokenConfig(index-1);
        }

        return getTokenConfigByUnderlying(IjoveProductToken(jToken).underlying());
    }

    /**
     * @notice Get the config for an underlying asset
     * @param underlying The address of the underlying asset of the config to get
     * @return The config object
     */
    function getTokenConfigByUnderlying(address underlying) public view returns (TokenConfig memory) {
        uint index = getUnderlyingIndex(underlying);
        if (index != 0) {
            return getTokenConfig(index-1);
        }

        revert("token config not found");
    }
}
