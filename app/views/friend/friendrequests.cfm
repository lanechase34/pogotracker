<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-person-add fs-5"></i>Friend Requests
        </div>
        <div class="tableDiv">
            <table class="table table-hover table-sm mb-0">
                <cfloop index="i" item="currFriend" array="#args.friendRequests#">
                    <tr>
                        #view(view = "/views/friend/fragment/trainerCells", args = {trainer: currFriend})#
                        <td class="align-middle text-end" data-friendrequestid="#currFriend.friendrequestid#">
                            <button type="button" class="btn btn-success btn-sm decideRequest" data-accept="true" aria-label="Accept friend request from #encodeForHTMLAttribute(currFriend.username)#">
                                <i class="bi bi-check" aria-hidden="true"></i>
                            </button>
                            <button type="button" class="btn btn-danger btn-sm decideRequest" data-accept="false" aria-label="Decline friend request from #encodeForHTMLAttribute(currFriend.username)#">
                                <i class="bi bi-x" aria-hidden="true"></i>
                            </button>
                        </td>
                    </tr>
                </cfloop>
                <cfloop index="i" item="currFriend" array="#args.sentFriendRequests#">
                    <tr>
                        #view(view = "/views/friend/fragment/trainerCells", args = {trainer: currFriend})#
                        <td class="align-middle text-end">
                            <span class="badge text-bg-secondary">Pending</span>
                        </td>
                    </tr>
                </cfloop>
            </table>
        </div>
    </div>
</div>
</cfoutput>
