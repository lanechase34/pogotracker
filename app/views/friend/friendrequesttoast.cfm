<cfoutput>
<cfif args.friendRequests.len()>
    <div id="friendRequestToastDiv" class="toast-container position-fixed bottom-0 end-0 p-3">
        <div id="friendRequestToast" class="toast bg-white" role="alert" aria-live="assertive" aria-atomic="true">
            <div class="toast-header">
                <strong class="me-auto">New Friend Request</strong>
                <small>#args.ago# mins ago</small>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
            <div class="toast-body">
                <!--- show max 3 friend requests here --->
                <cfloop index="i" item="curr" array="#args.friendRequests#">
                    <cfif i GT 3><cfbreak></cfif>
                    <p>
                        <strong>#curr[1].getUsername()#</strong> sent you a friend request!
                    </p>
                </cfloop>
            </div>
        </div>
    </div>
</cfif>
</cfoutput>