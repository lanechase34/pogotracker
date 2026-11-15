component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();

        scheduler    = getInstance("appScheduler@coldbox");
        adminService = getInstance("services.admin");

        /**
         * Test-only task wired to the app scheduler's callbacks so the success/failure paths
         * run without touching a real task. Registered after scheduler startup, so it never gets scheduled
         */
        probeTaskName = "taskTestProbe";
        probeFails    = false;
        scheduler
            .task(probeTaskName)
            .before((task) => {
                task.overviewStruct.event = probeTaskName;
            })
            .call(() => {
                if(probeFails) throw("Probe task failure");
                return "Ok!";
            })
            .onFailure((task, exception) => {
                scheduler.callbackOnFailure(task, exception);
            })
            .onSuccess((task, results) => {
                scheduler.callbackOnSuccess(task);
            });
    }

    function afterAll() {
        if(scheduler.hasTask(probeTaskName)) scheduler.removeTask(probeTaskName);
        restoreBackgroundLogs();
        super.afterAll();
    }

    function run() {
        describe("Scheduled Tasks Tests", () => {
            beforeEach(() => {
                setup();
            });

            it("Can register tasks from config/", () => {
                var taskInfo  = adminService.getTaskInfo();
                var taskNames = taskInfo.map((task) => task.name);
                expect(taskInfo).toBeArray();
                expect(taskInfo.len()).toBe(8); // 6 config tasks + mail queue + test probe

                [
                    "nightlyUpdatePokemonData",
                    "nightlyUpdateMoveData",
                    "weeklyUpdateMedalData",
                    "nightlyCreateEvents",
                    "metricsSubscription",
                    "cleanupCookies"
                ].each((name) => {
                    expect(taskNames).toInclude(name);
                });
            });

            it("Can run a task successfully", () => {
                var task             = scheduler.getTaskRecord(probeTaskName).task;
                var auditCountBefore = testData.countRows("audit");

                task.run(true);
                var stats = task.getStats();
                expect(stats).toBeStruct();
                expect(dateDiff("s", parseDateTime(stats.lastRun), now())).toBeLTE(10);
                expect(testData.countRows("audit") - auditCountBefore).toBe(1);
            });

            it("Can run a task that errors and trap error", () => {
                var task             = scheduler.getTaskRecord(probeTaskName).task;
                var auditCountBefore = testData.countRows("audit");
                var bugCountBefore   = testData.countRows("bug");

                probeFails = true;
                try {
                    task.run(true);
                }
                finally {
                    probeFails = false;
                }

                var stats = task.getStats();
                expect(stats).toBeStruct();
                expect(dateDiff("s", parseDateTime(stats.lastRun), now())).toBeLTE(10);
                expect(testData.countRows("audit") - auditCountBefore).toBe(1);
                expect(testData.countRows("bug") - bugCountBefore).toBe(1);
            });

            it("Can force run a task through the admin service", () => {
                var result = adminService.runTask("appScheduler@coldbox", probeTaskName);
                expect(result).toBeStruct();
                expect(result.success).toBeTrue();
                expect(result.errorMessage).toBe("");
                expect(result.result).toBe("Ok!");
                expect(dateDiff("s", parseDateTime(result.lastRun), now())).toBeLTE(10);
            });

            it("Reports failure when a force run task errors", () => {
                var result = {};
                probeFails = true;
                try {
                    result = adminService.runTask("appScheduler@coldbox", probeTaskName);
                }
                finally {
                    probeFails = false;
                }

                expect(result.success).toBeFalse();
                expect(result.errorMessage).toBe("Probe task failure");
            });

            it("Rejects force running an unknown task", () => {
                var validation = getInstance("ValidationManager@cbvalidation");
                var passes     = (scheduler, name) => !validation
                    .validate(target = {scheduler: scheduler, name: name}, constraints = "admin.runTask")
                    .hasErrors();

                expect(passes("appScheduler@coldbox", "cleanupCookies")).toBeTrue("known task");
                expect(passes("appScheduler@coldbox", "notARealTask")).toBeFalse("unknown task");
                expect(passes("notARealScheduler", "cleanupCookies")).toBeFalse("unknown scheduler");
            });
        });
    }

}
