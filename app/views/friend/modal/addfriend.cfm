<cfoutput>
<div class="modal fade" 
    id="addFriendModal" 
    data-bs-backdrop="static"
    data-bs-keyboard="false" 
    tabindex="-1"
>
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="addFriendModalLabel">Add Friend</h5>
                <span type="button" class="btn-close" data-bs-dismiss="modal"></span>
            </div>
            <div class="modal-body">
                <form name="addFriendForm" id="addFriendForm" class="needs-validation" novalidate autocomplete="off">
                    <input type="hidden" id="trainerid" name="trainerid" value="#EncodeForHTML(args.trainerid)#">
                    <div class="mb-3 row">
                        <label for="inputFriend" class="col-2 col-form-label">Trainer</label>
                        <div class="col-10">
                            <select id="friendsToAddSearch" class="form-select" name="friendid" required autocomplete="off"></select>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <div class="btn-group" role="group">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="submit" id="submitAddFriendForm" class="btn btn-primary">
                        <i class="bi bi-person-add me-1"></i>
                        Send Friend Request
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>