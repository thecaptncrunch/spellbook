{{ config(
    schema = 'opensea_v4_polygon',
    alias = 'events',
    materialized = 'incremental',
    file_format = 'delta',
    incremental_strategy = 'merge',
    unique_key = ['tx_hash', 'evt_index', 'nft_contract_address', 'token_id', 'sub_type', 'sub_idx']
    )
}}
WITH fee_wallets as (
    select wallet_address, wallet_name from (
    values (0x0000a26b00c1f0df003000390027140000faa719,'opensea')
    ) as foo(wallet_address, wallet_name)
)
, trades as (
    {{ seaport_v4_trades(
     blockchain = 'polygon'
     ,source_transactions = source('polygon','transactions')
     ,Seaport_evt_OrderFulfilled = source('seaport_polygon','Seaport_evt_OrderFulfilled')
     ,Seaport_evt_OrdersMatched = source('seaport_polygon','Seaport_evt_OrdersMatched')
     ,fee_wallet_list_cte = 'fee_wallets'
     ,start_date = '2023-02-01'
     ,native_currency_contract = '0x0000000000000000000000000000000000001010'
    )
  }}
)

select *
from trades
where (    fee_wallet_name = 'opensea'
           or right_hash = 0x360c6ebe
         )
-- temporary fix to exclude duplicates
and tx_hash not in (
select tx_hash from
trades
group by tx_hash, evt_index, nft_contract_address, token_id, sub_type, sub_idx
having count(*) > 1
)
