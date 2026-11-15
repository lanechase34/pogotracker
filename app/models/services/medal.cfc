component singleton accessors="true" {

    property name="cache"        inject="cachebox:appCache";
    property name="trainerCache" inject="cachebox:trainerCache";
    property name="utilService"  inject="services.util";

    // Medal columns, with the image alt text built from the name
    variables.MEDAL_COLUMNS = "
        medal.id, medal.created, medal.updated, medal.name, medal.description, medal.bronze, medal.silver,
        medal.gold, medal.platinum, medal.displayorder,
        UPPER(LEFT(medal.name, 1)) || SUBSTR(medal.name, 2) || ' medal icon' AS alttext
    ";

    /**
     * Create the medal, or update it when one with the name exists
     *
     * @medalProperties name, description, bronze, silver, gold, platinum, displayorder
     */
    public void function upsertMedal(required struct medalProperties) {
        queryExecute(
            "
            INSERT INTO medal (name, description, bronze, silver, gold, platinum, displayorder)
            VALUES (:name, :description, :bronze, :silver, :gold, :platinum, :displayorder)
            ON CONFLICT (name) DO UPDATE SET
                description  = excluded.description,
                bronze       = excluded.bronze,
                silver       = excluded.silver,
                gold         = excluded.gold,
                platinum     = excluded.platinum,
                displayorder = excluded.displayorder
            ",
            {
                name        : {value: arguments.medalProperties.name, cfsqltype: "varchar"},
                description : {value: arguments.medalProperties.description, cfsqltype: "varchar"},
                bronze      : {value: arguments.medalProperties.bronze, cfsqltype: "integer"},
                silver      : {value: arguments.medalProperties.silver, cfsqltype: "integer"},
                gold        : {value: arguments.medalProperties.gold, cfsqltype: "integer"},
                platinum    : {value: arguments.medalProperties.platinum, cfsqltype: "integer"},
                displayorder: {value: arguments.medalProperties.displayorder, cfsqltype: "integer"}
            }
        );
        return;
    }

    /**
     * Every medal in display order
     */
    public array function getAll() {
        return cache.getOrSet(
            getAllCacheKey(),
            () => queryExecute(
                "
                SELECT #variables.MEDAL_COLUMNS# 
                FROM medal 
                ORDER BY medal.displayorder ASC, medal.id ASC
                ",
                {},
                {returnType: "array"}
            ),
            720,
            720
        );
    }

    /**
     * Evict the cached medal list so the next getAll reads the database
     * Call after anything that changes the medals
     */
    public void function clearAllCache() {
        cache.clear(getAllCacheKey());
        return;
    }

    /**
     * One medal, null when there is no such medal
     *
     * @id medal pk
     */
    public any function getFromId(required numeric id) {
        var medal = queryExecute(
            "
            SELECT #variables.MEDAL_COLUMNS# 
            FROM medal 
            WHERE medal.id = :id
            ",
            {id: {value: arguments.id, cfsqltype: "integer"}},
            {returnType: "array"}
        );
        return utilService.firstRow(medal);
    }

    /**
     * Get the supplied trainer's progress on all medals, in display order
     * Each medal's columns plus:
     * tracked - whether the trainer has recorded progress on it
     * current - their recorded progress (0 when not tracked)
     * tier    - the highest tier reached: bronze, silver, gold, platinum, or blank
     *
     * @trainerid trainer pk
     */
    public array function getProgress(required numeric trainerid) {
        var forTrainerid = arguments.trainerid;
        return trainerCache.getOrSet(
            getProgressCacheKey(forTrainerid),
            () => queryExecute(
                "
                SELECT #variables.MEDAL_COLUMNS#,
                    trainermedal.id IS NOT NULL AS tracked,
                    COALESCE(trainermedal.current, 0) AS current,
                    CASE
                        WHEN trainermedal.id IS NULL THEN ''
                        WHEN trainermedal.current >= medal.platinum THEN 'platinum'
                        WHEN trainermedal.current >= medal.gold THEN 'gold'
                        WHEN trainermedal.current >= medal.silver THEN 'silver'
                        WHEN trainermedal.current >= medal.bronze THEN 'bronze'
                        ELSE ''
                    END AS tier
                FROM medal
                LEFT JOIN trainermedal ON trainermedal.medalid = medal.id AND trainermedal.trainerid = :trainerid
                ORDER BY medal.displayorder ASC, medal.id ASC
                ",
                {trainerid: {value: forTrainerid, cfsqltype: "integer"}},
                {returnType: "array"}
            ),
            10,
            10
        );
    }

    /**
     * Evict the trainer's cached medal progress so the next getProgress reads the database
     * Call after anything that changes the trainer's medal progress
     *
     * @trainerid trainer pk
     */
    public void function clearProgressCache(required numeric trainerid) {
        trainerCache.clear(getProgressCacheKey(arguments.trainerid));
        return;
    }

    /**
     * Track trainer's progress on a medal
     *
     * @trainerid trainer pk
     * @medal     medal struct (getFromId)
     * @current   current progress
     */
    public void function trackProgress(
        required numeric trainerid,
        required struct medal,
        required numeric current
    ) {
        // One row per trainer + medal (unq_trainermedal_trainerid_medalid) - concurrent saves update the same row
        queryExecute(
            "
            INSERT INTO trainermedal (trainerid, medalid, current)
            VALUES (:trainerid, :medalid, :current)
            ON CONFLICT (trainerid, medalid) DO UPDATE SET current = excluded.current
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                medalid  : {value: arguments.medal.id, cfsqltype: "integer"},
                current  : {value: arguments.current, cfsqltype: "integer"}
            }
        );

        clearProgressCache(arguments.trainerid);
        return;
    }

    /**
     * Cache key for the medal list getAll loads
     */
    private string function getAllCacheKey() {
        return "medal.getAll";
    }

    /**
     * Cache key for the medal progress getProgress loads
     *
     * @trainerid trainer pk
     */
    private string function getProgressCacheKey(required numeric trainerid) {
        return "#arguments.trainerid#|medal.getProgress";
    }

}
