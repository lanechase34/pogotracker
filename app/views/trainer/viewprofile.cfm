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
            <div class="card-body text-center mx-3">
                <img class="avatarIcon" id="profileIcon" src="#prc.trainer.getIconPath()#" alt="#prc.trainer.getIconAltText()#">
                <h5 class="my-3" id="mainProfileUsername" data-trainerid="#prc.trainer.getId()#">#prc.trainer.getUsername()#</h5>
                <p class="text-muted mb-1">
                    Level #prc.statStruct.level#
                </p>
                <cfif prc.statStruct.level != "--" AND prc.statStruct.level LT 50>
                    <p class="text-muted mb-1">
                        #numberFormat(prc.statStruct.currxp, ",")# / #numberFormat(prc.statStruct.nextlevelxp, ",")# XP
                    </p>
                    <div class="progress mx-3" role="progressbar" aria-label="Basic example" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100">
                        <div class="progress-bar" style="width: #prc.statStruct.progress#%"></div>
                    </div>
                </cfif>
                
            </div>
        </div>
    </div>
    <div class="d-flex col-lg-8 mt-3">
        <div class="h-100 w-100 card shadow-sm">
            <div class="card-body mx-1">
                <dl class="row my-2">
                    <div class="col-12">
                        <div class="row">
                            <dt class="col-sm-3">
                                <p class="mb-0">Username</p>
                            </dt>
                            <dd class="col-sm-9">
                                <p class="text-muted mb-0" id="profileUsername">
                                    #prc.trainer.getUsername()#
                                </p>
                            </dd>
                        </div>
                        <div class="col-12">
                            <div class="border-bottom mb-2"></div>
                        </div>

                        <cfif prc.myProfile> 
                            <div class="row">
                                <dt class="col-sm-3">
                                    <p class="mb-0">Email</p>
                                </dt>
                                <dd class="col-sm-9">
                                    <p class="text-muted mb-0" id="profileEmail">
                                        #prc.trainer.getEmail()#
                                    </p>
                                </dd>
                            </div>
                            <div class="col-12">
                                <div class="border-bottom mb-2"></div>
                            </div>
                        </cfif>
                        
                        <div class="row">
                            <dt class="col-sm-3">
                                <p class="mb-0">Friend Code</p>
                            </dt>
                            <dd class="col-sm-9">
                                <p class="text-muted mb-0">
                                    #prc.trainer.getFormattedFriendCode()#
                                </p>
                            </dd>
                        </div>
                        <div class="col-12">
                            <div class="border-bottom mb-2"></div>
                        </div>

                        <div class="row">
                            <dt class="col-sm-3">
                                <p class="mb-0">Total XP</p>
                            </dt>
                            <dd class="col-sm-9">
                                <p class="text-muted mb-0">#prc.statStruct.totalxp#</p>
                            </dd>
                        </div>
                        <div class="col-12">
                            <div class="border-bottom mb-3"></div>
                        </div>

                        <cfif prc.myProfile> 
                            <div class="row">
                                <div class="col-auto ms-auto">
                                    <button id="trackStats" role="button" class="btn btn-dark btn-sm me-2" <cfif dateDiff("d", prc.statStruct.dateTracked, now()) LT 1>disabled</cfif>>
                                        <i class="bi bi-graph-up me-2"></i>Track Stats
                                    </button>
                                    <button id="editProfile" role="button" class="btn btn-dark btn-sm">
                                        <i class="bi bi-pencil me-2"></i>Edit
                                    </button>
                                </div>
                            </div>
                        </cfif>
                    </div>
                </dl>
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
</div>
</cfoutput>