component {

    /**
     * Blog comments load a page at a time, newest first (WHERE blogid = ? AND id < ? ORDER BY id DESC LIMIT n)
     * (blogid, id) serves the filter and the order, and replaces the blogid only index
     */
    function up(schema, qb) {
        queryExecute("CREATE INDEX IF NOT EXISTS idx_comment_blogid_id ON comment (blogid, id)");
        queryExecute("DROP INDEX IF EXISTS idx_comment_blogid");
    }

    function down(schema, qb) {
        queryExecute("CREATE INDEX IF NOT EXISTS idx_comment_blogid ON comment (blogid)");
        queryExecute("DROP INDEX IF EXISTS idx_comment_blogid_id");
    }

}
