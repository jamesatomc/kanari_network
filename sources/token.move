module kanari_network::token {
    use std::option;
    use std::string;
    use moveos_std::signer;
    use moveos_std::object::{Self, Object};
    use rooch_framework::coin::{Self, Coin};
    use rooch_framework::coin_store::{Self, CoinStore};
    use rooch_framework::account_coin_store;
    const ErrorTransferAmountTooLarge: u64 = 1;
    const TOTAL_SUPPLY: u256 = 210_000_000_000u256;
    const DECIMALS: u8 = 1u8;
    // The `KARI` CoinType has `key` and `store` ability.
    // So `KARI` coin is public.
    struct KARI has key, store {}
    // construct the `KARI` coin and make it a global object that stored in `Treasury`.
    struct Treasury has key {
        coin_store: Object<CoinStore<KARI>>
    }
    
    fun init() {
        let coin_info_obj = coin::register_extend<KARI>(    
            string::utf8(b"Fixed Supply Coin"),
            string::utf8(b"KARI"),
              option::some(string::utf8(b"https://example.com/KARI-icon.png")), // Replace with actual icon URL
            DECIMALS,
        );
        // Mint the total supply of coins, and store it to the treasury
        let coin = coin::mint_extend<KARI>(&mut coin_info_obj, TOTAL_SUPPLY);
        // Frozen the CoinInfo object, so that no more coins can be minted
        object::to_frozen(coin_info_obj);
        let coin_store_obj = coin_store::create_coin_store<KARI>();
        coin_store::deposit(&mut coin_store_obj, coin);
        let treasury_obj = object::new_named_object(Treasury { coin_store: coin_store_obj });
        // Make the treasury object to shared, so anyone can get mutable Treasury object
        object::to_shared(treasury_obj);
    }

    public entry fun transfer(from: &signer, to_addr: address, amount: u256) {
        assert!(amount <= 10000u256, ErrorTransferAmountTooLarge);
        let from_addr = signer::address_of(from);
        let fee_amount = amount / 100u256;
        if (fee_amount > 0u256) {
            let fee = account_coin_store::withdraw_extend<KARI>(from_addr, fee_amount);
            deposit_to_treaury(fee);
        };
        account_coin_store::transfer_extend<KARI>(from_addr, to_addr, amount);
    }

    fun deposit_to_treaury(coin: Coin<KARI>) {
        let treasury_object_id = object::named_object_id<Treasury>();
        let treasury_obj = object::borrow_mut_object_extend<Treasury>(treasury_object_id);
        coin_store::deposit_extend(&mut object::borrow_mut(treasury_obj).coin_store, coin);
    }
}