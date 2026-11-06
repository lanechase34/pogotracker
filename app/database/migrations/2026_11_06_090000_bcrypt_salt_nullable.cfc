component {

    // bcrypt stores its salt inside the hash, salt is only needed for legacy hashes
    function up(schema, qb) {
        schema.alter("trainer", (table) => {
            table.modifyColumn("salt", table.string("salt", 128).nullable());
        });
    }

    function down(schema, qb) {
        queryExecute("
            UPDATE trainer
            SET salt = ''
            WHERE salt IS NULL
        ");

        schema.alter("trainer", (table) => {
            table.modifyColumn("salt", table.string("salt", 128));
        });
    }

}
