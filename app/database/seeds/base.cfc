component {

    // Stub
    function run() {
        application.delete('pokemonData');
    }

    /**
     * Detect if we are in windows environment (not UTF-8) and convert
     * Whatever encoding it is to UTF-8
     *
     * @str string that has mystery encoding
     */
    function toUTF8(string str) {
        if(createObject('java', 'java.lang.System').getProperty('file.encoding') != 'UTF-8') {
            var bytes = createObject('java', 'java.lang.String')
                .init(str)
                .getBytes(createObject('java', 'java.lang.System').getProperty('file.encoding'));
            return createObject('java', 'java.lang.String').init(bytes, 'UTF-8');
        }
        return str;
    }

    /**
     * Get the pokemon data json struct
     * Store in applicatio scope to be shared throughout seeder
     */
    function getPokemonData() {
        if(!application.keyExists('pokemonData')) {
            var pokedexFile = fileOpen(
                file    = 'resources/pokedex.json',
                mode    = 'read',
                charset = 'UTF-8'
            );

            var pokemonData = deserializeJSON(fileRead(pokedexFile));

            application.pokemonData = pokemonData;
        }
        return application.pokemonData;
    }

}
