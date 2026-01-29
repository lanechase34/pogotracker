component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Image Service Test', () => {
            beforeEach(() => {
                setup();

                imageService = getInstance('services.image');
            });

            it('Service can be created', () => {
                expect(imageService).toBeComponent();
            });

            // it('Can verify image magickis functioning', () => {
            //     var verify = imageService.verifyImageMagick();
            //     expect(verify).toBe(true);
            // });
        });
    }

}
