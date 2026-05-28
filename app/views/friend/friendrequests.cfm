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
                        <td class="align-middle" style="width: 56px;">
                            <img
                                class="profileIcon"
                                src="#currFriend[1].getIconPath()#"
                                alt="#currFriend[1].getIconAltText()#"
                            >
                        </td>
                        <td class="align-middle">#EncodeForHTML(currFriend[1].getUsername())#</td>
                        <td class="align-middle text-end" data-friendrequestid="#currFriend[2]#">
                            <button type="button" class="btn btn-success btn-sm decideRequest" data-accept="true">
                                <i class="bi bi-check"></i>
                            </button>
                            <button type="button" class="btn btn-danger btn-sm decideRequest" data-accept="false">
                                <i class="bi bi-x"></i>
                            </button>
                        </td>
                    </tr>
                </cfloop>
                <cfloop index="i" item="currFriend" array="#args.sentFriendRequests#">
                    <tr>
                        <td class="align-middle" style="width: 56px;">
                            <img
                                class="profileIcon"
                                src="#currFriend[1].getIconPath()#"
                                alt="#currFriend[1].getIconAltText()#"
                            >
                        </td>
                        <td class="align-middle">#encodeForHTML(currFriend[1].getUsername())#</td>
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
