component {

    // Stub
    function run() {
        application.delete("pokemonData");
    }

    /**
     * Get the pokemon data json struct
     * Store in application scope to be shared throughout seeder
     */
    function getPokemonData() {
        if(!application.keyExists("pokemonData")) {
            application.pokemonData = deserializeJSON(fileRead("resources/pokedex.json", "UTF-8"));
        }
        return application.pokemonData;
    }

    /**
     * Get the costume data json struct
     */
    function getCostumeData() {
        return deserializeJSON(fileRead("../../includes/assets/costumes.json", "UTF-8"));
    }

    /**
     * Get the pokedex overrides packet
     */
    function getPokedexOverrides() {
        return deserializeJSON(fileRead("resources/pokedexoverrides.json", "UTF-8"));
    }

}
