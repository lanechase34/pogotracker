component singleton accessors="true" {

    property name="cache" inject="cachebox:appCache";
    property name="generationMap" type="struct";

    public void function init() {
        setGenerationMap(deserializeJSON(fileRead("/includes/assets/generationmap.json", "UTF-8")));
        return;
    }

    /**
     * Every generation, in order - each {id, generation, region}
     */
    public array function getAll() {
        return cache.getOrSet(
            getAllCacheKey(),
            () => queryExecute(
                "
                SELECT id, generation, region 
                FROM generation 
                ORDER BY generation ASC
                ",
                {},
                {returnType: "array"}
            ),
            720,
            720
        );
    }

    /**
     * Evict the cached generation list so the next getAll reads the database
     * Call after anything that changes the generations
     */
    public void function clearAllCache() {
        cache.clear(getAllCacheKey());
        return;
    }

    // This function creates any missing generations
    public void function createAll() {
        getGenerationMap().each((key, value) => {
            queryExecute(
                "
                INSERT INTO generation (generation, region) 
                VALUES (:generation, :region) 
                ON CONFLICT (generation) DO NOTHING
                ",
                {
                    generation: {
                        value    : key,
                        cfsqltype: "decimal",
                        scale    : 1
                    },
                    region: {value: value, cfsqltype: "varchar"}
                }
            );
        });

        clearAllCache();
        return;
    }

    // Get generation record based on region, null when there is none
    public any function getFromRegion(required string region) {
        var wanted      = arguments.region;
        var generations = getAll();
        var position    = generations.find((generation) => compare(generation.region, wanted) == 0);
        if(position) return generations[position];
        return;
    }

    /**
     * Cache key for the generation list getAll loads
     */
    private string function getAllCacheKey() {
        return "generation.getAll";
    }

}
