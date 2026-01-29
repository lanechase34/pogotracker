component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
    }

    function afterAll() {
        super.afterAll();
    }

    function run() {
        describe('Scheduled Tasks Tests', () => {
            beforeEach(() => {
                setup();

                testTaskName = 'healthCheck';

                scheduler        = getInstance('appScheduler@coldbox');
                schedulerService = getInstance('coldbox:schedulerService');
            });

            it('Can be created', () => {
                expect(schedulerService).toBeComponent();
                expect(scheduler).toBeComponent();
            });

            it('Can register tasks from config/', () => {
                adminService = getInstance('services.admin');
                taskInfo     = adminService.getTaskInfo();
                expect(taskInfo).toBeArray();
                expect(taskInfo.len()).toBe(8); // number of tasks defined + mail queue
            });

            it('Can run a task successfully', () => {
                task = scheduler.getTaskRecord(testTaskName).task;
                expect(task).toBeComponent();

                // Verify the task has successful audits
                auditCountBefore = ormExecuteQuery('select count(id) from audit')[1];

                // Force run the task
                task.run(true);
                stats = task.getStats();
                expect(stats).toBeStruct();
                expect(dateDiff('s', stats.lastRun, now())).toBeLTE(10);

                auditCountAfter = ormExecuteQuery('select count(id) from audit')[1];
                expect(auditCountAfter - auditCountBefore).toBe(1);
            });

            it('Can run a task that errors and trap error', () => {
                task = scheduler.getTaskRecord(testTaskName).task;
                expect(task).toBeComponent();

                // Verify the task has successful audits and logs bug
                auditCountBefore = ormExecuteQuery('select count(id) from audit')[1];
                bugCountBefore   = ormExecuteQuery('select count(id) from bug')[1];

                // Set the task to fail
                application.cbController.setSetting('healthCheck', false);

                // Force run the task
                task.run(true);
                stats = task.getStats();
                expect(stats).toBeStruct();
                expect(dateDiff('s', stats.lastRun, now())).toBeLTE(10);

                auditCountAfter = ormExecuteQuery('select count(id) from audit')[1];
                bugCountAfter   = ormExecuteQuery('select count(id) from bug')[1];
                expect(auditCountAfter - auditCountBefore).toBe(1);
                expect(bugCountAfter - bugCountBefore).toBe(1);
            });

            it('Can toggle a task', () => {
                task = scheduler.getTaskRecord(testTaskName).task;
                expect(task).toBeComponent();

                task.disable();
                expect(task.isDisabled()).toBeTrue();

                task.enable();
                expect(task.isDisabled()).toBeFalse();
            });

            it('Can delete a task', () => {
                taskInfoBefore = adminService.getTaskInfo();
                expect(taskInfoBefore).toBeArray();
                expect(taskInfoBefore.len()).toBe(8);

                scheduler.removeTask(testTaskName);
                taskInfoAfter = adminService.getTaskInfo();
                expect(taskInfoAfter).toBeArray();
                expect(taskInfoAfter.len()).toBe(7);
                expect(scheduler.hasTask(testTaskName)).toBeFalse();
            });
        });
    }

}
