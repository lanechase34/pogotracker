component extends="tests.resources.baseTest" {

    function run() {
        describe("Rate limit service", () => {
            beforeEach(() => {
                setup();
                rateLimitService = getInstance("services.rateLimit");
                key              = "ratelimit:test:#createUUID()#";
            });

            it("Can be created", () => {
                expect(rateLimitService).toBeComponent();
            });

            it("Allows hits up to the limit then blocks", () => {
                for(var i = 1; i <= 3; i++) {
                    expect(rateLimitService.hit(key = key, limit = 3, window = 15)).toBeTrue();
                }
                expect(rateLimitService.hit(key = key, limit = 3, window = 15)).toBeFalse();
            });

            it("Starts fresh after clear", () => {
                rateLimitService.hit(key = key, limit = 1, window = 15);
                expect(rateLimitService.hit(key = key, limit = 1, window = 15)).toBeFalse();

                rateLimitService.clear(key = key);
                expect(rateLimitService.hit(key = key, limit = 1, window = 15)).toBeTrue();
            });

            it("Builds the same key regardless of case and whitespace", () => {
                var a = rateLimitService.buildKey(
                    currentEvent = "login.dologin",
                    by           = ["ip", "email"],
                    ip           = "1.2.3.4",
                    context      = {email: "Test@Gmail.com "}
                );
                var b = rateLimitService.buildKey(
                    currentEvent = "login.dologin",
                    by           = ["ip", "email"],
                    ip           = "1.2.3.4",
                    context      = {email: "test@gmail.com"}
                );
                expect(a).toBe(b);
                expect(a).toInclude("login.dologin:ip+email:");
            });

            it("Returns an empty key when a field is missing", () => {
                expect(
                    rateLimitService.buildKey(
                        currentEvent = "login.dologin",
                        by           = ["ip", "email"],
                        ip           = "1.2.3.4",
                        context      = {}
                    )
                ).toBe("");
            });

            it("Uses the passed ip, never an rc ip field", () => {
                var real = rateLimitService.buildKey(
                    currentEvent = "login.dologin",
                    by           = ["ip"],
                    ip           = "1.2.3.4",
                    context      = {ip: "9.9.9.9"}
                );
                var expected = rateLimitService.buildKey(
                    currentEvent = "login.dologin",
                    by           = ["ip"],
                    ip           = "1.2.3.4",
                    context      = {}
                );
                expect(real).toBe(expected);
            });
        });
    }

}
