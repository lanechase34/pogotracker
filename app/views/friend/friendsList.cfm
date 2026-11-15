<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-person-check fs-5"></i>Friends
            <button type="button" class="btn btn-dark btn-sm ms-auto" id="addFriendBtn">
                <i class="bi bi-person-plus me-1"></i>Add Friend
            </button>
        </div>
        <div class="tableDiv">
            <table class="table table-hover table-sm mb-0">
                <cfloop index="i" item="currFriend" array="#args.friendsList#">
                    <tr class="trainerRow" data-profilelink="/profile/#currFriend.id#">
                        #view(view = "/views/friend/fragment/trainerCells", args = {trainer: currFriend, nameClass: "profileLink"})#
                        <td class="align-middle text-end">
                            <cfif currFriend.accepted>
                                <span class="badge text-bg-success">Accepted</span>
                            <cfelse>
                                <span class="badge text-bg-secondary">Pending</span>
                            </cfif>
                        </td>
                    </tr>
                </cfloop>
            </table>
        </div>
    </div>
</div>
</cfoutput>
