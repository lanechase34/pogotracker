component {

    /**
     * Natural keys the app relied on but the database never enforced
     * - stat: one per trainer per day (created is UTC, the same day window stats.getFromDay uses)
     * - custom: one per leekduck event link (matched ignoring case, like custom.findByLink) - user made customs have no link
     * - pokemon.generation: the only foreign key without an index
     * Stops with the offending rows instead of deleting anything when existing data breaks a key
     */
    function up(schema, qb) {
        var statDupes = queryExecute(
            "
            SELECT trainerid, CAST(created AS date) AS day, COUNT(*) AS total
            FROM stat
            GROUP BY trainerid, CAST(created AS date)
            HAVING COUNT(*) > 1
            ",
            {},
            {returnType: "array"}
        );
        if(statDupes.len()) {
            throw(
                type    = "migration.DuplicateRows",
                message = "stat has more than one row per trainer per day - resolve before migrating",
                detail  = serializeJSON(statDupes)
            );
        }

        var customDupes = queryExecute(
            "
            SELECT UPPER(link) AS link, COUNT(*) AS total
            FROM custom
            WHERE link <> ''
            GROUP BY UPPER(link)
            HAVING COUNT(*) > 1
            ",
            {},
            {returnType: "array"}
        );
        if(customDupes.len()) {
            throw(
                type    = "migration.DuplicateRows",
                message = "custom has more than one row per event link - resolve before migrating",
                detail  = serializeJSON(customDupes)
            );
        }

        queryExecute("CREATE UNIQUE INDEX unq_stat_trainerid_day ON stat (trainerid, CAST(created AS date))");
        queryExecute("CREATE UNIQUE INDEX unq_custom_upper_link ON custom (UPPER(link)) WHERE link <> ''");
        queryExecute("CREATE INDEX idx_pokemon_generation ON pokemon (generation)");
    }

    function down(schema, qb) {
        queryExecute("DROP INDEX IF EXISTS idx_pokemon_generation");
        queryExecute("DROP INDEX IF EXISTS unq_custom_upper_link");
        queryExecute("DROP INDEX IF EXISTS unq_stat_trainerid_day");
    }

}
