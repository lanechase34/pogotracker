component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
        appCache       = getCache("appCache");
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
                select ses
                from pokemon
                where costume = false and shiny = :shiny and shadow = :shadow
                order by number asc
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
        pokemonService.clearDetailCache(ses = ses);
        return pokemonService.getDetailInfo(ses = ses);
    }

    function run() {
        describe("Pokedex index data", () => {
            beforeEach(() => {
                appCache.clear("pokemon.getIndex");
            });

            it("Includes every live non-costume pokemon exactly once", () => {
                var index = pokemonService.getIndex();
                expect(index).toBeArray().notToBeEmpty();

                var allSes = [];
                index.each((group) => allSes.append(group.pokemon.map((mon) => mon.ses), true));

                var expected = queryExecute("select count(id) as count from pokemon where costume = false and live = true");
                expect(allSes.len()).toBe(expected.count);

                // No duplicates
                var unique = {};
                allSes.each((ses) => unique[ses] = true);
                expect(unique.count()).toBe(allSes.len());
            });

            it("Lists exactly the live non-costume pokemon (no costumes)", () => {
                var indexSes = [];
                pokemonService.getIndex().each((group) => indexSes.append(group.pokemon.map((mon) => mon.ses), true));

                var expectedSes = valueArray(
                    queryExecute("select ses from pokemon where costume = false and live = true"),
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
                        select g.region
                        from generation g
                        where exists (select 1 from pokemon p where p.generation = g.generation and p.costume = false and p.live = true)
                        order by g.generation asc
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
                        select ses
                        from pokemon
                        where costume = false and live = true
                        order by generation asc, number asc, form asc
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
                expect(appCache.lookup("pokemon.getIndex")).toBeFalse();
                pokemonService.getIndex();
                expect(appCache.lookup("pokemon.getIndex")).toBeTrue();
            });
        });

        describe("Pokemon detail title and meta description", () => {
            afterEach(() => {
                pokemonService.clearDetailCache(ses = "1");
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
                pokemonService.clearDetailCache(ses = ses);
            });

            it("Mentions only shiny when there is no shadow", () => {
                var ses = findSes(shiny = true, shadow = false);
                if(!ses.len()) return;

                var info = freshDetailInfo(ses);
                expect(info.metaDescription).toInclude("Shiny available.");
                expect(info.metaDescription).notToInclude("shadow available");
                pokemonService.clearDetailCache(ses = ses);
            });

            it("Leaves out availability when neither shiny nor shadow exist", () => {
                var ses = findSes(shiny = false, shadow = false);
                if(!ses.len()) return;

                var info = freshDetailInfo(ses);
                expect(info.metaDescription).notToInclude("available.");
                pokemonService.clearDetailCache(ses = ses);
            });
        });
    }

}
