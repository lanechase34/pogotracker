<cfoutput>
<div class="row">
    <div class="col-12 col-lg-6 col-xxxl-4 mt-3">
        <div class="card h-100 w-100 shadow-sm">
            <div class="card-body">
                <h5 class="card-title text-center">
                    Trade Plan
                </h5>
                <div class="p-3 row">
                    <form 
                        name="tradePlanForm"
                        id="tradePlanForm" 
                        class="needs-validation" 
                        novalidate
                        method="get" 
                        autocomplete="off"
                    >
                        <div class="mb-3 row pe-0">
                            <label for="inputFriend" class="col-sm-3 col-form-label">Friend</label>
                            <div class="col-sm-9">
                                <select id="inputFriend" class="form-select" name="friend" required></select>
                            </div>
                        </div>
        
                        <hr>

                        <div class="mb-3 row pe-0">
                            <label for="inputRegion" class="col-sm-3 col-form-label">Region</label>
                            <div class="col-sm-9">
                                <select class="form-select optionalSelect" id="inputRegion" name="region">
                                    <option value=""></option>
                                    <cfloop index="i" item="currGen" array="#prc.generations#">
                                        <option value="#currGen.getRegion()#">#currGen.getRegion()#</option>
                                    </cfloop>
                                </select>
                            </div>
                        </div>

                        <div class="mb-3 row pe-0">
                            <span><strong>OR</strong></span>
                        </div>
        
                        <div class="mb-3 row pe-0">
                            <label for="inputCustomPokedex" class="col-sm-3 col-form-label">Custom</label>
                            <div class="col-sm-9">
                                <select class="form-select optionalSelect" id="inputCustomPokedex" name="customid"></select>
                            </div>
                        </div>

                        <div class="mb-3 row pe-0">
                            <div class="col-sm-10 offset-sm-2 d-flex justify-content-end">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="inputShiny" name="shiny">
                                    <label class="form-check-label" for="inputShiny">Shiny</label>
                                </div>
                            </div>
                        </div>
                        <div class="row pe-0 text-end">
                            <div class="col-sm-12">
                                <div class="btn-group" role="group">
                                    <button class="btn btn-secondary" id="resetTradePlan" type="button">
                                        <i class="bi bi-recycle me-1"></i>
                                        Reset
                                    </button>
                                    <button class="btn btn-dark" id="submitTradePlan" type="button">
                                        <i class="bi bi-bezier2 me-1"></i>
                                        Create Trade Plan
                                    </button>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
    <div class="col-12 col-lg-6 col-xxxl-8 mt-3">
        <div class="card h-100 w-100 shadow-sm">
            <div class="card-body">
                <div id="tradePlanAlert"></div>
                <div id="tradePlanDiv">

                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>