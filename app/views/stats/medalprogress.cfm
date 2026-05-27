<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-award fs-5"></i>Medal Progress
            <button
                class="btn btn-sm p-0 border-0 ms-auto text-muted"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="##medalProgressCollapse"
                aria-expanded="true"
                aria-controls="medalProgressCollapse"
            >
                <i class="bi bi-chevron-up collapse-chevron"></i>
            </button>
        </div>
        <div class="collapse show" id="medalProgressCollapse">
            <div class="tableDiv pt-2">
                <table class="table table-hover table-sm mb-0">
                    <thead class="table-light">
                        <tr>
                            <th style="width: 80px;"></th>
                            <th>Name</th>
                            <th>Count</th>
                            <th>Progress</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop index="i" item="currMedal" array="#args.medalProgress#">
                            <tr
                                data-name="#currMedal[1].getName()#"
                                data-id="#currMedal[1].getId()#"
                                data-bronze="#currMedal[1].getBronze()#"
                                data-silver="#currMedal[1].getSilver()#"
                                data-gold="#currMedal[1].getGold()#"
                                data-platinum="#currMedal[1].getPlatinum()#"
                            >
                                <td class="align-middle text-center">
                                    <img
                                        id="#currMedal[1].getId()#icon"
                                        alt="#currMedal[1].getAltText()#"
                                        src="/includes/images/medals/#currMedal[1].getName()##getSetting('imageExtension')#"
                                        loading="lazy"
                                        class="medalIcon <cfif!isNull(currMedal[2])>#currMedal[2].getCurrentMedal()#Medal</cfif>"
                                    />
                                </td>
                                <td class="align-middle">
                                    #currMedal[1].getName()#
                                </td>
                                <td class="align-middle">
                                    <input
                                        type="text"
                                        value="#!isNull(currMedal[2]) ? currMedal[2].getCurrent() : ''#"
                                        inputmode="numeric"
                                        pattern="[0-9\s]"
                                        id="input#currMedal[1].getName()#"
                                        class="form-control medalInput"
                                    >
                                    <div class="invalid-feedback">Please provide a numeric value</div>
                                </td>
                                <td class="align-middle">
                                    <cfset currProgress = !isNull(currMedal[2]) ? (currMedal[2].getCurrent() / currMedal[1].getPlatinum()) * 100 : 0/>
                                    <div
                                        class="progress medalProgressBar"
                                        role="progressbar"
                                        aria-label="Medal progress"
                                        aria-valuemin="0"
                                        aria-valuemax="100"
                                    >
                                        <div id="#currMedal[1].getId()#progressBar" class="progress-bar" style="width: #currProgress#%"></div>
                                    </div>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
</cfoutput>
