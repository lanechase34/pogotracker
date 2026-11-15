component {

    /**
     * Index created on the audit and bug logs - the admin tables sort by it
     */
    function up(schema, qb) {
        queryExecute("CREATE INDEX IF NOT EXISTS idx_audit_created ON audit (created)");
        queryExecute("CREATE INDEX IF NOT EXISTS idx_bug_created ON bug (created)");
    }

    function down(schema, qb) {
        queryExecute("DROP INDEX IF EXISTS idx_bug_created");
        queryExecute("DROP INDEX IF EXISTS idx_audit_created");
    }

}
