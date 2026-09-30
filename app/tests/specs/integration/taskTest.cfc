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
                expect(dateDiff('s', parseDateTime(stats.lastRun), now())).toBeLTE(10);

                auditCountAfter = ormExecuteQuery('select count(id) from audit')[1];
                expect(auditCountAfter - auditCountBefore).toBe(1);
            });

            it('Can run a task that errors and trap error', () => {
                task = scheduler.getTaskRecord(testTaskName).task;
                expect(task).toBeComponent();

                // Verify the task successfully logs bug and audits
                auditCountBefore = ormExecuteQuery('select count(id) from audit')[1];
                bugCountBefore   = ormExecuteQuery('select count(id) from bug')[1];

                // Set the task to fail
                application.cbController.setSetting('healthCheck', false);

                // Force run the task
                task.run(true);
                stats = task.getStats();
                expect(stats).toBeStruct();
                expect(dateDiff('s', parseDateTime(stats.lastRun), now())).toBeLTE(10);

                auditCountAfter = ormExecuteQuery('select count(id) from audit')[1];
                expect(auditCountAfter - auditCountBefore).toBe(1);
                bugCountAfter = ormExecuteQuery('select count(id) from bug')[1];
                expect(bugCountAfter - bugCountBefore).toBe(1);

                application.cbController.setSetting('healthCheck', true);
            });

            it('Can force run a task through the admin service', () => {
                adminService = getInstance('services.admin');

                result = adminService.runTask('appScheduler@coldbox', testTaskName);
                expect(result).toBeStruct();
                expect(result.success).toBeTrue();
                expect(result.errorMessage).toBe('');
                expect(dateDiff('s', parseDateTime(result.lastRun), now())).toBeLTE(10);
            });

            it('Reports failure when a force run task errors', () => {
                adminService = getInstance('services.admin');
                application.cbController.setSetting('healthCheck', false);

                result = adminService.runTask('appScheduler@coldbox', testTaskName);
                expect(result.success).toBeFalse();
                expect(result.errorMessage).notToBe('');

                application.cbController.setSetting('healthCheck', true);
            });

            it('Throws when force running an unknown task', () => {
                adminService = getInstance('services.admin');

                expect(() => adminService.runTask('appScheduler@coldbox', 'notARealTask')).toThrow('TaskNotFound');
                expect(() => adminService.runTask('notARealScheduler', testTaskName)).toThrow('TaskNotFound');
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
