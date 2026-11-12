component extends="tests.resources.baseTest" {

    function run() {
        describe("Trainer permissions", () => {
            it("Maps security levels to named permissions", () => {
                var trainer = entityNew("trainer", {securityLevel: 50, verified: true});

                expect(trainer.hasPermission("user")).toBeTrue();
                expect(trainer.hasPermission("trusted")).toBeTrue();
                expect(trainer.hasPermission("admin")).toBeTrue();
                expect(trainer.hasPermission("developer")).toBeFalse();
                expect(trainer.hasPermission("developer,admin")).toBeTrue(); // any match
                expect(trainer.hasPermission("not-a-permission")).toBeFalse();
                expect(trainer.hasRole("admin")).toBeTrue();
            });

            it("Grants nothing to unverified trainers", () => {
                var trainer = entityNew("trainer", {securityLevel: 60, verified: false});
                expect(trainer.hasPermission("user")).toBeFalse();
                expect(trainer.hasPermission("developer")).toBeFalse();
            });
        });
    }

}
