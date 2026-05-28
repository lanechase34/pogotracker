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
                    <tr class="trainerRow" data-profilelink="/profile/#currFriend[1].getId()#">
                        <td class="align-middle" style="width: 56px;">
                            <img
                                class="profileIcon"
                                src="#currFriend[1].getIconPath()#"
                                alt="#currFriend[1].getIconAltText()#"
                            >
                        </td>
                        <td class="align-middle profileLink">#encodeForHTML(currFriend[1].getUsername())#</td>
                        <td class="align-middle text-end">
                            <cfif currFriend[2]>
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
