component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('MailService', () => {
            beforeEach(() => {
                setup();
                mailModel = getInstance('services.email');
            });

            it('Can be created', () => {
                expect(mailModel).toBeComponent();
            });

            it('Can send a test email to the testemails directory', () => {
                var beforeCount = globalFunctions.countTestEmails();
                mailModel.sendTestEmail();

                expect(beforeCount + 1).toBe(globalFunctions.countTestEmails());
            });
        });
    }

}
