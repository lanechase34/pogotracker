component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Branching Evolutions Tests', () => {
            beforeEach(() => {
                setup();
            });

            it('Retrieve Wurmple''s Evolutions', () => {
                var wurmple = pokemonService.get({
                    number: 265,
                    name  : 'Wurmple',
                    gender: ''
                });
                expect(wurmple).toBeArray();
                expect(wurmple.len()).toBe(1);
                wurmple = wurmple[1];
                expect(wurmple).toBeComponent();

                var evolutions = pokemonService.getEvolution(wurmple);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkStage1 = ['Cascoon', 'Silcoon'];
                var checkStage2 = ['Dustox', 'Beautifly'];
                evolutions.each((evolution) => {
                    checkStage1.delete(evolution.getEvolution().getName());

                    var nextStage = pokemonService.getEvolution(evolution.getEvolution());
                    expect(nextStage).toBeArray();
                    expect(nextStage.len()).toBe(1);
                    checkStage2.delete(nextStage[1].getEvolution().getName());
                });

                expect(checkStage1.len()).toBe(0);
                expect(checkStage2.len()).toBe(0);
            });

            it('Retrieve Oddish''s Evolutions', () => {
                var oddish = pokemonService.get({number: 43, name: 'Oddish', gender: ''});
                expect(oddish).toBeArray();
                expect(oddish.len()).toBe(1);
                oddish = oddish[1];

                var stage1 = pokemonService.getEvolution(oddish);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].getEvolution().getName()).toBe('Gloom');

                var stage2 = pokemonService.getEvolution(stage1[1].getEvolution());
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ['Vileplume', 'Bellossom'];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.getEvolution().getName());
                });
                expect(checkStage2.len()).toBe(0);
            });

            it('Retrieve Poliwag''s Evolutions', () => {
                var poliwag = pokemonService.get({
                    number: 60,
                    name  : 'Poliwag',
                    gender: ''
                });
                expect(poliwag).toBeArray();
                expect(poliwag.len()).toBe(1);
                poliwag = poliwag[1];

                var stage1 = pokemonService.getEvolution(poliwag);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].getEvolution().getName()).toBe('Poliwhirl');

                var stage2 = pokemonService.getEvolution(stage1[1].getEvolution());
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ['Poliwrath', 'Politoed'];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.getEvolution().getName());
                });
                expect(checkStage2.len()).toBe(0);
            });

            it('Retrieve Slowpoke''s Evolutions', () => {
                var slowpoke = pokemonService.get({
                    number: 79,
                    name  : 'Slowpoke',
                    gender: ''
                });
                expect(slowpoke).toBeArray();
                expect(slowpoke.len()).toBe(1);
                slowpoke = slowpoke[1];

                var evolutions = pokemonService.getEvolution(slowpoke);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Slowbro', 'Slowking'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Galarian Slowpoke''s Evolutions', () => {
                var slowpoke = pokemonService.get({
                    number: 79,
                    name  : 'Galarian Slowpoke',
                    gender: ''
                });
                expect(slowpoke).toBeArray();
                expect(slowpoke.len()).toBe(1);
                slowpoke = slowpoke[1];

                var evolutions = pokemonService.getEvolution(slowpoke);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Galarian Slowbro', 'Galarian Slowking'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Eevee''s Evolutions', () => {
                var eevee = pokemonService.get({number: 133, name: 'Eevee', gender: ''});
                expect(eevee).toBeArray();
                expect(eevee.len()).toBe(1);
                eevee = eevee[1];

                var evolutions = pokemonService.getEvolution(eevee);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBeGTE(8); // Gigantamax eevee 'counts'

                var checkEvolutions = [
                    'Vaporeon',
                    'Jolteon',
                    'Flareon',
                    'Espeon',
                    'Umbreon',
                    'Leafeon',
                    'Glaceon',
                    'Sylveon'
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Tyrogue''s Evolutions', () => {
                var tyrogue = pokemonService.get({
                    number: 236,
                    name  : 'Tyrogue',
                    gender: ''
                });
                expect(tyrogue).toBeArray();
                expect(tyrogue.len()).toBe(1);
                tyrogue = tyrogue[1];

                var evolutions = pokemonService.getEvolution(tyrogue);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(3);

                var checkEvolutions = ['Hitmonlee', 'Hitmonchan', 'Hitmontop'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Ralts''s Evolutions', () => {
                var ralts = pokemonService.get({number: 280, name: 'Ralts', gender: ''});
                expect(ralts).toBeArray();
                expect(ralts.len()).toBe(1);
                ralts = ralts[1];

                var stage1 = pokemonService.getEvolution(ralts);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].getEvolution().getName()).toBe('Kirlia');

                var stage2 = pokemonService.getEvolution(stage1[1].getEvolution());
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ['Gardevoir', 'Gallade'];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.getEvolution().getName());
                });
                expect(checkStage2.len()).toBe(0);
            });

            it('Retrieve Nincada''s Evolutions', () => {
                var nincada = pokemonService.get({
                    number: 290,
                    name  : 'Nincada',
                    gender: ''
                });
                expect(nincada).toBeArray();
                expect(nincada.len()).toBe(1);
                nincada = nincada[1];

                var evolutions = pokemonService.getEvolution(nincada);
                expect(evolutions).toBeArray();

                // Cannot evolve into Shedinja in GO!
                expect(evolutions.len()).toBe(1);

                var checkEvolutions = ['Ninjask'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Burmy (Plant Cloak)''s Evolutions', () => {
                var burmy = pokemonService.get({
                    number: 412,
                    name  : 'Burmy Plant Cloak',
                    gender: ''
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Wormadam Plant Cloak', 'Mothim'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Burmy (Sandy Cloak)''s Evolutions', () => {
                var burmy = pokemonService.get({
                    number: 412,
                    name  : 'Burmy Sandy Cloak',
                    gender: ''
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Wormadam Sandy Cloak', 'Mothim'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Burmy (Trash Cloak)''s Evolutions', () => {
                var burmy = pokemonService.get({
                    number: 412,
                    name  : 'Burmy Trash Cloak',
                    gender: ''
                });
                expect(burmy).toBeArray();
                expect(burmy.len()).toBe(1);
                burmy = burmy[1];

                var evolutions = pokemonService.getEvolution(burmy);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Wormadam Trash Cloak', 'Mothim'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Snorunt''s Evolutions', () => {
                var snorunt = pokemonService.get({
                    number: 361,
                    name  : 'Snorunt',
                    gender: ''
                });
                expect(snorunt).toBeArray();
                expect(snorunt.len()).toBe(1);
                snorunt = snorunt[1];

                var evolutions = pokemonService.getEvolution(snorunt);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Glalie', 'Froslass'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Clamperl''s Evolutions', () => {
                var clamperl = pokemonService.get({
                    number: 366,
                    name  : 'Clamperl',
                    gender: ''
                });
                expect(clamperl).toBeArray();
                expect(clamperl.len()).toBe(1);
                clamperl = clamperl[1];

                var evolutions = pokemonService.getEvolution(clamperl);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = ['Huntail', 'Gorebyss'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Cosmog''s Evolutions', () => {
                var cosmog = pokemonService.get({
                    number: 789,
                    name  : 'Cosmog',
                    gender: ''
                });
                expect(cosmog).toBeArray();
                expect(cosmog.len()).toBe(1);
                cosmog = cosmog[1];

                var stage1 = pokemonService.getEvolution(cosmog);
                expect(stage1).toBeArray();
                expect(stage1.len()).toBe(1);
                expect(stage1[1].getEvolution().getName()).toBe('Cosmoem');

                var stage2 = pokemonService.getEvolution(stage1[1].getEvolution());
                expect(stage2).toBeArray();
                expect(stage2.len()).toBe(2);

                var checkStage2 = ['Solgaleo', 'Lunala'];
                stage2.each((evolution) => {
                    checkStage2.delete(evolution.getEvolution().getName());
                });
                expect(checkStage2.len()).toBe(0);
            });

            it('Retrieve Rockruff''s Evolutions', () => {
                var rockruff = pokemonService.get({
                    number: 744,
                    name  : 'Rockruff',
                    gender: ''
                });
                expect(rockruff).toBeArray();
                expect(rockruff.len()).toBe(1);
                rockruff = rockruff[1];

                var evolutions = pokemonService.getEvolution(rockruff);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = [
                    'Lycanroc Midday Form',
                    'Lycanroc Midnight Form',
                    // 'Lycanroc Dusk Form'
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Toxel''s Evolutions', () => {
                var toxel = pokemonService.get({number: 848, name: 'Toxel', gender: ''});
                expect(toxel).toBeArray();
                expect(toxel.len()).toBe(1);
                toxel = toxel[1];

                var evolutions = pokemonService.getEvolution(toxel);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = [
                    'Toxtricity Amped Form',
                    'Toxtricity Low Key Form'
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Applin''s Evolutions', () => {
                var applin = pokemonService.get({
                    number: 840,
                    name  : 'Applin',
                    gender: ''
                });
                expect(applin).toBeArray();
                expect(applin.len()).toBe(1);
                applin = applin[1];

                var evolutions = pokemonService.getEvolution(applin);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(3);

                var checkEvolutions = ['Flapple', 'Appletun', 'Dipplin'];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Dipplin''s Evolutions', () => {
                var dipplin = pokemonService.get({
                    number: 1011,
                    name  : 'Dipplin',
                    gender: ''
                });
                expect(dipplin).toBeArray();
                expect(dipplin.len()).toBe(1);
                dipplin = dipplin[1];

                var evolutions = pokemonService.getEvolution(dipplin);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].getEvolution().getName()).toBe('Hydrapple');
            });

            it('Retrieve Kubfu''s Evolutions', () => {
                var cubfu = pokemonService.get({number: 891, name: 'Kubfu', gender: ''});
                expect(cubfu).toBeArray();
                expect(cubfu.len()).toBe(1);
                cubfu = cubfu[1];

                var evolutions = pokemonService.getEvolution(cubfu);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(2);

                var checkEvolutions = [
                    'Urshifu Single Strike Style',
                    'Urshifu Rapid Strike Style'
                ];
                evolutions.each((evolution) => {
                    checkEvolutions.delete(evolution.getEvolution().getName());
                });
                expect(checkEvolutions.len()).toBe(0);
            });

            it('Retrieve Clobbopus''s Evolutions', () => {
                var clobbopus = pokemonService.get({
                    number: 852,
                    name  : 'Clobbopus',
                    gender: ''
                });
                expect(clobbopus).toBeArray();
                expect(clobbopus.len()).toBe(1);
                clobbopus = clobbopus[1];

                var evolutions = pokemonService.getEvolution(clobbopus);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].getEvolution().getName()).toBe('Grapploct');
            });

            it('Retrieve Yungoos''s Evolutions', () => {
                var yungoos = pokemonService.get({
                    number: 734,
                    name  : 'Yungoos',
                    gender: ''
                });
                expect(yungoos).toBeArray();
                expect(yungoos.len()).toBe(1);
                yungoos = yungoos[1];

                var evolutions = pokemonService.getEvolution(yungoos);
                expect(evolutions).toBeArray();
                expect(evolutions.len()).toBe(1);
                expect(evolutions[1].getEvolution().getName()).toBe('Gumshoos');
            });
        });
    }

}
