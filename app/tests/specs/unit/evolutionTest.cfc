component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance("services.pokemon");
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("Evolutions Tests", () => {
            beforeEach(() => {
                setup();
            });

            it("Retrieve Bulbasaur's Evolutions", () => {
                var bulbasaur = pokemonService.findPokemon({
                    number : 1,
                    name   : "Bulbasaur",
                    gender : "",
                    costume: false
                });
                expect(bulbasaur).toBeArray();
                expect(bulbasaur.len()).toBe(1);
                bulbasaur = bulbasaur[1];
                expect(bulbasaur).toBeStruct();

                var evolutions = pokemonService.getEvolution(bulbasaur);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].evolution.name).toBe("Ivysaur");
            });

            it("Retrieve Pikachu's Evolutions", () => {
                var pikachu = pokemonService.findPokemon({
                    number : 25,
                    name   : "Pikachu",
                    gender : "",
                    costume: false
                });
                expect(pikachu).toBeArray();
                expect(pikachu.len()).toBe(1);
                pikachu = pikachu[1];

                // Raichu and Gigantamax Pikachu
                var evolutions = pokemonService.getEvolution(pikachu);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Raichu", "Gigantamax Pikachu"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Wurmple's Evolutions", () => {
                var wurmple = pokemonService.findPokemon({
                    number : 265,
                    name   : "Wurmple",
                    gender : "",
                    costume: false
                });
                expect(wurmple).toBeArray();
                expect(wurmple.len()).toBe(1);
                wurmple = wurmple[1];
                expect(wurmple).toBeStruct();

                var evolutions = pokemonService.getEvolution(wurmple);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkStage1 = ["Cascoon", "Silcoon"];
                var checkStage2 = ["Dustox", "Beautifly"];
                evolutions.each((evolution) => {
                    checkStage1.delete(evolution.evolution.name);

                    var nextStage = pokemonService.getEvolution(evolution.evolution);
                    expect(nextStage).toBeArray();
                    expect(nextStage.len()).toBe(1);
                    checkStage2.delete(nextStage[1].evolution.name);
                });

                expect(checkStage1.len()).toBe(0);
                expect(checkStage2.len()).toBe(0);
            });

            it("Retrieve Oddish's Evolutions", () => {
                var oddish = pokemonService.findPokemon({
                    number : 43,
                    name   : "Oddish",
                    gender : "",
                    costume: false
                });
                expect(oddish).toBeArray();
                expect(oddish.len()).toBe(1);
                oddish = oddish[1];

                var stage1 = pokemonService.getEvolution(oddish);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].evolution.name).toBe("Gloom");

                var stage2 = pokemonService.getEvolution(stage1[1].evolution);
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ["Vileplume", "Bellossom"];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.evolution.name);
                });
                expect(checkStage2.len()).toBe(0);
            });

            it("Retrieve Poliwag's Evolutions", () => {
                var poliwag = pokemonService.findPokemon({
                    number : 60,
                    name   : "Poliwag",
                    gender : "",
                    costume: false
                });
                expect(poliwag).toBeArray();
                expect(poliwag.len()).toBe(1);
                poliwag = poliwag[1];

                var stage1 = pokemonService.getEvolution(poliwag);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].evolution.name).toBe("Poliwhirl");

                var stage2 = pokemonService.getEvolution(stage1[1].evolution);
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ["Poliwrath", "Politoed"];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.evolution.name);
                });
                expect(checkStage2.len()).toBe(0);
            });

            it("Retrieve Slowpoke's Evolutions", () => {
                var slowpoke = pokemonService.findPokemon({
                    number : 79,
                    name   : "Slowpoke",
                    gender : "",
                    costume: false
                });
                expect(slowpoke).toBeArray();
                expect(slowpoke.len()).toBe(1);
                slowpoke = slowpoke[1];

                var evolutions = pokemonService.getEvolution(slowpoke);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Slowbro", "Slowking"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Galarian Slowpoke's Evolutions", () => {
                var slowpoke = pokemonService.findPokemon({
                    number : 79,
                    name   : "Galarian Slowpoke",
                    gender : "",
                    costume: false
                });
                expect(slowpoke).toBeArray();
                expect(slowpoke.len()).toBe(1);
                slowpoke = slowpoke[1];

                var evolutions = pokemonService.getEvolution(slowpoke);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Galarian Slowbro", "Galarian Slowking"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Eevee's Evolutions", () => {
                var eevee = pokemonService.findPokemon({
                    number : 133,
                    name   : "Eevee",
                    gender : "",
                    costume: false
                });
                expect(eevee).toBeArray();
                expect(eevee.len()).toBe(1);
                eevee = eevee[1];

                var evolutions = pokemonService.getEvolution(eevee);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBeGTE(8); // Gigantamax eevee 'counts'

                var checkEvolutions = [
                    "Vaporeon",
                    "Jolteon",
                    "Flareon",
                    "Espeon",
                    "Umbreon",
                    "Leafeon",
                    "Glaceon",
                    "Sylveon"
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Tyrogue's Evolutions", () => {
                var tyrogue = pokemonService.findPokemon({
                    number : 236,
                    name   : "Tyrogue",
                    gender : "",
                    costume: false
                });
                expect(tyrogue).toBeArray();
                expect(tyrogue.len()).toBe(1);
                tyrogue = tyrogue[1];

                var evolutions = pokemonService.getEvolution(tyrogue);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(3);

                var checkEvolutions = ["Hitmonlee", "Hitmonchan", "Hitmontop"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Ralts's Evolutions", () => {
                var ralts = pokemonService.findPokemon({
                    number : 280,
                    name   : "Ralts",
                    gender : "",
                    costume: false
                });
                expect(ralts).toBeArray();
                expect(ralts.len()).toBe(1);
                ralts = ralts[1];

                var stage1 = pokemonService.getEvolution(ralts);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].evolution.name).toBe("Kirlia");

                var stage2 = pokemonService.getEvolution(stage1[1].evolution);
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ["Gardevoir", "Gallade"];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.evolution.name);
                });
                expect(checkStage2.len()).toBe(0);
            });

            it("Retrieve Nincada's Evolutions", () => {
                var nincada = pokemonService.findPokemon({
                    number : 290,
                    name   : "Nincada",
                    gender : "",
                    costume: false
                });
                expect(nincada).toBeArray();
                expect(nincada.len()).toBe(1);
                nincada = nincada[1];

                var evolutions = pokemonService.getEvolution(nincada);
                expect(evolutions).toBeArray();

                // Cannot evolve into Shedinja in GO!
                expect(evolutions.len()).toBe(1);

                var checkEvolutions = ["Ninjask"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Burmy (Plant Cloak)'s Evolutions", () => {
                var burmy = pokemonService.findPokemon({
                    number : 412,
                    name   : "Burmy Plant Cloak",
                    gender : "",
                    costume: false
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Wormadam Plant Cloak", "Mothim"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Burmy (Sandy Cloak)'s Evolutions", () => {
                var burmy = pokemonService.findPokemon({
                    number : 412,
                    name   : "Burmy Sandy Cloak",
                    gender : "",
                    costume: false
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Wormadam Sandy Cloak", "Mothim"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Burmy (Trash Cloak)'s Evolutions", () => {
                var burmy = pokemonService.findPokemon({
                    number : 412,
                    name   : "Burmy Trash Cloak",
                    gender : "",
                    costume: false
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Wormadam Trash Cloak", "Mothim"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Snorunt's Evolutions", () => {
                var snorunt = pokemonService.findPokemon({
                    number : 361,
                    name   : "Snorunt",
                    gender : "",
                    costume: false
                });
                expect(snorunt).toBeArray();
                expect(snorunt.len()).toBe(1);
                snorunt = snorunt[1];

                var evolutions = pokemonService.getEvolution(snorunt);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Glalie", "Froslass"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Clamperl's Evolutions", () => {
                var clamperl = pokemonService.findPokemon({
                    number : 366,
                    name   : "Clamperl",
                    gender : "",
                    costume: false
                });
                expect(clamperl).toBeArray();
                expect(clamperl.len()).toBe(1);
                clamperl = clamperl[1];

                var evolutions = pokemonService.getEvolution(clamperl);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Huntail", "Gorebyss"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Cosmog's Evolutions", () => {
                var cosmog = pokemonService.findPokemon({
                    number : 789,
                    name   : "Cosmog",
                    gender : "",
                    costume: false
                });
                expect(cosmog).toBeArray();
                expect(cosmog.len()).toBe(1);
                cosmog = cosmog[1];

                var stage1 = pokemonService.getEvolution(cosmog);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].evolution.name).toBe("Cosmoem");

                var stage2 = pokemonService.getEvolution(stage1[1].evolution);
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ["Solgaleo", "Lunala"];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.evolution.name);
                });
                expect(checkStage2.len()).toBe(0);
            });

            it("Retrieve Rockruff's Evolutions", () => {
                var rockruff = pokemonService.findPokemon({
                    number : 744,
                    name   : "Rockruff",
                    gender : "",
                    costume: false
                });
                expect(rockruff).toBeArray();
                expect(rockruff.len()).toBe(1);
                rockruff = rockruff[1];

                var evolutions = pokemonService.getEvolution(rockruff);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ["Lycanroc Midday Form", "Lycanroc Midnight Form"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Toxel's Evolutions", () => {
                var toxel = pokemonService.findPokemon({
                    number : 848,
                    name   : "Toxel",
                    gender : "",
                    costume: false
                });
                expect(toxel).toBeArray();
                expect(toxel.len()).toBe(1);
                toxel = toxel[1];

                var evolutions = pokemonService.getEvolution(toxel);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = [
                    "Toxtricity Amped Form",
                    "Toxtricity Low Key Form"
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Applin's Evolutions", () => {
                var applin = pokemonService.findPokemon({
                    number : 840,
                    name   : "Applin",
                    gender : "",
                    costume: false
                });
                expect(applin).toBeArray();
                expect(applin.len()).toBe(1);
                applin = applin[1];

                var evolutions = pokemonService.getEvolution(applin);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(3);

                var checkEvolutions = ["Flapple", "Appletun", "Dipplin"];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Dipplin's Evolutions", () => {
                var dipplin = pokemonService.findPokemon({
                    number : 1011,
                    name   : "Dipplin",
                    gender : "",
                    costume: false
                });
                expect(dipplin).toBeArray();
                expect(dipplin.len()).toBe(1);
                dipplin = dipplin[1];

                var evolutions = pokemonService.getEvolution(dipplin);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].evolution.name).toBe("Hydrapple");
            });

            it("Retrieve Kubfu's Evolutions", () => {
                var cubfu = pokemonService.findPokemon({
                    number : 891,
                    name   : "Kubfu",
                    gender : "",
                    costume: false
                });
                expect(cubfu).toBeArray();
                expect(cubfu.len()).toBe(1);
                cubfu = cubfu[1];

                var evolutions = pokemonService.getEvolution(cubfu);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = [
                    "Urshifu Single Strike Style",
                    "Urshifu Rapid Strike Style"
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.evolution.name);
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it("Retrieve Clobbopus's Evolutions", () => {
                var clobbopus = pokemonService.findPokemon({
                    number : 852,
                    name   : "Clobbopus",
                    gender : "",
                    costume: false
                });
                expect(clobbopus).toBeArray();
                expect(clobbopus.len()).toBe(1);
                clobbopus = clobbopus[1];

                var evolutions = pokemonService.getEvolution(clobbopus);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].evolution.name).toBe("Grapploct");
            });

            it("Retrieve Yungoos's Evolutions", () => {
                var yungoos = pokemonService.findPokemon({
                    number : 734,
                    name   : "Yungoos",
                    gender : "",
                    costume: false
                });
                expect(yungoos).toBeArray();
                expect(yungoos.len()).toBe(1);
                yungoos = yungoos[1];

                var evolutions = pokemonService.getEvolution(yungoos);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].evolution.name).toBe("Gumshoos");
            });

            it("Retrieve Pichu Santa Hat evolutions", () => {
                var santaPichu = pokemonService.findPokemon({
                    number     : 172,
                    name       : "Pichu",
                    gender     : "",
                    costume    : true,
                    costumetype: "Santa Hat"
                });
                expect(santaPichu).toBeArray();
                expect(santaPichu.len()).toBe(1);
                santaPichu = santaPichu[1];

                var stage1 = pokemonService.getEvolution(santaPichu);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].evolution.name).toBe("Pikachu");
                expect(stage1[1].evolution.costume).toBeTrue();
                expect(stage1[1].evolution.costumetype).toBe("Santa Hat");

                var stage2 = pokemonService.getEvolution(stage1[1].evolution);
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(1);
                expect(stage2[1].evolution.name).toBe("Raichu");
                expect(stage2[1].evolution.costume).toBeTrue();
                expect(stage2[1].evolution.costumetype).toBe("Santa Hat");
            });
        });
    }

}
