component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("Image Service Test", () => {
            beforeEach(() => {
                setup();

                imageService = getInstance("Helpers@ImageMagick");
            });

            // Skip check in test env
            it(
                "Can verify image magickis functioning",
                () => {
                    expect(() => {
                        imageService.verifyImageMagick()
                    }).notToThrow();
                },
                "",
                application.cbController.getSetting("environment") == "test"
            );
        });
    }

}
