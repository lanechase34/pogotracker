component extends="tests.resources.baseTest" asyncAll="false" {

    function beforeAll() {
        super.beforeAll();
        mockTrainer = getInstance("tests.resources.mockTrainer");

        // Set up trainer + friend that trainer will add, the trainer is logged in
        friend  = mockTrainer.make(securityLevel = 10, autoLogin = false);
        trainer = mockTrainer.makeSignedIn();
    }

    function afterAll() {
        super.afterAll();
        mockTrainer.deleteTrainer(friend.id);
        mockTrainer.deleteTrainer(trainer.id);
    }

    function run() {
        describe("Friend service tests", () => {
            beforeEach(() => {
                setup();
                friendService = getInstance("services.friend");
            });

            describe("friendService.getFriendsToAdd", () => {
                it("Can paginate through friends list to find friend to add", () => {
                    var found     = false;
                    var currPage  = 1;
                    var morePages = true;

                    while(morePages && !found) {
                        // Load the current page
                        var page = friendService.getFriendsToAdd(
                            trainerid = trainer.id,
                            search    = "",
                            page      = currPage
                        );

                        expect(page).toBeStruct();
                        expect(page).toHaveKey("results");
                        expect(page.results).toBeArray();
                        expect(page).toHaveKey("pagination");

                        // Try to find friend
                        found     = page.results.some((row) => row.id == friend.id);
                        morePages = page.pagination.more;
                        currPage++;
                    }

                    expect(found).toBeTrue();
                });

                it("Can search for friend to add", () => {
                    // Search for friend explicitly and expect only friend to be returned
                    var page = friendService.getFriendsToAdd(
                        trainerid = trainer.id,
                        search    = friend.username,
                        page      = 1
                    );
                    expect(page).toBeStruct();
                    expect(page).toHaveKey("results");
                    expect(page.results).toBeArray();
                    expect(page).toHaveKey("pagination");
                    expect(page.pagination.more).toBeFalse();
                    expect(page.results.len()).toBe(1);
                });
            });

            it("friendService.checkFriend", () => {
                // Check if they are friends
                expect(friendService.checkFriend(trainerid = trainer.id, friendid = friend.id)).toBeFalse();
            });

            describe("Friend request life cycle", () => {
                it("Can send a friend request", () => {
                    var event = post(
                        route  = "/friend/sendFriendRequest",
                        params = {trainerid: trainer.id, friendid: friend.id}
                    );
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();

                    // Call check friends again, with accepted = false
                    expect(
                        friendService.checkFriend(
                            trainerid = trainer.id,
                            friendid  = friend.id,
                            accepted  = false
                        )
                    ).toBeTrue();
                });

                it("Can load pending friend requests", () => {
                    // Load the friend requests as the friend and make sure we see one pending decision
                    var friendRequests = friendService.getFriendRequests(friend.id);
                    expect(friendRequests).toBeArray();
                    expect(friendRequests.len()).toBe(1);

                    // the sender's id plus the request's id and when it was sent
                    expect(friendRequests[1].id).toBe(trainer.id);
                    expect(friendRequests[1].username).toBe(trainer.username);
                    expect(dateDiff("s", friendRequests[1].created, now())).toBeLT(30);
                    friendRequestId = friendRequests[1].friendrequestid;
                });

                it("Can load sent friend requests", () => {
                    // Load the sent friend requests as the trainer and make sure we see one sent to friend
                    var sentFriendRequests = friendService.getFriendsList(trainerid = trainer.id, accepted = false);
                    expect(sentFriendRequests).toBeArray();
                    expect(sentFriendRequests.len()).toBe(1);

                    // the friend's id and the request's accepted flag
                    expect(sentFriendRequests[1].id).toBe(friend.id);
                    expect(sentFriendRequests[1].accepted).toBeFalse();
                });

                it("Can accept a friend request", () => {
                    // Act as friend and accept the friend request
                    mockTrainer.actAs(friend);

                    var event = post(
                        route  = "/friend/decideFriendRequest",
                        params = {friendrequestid: friendRequestId, accept: true}
                    );
                    // Verify successful response
                    expect(event.getStatusCode()).toBe(200);

                    var response = deserializeJSON(event.getRenderedContent());
                    expect(response.success).toBeTrue();

                    // Check friendship status
                    expect(
                        friendService.checkFriend(
                            trainerid = trainer.id,
                            friendid  = friend.id,
                            accepted  = true
                        )
                    ).toBeTrue();

                    // Check two directional status
                    expect(
                        friendService.checkFriend(
                            trainerid = friend.id,
                            friendid  = trainer.id,
                            accepted  = true
                        )
                    ).toBeTrue();
                });

                it("Can load friends list", () => {
                    // Verify friend is now accepted
                    var friendsList = friendService.getFriendsList(trainerid = trainer.id, accepted = true);
                    expect(friendsList).toBeArray();
                    expect(friendsList.len()).toBe(1);

                    // the friend's id and the request's accepted flag
                    expect(friendsList[1].id).toBe(friend.id);
                    expect(friendsList[1].accepted).toBeTrue();
                    expect(friendsList[1].iconpath).toInclude("/includes/images/icons/");
                });

                it("Can search friendslist for friend", () => {
                    var searchFriendsList = friendService.searchFriendsList(
                        trainerid = trainer.id,
                        search    = friend.username,
                        page      = 1
                    );

                    expect(searchFriendsList).toBeStruct();
                    expect(searchFriendsList).toHaveKey("results");
                    expect(searchFriendsList.results).toBeArray();
                    expect(searchFriendsList).toHaveKey("pagination");
                    expect(searchFriendsList.pagination.more).toBeFalse();
                    expect(searchFriendsList.results.len()).toBe(1);
                });
            });
        });
    }

}
