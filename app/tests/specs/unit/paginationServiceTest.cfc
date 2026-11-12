component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        pagination = getInstance("services.pagination");
        cols       = ["pokemon.generation", "pokemon.number", ""];
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe("Pagination service", () => {
            describe("orderBy", () => {
                it("Uses the default sort and tiebreak when no order is given", () => {
                    var orderBy = pagination.orderBy(
                        columns     = cols,
                        orders      = [{column: "", dir: ""}],
                        defaultSort = "pokemon.generation ASC",
                        tiebreak    = "pokemon.id ASC"
                    );
                    expect(orderBy).toBe("ORDER BY pokemon.generation ASC, pokemon.id ASC");
                });

                it("Maps column indexes to their SQL in priority order", () => {
                    var orderBy = pagination.orderBy(
                        columns = cols,
                        orders  = [
                            {column: 1, dir: "desc"},
                            {column: 0, dir: "asc"}
                        ],
                        defaultSort = "pokemon.id ASC"
                    );
                    expect(orderBy).toBe("ORDER BY pokemon.number DESC, pokemon.generation ASC");
                });

                it("Ignores unsortable, out of range, non-numeric columns and bad directions", () => {
                    var orderBy = pagination.orderBy(
                        columns = cols,
                        orders  = [
                            {column: 2, dir: "asc"}, // "" - not sortable
                            {column: 3, dir: "asc"}, // out of range
                            {column: -1, dir: "asc"},
                            {column: "1; DROP TABLE pokemon", dir: "asc"},
                            {column: 0, dir: "asc; DROP TABLE pokemon"}
                        ],
                        defaultSort = "pokemon.id ASC"
                    );
                    expect(orderBy).toBe("ORDER BY pokemon.id ASC");
                });

                it("Doesn't repeat the tiebreak when it's already the sort", () => {
                    var orderBy = pagination.orderBy(
                        columns     = cols,
                        orders      = [],
                        defaultSort = "pokemon.id ASC",
                        tiebreak    = "pokemon.id ASC"
                    );
                    expect(orderBy).toBe("ORDER BY pokemon.id ASC");
                });

                it("Adds NULLS LAST to the requested sorts", () => {
                    var orderBy = pagination.orderBy(
                        columns     = cols,
                        orders      = [{column: 0, dir: "asc"}],
                        defaultSort = "pokemon.id ASC",
                        tiebreak    = "pokemon.id ASC",
                        nullsLast   = true
                    );
                    expect(orderBy).toBe("ORDER BY pokemon.generation ASC NULLS LAST, pokemon.id ASC");
                });
            });

            it("searchSQL ORs an ILIKE per column", () => {
                expect(pagination.searchSQL(["a.x", "b.y"])).toBe("(a.x ILIKE :search OR b.y ILIKE :search)");
            });

            describe("countRecords", () => {
                it("Counts the matching rows", () => {
                    var expected = queryExecute("SELECT COUNT(*) AS total FROM pokemon WHERE costume = false").total;
                    var total    = pagination.countRecords(
                        fromSQL  = "FROM pokemon",
                        whereSQL = "WHERE pokemon.costume = :costume",
                        params   = {costume: {value: false, cfsqltype: "boolean"}}
                    );
                    expect(total).toBe(expected);
                });

                it("Reads a cached count until it's evicted", () => {
                    var cacheKey = "paginationServiceTest.#createUUID()#";
                    var expected = queryExecute("SELECT COUNT(*) AS total FROM pokemon").total;

                    expect(
                        pagination.countRecords(
                            fromSQL  = "FROM pokemon",
                            whereSQL = "",
                            params   = {},
                            cacheKey = cacheKey
                        )
                    ).toBe(expected);

                    getInstance("cachebox:appCache").set(cacheKey, -5);
                    expect(
                        pagination.countRecords(
                            fromSQL  = "FROM pokemon",
                            whereSQL = "",
                            params   = {},
                            cacheKey = cacheKey
                        )
                    ).toBe(-5);

                    getInstance("cachebox:appCache").clear(cacheKey);
                    expect(
                        pagination.countRecords(
                            fromSQL  = "FROM pokemon",
                            whereSQL = "",
                            params   = {},
                            cacheKey = cacheKey
                        )
                    ).toBe(expected);
                    getInstance("cachebox:appCache").clear(cacheKey);
                });
            });

            describe("paginate", () => {
                it("Returns the page's rows with the total and filtered counts", () => {
                    var total = queryExecute("SELECT COUNT(*) AS total FROM pokemon").total;
                    var kanto = queryExecute("SELECT COUNT(*) AS total FROM pokemon WHERE generation = 1").total;

                    var page = pagination.paginate(
                        records     = 5,
                        offset      = 0,
                        fromSQL     = "FROM pokemon",
                        baseWhere   = "",
                        whereSQL    = "WHERE pokemon.generation = :generation",
                        whereParams = {generation: {value: 1, cfsqltype: "numeric"}},
                        fetchRows   = (pageParams) => queryExecute(
                            "SELECT id FROM pokemon WHERE pokemon.generation = :generation ORDER BY id LIMIT :records OFFSET :offset",
                            pageParams,
                            {returntype: "array"}
                        )
                    );

                    expect(page.recordsTotal).toBe(total);
                    expect(page.recordsFiltered).toBe(kanto);
                    expect(page.rows).toHaveLength(min(5, kanto));
                });

                it("Uses the total as the filtered count when there are no filters", () => {
                    var total = queryExecute("SELECT COUNT(*) AS total FROM pokemon").total;

                    var page = pagination.paginate(
                        records   = 3,
                        offset    = 2,
                        fromSQL   = "FROM pokemon",
                        baseWhere = "",
                        whereSQL  = "",
                        fetchRows = (pageParams) => queryExecute(
                            "SELECT id FROM pokemon ORDER BY id LIMIT :records OFFSET :offset",
                            pageParams,
                            {returntype: "array"}
                        )
                    );

                    var expectedIds = queryExecute(
                        "SELECT id FROM pokemon ORDER BY id LIMIT 3 OFFSET 2",
                        {},
                        {returntype: "array"}
                    ).map((row) => row.id);

                    expect(page.recordsTotal).toBe(total);
                    expect(page.recordsFiltered).toBe(total);
                    expect(page.rows.map((row) => row.id)).toBe(expectedIds);
                });
            });
        });
    }

}
