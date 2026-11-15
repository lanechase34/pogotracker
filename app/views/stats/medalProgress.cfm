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
                                data-name="#currMedal.name#"
                                data-id="#currMedal.id#"
                                data-bronze="#currMedal.bronze#"
                                data-silver="#currMedal.silver#"
                                data-gold="#currMedal.gold#"
                                data-platinum="#currMedal.platinum#"
                            >
                                <td class="align-middle text-center">
                                    <img
                                        id="#currMedal.id#icon"
                                        alt="#currMedal.alttext#"
                                        src="/includes/images/medals/#currMedal.name##getSetting('imageExtension')#"
                                        loading="lazy"
                                        class="medalIcon <cfif currMedal.tracked>#currMedal.tier#Medal</cfif>"
                                    />
                                </td>
                                <td class="align-middle">
                                    #currMedal.name#
                                </td>
                                <td class="align-middle">
                                    <cfif args.editable>
                                        <input
                                            type="text"
                                            value="#currMedal.tracked ? currMedal.current : ''#"
                                            inputmode="numeric"
                                            pattern="[0-9\s]"
                                            id="input#currMedal.name#"
                                            class="form-control medalInput"
                                            aria-label="#encodeForHTMLAttribute(currMedal.name)# count"
                                        >
                                        <div class="invalid-feedback">Please provide a numeric value</div>
                                    <cfelse>
                                        #currMedal.tracked ? numberFormat(currMedal.current, ",") : "--"#
                                    </cfif>
                                </td>
                                <td class="align-middle">
                                    <cfset currProgress = currMedal.tracked ? (currMedal.current / currMedal.platinum) * 100 : 0/>
                                    <div
                                        class="progress medalProgressBar"
                                        role="progressbar"
                                        aria-label="Medal progress"
                                        aria-valuemin="0"
                                        aria-valuemax="100"
                                    >
                                        <div id="#currMedal.id#progressBar" class="progress-bar" style="width: #currProgress#%"></div>
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
