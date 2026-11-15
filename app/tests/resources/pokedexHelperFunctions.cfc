component extends="coldbox.system.testing.BaseTestCase" {

    /**
     * Count the number of registered pokemon in the supplied pokedex
     *
     * @pokedex array pokedex
     * @shiny   t/f
     */
    public numeric function countRegistered(required array pokedex, boolean shiny = false) {
        var registeredCount = 0;
        pokedex.each((entry) => {
            if(entry.registered && (!shiny || (shiny && entry.dex_shiny))) {
                registeredCount += 1;
            }
        });
        return registeredCount;
    }

}
