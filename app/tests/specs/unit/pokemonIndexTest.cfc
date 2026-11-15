component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
        appCache       = getCache("appCache");

        // Built once for the suite, so it reflects the current data rather than whatever was cached before
        appCache.clear("pokemon.getIndex");
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * ses of a non-costume pokemon matching the shiny/shadow flags, empty string when none exist
     */
    private string function findSes(required boolean shiny, required boolean shadow) {
        var result = queryExecute(
            "
                SELECT ses
                FROM pokemon
                WHERE costume = false AND shiny = :shiny AND shadow = :shadow
                ORDER BY number ASC
            ",
            {shiny: {value: shiny, cfsqltype: "boolean"}, shadow: {value: shadow, cfsqltype: "boolean"}},
            {maxrows: 1}
        );
        return result.recordCount ? result.ses : "";
    }

    /**
     * Fresh (uncached) detail info for a pokemon
     */
    private struct function freshDetailInfo(required string ses) {
        pokemonService.clearAllDetailCaches();
        return pokemonService.getDetailInfo(ses = ses);
    }

    function run() {
        describe("Pokedex index data", () => {
            it("Lists every live non-costume pokemon exactly once (no costumes)", () => {
                var index = pokemonService.getIndex();
                expect(index).toBeArray().notToBeEmpty();

                // Sorted equality also covers the count and no duplicates
                var indexSes = [];
                index.each((group) => indexSes.append(group.pokemon.map((mon) => mon.ses), true));

                var expectedSes = valueArray(
                    queryExecute("SELECT ses FROM pokemon WHERE costume = false AND live = true"),
                    "ses"
                );

                indexSes.sort("textnocase");
                expectedSes.sort("textnocase");
                expect(indexSes).toBe(expectedSes);
            });

            it("Groups by generation in ascending order", () => {
                var index = pokemonService.getIndex();

                var firstGeneration = queryExecute(
                    "
                        SELECT generation.region
                        FROM generation
                        WHERE EXISTS (
                            SELECT 1
                            FROM pokemon
                            WHERE pokemon.generation = generation.generation
                                AND pokemon.costume = false
                                AND pokemon.live = true
                        )
                        ORDER BY generation.generation ASC
                    ",
                    {},
                    {maxrows: 1}
                );
                expect(index[1].region).toBe(firstGeneration.region);
                expect(index[1].generation).notToInclude(".0", "Whole generations should not show a decimal");

                var generations = index.map((group) => parseNumber(group.generation));
                var sorted      = duplicate(generations);
                sorted.sort("numeric", "asc");
                expect(generations).toBe(sorted);

                // Each generation appears once
                var unique = {};
                generations.each((gen) => unique[gen] = true);
                expect(unique.count()).toBe(generations.len());
            });

            it("Contains only plain data so it is safe to cache", () => {
                var index = pokemonService.getIndex();
                var entry = index[1].pokemon[1];

                expect(isObject(entry)).toBeFalse();
                expect(entry).toHaveKey("name,number,ses,sprite,type1,type2");
                expect(entry.sprite).toInclude("/includes/images/sprites/");
                expect(isSimpleValue(entry.type2)).toBeTrue();
            });

            it("Orders pokemon by generation, number, then form", () => {
                var expected = queryExecute(
                    "
                        SELECT ses
                        FROM pokemon
                        WHERE costume = false AND live = true
                        ORDER BY generation ASC, number ASC, form ASC
                    ",
                    {},
                    {maxrows: 1}
                );
                expect(pokemonService.getIndex()[1].pokemon[1].ses).toBe(expected.ses);
            });

            it("Includes Bulbasaur linking to its detail page ses", () => {
                var bulbasaur = [];
                pokemonService
                    .getIndex()
                    .each((group) => bulbasaur.append(group.pokemon.filter((mon) => mon.ses == "1"), true));

                expect(bulbasaur).toHaveLength(1);
                expect(bulbasaur[1].name).toBe("Bulbasaur");
                expect(bulbasaur[1].number).toBe(1);
            });

            it("Is cached after the first call", () => {
                appCache.clear("pokemon.getIndex");
                expect(appCache.lookup("pokemon.getIndex")).toBeFalse();
                pokemonService.getIndex();
                expect(appCache.lookup("pokemon.getIndex")).toBeTrue();
            });
        });

        describe("Pokemon detail title and meta description", () => {
            afterEach(() => {
                pokemonService.clearAllDetailCaches();
            });

            it("Title leads with the pokemon's name", () => {
                var info = freshDetailInfo("1");
                expect(info.title).toBe("Bulbasaur - Pokémon GO Max CP, Moves & Stats");
            });

            it("Meta description uses the pokemon's real numbers", () => {
                var info = freshDetailInfo("1");
                expect(info.metaDescription).toInclude("Bulbasaur (##1) in Pokémon GO");
                expect(info.metaDescription).toInclude("max CP #numberFormat(info.cp.lvl50[2], ",")# at level 50");
                expect(info.metaDescription).toInclude("base stats 118 ATK / 111 DEF / 128 HP");
                expect(info.metaDescription).toInclude("Moves, evolutions, and past events.");
            });

            it("Mentions shiny and shadow availability when both exist", () => {
                var ses = findSes(shiny = true, shadow = true);
                if(!ses.len()) return;

                var info = freshDetailInfo(ses);
                expect(info.metaDescription).toInclude("Shiny and shadow available.");
                pokemonService.clearAllDetailCaches();
            });

            it("Mentions only shiny when there is no shadow", () => {
                var ses = findSes(shiny = true, shadow = false);
                if(!ses.len()) return;

                var info = freshDetailInfo(ses);
                expect(info.metaDescription).toInclude("Shiny available.");
                expect(info.metaDescription).notToInclude("shadow available");
                pokemonService.clearAllDetailCaches();
            });

            it("Leaves out availability when neither shiny nor shadow exist", () => {
                var ses = findSes(shiny = false, shadow = false);
                if(!ses.len()) return;

                var info = freshDetailInfo(ses);
                expect(info.metaDescription).notToInclude("available.");
                pokemonService.clearAllDetailCaches();
            });
        });
    }

}
