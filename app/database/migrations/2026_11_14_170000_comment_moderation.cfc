component {

    /**
     * Comments are stored as plain text
     * trainer.commentbanned - set when an admin deletes one of the trainer's comments
     */
    function up(schema, qb) {
        queryExecute("ALTER TABLE trainer ADD COLUMN commentbanned boolean NOT NULL DEFAULT false");
        queryExecute("UPDATE comment SET comment = CAST(comment AS jsonb) ##>> '{}' WHERE LEFT(comment, 1) = '""'");
    }

    function down(schema, qb) {
        queryExecute("UPDATE comment SET comment = CAST(TO_JSONB(comment) AS text)");
        queryExecute("ALTER TABLE trainer DROP COLUMN IF EXISTS commentbanned");
    }

}
