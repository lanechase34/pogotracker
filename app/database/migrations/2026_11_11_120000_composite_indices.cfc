component {

    function up(schema, qb) {
        // Merge any duplicate pokedex rows (same trainer + pokemon) into the oldest row before adding the unique index
        queryExecute("
            WITH dupes AS (
                SELECT
                    trainerid,
                    pokemonid,
                    MIN(id) AS keepid,
                    BOOL_OR(caught) AS caught,
                    BOOL_OR(shiny) AS shiny,
                    BOOL_OR(hundo) AS hundo,
                    BOOL_OR(shadow) AS shadow,
                    BOOL_OR(shadowshiny) AS shadowshiny,
                    MAX(seen) AS seen,
                    MAX(total) AS total
                FROM pokedex
                GROUP BY trainerid, pokemonid
                HAVING COUNT(*) > 1
            )
            UPDATE pokedex
            SET caught = dupes.caught,
                shiny = dupes.shiny,
                hundo = dupes.hundo,
                shadow = dupes.shadow,
                shadowshiny = dupes.shadowshiny,
                seen = dupes.seen,
                total = dupes.total,
                updated = now()
            FROM dupes
            WHERE pokedex.id = dupes.keepid
        ");
        queryExecute("
            DELETE FROM pokedex
            USING pokedex keep
            WHERE pokedex.trainerid = keep.trainerid
                AND pokedex.pokemonid = keep.pokemonid
                AND pokedex.id > keep.id
        ");

        // Every pokedex lookup is by (trainer, pokemon). Leading trainerid makes the single column index redundant
        queryExecute("CREATE UNIQUE INDEX unq_pokedex_trainerid_pokemonid ON pokedex (trainerid, pokemonid)");
        queryExecute("DROP INDEX IF EXISTS idx_pokedex_trainerid");

        // Stats are always read per trainer over a date range, ordered by created
        queryExecute("CREATE INDEX idx_stat_trainerid_created ON stat (trainerid, created)");
        queryExecute("DROP INDEX IF EXISTS idx_stat_trainerid");

        // Friend checks run on every friend profile/stats/pokedex view
        queryExecute("CREATE INDEX idx_friend_trainerid_friendid_accepted ON friend (trainerid, friendid, accepted)");
        queryExecute("CREATE INDEX idx_friend_friendid_accepted ON friend (friendid, accepted)");
    }

    function down(schema, qb) {
        queryExecute("DROP INDEX IF EXISTS idx_friend_friendid_accepted");
        queryExecute("DROP INDEX IF EXISTS idx_friend_trainerid_friendid_accepted");

        queryExecute("CREATE INDEX IF NOT EXISTS idx_stat_trainerid ON stat (trainerid)");
        queryExecute("DROP INDEX IF EXISTS idx_stat_trainerid_created");

        queryExecute("CREATE INDEX IF NOT EXISTS idx_pokedex_trainerid ON pokedex (trainerid)");
        queryExecute("DROP INDEX IF EXISTS unq_pokedex_trainerid_pokemonid");
    }

}
