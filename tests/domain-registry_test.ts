[Previous tests remain unchanged...]

Clarinet.test({
    name: "Test subdomain separate ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('domain-registry', 'register-domain', [
                types.ascii("test.btc")
            ], wallet1.address),
            Tx.contractCall('domain-registry', 'register-subdomain', [
                types.ascii("test.btc"),
                types.ascii("sub")
            ], wallet2.address)
        ]);
        
        // Verify separate ownership records
        let domainQuery = chain.callReadOnlyFn(
            'domain-registry',
            'get-domain-info',
            [types.principal(wallet1.address)],
            wallet1.address
        );
        
        let subdomainQuery = chain.callReadOnlyFn(
            'domain-registry',
            'get-domain-info',
            [types.principal(wallet2.address)],
            wallet2.address
        );
        
        assertEquals(domainQuery.result.expectSome().owner, wallet1.address);
        assertEquals(subdomainQuery.result.expectSome().owner, wallet2.address);
    }
});

[Additional tests for format validation and expiration...]
