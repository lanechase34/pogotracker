component {

    /**
     * Index the trainer reset code - accountService.checkResetCode looks a trainer up by it
     * Partial on a non-empty resetcode so the NULL (never sent) and empty (already used) rows are left out
     */
    function up(schema, qb) {
        queryExecute("CREATE INDEX idx_trainer_resetcode ON trainer (resetcode) WHERE resetcode <> ''");
    }

    function down(schema, qb) {
        queryExecute("DROP INDEX IF EXISTS idx_trainer_resetcode");
    }

}
