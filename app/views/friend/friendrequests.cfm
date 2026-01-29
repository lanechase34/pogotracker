<cfoutput>
<div class="card col shadow-sm">
    <div class="card-body mx-1">
        <div class="d-flex align-items-center justify-content-center mb-3">
            <h5 class="m-0">
                <i class="bi bi-person-add me-1"></i>
                Friend Requests
            </h5>
        </div>
        <div class="tableDiv">
        <table class="table table-hover border-top">
            <cfloop index="i" item="currFriend" array="#args.friendRequests#">
                <tr>
                    <td class="align-middle">
                        <img 
                            class="profileIcon" 
                            src="#currFriend[1].getIconPath()#"
                            alt="#currFriend[1].getIconAltText()#"
                        >
                    </td>
                    <td class="align-middle">#EncodeForHTML(currFriend[1].getUsername())#</td>
                    <td class="align-middle text-end ms-auto" data-friendrequestid="#currFriend[2]#">
                        <button type="button" class="btn btn-success decideRequest" data-accept="true">
                            <i class="bi bi-check mx-1"></i>
                        </button>
                        <button type="button" class="btn btn-danger decideRequest" data-accept="false">
                            <i class="bi bi-x mx-1"></i>
                        </button>
                    </td>
                </tr>
            </cfloop>
            <cfloop index="i" item="currFriend" array="#args.sentFriendRequests#">
                <tr>
                    <td class="align-middle">
                        <img 
                            class="profileIcon" 
                            src="#currFriend[1].getIconPath()#"
                            alt="#currFriend[1].getIconAltText()#"
                        >
                    </td>
                    <td class="align-middle">#encodeForHTML(currFriend[1].getUsername())#</td>
                    <td class="align-middle text-center">Pending</td>
                </tr>
            </cfloop>
        </table>
        </div>
    </div>
</div>
</cfoutput>