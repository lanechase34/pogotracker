component extends="base" secured="user" {

    this.allowedMethods = {
        decideFriendRequest  : "POST",
        getFriendsList       : "GET",
        getFriendsToAdd      : "GET",
        searchFriendsToAdd   : "GET",
        getFriendRequests    : "GET",
        sendFriendRequest    : "POST",
        getFriendRequestToast: "GET",
        searchFriendsList    : "GET"
    };

    property name="async"         inject="asyncManager@coldbox";
    property name="friendService" inject="services.friend";
    property name="utilService"   inject="services.util";

    /**
     * Decide a pending friend request
     *
     * @rc.friendrequestid pk of the pending request
     * @rc.accept          t/f accept request
     */
    function decideFriendRequest(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "friend.decideFriendRequest")) {
            jsonValidationFailure(event = event, message = "Invalid Friend Request");
            return;
        }

        prc.friendrequestid = parseNumber(rc.friendrequestid);
        prc.accept          = booleanFormat(rc.accept);
        if(prc.accept) {
            friendService.acceptFriendRequest(
                friendrequestid = prc.friendrequestid,
                trainerid       = prc.oCurrentUser.getId()
            );
        }
        else {
            friendService.denyFriendRequest(friendrequestid = prc.friendrequestid, trainerid = prc.oCurrentUser.getId());
        }
        jsonOk(event = event);
    }

    /**
     * Friends list view
     */
    function getFriendsList(event, rc, prc) {
        prc.friendsList = friendService.getFriendsList(trainerid = prc.oCurrentUser.getId());
        event.setView(
            view     = "/views/friend/friendsList",
            nolayout = true,
            args     = {friendsList: prc.friendsList}
        );
    }

    /**
     * Add friend modal
     */
    function getFriendsToAdd(event, rc, prc) {
        event.setView(
            view     = "/views/friend/modal/addFriend",
            nolayout = true,
            args     = {trainerid: prc.oCurrentUser.getId()}
        );
    }

    /**
     * Paginated search of trainers that aren't friends yet
     *
     * @rc.search (optional) search term
     * @rc.page   numeric page number
     */
    function searchFriendsToAdd(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "friend.searchFriends")) {
            jsonValidationFailure(event = event, message = "Invalid Friend Search");
            return;
        }

        prc.responseObj.data = friendService.getFriendsToAdd(
            trainerid = prc.oCurrentUser.getId(),
            search    = rc?.search ?: "",
            page      = rc.page
        );
        jsonOk(event = event, data = prc.responseObj.data);
    }

    /**
     * Friend requests pending current trainer's decision
     * And sent friend requests pending another trainer's decision
     * View
     */
    function getFriendRequests(event, rc, prc) {
        prc.trainerid = prc.oCurrentUser.getId();

        var results = async
            .all(
                () => friendService.getFriendRequests(trainerid = prc.trainerid),
                () => friendService.getFriendsList(trainerid = prc.trainerid, accepted = false)
            )
            .get();

        prc.friendRequests     = results[1];
        prc.sentFriendRequests = results[2];

        event.setView(
            view     = "/views/friend/friendRequests",
            nolayout = true,
            args     = {friendRequests: prc.friendRequests, sentFriendRequests: prc.sentFriendRequests}
        );
    }

    /**
     * Send a friend request to another trainer
     *
     * @rc.trainerid (optional) defaults to current session
     * @rc.friendid  another trainer's pk that you want to add
     */
    function sendFriendRequest(event, rc, prc) {
        rc.trainerid = rc?.trainerid ?: prc.oCurrentUser.getId();
        // Validate - not yourself, and no friend request between you yet
        if(hasValidationErrors(target = rc, constraints = "friend.sendFriendRequest")) {
            jsonValidationFailure(event = event, message = "Invalid Friend Request");
            return;
        }

        prc.trainerid = parseNumber(rc.trainerid);
        prc.friendid  = parseNumber(rc.friendid);
        friendService.sendFriendRequest(trainerid = prc.trainerid, friendid = prc.friendid);
        jsonOk(event = event);
    }

    /**
     * Get toast message for any pending friend requests
     */
    function getFriendRequestToast(event, rc, prc) {
        // Return blank on the profile page
        if(utilService.getReferer().find("/profile")) {
            event.setView(view = "/views/fragment/blank", nolayout = true);
            return;
        }

        prc.friendRequests = friendService.getFriendRequests(trainerid = prc.oCurrentUser.getId());

        prc.ago = "";
        if(prc.friendRequests.len()) {
            prc.ago = dateDiff("n", prc.friendRequests[1].created, now());
            if(prc.ago > 60) {
                prc.ago = "> 60"
            }
        }

        event.setView(
            view     = "/views/friend/friendRequestToast",
            nolayout = true,
            args     = {friendRequests: prc.friendRequests, ago: prc.ago}
        );
    }

    /**
     * Paginated search of current trainer's friends list
     *
     * @rc.search (optional) search term
     * @rc.page   numeric page number
     */
    function searchFriendsList(event, rc, prc) {
        if(hasValidationErrors(target = rc, constraints = "friend.searchFriends")) {
            jsonValidationFailure(event = event, message = "Invalid Friend Search");
            return;
        }

        prc.responseObj.data = friendService.searchFriendsList(
            trainerid = prc.oCurrentUser.getId(),
            search    = rc?.search ?: "",
            page      = rc.page
        );
        jsonOk(event = event, data = prc.responseObj.data);
    }

}
