component singleton accessors="true" {

    property name="cacheService" inject="services.cache";

    private void function create(required struct medalProperties) {
        var newMedal = entityNew('medal', arguments.medalProperties);
        entitySave(newMedal);
    }

    public void function update(required struct medalProperties) {
        // Attempt to load medal
        var currMedal = entityLoad('medal', {'name': arguments.medalProperties.name});

        // Create if this is a new medal
        if(!currMedal.len()) {
            create(arguments.medalProperties);
        }
        // Otherwise, update
        else {
            currMedal = currMedal[1];
            currMedal.setDescription(arguments.medalProperties.description);
            currMedal.setBronze(arguments.medalProperties.bronze);
            currMedal.setSilver(arguments.medalProperties.silver);
            currMedal.setGold(arguments.medalProperties.gold);
            currMedal.setPlatinum(arguments.medalProperties.platinum);
            currMedal.setDisplayOrder(arguments.medalProperties.displayorder);
            entitySave(currMedal);
        }

        return;
    }

    public array function getAll() {
        var cacheKey  = 'medal.getAll';
        var allMedals = cacheService.get(cacheKey);
        if(isNull(allMedals)) {
            allMedals = entityLoad('medal', {}, 'displayorder asc');
            cacheService.put(cacheKey, allMedals, 720, 720);
        }
        return allMedals;
    }

    public array function get(required string name) {
        return entityLoad('medal', {'name': arguments.name});
    }

    public component function getFromId(required numeric id) {
        return entityLoadByPK('medal', arguments.id);
    }

    public array function getTrainerMedal(required component trainer, required component medal) {
        return entityLoad('trainermedal', {'trainer': arguments.trainer, 'medal': arguments.medal});
    }

    public array function getProgress(required component trainer) {
        var cacheKey      = '#arguments.trainer.getId()#|medal.getProgress';
        var medalProgress = cacheService.get(cacheKey);

        if(isNull(medalStats)) {
            medalProgress = ormExecuteQuery(
                '
                select medal as medal, trainermedal as trainermedal
                from medal as medal
                left outer join medal.trainermedal as trainermedal with trainermedal.trainer = :trainer
                order by medal.displayorder asc
                ',
                {'trainer': arguments.trainer}
            );

            cacheService.put(cacheKey, medalProgress, 10, 10);
        }

        return medalProgress;
    }

    public void function trackProgress(
        required component trainer,
        required component medal,
        required numeric current
    ) {
        var trainerMedal = getTrainerMedal(arguments.trainer, arguments.medal);

        // If trainer medal doesnt exist
        if(!trainerMedal.len()) {
            trainerMedal = entityNew('trainermedal', {'trainer': arguments.trainer, 'medal': arguments.medal});
        }
        else {
            trainerMedal = trainerMedal[1];
        }

        trainerMedal.setCurrent(arguments.current);
        entitySave(trainerMedal);
        ormFlush();

        // Clear the cache
        cacheService.remove('#arguments.trainer.getId()#|medal.getProgress');
        return;
    }

}
