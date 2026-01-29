<cfoutput>
    <div class="modal fade" 
        id="trackStatsModal" 
        data-bs-backdrop="static" 
        data-bs-keyboard="false" 
        tabindex="-1" 
        aria-labelledby="trackStatsLabel" 
        aria-hidden="true"
    >
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5" id="trackStats">Track Stats for #dateFormat(args.currDate, "short")#</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form name="trackStatsForm" id="trackStatsForm" class="needs-validation row g-3" novalidate autocomplete="off">
                    <div id="statAlert"></div>
                    <input type="hidden" id="trainerid" name="trainerid" value="#EncodeForHTML(args.trainer.getId())#">
                    <div class="col-12">
                        <label for="inputWalked" class="form-label">Distance Walked</label>
                        <input name="walked" type="number" class="form-control" id="inputWalked" value="" min="1" max="1000000" step=".01" required>
                        <div class="invalid-feedback">
                            Please provide valid walked.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputCaught" class="form-label">Pokemon Caught</label>
                        <input name="caught" type="number" class="form-control" id="inputCaught" value="" min="1" max="1000000" required>
                        <div class="invalid-feedback">
                            Please provide valid caught.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputSpun" class="form-label">Pokestops Spun</label>
                        <input name="spun" type="number" class="form-control" id="inputSpun" value="" min="1" max="1000000" required>
                        <div class="invalid-feedback">
                            Please provide valid spun.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputXP" class="form-label">Total XP</label>
                        <input name="xp" type="number" class="form-control" id="inputXP" value="" min="1" max="1000000000" required>
                        <div class="invalid-feedback">
                            Please provide valid xp.
                        </div>  
                    </div>
                    <div class="col-12">
                        <label for="inputDate1" class="form-label">Date</label>
                        <input name="date1" type="text" class="form-control" id="inputDate1" value="#dateFormat(args.currDate, "mm/dd/yyyy")#" required disabled>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <div class="btn-group" role="group">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="submit" id="submitTrackStatsForm" class="btn btn-primary">
                        <i class="bi bi-check2-square me-1"></i>
                        Submit
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>  
</cfoutput>