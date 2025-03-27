#!/bin/bash
# Haal de Bitcoin-prijs op en sla deze op in een tekstbestand
curl -s 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd' | jq -r '.bitcoin.usd' | sed 's/^/$/' > ./bitcoin_price.txt
