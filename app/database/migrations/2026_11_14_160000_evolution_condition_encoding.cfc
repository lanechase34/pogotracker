component {

    /**
     * Repair evolution conditions seeded on a Windows-1252 JVM (UTF-8 bytes decoded as Windows-1252, e.g. "PokÃ©mon")
     * Re-encoding to Windows-1252 recovers the original UTF-8 bytes; correctly stored rows don't match and are untouched
     */
    function up(schema, qb) {
        queryExecute(
            "
            UPDATE evolution
            SET condition = CONVERT_FROM(CONVERT_TO(condition, 'WIN1252'), 'UTF8')
            WHERE condition LIKE '%Ã%'
            "
        );
    }

    /**
     * Data repair only, nothing to reverse
     */
    function down(schema, qb) {
    }

}
