component singleton accessors="true" {

    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

    /**
     * Get friends list
     *
     * @trainer  trainer
     * @accepted include only accepted friend requests (T) or pending ones (F)
     */
    public array function getFriendsList(required component trainer, boolean accepted = true) {
        return ormExecuteQuery(
            "
            select friend.friend, friend.accepted
            from friend as friend
            where friend.trainer = :trainer
            and friend.accepted = :accepted
            order by friend.accepted desc, friend.friend.username asc
            ",
            {"trainer": arguments.trainer, "accepted": arguments.accepted}
        );
    }

    /**
     * Search for accepted friends from your friends list
     *
     * @trainer  trainer
     * @search   search tearm
     * @page     current page
     * @pageSize default 10 records
     */
    public struct function searchFriendsList(
        required component trainer,
        required string search,
        required numeric page,
        numeric pageSize = 10
    ) {
        var fromWhere = "
            from friend as friend
            join friend.friend as trainer
            where friend.trainer = :trainer
                and friend.accepted = true
                and #utilService.searchHQL(["trainer.username"])#
        ";
        var params = {trainer: trainer, search: utilService.likeContains(search)};

        var trainers = ormExecuteQuery(
            "
            select trainer
            #fromWhere#
            order by trainer.username asc, trainer.id asc
            ",
            params,
            {offset: (page - 1) * pageSize, maxResults: pageSize + 1}
        );

        return toSelectPage(trainers, pageSize);
    }

    /**
     * Select2 page from a query that fetched one row past the page - that extra row means there is another page
     *
     * @trainers up to pageSize + 1 trainer entities, in display order
     * @pageSize rows per page
     */
    private struct function toSelectPage(required array trainers, required numeric pageSize) {
        var more = arguments.trainers.len() > arguments.pageSize;
        if(more) {
            arguments.trainers.deleteAt(arguments.trainers.len());
        }
        return {results: toSelectOptions(arguments.trainers), pagination: {more: more}};
    }

    /**
     * Select2 options for a page of trainers
     *
     * @trainers trainer entities, in display order
     */
    private array function toSelectOptions(required array trainers) {
        return arguments.trainers.map((trainer) => {
            return {
                id  : trainer.getId(),
                text: trainer.getUsername(),
                img : trainer.getIcon(),
                alt : trainer.getIconAltText()
            };
        });
    }

    /**
     * Send a friend request to another trainer
     * Accepts friend request if there was already one pending decision
     */
    public void function sendFriendRequest(required numeric trainerid, required numeric friendid) {
        var trainer = trainerService.getFromId(arguments.trainerid);
        var friend  = trainerService.getFromId(arguments.friendid);

        // Check if a friend request already exists, automatically accept if so
        var check = entityLoad("friend", {"trainer": friend, "friend": trainer});
        if(check.len() && check.len() == 1) {
            acceptFriendRequest(check[1].getId(), trainer);
        }
        // Create the friend request in pending status - a request already sent (double submit) is left as is
        else {
            queryExecute(
                "
                INSERT INTO friend (trainerid, friendid, accepted, created, updated)
                VALUES (:trainerid, :friendid, false, now(), now())
                ON CONFLICT (trainerid, friendid) DO NOTHING
                ",
                {
                    trainerid: {value: trainer.getId(), cfsqltype: "integer"},
                    friendid : {value: friend.getId(), cfsqltype: "integer"}
                }
            );
        }
        return;
    }

    /**
     * Get friend requests needing action from trainer
     */
    public array function getFriendRequests(required component trainer) {
        return ormExecuteQuery(
            "
            select friend.trainer, friend.id, friend.created
            from friend as friend
            where friend.friend = :trainer
            and accepted = false
            ",
            {trainer: arguments.trainer}
        );
    }

    /**
     * Accept the friend request
     * Makes a two way directional friend request
     */
    public void function acceptFriendRequest(required numeric friendrequestid, required component trainer) {
        var friendRequest = entityLoadByPK("friend", arguments.friendrequestid);
        friendRequest.setAccepted(true);
        entitySave(friendRequest);
        ormFlush();

        // The other direction - one row per pair
        // If it exists already (both trainers sent a request at once, or a double accept) it is accepted instead of inserted twice
        queryExecute(
            "
            INSERT INTO friend (trainerid, friendid, accepted, created, updated)
            VALUES (:trainerid, :friendid, true, now(), now())
            ON CONFLICT (trainerid, friendid) DO UPDATE SET accepted = true
            ",
            {
                trainerid: {value: arguments.trainer.getId(), cfsqltype: "integer"},
                friendid : {value: friendRequest.getTrainer().getId(), cfsqltype: "integer"}
            }
        );
        return;
    }

    /**
     * Denies the pending friend request
     */
    public void function denyFriendRequest(required numeric friendrequestid) {
        var friendRequest = entityLoadByPK("friend", arguments.friendrequestid);
        entityDelete(friendRequest);
        ormFlush();
        return;
    }

    /**
     * Check friendship status between trainer and friend
     * Can check for pending request
     */
    public boolean function checkFriend(
        required numeric trainerid,
        required numeric friendid,
        boolean accepted = false
    ) {
        var trainer = trainerService.getFromId(arguments.trainerid);
        var friend  = trainerService.getFromId(arguments.friendid);

        if(isNull(trainer) || isNull(friend)) {
            return false;
        }

        var params = {"trainer": trainer, "friend": friend};
        if(arguments.accepted) {
            params.insert("accepted", arguments.accepted);
        }

        var validFriend = entityLoad("friend", params, true);

        return !isNull(validFriend);
    }

    /**
     * Return list of trainers the trainer can add
     */
    public struct function getFriendsToAdd(
        required component trainer,
        required string search,
        required numeric page,
        numeric pageSize = 10
    ) {
        // Verified trainers this trainer has no friend row towards yet (accepted or pending)
        var fromWhere = "
            from trainer as trainer
            where trainer != :trainer
                and trainer.verified = true
                and #utilService.searchHQL(["trainer.username"])#
                and not exists (
                    select friend.id from friend as friend where friend.trainer = :trainer and friend.friend = trainer
                )
        ";
        var params = {trainer: trainer, search: utilService.likeContains(search)};

        var trainers = ormExecuteQuery(
            "
            select trainer
            #fromWhere#
            order by trainer.username asc, trainer.id asc
            ",
            params,
            {offset: (page - 1) * pageSize, maxResults: pageSize + 1}
        );

        return toSelectPage(trainers, pageSize);
    }

}
