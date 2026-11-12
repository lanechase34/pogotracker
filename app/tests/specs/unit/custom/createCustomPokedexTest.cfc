component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer   = getInstance("tests.resources.mocktrainer");
        customService = getInstance("services.custom");
        trainer       = mockTrainer.make(); // One trainer for the bundle - login is the slow part

        // Four plain Kanto pokemon to build lists from
        kantoIds = queryExecute(
            "
            SELECT pokemon.id
            FROM pokemon
            INNER JOIN generation ON generation.id = pokemon.generation
            WHERE generation.region = 'Kanto'
                AND pokemon.costume = false
                AND pokemon.mega = false
                AND pokemon.giga = false
            ORDER BY pokemon.number ASC, pokemon.id ASC
            LIMIT 4
            "
        ).columnData("id");
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete(); // also removes every custom + its entries
    }

    function run() {
        describe("customService.createCustomPokedex", () => {
            beforeEach(() => {
                setup();
                // Fresh custom per spec, the trainer is shared
                customid = customService.create(
                    trainer = trainer,
                    name    = "Custom Sync Test #left(createUUID(), 20)#",
                    public  = false
                );
                custom = customService.getFromId(customid);
            });

            it("Adds every submitted pokemon", () => {
                customService.createCustomPokedex(custom = custom, pokemon = [kantoIds[1], kantoIds[2], kantoIds[3]]);

                expect(members()).toBe(sorted([kantoIds[1], kantoIds[2], kantoIds[3]]));
                expect(custom.getCustomPokedex().len()).toBe(3);
            });

            it("Replaces the set on edit - removes dropped pokemon, keeps overlap, adds new", () => {
                customService.createCustomPokedex(custom = custom, pokemon = [kantoIds[1], kantoIds[2], kantoIds[3]]);
                var keptRowId = rowId(kantoIds[2]);

                customService.createCustomPokedex(custom = custom, pokemon = [kantoIds[2], kantoIds[4]]);

                expect(members()).toBe(sorted([kantoIds[2], kantoIds[4]]));
                // Overlapping pokemon is left alone, not deleted and re-inserted
                expect(rowId(kantoIds[2])).toBe(keptRowId);
                // entityReload means the entity reflects the new set
                expect(custom.getCustomPokedex().len()).toBe(2);
            });

            it("Ignores duplicate and string ids in the submitted list", () => {
                customService.createCustomPokedex(
                    custom  = custom,
                    pokemon = [
                        "#kantoIds[1]#",
                        kantoIds[1],
                        kantoIds[2],
                        "#kantoIds[2]#"
                    ]
                );

                expect(members()).toBe(sorted([kantoIds[1], kantoIds[2]]));
            });

            it("Removes everything when given an empty list", () => {
                customService.createCustomPokedex(custom = custom, pokemon = [kantoIds[1], kantoIds[2]]);
                customService.createCustomPokedex(custom = custom, pokemon = []);

                expect(members()).toBe([]);
                expect(custom.getCustomPokedex()?.len() ?: 0).toBe(0);
            });
        });
    }

    private array function members() {
        return queryExecute(
            "SELECT pokemonid FROM custompokedex WHERE customid = :customid ORDER BY pokemonid ASC",
            {customid: {value: customid, cfsqltype: "integer"}}
        ).columnData("pokemonid");
    }

    private numeric function rowId(required numeric pokemonid) {
        return queryExecute(
            "SELECT id FROM custompokedex WHERE customid = :customid AND pokemonid = :pokemonid",
            {
                customid : {value: customid, cfsqltype: "integer"},
                pokemonid: {value: arguments.pokemonid, cfsqltype: "integer"}
            }
        ).id;
    }

    private array function sorted(required array ids) {
        return duplicate(arguments.ids).sort("numeric");
    }

}
