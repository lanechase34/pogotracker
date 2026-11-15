component extends="tests.resources.baseTest" {

    function run() {
        describe("Trainer permissions", () => {
            beforeEach(() => {
                trainerService = getInstance("services.trainer");
                userService    = getInstance("services.user");
            });

            it("Maps security levels to named permissions", () => {
                var trainer = {securitylevel: 50, verified: true};

                expect(trainerService.hasPermission(trainer, "user")).toBeTrue();
                expect(trainerService.hasPermission(trainer, "trusted")).toBeTrue();
                expect(trainerService.hasPermission(trainer, "admin")).toBeTrue();
                expect(trainerService.hasPermission(trainer, "developer")).toBeFalse();
                expect(trainerService.hasPermission(trainer, "developer,admin")).toBeTrue(); // any match
                expect(trainerService.hasPermission(trainer, "not-a-permission")).toBeFalse();
            });

            it("Grants nothing to unverified trainers", () => {
                var trainer = {securitylevel: 60, verified: false};
                expect(trainerService.hasPermission(trainer, "user")).toBeFalse();
                expect(trainerService.hasPermission(trainer, "developer")).toBeFalse();
                expect(trainerService.getPermissionNames(trainer)).toBeEmpty();
            });

            it("The logged in user checks the same permissions, as roles too", () => {
                var user = userService.buildUser({
                    id            : 1,
                    securitylevel : 50,
                    verified      : true,
                    settings      : {},
                    sessionversion: 0
                });

                expect(user.hasPermission("admin")).toBeTrue();
                expect(user.hasPermission("developer")).toBeFalse();
                expect(user.hasPermission("developer,admin")).toBeTrue();
                expect(user.hasRole("admin")).toBeTrue();
                expect(user.hasRole("developer")).toBeFalse();
            });
        });
    }

}
