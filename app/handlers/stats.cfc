component extends="base" {

    this.allowedMethods = {
        overview          : "GET,POST",
        leaderboard       : "GET",
        trackForm         : "GET",
        track             : "POST",
        getPokedexStats   : "GET",
        getMedalSummary   : "GET",
        getMedalProgress  : "GET",
        trackMedalProgress: "POST",
        topDeltas         : "GET"
    };

    property name="async"          inject="asyncManager@coldbox";
    property name="pokedexService" inject="services.pokedex";
    property name="medalService"   inject="services.medal";
    property name="statsService"   inject="services.stats";
    property name="trainerService" inject="services.trainer";

    this.prehandler_only = "overview";

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = "Stats | #getSetting("title")#";
        prc.metaDescription = "Keep an eye on your progress with detailed tracking of your total XP, Pokemon caught, PokeStops spun, distance walked, and medals.";
        prc.metaRobots      = "noindex, nofollow";
    }

    /**
     * Stats overview page
     *
     * @rc.trainerid (optional) defaults to current session
     * @rc.startDate (optional) defaults to this week's sunday
     * @rc.endDate   (optional) defaults to this week's saturday
     * @rc.summary   (optional) t/f quick summary view 
     */
    function overview(event, rc, prc) secured="user" {
        var currDate = dateFormat(now(), "short");
        var weekday  = dayOfWeek(currDate);

        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();
        rc.startDate = rc?.startDate ?: dateAdd("d", -(weekday - 1), currDate);
        rc.endDate   = rc?.endDate ?: dateAdd("d", (7 - weekday), currDate);
        rc.summary   = rc?.summary ?: false;

        // Your own stats, or a friend's
        if(hasValidationErrors(target = rc, constraints = "stats.overview")) {
            htmlValidationFailure(event = event, redirectEvent = "home");
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.myProfile = prc.trainerid == prc.oCurrentUser.getId();
        prc.startDate = parseDateTime(rc.startDate);
        prc.endDate   = parseDateTime(rc.endDate);
        prc.stats     = statsService.getStats(
            trainerid = prc.trainerid,
            startDate = prc.startDate,
            endDate   = prc.endDate
        );

        prc.trainerStatStruct = trainerService.getCurrentLevel(trainerid = prc.trainerid);

        if(rc.summary) {
            event.setView(view = "/views/stats/summary", nolayout = true);
        }
    }

    /**
     * Leaderboard view for the given month and stat
     *
     * @rc.stat (optional) stat type, defaults to XP
     */
    function leaderboard(event, rc, prc) {
        rc.stat = rc?.stat ?: "XP";

        if(hasValidationErrors(target = rc, constraints = "stats.leaderboard")) {
            htmlValidationFailure(event = event);
            return;
        }

        // The current month's leaderboard
        prc.date        = now();
        prc.leaderboard = statsService.getLeaderboard(date = prc.date, stat = rc.stat);

        event.setView(
            view     = "/views/stats/leaderboard",
            nolayout = true,
            args     = {
                leaderboard: prc.leaderboard,
                stat       : rc.stat,
                title      : "#dateFormat(prc.date, "mmm")# #ucFirst(rc.stat)# Leaderboard"
            }
        );
    }

    /**
     * Track daily stats form
     */
    function trackForm(event, rc, prc) secured="user" {
        prc.trainerid  = prc.oCurrentUser.getId();
        prc.latestStat = statsService.getLatestStat(trainerid = prc.trainerid);
        event.setView(
            view     = "/views/stats/modal/track",
            nolayout = true,
            args     = {
                currDate  : now(),
                trainerid : prc.trainerid,
                latestStat: isNull(prc.latestStat) ? "" : prc.latestStat
            }
        );
    }

    /**
     * Submit and track daily stats
     *
     * @rc.trainerid (optional) defaults to current session
     * @rc.xp        xp
     * @rc.caught    caught
     * @rc.spun      spun
     * @rc.walked    walked
     */
    function track(event, rc, prc) secured="user" {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        if(hasValidationErrors(target = rc, constraints = "stats.track")) {
            jsonValidationFailure(event = event, message = "Unable To Track Stats");
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.xp        = parseNumber(rc.xp);
        prc.caught    = parseNumber(rc.caught);
        prc.spun      = parseNumber(rc.spun);
        prc.walked    = parseNumber(rc.walked);

        var tracked = statsService.track(
            trainerid = prc.trainerid,
            xp        = prc.xp,
            caught    = prc.caught,
            spun      = prc.spun,
            walked    = prc.walked
        );
        if(!tracked) {
            jsonValidationFailure(event = event, message = "Unable To Track Stats");
            return;
        }

        jsonOk(event = event);
    }

    /**
     * Pokedex stats views
     * Shows caught/total pokemon for normal and shiny per region
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function getPokedexStats(event, rc, prc) secured="user" {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        // Your own pokedex stats, or a friend's
        if(hasValidationErrors(target = rc, constraints = "stats.friendStats")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.myProfile = prc.trainerid == prc.oCurrentUser.getId();

        var results = async
            .all(
                () => statsService.getPokedexStats(trainerid = prc.trainerid),
                () => pokedexService.getMissingString(trainerid = prc.trainerid, shiny = false),
                () => pokedexService.getMissingString(trainerid = prc.trainerid, shiny = true)
            )
            .get();

        prc.pokedexStats       = results[1];
        prc.missingString      = results[2];
        prc.missingShinyString = results[3];

        event.setView(
            view     = "/views/stats/pokedexstats",
            nolayout = true,
            args     = {
                pokedexstats      : prc.pokedexStats,
                missingString     : prc.missingString,
                missingShinyString: prc.missingShinyString
            }
        );
    }

    /**
     * Medal summary view
     * Lists medals in none, bronze, silver, gold, platinum state
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function getMedalSummary(event, rc, prc) secured="user" {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        // Your own medals, or a friend's
        if(hasValidationErrors(target = rc, constraints = "stats.friendStats")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainerid     = parseNumber(rc.trainerid);
        prc.medalProgress = medalService.getProgress(trainerid = prc.trainerid);

        event.setView(
            view     = "/views/stats/medalsummary",
            nolayout = true,
            args     = {medalProgress: prc.medalProgress}
        );
    }

    /**
     * Medal progress view
     * Displays medals and progress for each to platinum rank
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function getMedalProgress(event, rc, prc) secured="user" {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        // Your own medals, or a friend's
        if(hasValidationErrors(target = rc, constraints = "stats.friendStats")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainerid     = parseNumber(rc.trainerid);
        prc.medalProgress = medalService.getProgress(trainerid = prc.trainerid);

        event.setView(
            view     = "/views/stats/medalprogress",
            nolayout = true,
            // A friend's medals are shown, not edited
            args     = {medalProgress: prc.medalProgress, editable: prc.trainerid == prc.oCurrentUser.getId()}
        );
    }

    /**
     * Track progress for the given model
     * Returns JSON
     *
     * @rc.medal   medal pk
     * @rc.current value to track
     */
    function trackMedalProgress(event, rc, prc) secured="user" {
        if(hasValidationErrors(target = rc, constraints = "stat.trackMedalProgress")) {
            jsonValidationFailure(event = event, message = "Unable to track medal progress");
            return;
        }

        prc.medal = medalService.getFromId(id = parseNumber(rc.medal));

        medalService.trackProgress(
            trainerid = prc.oCurrentUser.getId(),
            medal     = prc.medal,
            current   = parseNumber(rc.current)
        );

        jsonOk(event = event);
    }

    /**
     * Top deltas view
     * Lists the biggest deltas for each stat
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function topDeltas(event, rc, prc) secured="user" {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();

        // Your own deltas, or a friend's
        if(hasValidationErrors(target = rc, constraints = "stats.friendStats")) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.topDeltas = statsService.getTopDeltas(trainerid = prc.trainerid);

        event.setView(
            view     = "/views/stats/topdeltas",
            nolayout = true,
            args     = {topDeltas: prc.topDeltas}
        );
    }

}
