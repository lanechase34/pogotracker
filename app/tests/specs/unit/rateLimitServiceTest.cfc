component extends="tests.resources.baseTest" {

    /**
     * Configure the limits the service under test sees
     */
    private function withRules(required array rules) {
        service.$property(propertyName = "rateLimits", mock = {"#name#": {redirect: "", rules: rules}});
    }

    function run() {
        describe("Rate limit service", () => {
            beforeEach(() => {
                setup();
                rateLimitService = getInstance("services.rateLimit");
                key              = "ratelimit:test:#createUUID()#";
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

            describe("allow and reset", () => {
                beforeEach(() => {
                    // Fresh instance - limits and the switch are swapped per test without touching the singleton
                    service = prepareMock(new models.services.rateLimit());
                    service.$property(propertyName = "cacheStorage", mock = getCache("rateLimitStorage"));
                    service.$property(propertyName = "useRateLimiter", mock = true);

                    // Unique name per test so counters never carry over
                    name = "test.#createUUID()#";
                    ip   = "1.2.3.4";
                });

                it("Allows everything when useRateLimiter is false", () => {
                    withRules([{by: "ip", limit: 1, window: 15}]);
                    service.$property(propertyName = "useRateLimiter", mock = false);

                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                });

                it("Allows a name with no rate limit configured", () => {
                    service.$property(propertyName = "rateLimits", mock = {});

                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                });

                it("Blocks once a rule is over its limit", () => {
                    withRules([{by: "ip", limit: 2, window: 15}]);

                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                    expect(service.allow(name = name, ip = ip)).toBeFalse();
                });

                it("Scopes rules by context fields", () => {
                    withRules([{by: "email", limit: 1, window: 15}]);

                    expect(
                        service.allow(
                            name    = name,
                            ip      = ip,
                            context = {email: "a@gmail.com"}
                        )
                    ).toBeTrue();
                    expect(
                        service.allow(
                            name    = name,
                            ip      = ip,
                            context = {email: "a@gmail.com"}
                        )
                    ).toBeFalse();
                    expect(
                        service.allow(
                            name    = name,
                            ip      = ip,
                            context = {email: "b@gmail.com"}
                        )
                    ).toBeTrue();
                });

                it("Skips a rule whose key cannot be built", () => {
                    withRules([{by: "email", limit: 1, window: 15}]);

                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                    expect(service.allow(name = name, ip = ip)).toBeTrue();
                });

                it("Counts every rule even after one is over", () => {
                    var context = {email: "a@gmail.com"};
                    withRules([
                        {by: "ip", limit: 1, window: 15},
                        {by: "ip,email", limit: 2, window: 15}
                    ]);

                    expect(service.allow(name = name, ip = ip, context = context)).toBeTrue();
                    // ip rule is over - the ip+email rule still takes its second hit
                    expect(service.allow(name = name, ip = ip, context = context)).toBeFalse();

                    withRules([{by: "ip,email", limit: 2, window: 15}]);
                    expect(service.allow(name = name, ip = ip, context = context)).toBeFalse();
                });

                it("Resets only the rules marked resetOnSuccess", () => {
                    var context = {email: "a@gmail.com"};
                    withRules([
                        {by: "ip", limit: 1, window: 15},
                        {
                            by            : "ip,email",
                            limit         : 1,
                            window        : 15,
                            resetOnSuccess: true
                        }
                    ]);
                    service.allow(name = name, ip = ip, context = context);

                    service.reset(name = name, ip = ip, context = context);

                    withRules([{by: "ip,email", limit: 1, window: 15}]);
                    expect(service.allow(name = name, ip = ip, context = context)).toBeTrue();

                    withRules([{by: "ip", limit: 1, window: 15}]);
                    expect(service.allow(name = name, ip = ip, context = context)).toBeFalse();
                });

                it("Does not reset when useRateLimiter is false", () => {
                    withRules([
                        {
                            by            : "ip",
                            limit         : 1,
                            window        : 15,
                            resetOnSuccess: true
                        }
                    ]);
                    service.allow(name = name, ip = ip);

                    service.$property(propertyName = "useRateLimiter", mock = false);
                    service.reset(name = name, ip = ip);

                    service.$property(propertyName = "useRateLimiter", mock = true);
                    expect(service.allow(name = name, ip = ip)).toBeFalse();
                });
            });
        });
    }

}
