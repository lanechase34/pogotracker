component singleton accessors="true" {

    property name="cache" inject="cachebox:appCache";
    property name="generationMap" type="struct";

    public void function init() {
        setGenerationMap(deserializeJSON(fileRead("/includes/assets/generationmap.json")));
        return;
    }

    public array function getAll() {
        var cacheKey       = "generation.getAll";
        var allGenerations = cache.get(cacheKey);
        if(isNull(allGenerations)) {
            allGenerations = entityLoad("generation", {}, "generation asc");
            cache.set(cacheKey, allGenerations, 720, 720);
        }
        return allGenerations;
    }

    private void function create(required struct generationProperties) {
        var newGeneration = entityNew("generation", arguments.generationProperties);
        entitySave(newGeneration);
        return;
    }

    // This function creates any missing generations
    public void function createAll() {
        getGenerationMap().each((key, value) => {
            if(isNull(get(key))) {
                create({"generation": key, "region": value});
            }
        });

        ormFlush();
        cache.clear("generation.getAll");
        return;
    }

    // Get single generation
    public any function get(required numeric generation) {
        return entityLoad(
            "generation",
            {"generation": arguments.generation},
            true
        );
    }

    // Get generation record based on region
    public any function getFromRegion(required string region) {
        var wanted = arguments.region;
        var found  = getAll().filter((generation) => compare(generation.getRegion(), wanted) == 0);
        if(found.len()) return found[1];
        return;
    }

}
