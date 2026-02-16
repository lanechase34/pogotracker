component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer    = getInstance('tests.resources.mocktrainer');
        mocktrainerids = []; // 1 - friend, 2 - trainer

        // Set up trainer + friend that trainer will add
        friend = mockTrainer.make(securityLevel = 10, autoLogin = false);
        mocktrainerids.append(session.mocktrainerid);
        trainer = mockTrainer.make(securityLevel = 10, autoLogin = true);
        mocktrainerids.append(session.mocktrainerid);
    }

    function afterAll() {
        super.afterAll();
        mocktrainerids.each((id) => {
            mockTrainer.delete(id);
        });
    }

    function run() {
        describe('Friend service tests', () => {
            beforeEach(() => {
                setup();
                friendService = getInstance('services.friend');
            });

            it('Can be created', () => {
                expect(friendService).toBeComponent();
            });

            describe('friendService.getFriendsToAdd', () => {
                it('Can paginate through friends list to find friend to add', () => {
                    found     = false;
                    currPage  = 1;
                    morePages = true;

                    while(morePages && !found) {
                        // Load the current page
                        page = friendService.getFriendsToAdd(trainer = trainer, search = '', page = currPage);

                        expect(page).toBeStruct();
                        expect(page).toHaveKey('results');
                        expect(page.results).toBeArray();
                        expect(page).toHaveKey('pagination');

                        // Try to find friend
                        page.results.each((row) => {
                            if(row.id == friend.getId()) {
                                found = true;
                                break;
                            }
                        });

                        if(found) break;
                        morePages = page.pagination.more;
                        currPage++;
                    }

                    expect(found).toBeTrue();
                });

                it('Can search for friend to add', () => {
                    // Search for friend explicitly and expect only friend to be returned
                    page = friendService.getFriendsToAdd(
                        trainer = trainer,
                        search  = friend.getUsername(),
                        page    = 1
                    );
                    expect(page).toBeStruct();
                    expect(page).toHaveKey('results');
                    expect(page.results).toBeArray();
                    expect(page).toHaveKey('pagination');
                    expect(page.pagination.more).toBeFalse();
                    expect(page.results.len()).toBe(1);
                });
            });

            it('friendService.checkFriend', () => {
                // Check if they are friends
                expect(friendService.checkFriend(trainerid = mocktrainerids[2], friendid = mocktrainerids[1])).toBeFalse();
            });

            describe('Friend request life cycle', () => {
                it('Can send a friend request', () => {
                    event = post(
                        route  = '/friend/sendFriendRequest',
                        params = {trainerid: mocktrainerids[2], friendid: mocktrainerids[1]}
                    );
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();

                    // Call check friends again, with accepted = false
                    expect(
                        friendService.checkFriend(
                            trainerid = mocktrainerids[2],
                            friendid  = mocktrainerids[1],
                            accepted  = false
                        )
                    ).toBeTrue();
                });

                it('Can load pending friend requests', () => {
                    // Load the friend requests as the friend and make sure we see one pending decision
                    friendRequests = friendService.getFriendRequests(friend);
                    expect(friendRequests).toBeArray();
                    expect(friendRequests.len()).toBe(1);

                    // returns trainer, id, created
                    expect(friendRequests[1][1].getId()).toBe(mocktrainerids[2]);
                    friendRequestId = friendRequests[1][2];
                });

                it('Can load sent friend requests', () => {
                    // Load the sent friend requests as the trainer and make sure we see one sent to friend
                    sentFriendRequests = friendService.getFriendsList(trainer = trainer, accepted = false);
                    expect(sentFriendRequests).toBeArray();
                    expect(sentFriendRequests.len()).toBe(1);

                    // returns friend, accepted
                    expect(sentFriendRequests[1][1].getId()).toBe(mocktrainerids[1]);
                    expect(sentFriendRequests[1][2]).toBeFalse();
                });

                it('Can accept a friend request', () => {
                    // Login as friend and accept the friend request
                    mockTrainer.logout();
                    mockTrainer.login(friend);

                    event = post(
                        route  = '/friend/decideFriendRequest',
                        params = {friendrequestid: friendRequestId, accept: true}
                    );
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();

                    // Check friendship status
                    expect(
                        friendService.checkFriend(
                            trainerid = mocktrainerids[2],
                            friendid  = mocktrainerids[1],
                            accepted  = true
                        )
                    ).toBeTrue();

                    // Check two directional status
                    expect(
                        friendService.checkFriend(
                            trainerid = mocktrainerids[1],
                            friendid  = mocktrainerids[2],
                            accepted  = true
                        )
                    ).toBeTrue();
                });

                it('Can load friends list', () => {
                    // Login as trainer and load friends list
                    mockTrainer.logout();
                    mockTrainer.login(trainer);

                    // Verify friend is now accepted
                    friendsList = friendService.getFriendsList(trainer = trainer, accepted = true);
                    expect(friendsList).toBeArray();
                    expect(friendsList.len()).toBe(1);

                    // returns friend, accepted
                    expect(friendsList[1][1].getId()).toBe(mocktrainerids[1]);
                    expect(friendsList[1][2]).toBeTrue();
                });

                it('Can search friendslist for friend', () => {
                    searchFriendsList = friendService.searchFriendsList(
                        trainer = trainer,
                        search  = friend.getUsername(),
                        page    = 1
                    );

                    expect(searchFriendsList).toBeStruct();
                    expect(searchFriendsList).toHaveKey('results');
                    expect(searchFriendsList.results).toBeArray();
                    expect(searchFriendsList).toHaveKey('pagination');
                    expect(searchFriendsList.pagination.more).toBeFalse();
                    expect(searchFriendsList.results.len()).toBe(1);
                });
            });
        });
    }

}
