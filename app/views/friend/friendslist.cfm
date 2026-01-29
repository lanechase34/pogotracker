<cfoutput>
<div class="card shadow-sm">
    <div class="card-body mx-1">
        <div class="d-flex align-items-center justify-content-center mb-3">
            <h5 class="m-0">
                <i class="bi bi-person-check me-1"></i>
                Friends
            </h5>
            <div class="ms-auto">
                <button type="button" class="btn-dark btn btn-sm" id="addFriendBtn">
                    <i class="bi bi-person-plus me-2"></i>Add Friend
                </button>  
            </div>
        </div>  
        <div class="tableDiv">
        <table class="table table-hover border-top">
            <cfloop index="i" item="currFriend" array="#args.friendsList#">
                <tr class="trainerRow" data-profilelink="/profile/#currFriend[1].getId()#">
                    <td class="align-middle">
                        <img 
                            class="profileIcon" 
                            src="#currFriend[1].getIconPath()#"
                            alt="#currFriend[1].getIconAltText()#"
                        >
                    </td>
                    <td class="align-middle profileLink">#encodeForHTML(currFriend[1].getUsername())#</td>
                    <td class="align-middle text-center"><cfif currFriend[2]>Accepted<cfelse>Pending</cfif></td>
                </tr>
            </cfloop>
        </table>
        </div>
    </div>
</div>
</cfoutput>