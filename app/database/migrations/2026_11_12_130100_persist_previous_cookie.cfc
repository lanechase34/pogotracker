component {

    // Keep the hash of the cookie a persist row was rotated from - requests the browser sent before it saw the
    // rotated cookie are still let in for a few seconds (services.persist.login)
    function up(schema, qb) {
        schema.alter("persist", (table) => {
            table.addColumn(table.string("previouscookie", 128).nullable());
        });
    }

    function down(schema, qb) {
        schema.alter("persist", (table) => {
            table.dropColumn("previouscookie");
        });
    }

}
