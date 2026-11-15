component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");
        trainer     = mockTrainer.makeSignedIn(); // tracks medal progress through the handler
        testMedal   = left("Test Medal #createUUID()#", 50);

        // Seeded medal the trainer medal lifecycle tracks progress against
        medal      = testData.findRow("medal", {name: "Youngster"});
        silverProg = medal.silver;
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(trainer.id);

        queryExecute("DELETE FROM medal WHERE name LIKE '%Test Medal%'");
    }

    function run() {
        describe("Medal service tests", () => {
            beforeEach(() => {
                setup();
                medalService = getInstance("services.medal");
            });

            it("Can getAll medals", () => {
                var medals = medalService.getAll();
                expect(medals).toBeArray();
                expect(medals.len()).toBeGT(1);
            });

            it("Can create a new medal", () => {
                var medalProperties = {
                    name        : testMedal,
                    description : "Testing",
                    bronze      : 1,
                    silver      : 2,
                    gold        : 3,
                    platinum    : 4,
                    displayOrder: 50
                };
                saveMedal(medalProperties);

                // Load medal by name
                var saved = testData.findRows("medal", {name: medalProperties.name});
                expect(saved.len()).toBe(1);
                expect(saved[1].name).toBe(medalProperties.name);
            });

            it("Can update a medal", () => {
                var medalProperties = {
                    name        : testMedal,
                    description : "Updated",
                    bronze      : 1,
                    silver      : 2,
                    gold        : 3,
                    platinum    : 4,
                    displayOrder: 50
                };
                saveMedal(medalProperties);

                // Load medal by name
                var saved = testData.findRows("medal", {name: medalProperties.name});
                expect(saved.len()).toBe(1);
                expect(saved[1].description).toBe("Updated");
            });

            describe("Trainer medal lifecycle", () => {
                it("Can get no progress against medal", () => {
                    var medalProgress = medalService.getProgress(trainer.id);
                    expect(medalProgress).toBeArray();

                    var found = false;
                    for(var progress in medalProgress) {
                        if(progress.name == medal.name) {
                            expect(progress.tracked).toBeFalse();
                            expect(progress.tier).toBe("");
                            found = true;
                            break;
                        }
                    }

                    expect(found).toBeTrue();
                });

                it("Can track progress against medal", () => {
                    var event = post(
                        route  = "/stats/trackMedalProgress",
                        params = {medal: medal.id, current: silverProg}
                    );
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();
                });

                it("Can get new progress against medal", () => {
                    var medalProgress = medalService.getProgress(trainer.id);
                    expect(medalProgress).toBeArray();

                    var found = false;
                    for(var progress in medalProgress) {
                        if(progress.id == medal.id) {
                            // Expect the amount to be the progress we just tracked
                            expect(progress.tracked).toBeTrue();
                            expect(progress.current).toBe(silverProg);
                            expect(progress.tier).toBe("silver");
                            found = true;
                            break;
                        }
                    }

                    expect(found).toBeTrue();
                });
            });

            describe("Progress cache", () => {
                beforeEach(() => {
                    trainerCache = getInstance("cachebox:trainerCache");
                    cacheKey     = "#trainer.id#|medal.getProgress";
                    getInstance("services.medal").clearProgressCache(trainer.id);
                });

                afterEach(() => {
                    getInstance("services.medal").clearProgressCache(trainer.id);
                });

                it("Caches progress on first load", () => {
                    expect(medalService.getProgress(trainer.id)).toBeArray();
                    expect(trainerCache.get(cacheKey)).notToBeNull();
                });

                it("Returns the cached value instead of querying again", () => {
                    // A sentinel in the cache can only come back if the query is skipped
                    trainerCache.set(cacheKey, ["cached"], 10, 10);
                    expect(medalService.getProgress(trainer.id)).toBe(["cached"]);
                });
            });
        });
    }

    /**
     * Save a medal the way the medal data import does
     *
     * @medalProperties name, description, bronze, silver, gold, platinum, displayOrder
     */
    private void function saveMedal(required struct medalProperties) {
        var properties   = duplicate(arguments.medalProperties);
        var name         = properties.name;
        properties.order = properties.displayOrder;
        properties.delete("name");
        properties.delete("displayOrder");
        getInstance("services.admin").updateMedalData({"#name#": properties});
    }

}
