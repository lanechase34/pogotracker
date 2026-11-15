component {

    /**
     * Blogs are read by url slug - the header with spaces replaced by - (blogService.getSlug), ignoring case
     * Unique on the slug, so "Foo Bar" and "Foo-Bar" can't both exist, and it serves blogService.getFromSlug
     * Replaces the LOWER(header) unique index, which the slug one covers
     */
    function up(schema, qb) {
        queryExecute("CREATE UNIQUE INDEX IF NOT EXISTS unq_blog_slug ON blog (LOWER(REPLACE(header, ' ', '-')))");
        queryExecute("DROP INDEX IF EXISTS unq_blog_lower_header");
    }

    function down(schema, qb) {
        queryExecute("CREATE UNIQUE INDEX IF NOT EXISTS unq_blog_lower_header ON blog (LOWER(header))");
        queryExecute("DROP INDEX IF EXISTS unq_blog_slug");
    }

}
