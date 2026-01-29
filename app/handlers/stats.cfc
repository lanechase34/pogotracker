component extends="base" {

    this.allowedMethods = {
        overview          : 'GET,POST',
        leaderboard       : 'GET',
        trackForm         : 'GET',
        track             : 'POST',
        getPokedexStats   : 'GET',
        getMedalSummary   : 'GET',
        getMedalProgress  : 'GET',
        trackMedalProgress: 'POST'
    };

    property name="cacheService"   inject="services.cache";
    property name="pokedexService" inject="services.pokedex";
    property name="friendService"  inject="services.friend";
    property name="medalService"   inject="services.medal";
    property name="sessionService" inject="services.session";
    property name="statsService"   inject="services.stats";
    property name="trainerService" inject="services.trainer";

    this.prehandler_only = 'overview';

    function preHandler(event, rc, prc, action, eventArguments) {
        prc.title           = 'Stats - #getSetting('title')#';
        prc.metaDescription = 'Keep an eye on your progress with detailed tracking of your total XP, Pokemon caught, PokeStops spun, distance walked, and medals.';
    }

    /**
     * Stats overview page
     *
     * @rc.trainerid (optional) defaults to current session
     * @rc.startDate (optional) defaults to this week's sunday
     * @rc.endDate   (optional) defaults to this week's saturday
     * @rc.summary   (optional) t/f quick summary view 
     */
    function overview(event, rc, prc) {
        var currDate  = dateFormat(now(), 'short');
        var dayOfWeek = dayOfWeek(currDate);

        rc.trainerid = rc?.trainerid ?: session.trainerid;
        rc.startDate = rc?.startDate ?: dateAdd('d', -(dayOfWeek - 1), currDate);
        rc.endDate   = rc?.endDate ?: dateAdd('d', (7 - dayOfWeek), currDate);
        rc.summary   = rc?.summary ?: false;

        if(hasValidationErrors(target = rc, constraints = 'stats.overview')) {
            htmlValidationFailure(event = event, redirectEvent = 'home');
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.myProfile = prc.trainerid == session.trainerid;

        // Validate viewing a friend's stat overview
        if(
            !prc.myProfile && !friendService.checkFriend(
                trainerid = session.trainerid,
                friendid  = prc.trainerid,
                accepted  = true
            )
        ) {
            htmlValidationFailure(event = event, redirectEvent = 'home');
            return;
        }

        prc.startDate = parseDateTime(rc.startDate);
        prc.endDate   = parseDateTime(rc.endDate);
        prc.trainer   = trainerService.getFromId(trainerid = prc.trainerid);
        prc.stats     = statsService.get(
            trainer   = prc.trainer,
            datePart  = 'd',
            startDate = prc.startDate,
            endDate   = prc.endDate
        );

        prc.trainerStatStruct = prc.myProfile ? session.statStruct : prc.trainer.getCurrentLevel();

        if(rc.summary) {
            event.setView(view = '/views/stats/summary', nolayout = true);
        }
    }

    /**
     * Leaderboard view for the given month and stat
     *
     * @rc.stat (optional) stat type, defaults to XP
     */
    function leaderboard(event, rc, prc) {
        rc.epochdate = now().getTime();
        rc.stat      = rc?.stat ?: 'XP';

        if(hasValidationErrors(target = rc, constraints = 'stats.leaderboard')) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.leaderboard = [];
        prc.date        = dateAdd(
            's',
            rc.epochdate / 1000,
            dateConvert('utc2Local', 'January 1 1970 00:00')
        );
        prc.leaderboard = statsService.getLeaderboard(date = prc.date, stat = rc.stat);

        event.setView(
            view     = '/views/stats/leaderboard',
            nolayout = true,
            args     = {
                leaderboard: prc.leaderboard,
                stat       : rc.stat,
                title      : '#dateFormat(prc.date, 'mmm')# #ucFirst(rc.stat)# Leaderboard'
            }
        );
    }

    /**
     * Track daily stats form
     */
    function trackForm(event, rc, prc) {
        prc.trainer = trainerService.getFromId(session.trainerid);
        event.setView(
            view     = '/views/stats/modal/track',
            nolayout = true,
            args     = {currDate: now(), trainer: prc.trainer}
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
    function track(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: session.trainerid;
        if(hasValidationErrors(target = rc, constraints = 'stats.track')) {
            jsonValidationFailure(event = event, message = 'Unable To Track Stats');
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid)
        prc.trainer   = trainerService.getFromId(prc.trainerid);

        // Make sure user hasn't already tracked stats on this day
        if(!isNull(statsService.getFromDay(trainer = prc.trainer, suppliedDate = now()))) {
            jsonValidationFailure(event = event, message = 'Unable To Track Stats');
            return;
        }

        prc.xp     = parseNumber(rc.xp);
        prc.caught = parseNumber(rc.caught);
        prc.spun   = parseNumber(rc.spun);
        prc.walked = parseNumber(rc.walked);

        statsService.track(
            trainer = prc.trainer,
            xp      = prc.xp,
            caught  = prc.caught,
            spun    = prc.spun,
            walked  = prc.walked
        );

        sessionService.update(prc.trainerid);

        jsonOk(event = event);
    }

    /**
     * Pokedex stats views
     * Shows caught/total pokemon for normal and shiny per region
     *
     * @rc.trainerid (optional) defaults to current session
     */
    function getPokedexStats(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: session.trainerid;

        // Validate viewing a friend's pokedex stats
        prc.trainerid = parseNumber(rc.trainerid);
        prc.myProfile = prc.trainerid == session.trainerid;
        if(
            !prc.myProfile && !friendService.checkFriend(
                trainerid = session.trainerid,
                friendid  = prc.trainerid,
                accepted  = true
            )
        ) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainer            = trainerService.getFromId(trainerid = prc.trainerid);
        prc.pokedexStats       = statsService.getPokedexStats(trainer = prc.trainer);
        prc.missingString      = pokedexService.getMissingString(trainer = prc.trainer, shiny = false);
        prc.missingShinyString = pokedexService.getMissingString(trainer = prc.trainer, shiny = true);

        event.setView(
            view     = '/views/stats/pokedexstats',
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
    function getMedalSummary(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: session.trainerid;

        // Validate viewing a friend's pokedex stats
        prc.trainerid = parseNumber(rc.trainerid);
        if(
            prc.trainerid != session.trainerid && !friendService.checkFriend(
                trainerid = session.trainerid,
                friendid  = prc.trainerid,
                accepted  = true
            )
        ) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainer       = trainerService.getFromId(trainerid = prc.trainerid);
        prc.medalProgress = medalService.getProgress(trainer = prc.trainer);

        event.setView(
            view     = '/views/stats/medalsummary',
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
    function getMedalProgress(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: session.trainerid;

        // Validate viewing a friend's pokedex stats
        prc.trainerid = parseNumber(rc.trainerid);
        if(prc.trainerid != session.trainerid && !friendService.checkFriend(session.trainerid, prc.trainerid, true)) {
            htmlValidationFailure(event = event);
            return;
        }

        prc.trainer       = trainerService.getFromId(trainerid = prc.trainerid);
        prc.medalProgress = medalService.getProgress(trainer = prc.trainer);

        event.setView(
            view     = '/views/stats/medalprogress',
            nolayout = true,
            args     = {medalProgress: prc.medalProgress}
        );
    }

    /**
     * Track progress for the given model
     * Returns JSON
     *
     * @rc.medal   medal pk
     * @rc.current value to track
     */
    function trackMedalProgress(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = 'stat.trackMedalProgress')) {
            jsonValidationFailure(event = event, message = 'Unable to track medal progress');
            return;
        }

        prc.trainer = trainerService.getFromId(trainerid = session.trainerid);
        prc.medal   = medalService.getFromId(id = rc.medal);

        medalService.trackProgress(
            trainer = prc.trainer,
            medal   = prc.medal,
            current = rc.current
        );

        jsonOk(event = event);
    }

}
