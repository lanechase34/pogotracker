<cfoutput>
<div
    class="row"
    id="profilerow"
    data-myprofile="#encodeForHTML(prc.myProfile)#"
    data-startdate="#encodeForHTML(prc.startDate)#"
    data-enddate="#encodeForHTML(prc.endDate)#"
>
    <div class="d-flex col-lg-4 mt-3">
        <div class="h-100 w-100 card shadow-sm">
            <div class="card-body text-center p-4">
                <img class="profileAvatar mb-3" id="profileIcon" src="#prc.trainer.getIconPath()#" alt="#prc.trainer.getIconAltText()#">
                <h5 class="fw-bold mb-1" id="mainProfileUsername" data-trainerid="#prc.trainer.getId()#">#encodeForHTML(prc.trainer.getUsername())#</h5>
                <span class="badge bg-dark mb-3">Level #prc.statStruct.level#</span>
                <cfif prc.statStruct.level != "--" AND prc.statStruct.level LT 80>
                    <div class="px-2">
                        <div class="d-flex justify-content-between small text-muted mb-1">
                            <span>#numberFormat(prc.statStruct.currxp, ",")#</span>
                            <span>#numberFormat(prc.statStruct.nextlevelxp, ",")# XP</span>
                        </div>
                        <div class="progress" role="progressbar" aria-label="XP Progress" aria-valuenow="#prc.statStruct.progress#" aria-valuemin="0" aria-valuemax="100">
                            <div class="progress-bar" style="width: #prc.statStruct.progress#%"></div>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
    <div class="d-flex col-lg-8 mt-3">
        <div class="h-100 w-100 card shadow-sm">
            <div class="card-body p-3">
                <div class="home-section-label">
                    <i class="bi bi-person fs-5"></i>Trainer Info
                </div>
                <div class="row g-0 py-2 border-bottom align-items-center">
                    <div class="col-sm-3 text-muted small fw-semibold">Username</div>
                    <div class="col-sm-9" id="profileUsername">#encodeForHTML(prc.trainer.getUsername())#</div>
                </div>
                <cfif prc.myProfile>
                    <div class="row g-0 py-2 border-bottom align-items-center">
                        <div class="col-sm-3 text-muted small fw-semibold">Email</div>
                        <div class="col-sm-9" id="profileEmail">#prc.trainer.getEmail()#</div>
                    </div>
                </cfif>
                <div class="row g-0 py-2 border-bottom align-items-center">
                    <div class="col-sm-3 text-muted small fw-semibold">Friend Code</div>
                    <div class="col-sm-9">#prc.trainer.getFormattedFriendCode()#</div>
                </div>
                <div class="row g-0 py-2 align-items-center<cfif prc.myProfile> border-bottom</cfif>">
                    <div class="col-sm-3 text-muted small fw-semibold">Total XP</div>
                    <div class="col-sm-9">#prc.statStruct.totalxp#</div>
                </div>
                <cfif prc.myProfile>
                    <div class="row g-0 pt-3">
                        <div class="col-auto ms-auto d-flex gap-2">
                            <button id="trackStats" role="button" class="btn btn-dark btn-sm" <cfif dateDiff("d", prc.statStruct.dateTracked, now()) LT 1>disabled</cfif>>
                                <i class="bi bi-graph-up me-1"></i>Track Stats
                            </button>
                            <button id="editProfile" role="button" class="btn btn-dark btn-sm">
                                <i class="bi bi-pencil me-1"></i>Edit
                            </button>
                        </div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>
</div>
<div class="row profileCards">
    <cfif prc.myProfile>
        <div class="col-12 col-xl-6 mt-3 profileCard" id="friendRequestsDiv"></div>
        <div class="col-12 col-xl-6 mt-3 profileCard" id="friendsListDiv"></div>
    </cfif>
    <div class="col-12 col-xl-6 mt-3 profileCard" id="summaryStatsDiv"></div>
    <div class="col-12 col-xl-6 mt-3 profileCard" id="pokedexStatsDiv"></div>
    <div class="col-12 col-xl-6 mt-3 profileCard" id="medalSummaryDiv"></div>
    <div class="col-12 col-xl-6 mt-3 profileCard" id="topDeltasDiv"></div>
</div>
</cfoutput>
