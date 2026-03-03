import Proto
import Testing

@Suite("Generated mock auto-default integration")
struct AutoDefaultMockTests {
    @Test
    private func `auto-default generated mock returns protocol mocks for unstubbed members`() {
        let mock = AutoDefaultBillingServiceMock()
        let service: any AutoDefaultBillingServiceProtocol = mock

        let account = service.primaryAccount()
        let optionalAccount = service.optionalAccount()
        let accounts = service.allAccounts()

        #expect(account is BillingAccountMock)
        #expect(optionalAccount is BillingAccountMock)
        #expect(accounts.count == 1)
        #expect(accounts.first is BillingAccountMock)
    }

    @Test
    private func `auto-default generated mock applies to properties and subscripts`() {
        let mock = AutoDefaultBillingServiceMock()
        let service: any AutoDefaultBillingServiceProtocol = mock

        let currentAccount = service.currentAccount
        let indexedAccount = service[0]

        #expect(currentAccount is BillingAccountMock)
        #expect(indexedAccount is BillingAccountMock)
    }
}
