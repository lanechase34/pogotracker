component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance('tests.resources.mocktrainer');

        // Other trainer used for uniqueness conflicts
        otherTrainer   = mockTrainer.make(securityLevel = 10, autoLogin = false);
        otherTrainerId = otherTrainer.getId();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.delete(otherTrainerId);
    }

    /**
     * Post the profile form as the logged in trainer
     */
    private any function postProfile(required component trainer, struct overrides = {}) {
        setup();
        var params = {
            trainerid    : arguments.trainer.getId(),
            username     : arguments.trainer.getUsername(),
            email        : arguments.trainer.getEmail(),
            icon         : arguments.trainer.getIcon(),
            password     : '',
            defaultView  : 'normal',
            defaultRegion: 'Kanto',
            defaultPage  : '/'
        };
        params.append(arguments.overrides);

        return post(route = '/trainer/updateProfile', params = params);
    }

    function run() {
        describe('Update profile', () => {
            afterEach(() => {
                if(session.keyExists('mocktrainerid')) mockTrainer.delete();
            });

            it('Lets a regular user save their profile without changing username/email', () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer);
                var res   = event.getPrivateValue('responseObj');

                expect(res.success).toBeTrue(res.message);
            });

            it('Lets a regular user change their username', () => {
                var trainer     = mockTrainer.make(securityLevel = 10, autoLogin = true);
                var newUsername = 'UPD_#left(createUUID().replace('-', '', 'all'), 10)#';

                var event = postProfile(trainer, {username: newUsername});
                expect(event.getPrivateValue('responseObj').success).toBeTrue();

                entityReload(trainer);
                expect(trainer.getUsername()).toBe(newUsername);
            });

            it('Rejects a regular user taking another trainer''s username', () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer, {username: otherTrainer.getUsername()});
                expect(event.getPrivateValue('responseObj').success).toBeFalse();
            });

            it('Rejects a regular user setting their own security level', () => {
                var trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);

                var event = postProfile(trainer, {securityLevel: '60', verified: 'on'});
                expect(event.getPrivateValue('responseObj').success).toBeFalse();

                entityReload(trainer);
                expect(trainer.getSecurityLevel()).toBe(10);
            });

            it('Rejects an admin setting a friendcode that belongs to another trainer', () => {
                var trainer = mockTrainer.make(securityLevel = 50, autoLogin = true);

                var event = postProfile(trainer, {friendcode: otherTrainer.getFriendcode()});
                expect(event.getPrivateValue('responseObj').success).toBeFalse();
            });
        });
    }

}
