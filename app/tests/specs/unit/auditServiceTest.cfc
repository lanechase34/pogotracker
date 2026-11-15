component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        inlineBackgroundLogs();
        auditService = getInstance("services.audit");
        bugService   = getInstance("services.bug");
        mockTrainer  = getInstance("tests.resources.mockTrainer");
        trainer      = mockTrainer.make(autoLogin = false);

        // Unique per run so cleanup only touches these rows
        marker    = "TEST_logging_#left(createUUID(), 8)#";
        // A trainer id with no trainer behind it (e.g. a stale session)
        missingid = queryExecute("SELECT COALESCE(MAX(id), 0) + 100000 AS id FROM trainer").id;
    }

    function afterAll() {
        testData.deleteRows("audit", {event: marker});
        testData.deleteRows("bug", {event: marker});
        testData.deleteRows("request_log", {urlpath: marker});
        mockTrainer.deleteTrainer(trainer.id);
        restoreBackgroundLogs();
        super.afterAll();
    }

    private void function audit(required numeric trainerid) {
        auditService.audit(
            ip        = "127.0.0.1",
            event     = marker,
            referer   = "",
            detail    = "",
            agent     = "",
            trainerid = arguments.trainerid
        );
    }

    private void function logBug(required numeric trainerid) {
        bugService.logBug(
            ip        = "127.0.0.1",
            event     = marker,
            message   = "",
            stack     = "",
            trainerid = arguments.trainerid
        );
    }

    private void function logRequest(required numeric trainerid) {
        auditService.logRequest(
            ip        = "127.0.0.1",
            urlpath   = marker,
            method    = "GET",
            agent     = "",
            referer   = "",
            response  = "",
            trainerid = arguments.trainerid
        );
    }

    function run() {
        describe("Log rows and the trainer they belong to", () => {
            beforeEach(() => {
                setup();
                testData.deleteRows("audit", {event: marker});
                testData.deleteRows("bug", {event: marker});
                testData.deleteRows("request_log", {urlpath: marker});
            });

            it("Keeps the trainer when it exists", () => {
                audit(trainer.id);
                logBug(trainer.id);
                logRequest(trainer.id);

                expect(testData.findRow("audit", {event: marker}).trainerid).toBe(trainer.id);
                expect(testData.findRow("bug", {event: marker}).trainerid).toBe(trainer.id);
                expect(testData.findRow("request_log", {urlpath: marker}).trainerid).toBe(trainer.id);
            });

            it("Logs without a trainer when there is none", () => {
                audit(-1);
                logBug(-1);
                logRequest(-1);

                expect(testData.findRow("audit", {event: marker}).trainerid ?: "").toBe("");
                expect(testData.findRow("bug", {event: marker}).trainerid ?: "").toBe("");
                expect(testData.findRow("request_log", {urlpath: marker}).trainerid ?: "").toBe("");
            });

            it("Logs without a trainer when the trainer doesn't exist, instead of failing", () => {
                audit(missingid);
                logBug(missingid);
                logRequest(missingid);

                expect(testData.findRow("audit", {event: marker}).trainerid ?: "").toBe("");
                expect(testData.findRow("bug", {event: marker}).trainerid ?: "").toBe("");
                expect(testData.findRow("request_log", {urlpath: marker}).trainerid ?: "").toBe("");
            });
        });

        describe("Log values longer than their columns", () => {
            beforeEach(() => {
                setup();
                testData.deleteRows("audit", {event: marker});
                testData.deleteRows("bug", {event: marker});
                testData.deleteRows("request_log", {urlpath: marker});
            });

            it("Cuts audit values to their column widths instead of failing", () => {
                auditService.audit(
                    ip      = repeatString("1", 60),
                    event   = marker,
                    referer = repeatString("r", 300),
                    detail  = repeatString("d", 300),
                    agent   = repeatString("a", 300)
                );

                var row = testData.findRow("audit", {event: marker});
                expect(len(row.ip)).toBe(45);
                expect(len(row.referer)).toBe(250);
                expect(len(row.detail)).toBe(250);
                expect(len(row.agent)).toBe(250);
            });

            it("Cuts bug values to their column widths instead of failing", () => {
                bugService.logBug(
                    ip      = repeatString("1", 150),
                    event   = marker,
                    message = repeatString("m", 300),
                    stack   = repeatString("s", 5000)
                );

                var row = testData.findRow("bug", {event: marker});
                expect(len(row.ip)).toBe(128);
                expect(len(row.message)).toBe(256);
                expect(len(row.stack)).toBe(5000);
            });

            it("Cuts request log values to their column widths instead of failing", () => {
                auditService.logRequest(
                    ip       = repeatString("1", 120),
                    urlpath  = marker,
                    method   = "VERYLONGMETHOD",
                    agent    = repeatString("a", 300),
                    referer  = repeatString("r", 300),
                    response = ""
                );

                var row = testData.findRow("request_log", {urlpath: marker});
                expect(len(row.ip)).toBe(100);
                expect(row.method).toBe("VERYLONGME");
                expect(len(row.agent)).toBe(250);
                expect(len(row.referer)).toBe(250);
            });
        });
    }

}
