component singleton accessors="true" {

    property name="trainerService" inject="services.trainer";

    /**
     * Get friends list
     *
     * @trainer  trainer
     * @accepted include only accepted friend requests (T) or pending ones (F)
     */
    public array function getFriendsList(required component trainer, boolean accepted = true) {
        return ormExecuteQuery(
            '
            select friend.friend, friend.accepted
            from friend as friend
            where friend.trainer = :trainer
            and friend.accepted = :accepted
            order by friend.accepted desc, friend.friend.username asc
            ',
            {'trainer': arguments.trainer, 'accepted': arguments.accepted}
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
        var friendsList = ormExecuteQuery(
            '
            select friend.friend, friend.accepted
            from friend as friend
            where friend.trainer = :trainer
                and friend.accepted = true
                and upper(friend.friend.username) like :search
            order by friend.accepted desc, friend.friend.username asc
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'},
            {offset: (arguments.page - 1) * pageSize, maxResults: pageSize}
        );

        var friendsListCount = ormExecuteQuery(
            '
            select count(friend.friend.id)
            from friend as friend
            where friend.trainer = :trainer
                and friend.accepted = true
                and upper(friend.friend.username) like :search
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'}
        );

        var result = {results: [], pagination: {more: friendsListCount[1] > arguments.page * pageSize}};
        friendsList.each((friend) => {
            result.results.append({
                id  : friend[1].getId(),
                text: friend[1].getUsername(),
                img : friend[1].getIcon(),
                alt : friend[1].getIconAltText()
            });
        });

        return result;
    }

    /**
     * Send a friend request to another trainer
     * Accepts friend request if there was already one pending decision
     */
    public void function sendFriendRequest(required numeric trainerid, required numeric friendid) {
        var trainer = trainerService.getFromId(arguments.trainerid);
        var friend  = trainerService.getFromId(arguments.friendid);

        // Check if a friend request already exists, automatically accept if so
        var check = entityLoad('friend', {'trainer': friend, 'friend': trainer});
        if(check.len() && check.len() == 1) {
            acceptFriendRequest(check[1].getId(), trainer);
        }
        // Create the friend request in pending status
        else {
            var newFriendRequest = entityNew(
                'friend',
                {
                    'trainer' : trainer,
                    'friend'  : friend,
                    'accepted': false
                }
            );
            entitySave(newFriendRequest);
            ormFlush();
        }
        return;
    }

    /**
     * Get friend requests needing action from trainer
     */
    public array function getFriendRequests(required component trainer) {
        return ormExecuteQuery(
            '
            select friend.trainer, friend.id, friend.created
            from friend as friend
            where friend.friend = :trainer
            and accepted = false
            ',
            {trainer: arguments.trainer}
        );
    }

    /**
     * Accept the friend request
     * Makes a two way directional friend request
     */
    public void function acceptFriendRequest(required numeric friendrequestid, required component trainer) {
        var friendRequest       = entityLoadByPK('friend', arguments.friendrequestid);
        var twoWayFriendRequest = entityNew(
            'friend',
            {
                'trainer' : arguments.trainer,
                'friend'  : friendRequest.getTrainer(),
                'accepted': true
            }
        );
        friendRequest.setAccepted(true);
        entitySave(friendRequest);
        entitySave(twoWayFriendRequest);
        ormFlush();
        return;
    }

    /**
     * Denies the pending friend request
     */
    public void function denyFriendRequest(required numeric friendrequestid) {
        var friendRequest = entityLoadByPK('friend', arguments.friendrequestid);
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

        var params = {'trainer': trainer, 'friend': friend};
        if(arguments.accepted) {
            params.insert('accepted', arguments.accepted);
        }

        var validFriend = entityLoad('friend', params, true);

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
        // grab ones that are pending - need to show to user that these are pending requests
        // right xor here so we can join f.friendid = t.id
        var canAdd = ormExecuteQuery(
            '
            select trainer
            from friend as friend
            right outer join friend.friend as trainer with friend.trainer = :trainer
            where friend is null 
                and trainer != :trainer 
                and trainer.verified = true
                and upper(trainer.username) like :search
            order by trainer.username asc
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'},
            {offset: (arguments.page - 1) * pageSize, maxResults: pageSize}
        );

        var canAddCount = ormExecuteQuery(
            '
            select count(trainer.id)
            from friend as friend
            right outer join friend.friend as trainer with friend.trainer = :trainer
            where friend is null 
                and trainer != :trainer 
                and trainer.verified = true
                and upper(trainer.username) like :search
            ',
            {trainer: arguments.trainer, search: '%#uCase(arguments.search)#%'}
        );

        var result = {results: [], pagination: {more: canAddCount[1] > arguments.page * pageSize}};
        canAdd.each((trainer) => {
            result.results.append({
                id  : trainer.getId(),
                text: trainer.getUsername(),
                img : trainer.getIcon(),
                alt : trainer.getIconAltText()
            });
        });

        return result;
    }

}
