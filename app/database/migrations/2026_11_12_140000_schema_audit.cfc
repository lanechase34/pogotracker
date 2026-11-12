component {

    // Every unique index/constraint is named unq_* - utilService.getUniqueViolation matches on that prefix
    function up(schema, qb) {
        // pokemonmove - every lookup is by pokemon (detail page, updatePokemonMoves) and nothing stopped duplicate rows
        queryExecute("CREATE UNIQUE INDEX unq_pokemonmove_pokemonid_moveid ON pokemonmove (pokemonid, moveid)");
        queryExecute("CREATE INDEX idx_pokemonmove_moveid ON pokemonmove (moveid)");

        // evolution - looked up from both ends (getEvolution by pokemon, getEvolvers by evolution)
        queryExecute("CREATE UNIQUE INDEX unq_evolution_pokemonid_evolutionid ON evolution (pokemonid, evolutionid)");
        queryExecute("CREATE INDEX idx_evolution_evolutionid ON evolution (evolutionid)");
        queryExecute("ALTER TABLE evolution ADD CONSTRAINT chk_evolution_not_self CHECK (pokemonid <> evolutionid)");
        queryExecute("ALTER TABLE evolution ADD CONSTRAINT chk_evolution_cost CHECK (cost >= 0)");

        // persist - remember me login looks up by cookie or the cookie it was rotated from, logout by cookie, revoke by trainer
        queryExecute("CREATE UNIQUE INDEX unq_persist_cookie ON persist (cookie)");
        queryExecute("CREATE INDEX idx_persist_previouscookie ON persist (previouscookie) WHERE previouscookie IS NOT NULL");
        queryExecute("CREATE INDEX idx_persist_trainerid ON persist (trainerid)");

        // trainermedal - the only relationship table without foreign keys, one row per trainer + medal
        queryExecute("ALTER TABLE trainermedal ADD CONSTRAINT fk_trainermedal_trainerid FOREIGN KEY (trainerid) REFERENCES trainer(id)");
        queryExecute("ALTER TABLE trainermedal ADD CONSTRAINT fk_trainermedal_medalid FOREIGN KEY (medalid) REFERENCES medal(id)");
        queryExecute("CREATE UNIQUE INDEX unq_trainermedal_trainerid_medalid ON trainermedal (trainerid, medalid)");
        queryExecute("CREATE INDEX idx_trainermedal_medalid ON trainermedal (medalid)");
        queryExecute("ALTER TABLE trainermedal ADD CONSTRAINT chk_trainermedal_current CHECK (current >= 0)");

        // trainer - usernames are unique ignoring case, emails are stored trimmed + lowercase
        // The lower() index replaces both case sensitive username indexes - nothing looks a username up by exact case
        queryExecute("CREATE UNIQUE INDEX unq_trainer_lower_username ON trainer (lower(username))");
        queryExecute("DROP INDEX IF EXISTS idx_trainer_username");
        queryExecute("ALTER TABLE trainer DROP CONSTRAINT trainer_username_key");
        queryExecute("ALTER TABLE trainer RENAME CONSTRAINT trainer_email_key TO unq_trainer_email");
        queryExecute("ALTER TABLE trainer RENAME CONSTRAINT trainer_friendcode_key TO unq_trainer_friendcode");
        queryExecute("ALTER TABLE trainer ADD CONSTRAINT chk_trainer_username CHECK (username = btrim(username) AND username <> '')");
        queryExecute("ALTER TABLE trainer ADD CONSTRAINT chk_trainer_email CHECK (email = lower(btrim(email)) AND email <> '')");
        queryExecute("ALTER TABLE trainer ADD CONSTRAINT chk_trainer_friendcode CHECK (friendcode ~ '^[0-9]{12}$')");
        queryExecute("ALTER TABLE trainer ADD CONSTRAINT chk_trainer_securitylevel CHECK (securitylevel IN (0, 5, 10, 20, 50, 60))");

        // Other auto named unique constraints - renamed to unq_* so violations are recognised
        queryExecute("ALTER TABLE move RENAME CONSTRAINT move_nameid_key TO unq_move_nameid");
        queryExecute("ALTER TABLE generation RENAME CONSTRAINT generation_generation_key TO unq_generation_generation");
        queryExecute("ALTER TABLE level RENAME CONSTRAINT level_level_key TO unq_level_level");

        // custompokedex - one row per custom + pokemon, the leading customid makes the single column index redundant
        queryExecute("CREATE UNIQUE INDEX unq_custompokedex_customid_pokemonid ON custompokedex (customid, pokemonid)");
        queryExecute("DROP INDEX IF EXISTS idx_custompokedex_customid");

        // Foreign keys with nothing indexing the referencing column
        queryExecute("CREATE INDEX idx_custom_trainerid ON custom (trainerid)");
        queryExecute("CREATE INDEX idx_comment_blogid ON comment (blogid)");
        queryExecute("CREATE INDEX idx_comment_trainerid ON comment (trainerid)");
        queryExecute("CREATE INDEX idx_audit_trainerid ON audit (trainerid)");
        queryExecute("CREATE INDEX idx_bug_trainerid ON bug (trainerid)");
        queryExecute("CREATE INDEX idx_blog_trainerid ON blog (trainerid)");
        queryExecute("CREATE INDEX idx_request_log_trainerid ON request_log (trainerid)");

        // Natural keys the code already treats as unique
        queryExecute("CREATE UNIQUE INDEX unq_pokemon_ses ON pokemon (ses)");
        queryExecute("CREATE UNIQUE INDEX unq_pokemon_identity ON pokemon (number, name, gender, costume, costumetype)");
        queryExecute("CREATE UNIQUE INDEX unq_blog_lower_header ON blog (lower(header))");
        queryExecute("CREATE UNIQUE INDEX unq_overrides_name ON overrides (name)");
        queryExecute("CREATE UNIQUE INDEX unq_medal_name ON medal (name)");

        // friend - each direction of a friendship is one row. The pair is unique so accepted no longer needs to be in the key
        queryExecute("CREATE UNIQUE INDEX unq_friend_trainerid_friendid ON friend (trainerid, friendid)");
        queryExecute("DROP INDEX IF EXISTS idx_friend_trainerid_friendid_accepted");
        queryExecute("ALTER TABLE friend ADD CONSTRAINT chk_friend_not_self CHECK (trainerid <> friendid)");

        // Redundant / unused indexes - idx_request_log_id duplicates the pk, nothing filters custom.name by equality
        queryExecute("DROP INDEX IF EXISTS idx_request_log_id");
        queryExecute("DROP INDEX IF EXISTS idx_custom_name");

        // Cheap sanity checks
        queryExecute("ALTER TABLE stat ADD CONSTRAINT chk_stat_nonnegative CHECK (caught >= 0 AND spun >= 0 AND walked >= 0 AND xp >= 0)");
        queryExecute("ALTER TABLE custom ADD CONSTRAINT chk_custom_dates CHECK (ends >= begins)");
        queryExecute("ALTER TABLE medal ADD CONSTRAINT chk_medal_tiers CHECK (bronze >= 0 AND silver >= 0 AND gold >= 0 AND platinum >= 0)");
        queryExecute("ALTER TABLE pokedex ADD CONSTRAINT chk_pokedex_counts CHECK (seen >= 0 AND total >= 0)");
        queryExecute("ALTER TABLE pokemon ADD CONSTRAINT chk_pokemon_stats CHECK (attack >= 0 AND defense >= 0 AND hp >= 0)");
        queryExecute("ALTER TABLE level ADD CONSTRAINT chk_level_values CHECK (level >= 1 AND requiredxp >= 0)");
        queryExecute("ALTER TABLE blog ADD CONSTRAINT chk_blog_upvote CHECK (upvote >= 0)");

        // updated is kept by the database on every UPDATE - covers raw SQL the orm event handler never sees
        // A statement that sets updated itself (the orm preUpdate handler, rotateCookie) keeps its value
        // Millisecond precision like the JVM - a microsecond value reads back different from what Lucee's orm holds,
        // so every entity reloaded after a raw update would look dirty and be written again on the next flush
        queryExecute("
            CREATE OR REPLACE FUNCTION set_updated() RETURNS trigger AS $$
            BEGIN
                IF NEW.updated IS NOT DISTINCT FROM OLD.updated THEN
                    NEW.updated = date_trunc('milliseconds', localtimestamp);
                END IF;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql
        ");
        getUpdatedTables().each((table) => {
            queryExecute("CREATE TRIGGER trg_#table#_updated BEFORE UPDATE ON #table# FOR EACH ROW EXECUTE FUNCTION set_updated()");
        });
    }

    function down(schema, qb) {
        getUpdatedTables().each((table) => {
            queryExecute("DROP TRIGGER IF EXISTS trg_#table#_updated ON #table#");
        });
        queryExecute("DROP FUNCTION IF EXISTS set_updated()");

        queryExecute("ALTER TABLE blog DROP CONSTRAINT IF EXISTS chk_blog_upvote");
        queryExecute("ALTER TABLE level DROP CONSTRAINT IF EXISTS chk_level_values");
        queryExecute("ALTER TABLE pokemon DROP CONSTRAINT IF EXISTS chk_pokemon_stats");
        queryExecute("ALTER TABLE pokedex DROP CONSTRAINT IF EXISTS chk_pokedex_counts");
        queryExecute("ALTER TABLE medal DROP CONSTRAINT IF EXISTS chk_medal_tiers");
        queryExecute("ALTER TABLE custom DROP CONSTRAINT IF EXISTS chk_custom_dates");
        queryExecute("ALTER TABLE stat DROP CONSTRAINT IF EXISTS chk_stat_nonnegative");

        queryExecute("CREATE INDEX IF NOT EXISTS idx_custom_name ON custom (name)");
        queryExecute("CREATE INDEX IF NOT EXISTS idx_request_log_id ON request_log (id)");

        queryExecute("ALTER TABLE friend DROP CONSTRAINT IF EXISTS chk_friend_not_self");
        queryExecute("CREATE INDEX IF NOT EXISTS idx_friend_trainerid_friendid_accepted ON friend (trainerid, friendid, accepted)");
        queryExecute("DROP INDEX IF EXISTS unq_friend_trainerid_friendid");

        queryExecute("DROP INDEX IF EXISTS unq_medal_name");
        queryExecute("DROP INDEX IF EXISTS unq_overrides_name");
        queryExecute("DROP INDEX IF EXISTS unq_blog_lower_header");
        queryExecute("DROP INDEX IF EXISTS unq_pokemon_identity");
        queryExecute("DROP INDEX IF EXISTS unq_pokemon_ses");

        queryExecute("DROP INDEX IF EXISTS idx_request_log_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_blog_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_bug_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_audit_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_comment_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_comment_blogid");
        queryExecute("DROP INDEX IF EXISTS idx_custom_trainerid");

        queryExecute("CREATE INDEX IF NOT EXISTS idx_custompokedex_customid ON custompokedex (customid)");
        queryExecute("DROP INDEX IF EXISTS unq_custompokedex_customid_pokemonid");

        queryExecute("ALTER TABLE level RENAME CONSTRAINT unq_level_level TO level_level_key");
        queryExecute("ALTER TABLE generation RENAME CONSTRAINT unq_generation_generation TO generation_generation_key");
        queryExecute("ALTER TABLE move RENAME CONSTRAINT unq_move_nameid TO move_nameid_key");

        queryExecute("ALTER TABLE trainer DROP CONSTRAINT IF EXISTS chk_trainer_securitylevel");
        queryExecute("ALTER TABLE trainer DROP CONSTRAINT IF EXISTS chk_trainer_friendcode");
        queryExecute("ALTER TABLE trainer DROP CONSTRAINT IF EXISTS chk_trainer_email");
        queryExecute("ALTER TABLE trainer DROP CONSTRAINT IF EXISTS chk_trainer_username");
        queryExecute("ALTER TABLE trainer RENAME CONSTRAINT unq_trainer_friendcode TO trainer_friendcode_key");
        queryExecute("ALTER TABLE trainer RENAME CONSTRAINT unq_trainer_email TO trainer_email_key");
        queryExecute("ALTER TABLE trainer ADD CONSTRAINT trainer_username_key UNIQUE (username)");
        queryExecute("CREATE INDEX IF NOT EXISTS idx_trainer_username ON trainer (username)");
        queryExecute("DROP INDEX IF EXISTS unq_trainer_lower_username");

        queryExecute("ALTER TABLE trainermedal DROP CONSTRAINT IF EXISTS chk_trainermedal_current");
        queryExecute("DROP INDEX IF EXISTS idx_trainermedal_medalid");
        queryExecute("DROP INDEX IF EXISTS unq_trainermedal_trainerid_medalid");
        queryExecute("ALTER TABLE trainermedal DROP CONSTRAINT IF EXISTS fk_trainermedal_medalid");
        queryExecute("ALTER TABLE trainermedal DROP CONSTRAINT IF EXISTS fk_trainermedal_trainerid");

        queryExecute("DROP INDEX IF EXISTS idx_persist_trainerid");
        queryExecute("DROP INDEX IF EXISTS idx_persist_previouscookie");
        queryExecute("DROP INDEX IF EXISTS unq_persist_cookie");

        queryExecute("ALTER TABLE evolution DROP CONSTRAINT IF EXISTS chk_evolution_cost");
        queryExecute("ALTER TABLE evolution DROP CONSTRAINT IF EXISTS chk_evolution_not_self");
        queryExecute("DROP INDEX IF EXISTS idx_evolution_evolutionid");
        queryExecute("DROP INDEX IF EXISTS unq_evolution_pokemonid_evolutionid");

        queryExecute("DROP INDEX IF EXISTS idx_pokemonmove_moveid");
        queryExecute("DROP INDEX IF EXISTS unq_pokemonmove_pokemonid_moveid");
    }

    /**
     * Every table with an updated column
     */
    private array function getUpdatedTables() {
        return [
            "audit",
            "blog",
            "bug",
            "comment",
            "custom",
            "custompokedex",
            "evolution",
            "friend",
            "generation",
            "level",
            "medal",
            "move",
            "overrides",
            "persist",
            "pokedex",
            "pokemon",
            "pokemonmove",
            "request_log",
            "stat",
            "trainer",
            "trainermedal"
        ];
    }

}
