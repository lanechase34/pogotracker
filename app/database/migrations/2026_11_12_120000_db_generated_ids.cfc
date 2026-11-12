component {

    /**
     * The database hands out primary keys (models/orm/base.cfc generator="identity")
     * Hibernate's increment generator supplied the ids itself, so the SERIAL sequences weren't kept in step with the data -
     * set every sequence in public so its next id is the table's highest id + 1 (1 for an empty table)
     * Tables created after this get their ids from the sequence from the first insert, so they never need it
     */
    function up(schema, qb) {
        queryExecute("
            DO $$
            DECLARE
                col record;
            BEGIN
                FOR col IN
                    SELECT
                        table_schema,
                        table_name,
                        column_name,
                        pg_get_serial_sequence(format('%I.%I', table_schema, table_name), column_name) AS seq
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                LOOP
                    IF col.seq IS NOT NULL THEN
                        -- is_called = false: the next nextval() returns exactly max + 1 (1 for an empty table)
                        EXECUTE format(
                            'SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I.%I), 0) + 1, false)',
                            col.seq,
                            col.column_name,
                            col.table_schema,
                            col.table_name
                        );
                    END IF;
                END LOOP;
            END $$;
        ");
    }

    /**
     * Nothing to undo - the increment generator ignores the sequences
     */
    function down(schema, qb) {
    }

}
