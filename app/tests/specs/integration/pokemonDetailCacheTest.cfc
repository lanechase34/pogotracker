component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pokemonService = getInstance('services.pokemon');
        appCache       = getCache('appCache');
        templateCache  = getCache('template');

        // Event caching is off in development, the viewlet cache needs it on
        originalEventCaching = getController().getSetting('eventCaching');
        getController().setSetting('eventCaching', true);

        ses = '1'; // Bulbasaur
    }

    function afterAll() {
        getController().setSetting('eventCaching', originalEventCaching);
        pokemonService.clearDetailCache(ses = ses);
        super.afterAll();
    }

    /**
     * Cached detailContent viewlet keys for the ses + audience
     */
    private array function getViewletKeys(required string audience) {
        return templateCache.getKeys().filter((key) => key.findNoCase('pokemon.detailcontent-#ses#|#audience#-'));
    }

    private any function getDetailPage() {
        setup();
        return get(route = '/pokemon/#ses#');
    }

    function run() {
        describe('Pokemon detail page viewlet cache', () => {
            beforeEach(() => {
                setup();
                session.securityLevel = 0;
                pokemonService.clearDetailCache(ses = ses);
            });

            afterEach(() => {
                session.securityLevel = 0;
            });

            it('Caches the rendered detail body on first view', () => {
                expect(getViewletKeys('public')).toBeEmpty();

                var event = getDetailPage();
                expect(event.getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toInclude('128 HP');
                expect(getViewletKeys('public')).toHaveLength(1);
            });

            it('Serves the cached body without running the viewlet', () => {
                getDetailPage();
                var keys = getViewletKeys('public');
                expect(keys).toHaveLength(1);

                // Swap the cached html, if the viewlet ran again the real stats would render instead
                templateCache.set(keys[1], '<p>cached-detail-sentinel</p>');

                var html = getDetailPage().getRenderedContent();
                expect(html).toInclude('cached-detail-sentinel');
                expect(html).notToInclude('128 HP');
                // Layout still renders around the cached body
                expect(html).toInclude('Bulbasaur');
            });

            it('Does not show the admin form to the public', () => {
                var html = getDetailPage().getRenderedContent();
                expect(html).notToInclude('pokemonDetailForm');
            });

            it('Caches a separate admin copy containing the update form', () => {
                getDetailPage();

                session.securityLevel = 50;
                var html              = getDetailPage().getRenderedContent();
                expect(html).toInclude('pokemonDetailForm');
                expect(getViewletKeys('admin')).toHaveLength(1);

                // Public copy was not overwritten by the admin render
                session.securityLevel = 0;
                expect(getDetailPage().getRenderedContent()).notToInclude('pokemonDetailForm');
            });

            it('clearDetailCache removes the cached info and rendered pages', () => {
                getDetailPage();
                session.securityLevel = 50;
                getDetailPage();
                expect(getViewletKeys('public')).toHaveLength(1);
                expect(getViewletKeys('admin')).toHaveLength(1);
                expect(appCache.get('pokemon.getDetail|pokemonses=#ses#')).notToBeNull();

                pokemonService.clearDetailCache(ses = ses);

                expect(getViewletKeys('public')).toBeEmpty();
                expect(getViewletKeys('admin')).toBeEmpty();
                expect(appCache.get('pokemon.getDetail|pokemonses=#ses#')).toBeNull();
            });

            it('Returns 404 for an unknown pokemon', () => {
                setup();
                var event = get(route = '/pokemon/not-a-real-pokemon');
                expect(event.getStatusCode()).toBe(404);
            });
        });

        describe('Pokemon detail across ORM sessions', () => {
            beforeEach(() => {
                setup();
                pokemonService.clearDetailCache(ses = ses);
            });

            it('Cached detail info holds no entities', () => {
                var info = pokemonService.getDetailInfo(ses = ses);
                expect(info).notToBeEmpty();
                info.each((key, value) => {
                    expect(isObject(value)).toBeFalse('detail info key [#key#] is an entity');
                });
            });

            it('getDetail entities lazy load after the ORM session that cached the detail is closed', () => {
                // Populate the cache, then end the session like a request ending
                pokemonService.getDetail(ses = ses);
                ormCloseSession();

                var detail    = pokemonService.getDetail(ses = ses);
                var fastMoves = detail.pokemon.getMoves('fast', 'normal');
                expect(fastMoves).notToBeEmpty();
                fastMoves.each((move) => {
                    expect(move.getMove().getName()).notToBeEmpty();
                });
                expect(detail.pokemon.getMoves('charge', 'normal')).notToBeEmpty();
                expect(detail.baseStage.getEvolution()).notToBeEmpty();
                expect(detail.costumes).notToBeEmpty();
            });

            it('Detail page renders after previous events are loaded first', () => {
                // Loading more events first used to cache the detail with entities bound to this, soon closed, session
                var eventsResponse = get(route = '/pokemon/getPreviousEvents', params = {ses: ses, offset: 5});
                expect(eventsResponse.getStatusCode()).toBe(200);
                ormCloseSession();

                var expectedMove = pokemonService.getFromSes(ses = ses).getMoves('fast', 'normal')[1]
                    .getMove()
                    .getName();
                ormCloseSession();

                var event = getDetailPage();
                expect(event.getStatusCode()).toBe(200);
                expect(event.getRenderedContent()).toInclude(expectedMove);
                expect(event.getRenderedContent()).toInclude('128 HP');
            });
        });
    }

}
