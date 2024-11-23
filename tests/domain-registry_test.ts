import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test domain registration",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        
        // Verify domain ownership
        let query = chain.callReadOnlyFn(
            'domain-registry',
            'get-domain-owner',
            [types.ascii("test.btc")],
            wallet1.address
        );
        
        assertEquals(query.result.expectSome(), wallet1.address);
    }
});

Clarinet.test({
    name: "Test duplicate registration prevention",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet1.address),
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet2.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectErr(types.uint(101)); // err-already-registered
    }
});

Clarinet.test({
    name: "Test domain transfer",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet1.address),
            Tx.contractCall('domain-registry', 'transfer-domain', [
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        
        // Verify new ownership
        let query = chain.callReadOnlyFn(
            'domain-registry',
            'get-domain-owner',
            [types.ascii("test.btc")],
            wallet1.address
        );
        
        assertEquals(query.result.expectSome(), wallet2.address);
    }
});
