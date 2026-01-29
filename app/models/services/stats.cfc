component singleton accessors="true" {

    property name="cacheService" inject="services.cache";

    /**
     * Returns timestamp of date at 00:00:00
     *
     * @low date
     */
    private date function makeLowDate(required date low) {
        return createDateTime(year(low), month(low), day(low), 0, 0, 0);
    }

    /**
     * Returns timestamp of date at 23:59:59
     *
     * @high 
     */
    private date function makeHighDate(required date high) {
        return dateAdd(
            's',
            -1,
            dateAdd(
                'd',
                1,
                createDateTime(year(high), month(high), day(high), 0, 0, 0)
            )
        );
    }

    /**
     * Get stats for the supplied day
     * Returns null if no stats tracked
     */
    public any function getFromDay(required component trainer, required date suppliedDate) {
        return ormExecuteQuery(
            '
            from stat as stat
            where trainer = :trainer
            and created >= :low and created < :high
        ',
            {
                'trainer': arguments.trainer,
                'low'    : makeLowDate(arguments.suppliedDate),
                'high'   : makeHighDate(arguments.suppliedDate)
            },
            true
        );
    }

    /**
     * Inserts data to stats table
     */
    public void function track(
        required component trainer,
        required numeric xp,
        required numeric caught,
        required numeric spun,
        required numeric walked
    ) {
        var newStat = entityNew(
            'stat',
            {
                'trainer': arguments.trainer,
                'xp'     : arguments.xp,
                'caught' : arguments.caught,
                'spun'   : arguments.spun,
                'walked' : arguments.walked
            }
        );

        entitySave(newStat);
        ormFlush();

        // Clears the trainer's stat cache entries whenever they track stats
        cacheService.clear(filter = '#arguments.trainer.getId()#|stats.getStats');
        return;
    }

    /**
     * Return struct of trainer's stats between start/end dates in format for line chart
     *
     * @trainer   trainer
     * @datePart  'd', 'm' (day or month grouping)
     * @startDate start
     * @endDate   end
     */
    public struct function get(
        required component trainer,
        required string datePart,
        required date startDate,
        required date endDate
    ) {
        var cacheKey = '';
        var stats;

        // Cache if this is a week view OR month view OR year view
        if(
            (dayOfWeek(arguments.startDate) == 1 && dateDiff('d', arguments.startDate, arguments.endDate) == 6) ||
            (
                month(arguments.startDate) == month(arguments.endDate) &&
                day(arguments.startDate) == 1 &&
                day(arguments.endDate) == daysInMonth(arguments.endDate)
            ) ||
            (
                month(arguments.startDate) == 1 &&
                month(arguments.endDate) == 12 &&
                dateDiff('d', arguments.startDate, arguments.endDate) + 1 == daysInYear(arguments.startDate)
            )
        ) {
            cachekey = '#arguments.trainer.getId()#|stats.getStats|startDate=#dateFormat(arguments.startDate, 'short')#|endDate=#dateFormat(arguments.endDate, 'short')#';
            stats    = cacheService.get(cacheKey);
        }

        if(!cacheKey.len() || isNull(stats)) {
            stats = {
                labels : [],
                data   : {},
                summary: {
                    totalxp    : '--',
                    totalcaught: '--',
                    totalspun  : '--',
                    totalwalked: '--',
                    avgxp      : '--',
                    avgcaught  : '--',
                    avgspun    : '--',
                    avgwalked  : '--'
                }
            };

            var qStats = ormExecuteQuery(
                '
                from stat as stat
                where trainer = :trainer
                and created >= :startDate and created < :endDate
                order by created asc
            
            ',
                {
                    'trainer'  : arguments.trainer,
                    'startDate': makeLowDate(arguments.startDate),
                    'endDate'  : makeHighDate(arguments.endDate)
                }
            );

            qStats.each((currStats) => {
                var currDate = dateFormat(currStats.getCreated(), 'short');
                stats.labels.append(currDate);
                stats.data.insert(currDate, {});
                stats.data[currDate].xp = currStats.getXp();
                stats.data[currDate].caught = currStats.getCaught();
                stats.data[currDate].spun = currStats.getSpun();
                stats.data[currDate].walked = currStats.getWalked();
            });

            // Calculate deltas
            for(var i = 1; i <= stats.labels.len(); i++) {
                if(i == 1) {
                    // first date can't calculate deltas
                    stats.data[stats.labels[i]].deltaxp = '--';
                    stats.data[stats.labels[i]].deltacaught = '--';
                    stats.data[stats.labels[i]].deltaspun = '--';
                    stats.data[stats.labels[i]].deltawalked = '--';
                }
                else {
                    var currDiff = dateDiff('d', stats.labels[i - 1], stats.labels[i]);
                    stats.data[stats.labels[i]].deltaxp = round(
                        (stats.data[stats.labels[i]].xp - stats.data[stats.labels[i - 1]].xp) / currDiff,
                        1
                    );
                    stats.data[stats.labels[i]].deltacaught = round(
                        (stats.data[stats.labels[i]].caught - stats.data[stats.labels[i - 1]].caught) / currDiff,
                        1
                    );
                    stats.data[stats.labels[i]].deltaspun = round(
                        (stats.data[stats.labels[i]].spun - stats.data[stats.labels[i - 1]].spun) / currDiff,
                        1
                    );
                    stats.data[stats.labels[i]].deltawalked = round(
                        (stats.data[stats.labels[i]].walked - stats.data[stats.labels[i - 1]].walked) / currDiff,
                        1
                    );
                }
            }

            // Calculate summary stats
            if(stats.labels.len() >= 2) {
                // Totals for range
                stats.summary.totalxp     = stats.data[stats.labels[stats.labels.len()]].xp - stats.data[stats.labels[1]].xp;
                stats.summary.totalcaught = stats.data[stats.labels[stats.labels.len()]].caught - stats.data[
                    stats.labels[1]
                ].caught;
                stats.summary.totalspun   = stats.data[stats.labels[stats.labels.len()]].spun - stats.data[stats.labels[1]].spun;
                stats.summary.totalwalked = stats.data[stats.labels[stats.labels.len()]].walked - stats.data[
                    stats.labels[1]
                ].walked;

                // Average for range
                var daysTracked = dateDiff(
                    'd',
                    stats.labels[1],
                    stats.labels[stats.labels.len()]
                ) + 1;
                stats.summary.avgxp     = round(stats.summary.totalxp / daysTracked, 1);
                stats.summary.avgcaught = round(stats.summary.totalcaught / daysTracked, 1);
                stats.summary.avgspun   = round(stats.summary.totalspun / daysTracked, 1);
                stats.summary.avgwalked = round(stats.summary.totalwalked / daysTracked, 1);
            }

            if(cacheKey.len()) {
                cacheService.put(cacheKey, stats, 10, 10);
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
    public array function getLeaderboard(required date date, string stat = 'xp') {
        var cacheKey    = 'stats.getLeaderboard|date=#month(arguments.date)#|stat=#arguments.stat#';
        var leaderboard = cacheService.get(cacheKey);

        if(isNull(leaderboard)) {
            var low = createDateTime(
                year(arguments.date),
                month(arguments.date),
                1,
                0,
                0,
                0
            );
            var high        = dateAdd('s', -1, dateAdd('m', 1, low));
            var daysElapsed = dateDiff('d', low, arguments.date) + 1;

            var trainerDeltas = ormExecuteQuery(
                '
                select trainer, max(stat.#lCase(arguments.stat)#) - min(stat.#lCase(arguments.stat)#) as delta
                from trainer as trainer
                left outer join trainer.stat as stat with stat.created >= :low and stat.created <= :high
                where trainer.verified = true
                and trainer.username is not null
                group by trainer
                having count(stat) > 1
                ',
                {'low': low, 'high': high},
                {maxResults: 10}
            );

            leaderboard = [];
            trainerDeltas.each((trainer, index) => {
                leaderboard.append({username: trainer[1].getUsername(), delta: !isNull(trainer[2]) ? (trainer[2] / daysElapsed) : '--'});
            });

            leaderboard.sort((a, b) => {
                if(a.delta == '--') return 1;
                if(b.delta == '--') return -1;
                return (a.delta - b.delta) > 0 ? -1 : 1;
            });

            if(!leaderboard.len()) {
                leaderboard.append({username: 'Start tracking your stats!', delta: ''});
            }

            cacheService.put(cacheKey, leaderboard, 15, 15);
        }
        return leaderboard;
    }

    /**
     * For each region, get total number of caught and shiny pokemon
     * and total available pokemon and shiny pokemon
     */
    public array function getPokedexStats(required component trainer) {
        var cacheKey = '#arguments.trainer.getId()#|stats.getPokedexStats';

        if(isNull(pokedexStats)) {
            pokedexStats = ormExecuteQuery(
                '
                select 
                    sum(case when pokemon.live is true then 1 else 0 end) as total,
                    sum(case when pokemon.shiny is true then 1 else 0 end) as totalshiny,
                    pokemon.generation.region as region, 
                    sum(case when pokedexC.id is null then 0 when pokemon.live is false then 0 else 1 end) as caught,
                    sum(case when pokedexS.id is null then 0 when pokemon.shiny is false then 0 else 1 end) as shiny
                from pokemon as pokemon
                left outer join pokemon.pokedex as pokedexC with pokedexC.trainer = :trainer and pokedexC.caught = true
                left outer join pokemon.pokedex as pokedexS with pokedexS.trainer = :trainer and pokedexS.shiny = true
                where pokemon.mega = false and pokemon.giga = false
                group by pokemon.generation.region, pokemon.generation.generation
                order by pokemon.generation.generation asc
                ',
                {'trainer': arguments.trainer}
            );

            cacheService.put(cacheKey, pokedexStats, 10, 10);
        }

        return pokedexStats;
    }

}
