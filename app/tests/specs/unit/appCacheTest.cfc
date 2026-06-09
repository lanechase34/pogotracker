component extends="tests.resources.baseTest" {

    function beforeAll() {
        super.beforeAll();
        cache = application.cbController.getCacheBox().getCache('appCache');
    }

    function run() {
        describe('appCache region', () => {
            beforeEach(() => {
                setup();
                cache.clearAll();
            });

            afterEach(() => {
                cache.clearAll();
            });

            it('Can be loaded', () => {
                expect(cache).toBeComponent();
            });

            it('Can set and get a value', () => {
                cache.set('test.key', 'hello');
                expect(cache.get('test.key')).toBe('hello');
            });

            it('Returns null for a missing key', () => {
                expect(cache.get('test.nonexistent')).toBeNull();
            });

            it('Can clear a specific key', () => {
                cache.set('test.clear', 'value');
                cache.clear('test.clear');
                expect(cache.get('test.clear')).toBeNull();
            });

            it('Leaves unrelated keys intact after clear', () => {
                cache.set('test.a', 'one');
                cache.set('test.b', 'two');
                cache.clear('test.a');
                expect(cache.get('test.a')).toBeNull();
                expect(cache.get('test.b')).toBe('two');
            });

            it('Can clear multiple keys by snippet', () => {
                cache.set('trainer.1|pokedex.getRegistered|region=Kanto', []);
                cache.set('trainer.1|pokedex.getRegistered|region=Johto', []);
                cache.set('trainer.1|pokedex.getRegistered|region=Hoenn', []);
                cache.set('trainer.2|pokedex.getRegistered|region=Kanto', []);

                cache.clearByKeySnippet('trainer.1|pokedex.getRegistered');

                expect(cache.get('trainer.1|pokedex.getRegistered|region=Kanto')).toBeNull();
                expect(cache.get('trainer.1|pokedex.getRegistered|region=Johto')).toBeNull();
                expect(cache.get('trainer.1|pokedex.getRegistered|region=Hoenn')).toBeNull();
                expect(cache.get('trainer.2|pokedex.getRegistered|region=Kanto')).notToBeNull();
            });

            it('clearByKeySnippet matching is case-insensitive', () => {
                cache.set('blog.getFromId|blogid=1', {});
                cache.clearByKeySnippet('BLOG.GETFROMID');
                expect(cache.get('blog.getFromId|blogid=1')).toBeNull();
            });
        });
    }

}
