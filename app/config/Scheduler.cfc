component {

    /**
	 * Configure the ColdBox Scheduler
	 * https://coldbox.ortusbooks.com/digging-deeper/scheduled-tasks
	 */
    function configure() {
        /**
		 * --------------------------------------------------------------------------
		 * Configuration Methods 
		 * --------------------------------------------------------------------------
		 * From here you can set global configurations for the scheduler
		 * - setTimezone( ) : change the timezone for ALL tasks
		 * - setExecutor( executorObject ) : change the executor if needed
		 */

        setTimezone('America/New_York');

        /**
		 * --------------------------------------------------------------------------
		 * Register Scheduled Tasks
		 * --------------------------------------------------------------------------
		 * You register tasks with the task() method and get back a ColdBoxScheduledTask object
		 * that you can use to register your tasks configurations.
         * These do not need increased timeouts since they aren't normal CF threads
		 */

        // Update the pokemon data nightly
        task('nightlyUpdatePokemonData')
            .call(() => {
                // Update Data
                getInstance('services.admin').buildPokemonData();
                getInstance('services.audit').audit(
                    ip      = 'localhost',
                    event   = 'nightlyUpdatePokemonData',
                    referer = '',
                    detail  = 'Task Success (Callback)',
                    agent   = 'Scheduled Task User'
                );
            })
            .everyDayAt('06:00');

        // Update the move data nightly
        task('nightlyUpdateMoveData')
            .call(() => {
                getInstance('services.admin').buildMoveData();
                getInstance('services.audit').audit(
                    ip      = 'localhost',
                    event   = 'nightlyUpdateMoveData',
                    referer = '',
                    detail  = 'Task Success (Callback)',
                    agent   = 'Scheduled Task User'
                );
            })
            .everyDayAt('05:00');

        // Update medal data every week
        task('weeklyUpdateMedalData')
            .call(() => {
                getInstance('services.admin').buildMedalData();
                getInstance('services.audit').audit(
                    ip      = 'localhost',
                    event   = 'weeklyUpdateMedalData',
                    referer = '',
                    detail  = 'Task Success (Callback)',
                    agent   = 'Scheduled Task User'
                );
            })
            .onMondays('05:30');

        // Create custom pokedexs based on upcoming events
        task('nightlyCreateEvents')
            .call(() => {
                getInstance('services.admin').createEvents();
                getInstance('services.audit').audit(
                    ip      = 'localhost',
                    event   = 'nightlyCreateEvents',
                    referer = '',
                    detail  = 'Task Success (Callback)',
                    agent   = 'Scheduled Task User'
                );
            })
            .everyDayAt('06:30');

        // Post metrics information to any websocket subscribers
        task('metricsSubscription')
            .call(() => {
                var ws           = new WebSocket();
                var adminService = getInstance('services.admin');

                /**
                 * Check if there are any current subscribers to the 'metrics' subscription
                 */
                var subscriptions = ws.getSubscriptions();
                if((subscriptions?.metrics?.count() ?: 0) > 0) {
                    /**
                     * Post metrics response message to topic/metrics
                     */
                    var metrics = adminService.getMetrics();
                    ws.send('topic/metrics', {data: metrics, success: true});
                }

                /**
                 * Reset active request count
                 */
                adminService.resetActiveRequests();
            })
            .every(5, 'seconds');

        // Cleanup persist cookies every hour
        task('cleanupCookies')
            .call(() => {
                getInstance('services.persist').cleanupCookies();
            })
            .everyHour();

        task('healthcheck')
            .call(() => {
                runRoute('/healthCheck');
            })
            .delay(60, 'minutes')
            .every(60, 'minutes')
            .onEnvironment('development');
    }

    /**
	 * Called before the scheduler is going to be shutdown
	 */
    function onShutdown() {
    }

    /**
	 * Called after the scheduler has registered all schedules
	 */
    function onStartup() {
    }

    /**
	 * Called whenever ANY task fails
	 *
	 * @task      The task that got executed
	 * @exception The ColdFusion exception object
	 */
    function onAnyTaskError(required task, required exception) {
        getInstance('services.audit').audit(
            ip      = 'localhost',
            event   = '#task.getName()#',
            referer = '',
            detail  = 'Task Failure',
            agent   = 'Scheduled Task User'
        );

        getInstance('services.bug').logBug(
            ip      = 'localhost',
            event   = '#task.getName()#',
            message = left(exception?.message ?: 'Unknown Error Message', 250),
            stack   = left(exception?.stackTrace ?: 'Unknown Stack Trace', 1000)
        );

        getInstance('services.email').sendBug(
            error          = exception,
            requestContext = {task: '#task.getName()#', detail: 'Task Failure'}
        );
    }

    /**
	 * Called whenever ANY task succeeds
	 *
	 * @task   The task that got executed
	 * @result The result (if any) that the task produced
	 */
    function onAnyTaskSuccess(required task, result) {
        var taskName = task.getName();
        if(taskName == 'cleanupCookies' || taskName == 'metricsSubscription') {
            return;
        }

        getInstance('services.audit').audit(
            ip      = 'localhost',
            event   = '#task.getName()#',
            referer = '',
            detail  = 'Task Success',
            agent   = 'Scheduled Task User'
        );
    }

    /**
	 * Called before ANY task runs
	 *
	 * @task The task about to be executed
	 */
    function beforeAnyTask(required task) {
    }

    /**
	 * Called after ANY task runs
	 *
	 * @task   The task that got executed
	 * @result The result (if any) that the task produced
	 */
    function afterAnyTask(required task, result) {
    }

}
