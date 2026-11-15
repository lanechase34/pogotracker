component singleton accessors="true" {

    property name="cache"          inject="cachebox:appCache";
    property name="trainerCache"   inject="cachebox:trainerCache";
    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

    // A stat row's columns
    variables.STAT_COLUMNS = "id, created, updated, caught, spun, walked, xp, trainerid";

    // The tracked stat columns, in the order getStats builds each day's values, deltas, totals and averages
    variables.STAT_FIELDS = ["xp", "caught", "spun", "walked"];

    /**
     * Get stats for the supplied day
     * Returns null if no stats tracked
     */
    public any function getFromDay(required numeric trainerid, required date suppliedDate) {
        var rows = queryExecute(
            "
            SELECT #variables.STAT_COLUMNS#
            FROM stat
            WHERE trainerid = :trainerid
                AND created >= :low AND created < :high
            ORDER BY created DESC
            LIMIT 1
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                low      : {value: utilService.makeLowDate(arguments.suppliedDate), cfsqltype: "timestamp"},
                high     : {value: utilService.makeHighDate(arguments.suppliedDate), cfsqltype: "timestamp"}
            },
            {returnType: "array"}
        );
        return utilService.firstRow(rows);
    }

    /**
     * The trainer's most recent stat (by created date), null when they have none
     *
     * @trainerid trainer pk
     */
    public any function getLatestStat(required numeric trainerid) {
        var latest = queryExecute(
            "
            SELECT #variables.STAT_COLUMNS#
            FROM stat
            WHERE trainerid = :trainerid
            ORDER BY created DESC, id DESC
            LIMIT 1
            ",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}},
            {returnType: "array"}
        );
        return utilService.firstRow(latest);
    }

    /**
     * Inserts data to stats table
     * One stat per trainer per day - returns false when today's is already tracked (e.g. a double submit)
     */
    public boolean function track(
        required numeric trainerid,
        required numeric xp,
        required numeric caught,
        required numeric spun,
        required numeric walked
    ) {
        var inserted = queryExecute(
            "
            INSERT INTO stat (trainerid, xp, caught, spun, walked)
            VALUES (:trainerid, :xp, :caught, :spun, :walked)
            ON CONFLICT DO NOTHING
            RETURNING id
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                xp       : {value: arguments.xp, cfsqltype: "bigint"},
                caught   : {value: arguments.caught, cfsqltype: "integer"},
                spun     : {value: arguments.spun, cfsqltype: "integer"},
                walked   : {
                    value    : arguments.walked,
                    cfsqltype: "decimal",
                    scale    : 2
                }
            }
        );
        if(!inserted.recordCount) return false;

        // Clears the trainer's stat cache entries whenever they track stats
        trainerCache.clearByKeySnippet(getStatsCacheSnippet(arguments.trainerid), true);
        trainerCache.clear(getTopDeltasCacheKey(arguments.trainerid));

        // The cached trainer and their cached level are stale now
        trainerService.clearCache(arguments.trainerid);
        return true;
    }

    /**
     * Return struct of trainer's stats between start/end dates in format for line chart
     *
     * @trainerid trainer pk
     * @startDate start
     * @endDate   end
     */
    public struct function getStats(
        required numeric trainerid,
        required date startDate,
        required date endDate
    ) {
        var cacheKey = "";
        var stats;

        // Cache if this is a week view OR month view OR year view
        if(
            (dayOfWeek(arguments.startDate) == 1 && dateDiff("d", arguments.startDate, arguments.endDate) == 6) ||
            (
                month(arguments.startDate) == month(arguments.endDate) &&
                day(arguments.startDate) == 1 &&
                day(arguments.endDate) == daysInMonth(arguments.endDate)
            ) ||
            (
                month(arguments.startDate) == 1 &&
                month(arguments.endDate) == 12 &&
                dateDiff("d", arguments.startDate, arguments.endDate) + 1 == daysInYear(arguments.startDate)
            )
        ) {
            cacheKey = getStatsCacheKey(
                trainerid = arguments.trainerid,
                startDate = arguments.startDate,
                endDate   = arguments.endDate
            );
            stats = trainerCache.get(cacheKey);
        }

        if(!cacheKey.len() || isNull(stats)) {
            stats = {
                labels : [],
                data   : {},
                summary: {
                    totalxp    : "--",
                    totalcaught: "--",
                    totalspun  : "--",
                    totalwalked: "--",
                    avgxp      : "--",
                    avgcaught  : "--",
                    avgspun    : "--",
                    avgwalked  : "--"
                }
            };

            var qStats = queryExecute(
                "
                SELECT created, xp, caught, spun, walked
                FROM stat
                WHERE trainerid = :trainerid
                    AND created >= :startDate AND created < :endDate
                ORDER BY created ASC
                ",
                {
                    trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                    startDate: {value: utilService.makeLowDate(arguments.startDate), cfsqltype: "timestamp"},
                    endDate  : {value: utilService.makeHighDate(arguments.endDate), cfsqltype: "timestamp"}
                },
                {returnType: "array"}
            );

            qStats.each((currStats) => {
                var currDate = dateFormat(currStats.created, "short");
                stats.labels.append(currDate);
                stats.data.insert(currDate, {});
                for(var field in variables.STAT_FIELDS) {
                    stats.data[currDate][field] = currStats[field];
                }
            });

            // Calculate deltas
            for(var i = 1; i <= stats.labels.len(); i++) {
                var currRow = stats.data[stats.labels[i]];
                if(i == 1) {
                    // first date can't calculate deltas
                    for(var field in variables.STAT_FIELDS) {
                        currRow["delta#field#"] = "--";
                    }
                }
                else {
                    var prevRow  = stats.data[stats.labels[i - 1]];
                    var currDiff = dateDiff("d", stats.labels[i - 1], stats.labels[i]);
                    for(var field in variables.STAT_FIELDS) {
                        currRow["delta#field#"] = round((currRow[field] - prevRow[field]) / currDiff, 1);
                    }
                }
            }

            // Calculate summary stats
            if(stats.labels.len() >= 2) {
                var firstLabel  = stats.labels[1];
                var lastLabel   = stats.labels[stats.labels.len()];
                var firstRow    = stats.data[firstLabel];
                var lastRow     = stats.data[lastLabel];
                var daysTracked = dateDiff("d", firstLabel, lastLabel) + 1;

                // Totals and averages for range
                for(var field in variables.STAT_FIELDS) {
                    stats.summary["total#field#"] = lastRow[field] - firstRow[field];
                    stats.summary["avg#field#"]   = round(stats.summary["total#field#"] / daysTracked, 1);
                }
            }

            if(cacheKey.len()) {
                trainerCache.set(cacheKey, stats, 10, 10);
            }
        }

        return stats;
    }

    /**
     * Rank trainer's based on who has the most stat per day for month of supplied date
     *
     * @date date to get month from
     * @stat stat to rank (xp/caught/spun/walked)
     */
    public array function getLeaderboard(required date date, string stat = "xp") {
        var forDate = arguments.date;
        var forStat = arguments.stat;
        return cache.getOrSet(
            "stats.getLeaderboard|date=#year(forDate)#-#month(forDate)#|stat=#forStat#",
            () => {
                var low         = createDateTime(year(forDate), month(forDate), 1, 0, 0, 0);
                // Start of next month
                var high        = dateAdd("m", 1, low);
                var daysElapsed = dateDiff("d", low, forDate) + 1;

                var column = lCase(forStat);

                var trainerDeltas = queryExecute(
                    "
                    SELECT trainer.username, MAX(stat.#column#) - MIN(stat.#column#) AS delta
                    FROM trainer
                    INNER JOIN stat ON stat.trainerid = trainer.id AND stat.created >= :low AND stat.created < :high
                    WHERE trainer.verified = true
                    GROUP BY trainer.id, trainer.username
                    HAVING COUNT(stat.id) > 1
                    ORDER BY delta DESC
                    LIMIT 10
                    ",
                    {low: {value: low, cfsqltype: "timestamp"}, high: {value: high, cfsqltype: "timestamp"}},
                    {returnType: "array"}
                );

                var leaderboard = trainerDeltas.map((trainer) => {
                    return {
                        username: trainer.username,
                        delta   : !isNull(trainer.delta) ? (trainer.delta / daysElapsed) : "--"
                    };
                });

                // Highest delta first, "--" last
                leaderboard.sort((a, b) => {
                    var aMissing = a.delta == "--";
                    var bMissing = b.delta == "--";
                    if(aMissing || bMissing) return aMissing == bMissing ? 0 : (aMissing ? 1 : -1);
                    return sgn(b.delta - a.delta);
                });

                return leaderboard;
            },
            15,
            15
        );
    }

    /**
     * For each region, get total number of caught and shiny pokemon
     * and total available pokemon and shiny pokemon
     */
    public array function getPokedexStats(required numeric trainerid) {
        var forTrainerid = arguments.trainerid;
        return trainerCache.getOrSet(
            getPokedexStatsCacheKey(forTrainerid),
            // [total, totalshiny, region, caught, shiny] per region - the view reads them by position
            () => queryExecute(
                "
                SELECT
                    COUNT(*) FILTER (WHERE pokemon.live = true) AS total,
                    COUNT(*) FILTER (WHERE pokemon.shiny = true) AS totalshiny,
                    generation.region,
                    COUNT(*) FILTER (WHERE pokedex.caught = true AND pokemon.live = true) AS caught,
                    COUNT(*) FILTER (WHERE pokedex.shiny = true AND pokemon.shiny = true) AS shiny
                FROM pokemon
                INNER JOIN generation ON generation.generation = pokemon.generation
                LEFT JOIN pokedex ON pokedex.pokemonid = pokemon.id AND pokedex.trainerid = :trainerid
                WHERE pokemon.mega = false
                    AND pokemon.giga = false
                    AND pokemon.costume = false
                GROUP BY generation.region, generation.generation
                ORDER BY generation.generation ASC
                ",
                {trainerid: {value: forTrainerid, cfsqltype: "integer"}},
                {returnType: "array"}
            ).map((row) => [
                row.total,
                row.totalshiny,
                row.region,
                row.caught,
                row.shiny
            ]),
            10,
            10
        );
    }

    /**
     * Evict the trainer's cached pokedex stats so the next getPokedexStats reads the database
     * Call after anything that changes the trainer's pokedex
     *
     * @trainerid trainer pk
     */
    public void function clearPokedexStatsCache(required numeric trainerid) {
        trainerCache.clear(getPokedexStatsCacheKey(arguments.trainerid));
        return;
    }

    /**
     * Get top n biggest single-day deltas for each stat type for the supplied trainer
     *
     * @trainerid trainer pk
     * @records   number of top records to retrieve
     *
     * @return struct of arrays in format: { xp: [{date, delta}, ...], caught: [...], spun: [...], walked: [...] }
     */
    public struct function getTopDeltas(required numeric trainerid, numeric records = 5) {
        var forTrainerid = arguments.trainerid;
        var recordLimit  = arguments.records;
        return trainerCache.getOrSet(
            getTopDeltasCacheKey(forTrainerid),
            () => {
                // Each day's delta per stat divided by the calendar days since the previous stat, then the top n of each stat
                // The trainer's first stat has no previous one, so it has no delta
                var rows = queryExecute(
                    "
                    SELECT ranked.stat, ranked.curr_date, ranked.delta
                    FROM (
                        SELECT stats.stat, deltas.curr_date, stats.delta,
                            ROW_NUMBER() OVER (PARTITION BY stats.stat ORDER BY stats.delta DESC, deltas.curr_date ASC) AS position
                        FROM (
                            SELECT
                                created AS curr_date,
                                CAST(xp - LAG(xp) OVER byday AS numeric) AS xp_change,
                                CAST(caught - LAG(caught) OVER byday AS numeric) AS caught_change,
                                CAST(spun - LAG(spun) OVER byday AS numeric) AS spun_change,
                                CAST(walked - LAG(walked) OVER byday AS numeric) AS walked_change,
                                NULLIF(CAST(created AS date) - CAST(LAG(created) OVER byday AS date), 0) AS days
                            FROM stat
                            WHERE trainerid = :trainerid
                            WINDOW byday AS (ORDER BY created ASC)
                        ) AS deltas
                        CROSS JOIN LATERAL (
                            VALUES
                                ('xp', ROUND(deltas.xp_change / deltas.days, 1)),
                                ('caught', ROUND(deltas.caught_change / deltas.days, 1)),
                                ('spun', ROUND(deltas.spun_change / deltas.days, 1)),
                                ('walked', ROUND(deltas.walked_change / deltas.days, 1))
                        ) AS stats (stat, delta)
                        WHERE deltas.days IS NOT NULL
                    ) AS ranked
                    WHERE ranked.position <= :records
                    ORDER BY ranked.stat ASC, ranked.position ASC
                    ",
                    {
                        trainerid: {value: forTrainerid, cfsqltype: "integer"},
                        records  : {value: recordLimit, cfsqltype: "integer"}
                    },
                    {returnType: "array"}
                );

                var topDeltas = {
                    xp    : [],
                    caught: [],
                    spun  : [],
                    walked: []
                };
                rows.each((row) => {
                    topDeltas[row.stat].append({date: dateFormat(row.curr_date, "short"), delta: row.delta});
                });

                return topDeltas;
            },
            60,
            60
        );
    }

    /**
     * Cache key for the stats getStats loads for a date range
     *
     * @trainerid trainer pk
     * @startDate start
     * @endDate   end
     */
    private string function getStatsCacheKey(
        required numeric trainerid,
        required date startDate,
        required date endDate
    ) {
        return "#arguments.trainerid#|stats.getStats|startDate=#dateFormat(arguments.startDate, "short")#|endDate=#dateFormat(arguments.endDate, "short")#";
    }

    /**
     * Regex matching every getStats cache key of the trainer (see getStatsCacheKey)
     *
     * @trainerid trainer pk
     */
    private string function getStatsCacheSnippet(required numeric trainerid) {
        return "^#arguments.trainerid#\|stats\.getStats\|";
    }

    /**
     * Cache key for the pokedex stats getPokedexStats loads
     *
     * @trainerid trainer pk
     */
    private string function getPokedexStatsCacheKey(required numeric trainerid) {
        return "#arguments.trainerid#|stats.getPokedexStats";
    }

    /**
     * Cache key for the top deltas getTopDeltas loads
     *
     * @trainerid trainer pk
     */
    private string function getTopDeltasCacheKey(required numeric trainerid) {
        return "#arguments.trainerid#|stats.getTopDeltas";
    }

}
