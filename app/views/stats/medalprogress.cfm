<cfoutput>
<div class="col">
    <div class="text-center">
        <h5><i class="bi bi-award me-1"></i>Medal Progress</h5>
    </div>
    <div class="tableDiv shadow-sm">
        <table class="table table-bordered table-hover mb-0">
            <thead>
                <tr>
                    <th width="80px;"></th>
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
</cfoutput>