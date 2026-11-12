component {

    /**
     * Gives every public table's id column a sequence default if it has none
     * Each new sequence starts at the table's highest id + 1 (1 for an empty table)
     */
    function up(schema, qb) {
        queryExecute("
            DO $$
            DECLARE
                col record;
                seq text;
            BEGIN
                FOR col IN
                    SELECT table_schema, table_name, column_name
                    FROM information_schema.columns
                    WHERE table_schema = 'public'
                        AND column_name = 'id'
                        AND column_default IS NULL
                        AND is_identity = 'NO'
                        AND data_type IN ('integer', 'bigint', 'smallint')
                LOOP
                    seq := col.table_name || '_id_seq';
                    EXECUTE format('CREATE SEQUENCE IF NOT EXISTS %I.%I', col.table_schema, seq);
                    EXECUTE format('ALTER SEQUENCE %I.%I OWNED BY %I.%I.%I', col.table_schema, seq, col.table_schema, col.table_name, col.column_name);
                    EXECUTE format('ALTER TABLE %I.%I ALTER COLUMN %I SET DEFAULT nextval(%L)', col.table_schema, col.table_name, col.column_name, col.table_schema || '.' || seq);
                    -- is_called = false: the next nextval() returns exactly max + 1 (1 for an empty table)
                    EXECUTE format(
                        'SELECT setval(%L, COALESCE((SELECT MAX(%I) FROM %I.%I), 0) + 1, false)',
                        col.table_schema || '.' || seq,
                        col.column_name,
                        col.table_schema,
                        col.table_name
                    );
                END LOOP;
            END $$;
        ");
    }

    /**
     * Nothing to undo - the sequences are only used by the identity generator
     */
    function down(schema, qb) {
    }

}
