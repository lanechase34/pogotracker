component singleton accessors="true" {

    property name="cacheService" inject="services.cache";
    property name="generationMap" type="struct";

    public void function init() {
        setGenerationMap(deserializeJSON(fileRead('/includes/assets/generationmap.json')));
        return;
    }

    public array function getAll() {
        var cacheKey       = 'generation.getAll';
        var allGenerations = cacheService.get(cacheKey);
        if(isNull(allGenerations)) {
            allGenerations = entityLoad('generation', {}, 'generation asc');
            cacheService.put(cacheKey, allGenerations, 720, 720);
        }
        return allGenerations;
    }

    private void function create(required struct generationProperties) {
        var newGeneration = entityNew('generation', arguments.generationProperties);
        entitySave(newGeneration);
        return;
    }

    // This function creates any missing generations
    public void function createAll() {
        getGenerationMap().each((key, value) => {
            if(isNull(get(key))) {
                create({'generation': key, 'region': value});
            }
        });

        ormFlush();
        return;
    }

    // Get single generation
    public any function get(required numeric generation) {
        return entityLoad(
            'generation',
            {'generation': arguments.generation},
            true
        );
    }

    // Get generation record based on region
    public any function getFromRegion(required string region) {
        return entityLoad('generation', {region: arguments.region}, true);
    }

}
