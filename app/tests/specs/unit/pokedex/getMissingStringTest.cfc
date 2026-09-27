component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
        mockTrainer    = getInstance('tests.resources.mocktrainer');

        // Plain, live, tradable, non-form pokemon
        bulbasaur = pokemonService.get({
            number : 1,
            mega   : false,
            giga   : false,
            costume: false
        })[1];
        victreebel = pokemonService.get({number: 71, mega: false})[1];
        torchic    = pokemonService.get({number: 255, costume: false})[1];

        // Form variant pokemon (form=true) - number should be used instead of name
        deerlingSpring = pokemonService.get({number: 585, form: true})[1];

        // Mega/giga variants have their own distinct name and are always tradable=false,
        // but are also excluded outright by the WHERE clause (mega=false/giga=false)
        megaGengar    = pokemonService.get({number: 94, mega: true})[1];
        gigaCharizard = pokemonService.get({number: 6, giga: true})[1];

        // Costume variant shares its name with the base pokemon, but is excluded via costume=false
        bulbasaurPartyHat = pokemonService.get({
            number     : 1,
            name       : 'Bulbasaur',
            gender     : '',
            costume    : true,
            costumetype: 'Party Hat'
        })[1];

        // Mythical - tradable=false, otherwise a normal live/non-form pokemon
        mew = pokemonService.get({number: 151})[1];

        // Not yet live in-game
        zeraora = pokemonService.get({number: 807})[1];

        // Live and tradable, but shiny is not yet released
        honedge = pokemonService.get({number: 679})[1];
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('pokedexService.getMissingString', () => {
            beforeEach(() => {
                setup();
                pokedexService = getInstance('services.pokedex');
                trainer        = mockTrainer.make(autoLogin = false);
            });

            afterEach(() => {
                mockTrainer.delete();
            });

            it('Can be created', () => {
                expect(pokedexService).toBeComponent();
            });

            it('Prefixes non-form pokemon with + when missing from the caught dex', () => {
                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).toContain('+#bulbasaur.getName()#');
                expect(items).toContain('+#victreebel.getName()#');
            });

            it('Uses the plain number (no +) for form-variant pokemon that are missing', () => {
                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).toContain('#deerlingSpring.getNumber()#');
                // No '+' for numbers
                expect(items.some((item) => compare(item, '+#deerlingSpring.getNumber()#') == 0)).toBeFalse();
            });

            it('Excludes pokemon the trainer has already caught', () => {
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaur,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).notToContain('+#bulbasaur.getName()#');
                // Still-uncaught pokemon should remain, proving the list isn't just empty
                expect(items).toContain('+#victreebel.getName()#');
            });

            it('Excludes pokemon that are not yet live even if uncaught', () => {
                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).notToContain('+#zeraora.getName()#');
            });

            it('Excludes pokemon that are not tradable even if uncaught', () => {
                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).notToContain('+#mew.getName()#');
            });

            it('Excludes mega, giga, and unown regardless of catch status', () => {
                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                expect(items).notToContain('+#megaGengar.getName()#');
                expect(items).notToContain('+#gigaCharizard.getName()#');
                expect(items).notToContain('201');
            });

            it('Excludes costume pokemon and catching a costume does not affect the base pokemon', () => {
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaurPartyHat,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                var missingCaught = pokedexService.getMissingString(trainer, false);
                var items         = listToArray(missingCaught, ',');

                // Base Bulbasaur is unaffected by registering its costume variant
                expect(items).toContain('+#bulbasaur.getName()#');
            });

            it('Returns the shiny missing string prefixed with ''shiny&'' and excludes pokemon without a shiny release', () => {
                var missingShiny = pokedexService.getMissingString(trainer, true);

                expect(left(missingShiny, 6)).toBe('shiny&');

                var items = listToArray(replace(missingShiny, 'shiny&', '', 'one'), ',');
                expect(items).notToContain('+#honedge.getName()#');
                expect(items).toContain('+#bulbasaur.getName()#');
            });

            it('Excludes pokemon whose shiny has already been registered', () => {
                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = bulbasaur,
                    caught      = false,
                    shiny       = true,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                var missingShiny = pokedexService.getMissingString(trainer, true);
                var items        = listToArray(replace(missingShiny, 'shiny&', '', 'one'), ',');

                expect(items).notToContain('+#bulbasaur.getName()#');
                expect(items).toContain('+#victreebel.getName()#');
            });

            it('Caches the result and invalidates the cache after a new registration', () => {
                var first  = pokedexService.getMissingString(trainer, false);
                var second = pokedexService.getMissingString(trainer, false);
                expect(second).toBe(first);

                pokedexService.register(
                    trainer     = trainer,
                    pokemon     = torchic,
                    caught      = true,
                    shiny       = false,
                    hundo       = false,
                    shadow      = false,
                    shadowshiny = false
                );

                var third = pokedexService.getMissingString(trainer, false);
                expect(third).notToBe(first);
                expect(listToArray(third, ',')).notToContain('+#torchic.getName()#');
            });
        });
    }

}
