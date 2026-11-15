component {

    property name="adminService"   inject="provider:services.admin";
    property name="auditService"   inject="provider:services.audit";
    property name="bugService"     inject="provider:services.bug";
    property name="emailService"   inject="provider:services.email";
    property name="persistService" inject="provider:services.persist";
    property name="pokemonService" inject="provider:services.pokemon";

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

        /**
		 * --------------------------------------------------------------------------
		 * Register Scheduled Tasks
		 * --------------------------------------------------------------------------
		 * You register tasks with the task() method and get back a ColdBoxScheduledTask object
		 * that you can use to register your tasks configurations.
         * These do not need increased timeouts since they aren't normal CF threads
		 */

        // Update the pokemon data nightly
        task("nightlyUpdatePokemonData")
            .before((task) => {
                task.overviewStruct.event = "nightlyUpdatePokemonData";
            })
            .call(() => {
                adminService.buildPokemonData();

                // rerender and cache the database page
                var indexContentCacheTimeout = pokemonService.getCacheTime() * 15;
                runEvent(
                    event                  = "pokemon.indexContent",
                    private                = true,
                    prePostExempt          = true,
                    cache                  = true,
                    cacheTimeout           = indexContentCacheTimeout,
                    cacheLastAccessTimeout = indexContentCacheTimeout
                );
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .onSuccess((task, results) => {
                callbackOnSuccess(task);
            })
            .everyDayAt("07:00");

        // Update the move data nightly
        task("nightlyUpdateMoveData")
            .before((task) => {
                task.overviewStruct.event = "nightlyUpdateMoveData";
            })
            .call(() => {
                adminService.buildMoveData();
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .onSuccess((task, results) => {
                callbackOnSuccess(task);
            })
            .everyDayAt("06:00");

        // Update medal data every week
        task("weeklyUpdateMedalData")
            .before((task) => {
                task.overviewStruct.event = "weeklyUpdateMedalData";
            })
            .call(() => {
                adminService.buildMedalData();
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .onSuccess((task, results) => {
                callbackOnSuccess(task);
            })
            .onMondays("06:30");

        // Create custom pokedexs based on upcoming events
        task("nightlyCreateEvents")
            .before((task) => {
                task.overviewStruct.event = "nightlyCreateEvents";
            })
            .call(() => {
                adminService.createEvents();
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .onSuccess((task, results) => {
                callbackOnSuccess(task);
            })
            .everyDayAt("07:30");

        // Post metrics information to any websocket subscribers
        task("metricsSubscription")
            .before((task) => {
                task.overviewStruct.event = "metricsSubscription";
            })
            .call(() => {
                /**
                 * Check if there are any current subscribers to the 'metrics' subscription
                 */
                var subscriptions = application.ws.getSubscriptions();
                if((subscriptions?.metrics?.count() ?: 0) > 0) {
                    /**
                     * Post metrics response message to topic/metrics
                     */
                    var metrics = adminService.getMetrics();
                    application.ws.send("topic/metrics", {data: metrics, success: true});
                }

                /**
                 * Reset active request count
                 */
                adminService.resetActiveRequests();
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .every(5, "seconds");

        // Cleanup persist cookies every hour
        task("cleanupCookies")
            .before((task) => {
                task.overviewStruct.event = "cleanupCookies";
            })
            .call(() => {
                persistService.cleanupCookies();
            })
            .onFailure((task, exception) => {
                callbackOnFailure(task, exception);
            })
            .everyHour();
    }

    public void function callbackOnFailure(required struct task, struct exception = {}) {
        task.overviewStruct.detail = "Task Failure";
        auditService.audit(argumentCollection = task.overviewStruct);

        task.overviewStruct.message = exception?.message ?: "Unknown Error Message";
        task.overviewStruct.stack   = exception?.stackTrace ?: "Unknown Stack Trace";
        bugService.logBug(argumentCollection = task.overviewStruct);

        emailService.sendBug(error = exception, requestContext = {task: task.overviewStruct, detail: "Task Failure"});
    }

    public void function callbackOnSuccess(required struct task) {
        task.overviewStruct.detail = "Task Success";
        auditService.audit(argumentCollection = task.overviewStruct);
    }

    /**
	 * Called before ANY task runs
	 *
	 * @task The task about to be executed
	 */
    public void function beforeAnyTask(required any task) {
        task.overviewStruct = {
            ip     : "localhost",
            event  : "",
            referer: "",
            detail : "",
            agent  : "Scheduled Task User"
        };
    }

}
