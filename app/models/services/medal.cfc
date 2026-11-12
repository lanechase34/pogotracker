component singleton accessors="true" {

    property name="cache" inject="cachebox:appCache";

    private void function create(required struct medalProperties) {
        var newMedal = entityNew("medal", arguments.medalProperties);
        entitySave(newMedal);
    }

    public void function update(required struct medalProperties) {
        // Attempt to load medal
        var currMedal = entityLoad("medal", {"name": arguments.medalProperties.name});

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
        var cacheKey  = "medal.getAll";
        var allMedals = cache.get(cacheKey);
        if(isNull(allMedals)) {
            allMedals = entityLoad("medal", {}, "displayorder asc");
            cache.set(cacheKey, allMedals, 720, 720);
        }
        return allMedals;
    }

    public component function getFromId(required numeric id) {
        return entityLoadByPK("medal", arguments.id);
    }

    /**
     * Get the supplied trainers progress on all medals
     *
     * @trainer trainer cfc
     */
    public array function getProgress(required component trainer) {
        var cacheKey      = "#arguments.trainer.getId()#|medal.getProgress";
        var medalProgress = cache.get(cacheKey);

        if(isNull(medalProgress)) {
            medalProgress = ormExecuteQuery(
                "
                select medal as medal, trainermedal as trainermedal
                from medal as medal
                left outer join medal.trainermedal as trainermedal with trainermedal.trainer = :trainer
                order by medal.displayorder asc
                ",
                {"trainer": arguments.trainer}
            );

            cache.set(cacheKey, medalProgress, 10, 10);
        }

        return medalProgress;
    }

    /**
     * Track trainer's progress on a medal
     *
     * @trainer trainer cfc
     * @medal   medal cfc
     * @current current progress
     */
    public void function trackProgress(
        required component trainer,
        required component medal,
        required numeric current
    ) {
        // One row per trainer + medal (unq_trainermedal_trainerid_medalid) - concurrent saves update the same row
        queryExecute(
            "
            INSERT INTO trainermedal (trainerid, medalid, current, created, updated)
            VALUES (:trainerid, :medalid, :current, now(), now())
            ON CONFLICT (trainerid, medalid) DO UPDATE SET current = excluded.current
            ",
            {
                trainerid: {value: arguments.trainer.getId(), cfsqltype: "integer"},
                medalid  : {value: arguments.medal.getId(), cfsqltype: "integer"},
                current  : {value: int(arguments.current), cfsqltype: "integer"}
            }
        );

        // Clear the cache
        cache.clear("#arguments.trainer.getId()#|medal.getProgress");
        return;
    }

}
