Clarinet.test({
    name: "Test domain registration validation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        
        // Test empty domain name
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("")
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectErr(107); // err-empty-name
        
        // Test consecutive hyphens
        block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test--domain.btc")
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectErr(108); // err-consecutive-hyphens
        
        // Test valid domain
        block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test-domain.btc")
            ], wallet1.address)
        ]);
        block.receipts[0].result.expectOk(true);
    }
});

[... original test remains the same ...]
