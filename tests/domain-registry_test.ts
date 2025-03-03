Clarinet.test({
    name: "Test subdomain registration permissions",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Register domain with wallet1
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet1.address)
        ]);
        
        // Attempt to register subdomain with wallet2 (should fail)
        block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-subdomain', [
                types.ascii("test.btc"),
                types.ascii("sub")
            ], wallet2.address)
        ]);
        
        // Verify failure due to ownership check
        block.receipts[0].result.expectErr(100); // err-not-domain-owner
        
        // Register subdomain with correct owner (wallet1)
        block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-subdomain', [
                types.ascii("test.btc"),
                types.ascii("sub")
            ], wallet1.address)
        ]);
        
        // Verify successful registration
        block.receipts[0].result.expectOk(true);
    }
});
