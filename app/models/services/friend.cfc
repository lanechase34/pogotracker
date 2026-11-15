component singleton accessors="true" {

    property name="pagination"     inject="services.pagination";
    property name="trainerService" inject="services.trainer";
    property name="utilService"    inject="services.util";

    /**
     * Get friends list
     * Each row: id, username, icon, iconpath, iconalttext (the friend) and accepted
     *
     * @trainerid trainer pk
     * @accepted  include only accepted friend requests (T) or pending ones (F)
     */
    public array function getFriendsList(required numeric trainerid, boolean accepted = true) {
        return queryExecute(
            "
            SELECT trainer.id, trainer.username, trainer.icon, friend.accepted
            FROM friend
            INNER JOIN trainer ON trainer.id = friend.friendid
            WHERE friend.trainerid = :trainerid
                AND friend.accepted = :accepted
            ORDER BY friend.accepted DESC, trainer.username ASC
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                accepted : {value: arguments.accepted, cfsqltype: "boolean"}
            },
            {returnType: "array"}
        ).map((row) => withIcon(row));
    }

    /**
     * Search for accepted friends from your friends list
     *
     * @trainerid trainer pk
     * @search    search tearm
     * @page      current page
     * @pageSize  default 10 records
     */
    public struct function searchFriendsList(
        required numeric trainerid,
        required string search,
        required numeric page,
        numeric pageSize = 10
    ) {
        var trainers = queryExecute(
            "
            SELECT trainer.id, trainer.username, trainer.icon
            FROM friend
            INNER JOIN trainer ON trainer.id = friend.friendid
            WHERE friend.trainerid = :trainerid
                AND friend.accepted = true
                AND #pagination.searchSQL(["trainer.username"])#
            ORDER BY trainer.username ASC, trainer.id ASC
            LIMIT :pageRows
            OFFSET :offset
            ",
            pageParams(
                arguments.trainerid,
                arguments.search,
                arguments.page,
                arguments.pageSize
            ),
            {returnType: "array"}
        );

        return pagination.toSelectPage(
            trainers,
            arguments.pageSize,
            (trainer) => toSelectOption(trainer)
        );
    }

    /**
     * Query params for a select2 page of trainers - the trainer, the search and the page (pagination.selectPageParams)
     */
    private struct function pageParams(
        required numeric trainerid,
        required string search,
        required numeric page,
        required numeric pageSize
    ) {
        var params       = pagination.selectPageParams(arguments.page, arguments.pageSize);
        params.trainerid = {value: arguments.trainerid, cfsqltype: "integer"};
        params.search    = {value: utilService.likeContains(arguments.search), cfsqltype: "varchar"};
        return params;
    }

    /**
     * Select2 option for a trainer
     *
     * @trainer trainer row (id, username, icon)
     */
    private struct function toSelectOption(required struct trainer) {
        return {
            id  : arguments.trainer.id,
            text: arguments.trainer.username,
            img : arguments.trainer.icon,
            alt : trainerService.buildIconAltText(arguments.trainer.icon)
        };
    }

    /**
     * Add the icon's path and alt text to a row with an icon column
     */
    private struct function withIcon(required struct row) {
        arguments.row.iconpath    = trainerService.buildIconPath(arguments.row.icon);
        arguments.row.iconalttext = trainerService.buildIconAltText(arguments.row.icon);
        return arguments.row;
    }

    /**
     * Send a friend request to another trainer
     * Accepts friend request if there was already one pending decision
     */
    public void function sendFriendRequest(required numeric trainerid, required numeric friendid) {
        // Check if a friend request already exists, automatically accept if so
        var check = queryExecute(
            "SELECT id FROM friend WHERE trainerid = :friendid AND friendid = :trainerid",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                friendid : {value: arguments.friendid, cfsqltype: "integer"}
            }
        );

        // If the other trainer denied their request in the meantime, this becomes a new pending request instead
        if(check.recordCount && acceptFriendRequest(check.id, arguments.trainerid)) {
            return;
        }

        // Create the friend request in pending status - a request already sent (double submit) is left as is
        queryExecute(
            "
            INSERT INTO friend (trainerid, friendid, accepted)
            VALUES (:trainerid, :friendid, false)
            ON CONFLICT (trainerid, friendid) DO NOTHING
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                friendid : {value: arguments.friendid, cfsqltype: "integer"}
            }
        );
        return;
    }

    /**
     * Get friend requests needing action from trainer, oldest first
     * Each row: friendrequestid, created (when it was sent), and the sender's id, username, icon, iconpath, iconalttext
     */
    public array function getFriendRequests(required numeric trainerid) {
        return queryExecute(
            "
            SELECT friend.id AS friendrequestid, friend.created, trainer.id, trainer.username, trainer.icon
            FROM friend
            INNER JOIN trainer ON trainer.id = friend.trainerid
            WHERE friend.friendid = :trainerid
                AND friend.accepted = false
            ORDER BY friend.created ASC, friend.id ASC
            ",
            {trainerid: {value: arguments.trainerid, cfsqltype: "integer"}},
            {returnType: "array"}
        ).map((row) => withIcon(row));
    }

    /**
     * Accept the friend request sent to the trainer
     * Makes a two way directional friend request
     * Already accepted friendships are matched too, so a one sided friendship is repaired
     *
     * @return false when the request no longer exists (denied or withdrawn in the meantime)
     */
    public boolean function acceptFriendRequest(required numeric friendrequestid, required numeric trainerid) {
        // Both directions or neither - a one sided friendship is never left behind
        transaction {
            var friendRequest = queryExecute(
                "
                UPDATE friend
                SET accepted = true
                WHERE id = :id
                    AND friendid = :trainerid
                RETURNING trainerid
                ",
                {
                    id       : {value: arguments.friendrequestid, cfsqltype: "integer"},
                    trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
                }
            );

            // The other direction - one row per pair
            // If it exists already (both trainers sent a request at once, or a double accept) it is accepted instead of inserted twice
            if(friendRequest.recordCount) {
                queryExecute(
                    "
                    INSERT INTO friend (trainerid, friendid, accepted)
                    VALUES (:trainerid, :friendid, true)
                    ON CONFLICT (trainerid, friendid) DO UPDATE SET accepted = true
                    ",
                    {
                        trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                        friendid : {value: friendRequest.trainerid, cfsqltype: "integer"}
                    }
                );
            }
        }
        return friendRequest.recordCount > 0;
    }

    /**
     * Denies the pending friend request sent to the trainer
     * An accepted friendship is never deleted here - if an accept wins the race, the deny does nothing
     */
    public void function denyFriendRequest(required numeric friendrequestid, required numeric trainerid) {
        queryExecute(
            "
            DELETE FROM friend
            WHERE id = :id
                AND friendid = :trainerid
                AND accepted = false
            ",
            {
                id       : {value: arguments.friendrequestid, cfsqltype: "integer"},
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"}
            }
        );
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
        return queryExecute(
            "
            SELECT 1
            FROM friend
            WHERE trainerid = :trainerid
                AND friendid = :friendid
                #arguments.accepted ? "AND accepted = true" : ""#
            ",
            {
                trainerid: {value: arguments.trainerid, cfsqltype: "integer"},
                friendid : {value: arguments.friendid, cfsqltype: "integer"}
            }
        ).recordCount > 0;
    }

    /**
     * Return list of trainers the trainer can add
     */
    public struct function getFriendsToAdd(
        required numeric trainerid,
        required string search,
        required numeric page,
        numeric pageSize = 10
    ) {
        // Verified trainers this trainer has no friend row towards yet (accepted or pending)
        var trainers = queryExecute(
            "
            SELECT trainer.id, trainer.username, trainer.icon
            FROM trainer
            WHERE trainer.id <> :trainerid
                AND trainer.verified = true
                AND #pagination.searchSQL(["trainer.username"])#
                AND NOT EXISTS (
                    SELECT 1 FROM friend WHERE friend.trainerid = :trainerid AND friend.friendid = trainer.id
                )
            ORDER BY trainer.username ASC, trainer.id ASC
            LIMIT :pageRows
            OFFSET :offset
            ",
            pageParams(
                arguments.trainerid,
                arguments.search,
                arguments.page,
                arguments.pageSize
            ),
            {returnType: "array"}
        );

        return pagination.toSelectPage(
            trainers,
            arguments.pageSize,
            (trainer) => toSelectOption(trainer)
        );
    }

}
