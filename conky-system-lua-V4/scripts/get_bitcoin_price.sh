#!/bin/bash
# Bitcoin function is disabled, you can enable it in lua2-text.lua
# Line 384: uncomment     --    blocks.bitcoin_price_block(xc)

curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd' | jq -r '.bitcoin.usd' | sed 's/^/$/' > ./bitcoin_price.txt
