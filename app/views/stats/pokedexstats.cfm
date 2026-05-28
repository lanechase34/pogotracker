<cfoutput>
<div
    id="pokedexStatsCard"
    class="card shadow-sm"
    data-missingstring="#args.missingString#"
    data-missingshinystring="#args.missingshinystring#"
>
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-ui-checks-grid fs-5"></i>Pokédex Summary
        </div>
        <div class="tableDiv">
            <table class="table table-hover table-sm mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Region</th>
                        <th>
                            <div class="d-flex justify-content-between align-items-center">
                                <span>Caught</span>
                                <button type="button" class="btn btn-dark btn-sm me-1" id="copyMissingString">
                                    <i class="bi bi-copy me-1"></i>Missing
                                </button>
                            </div>
                        </th>
                        <th>
                            <div class="d-flex justify-content-between align-items-center">
                                <span>Shiny</span>
                                <button type="button" class="btn btn-dark btn-sm me-1" id="copyMissingShinyString">
                                    <i class="bi bi-copy me-1"></i>Missing
                                </button>
                            </div>
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop index="i" item="currRegion" array="#args.pokedexstats#">
                        <tr>
                            <td>#currRegion[3]#</td>
                            <td>#numberFormat(currRegion[4] / currRegion[1], ",.00") * 100#% (#currRegion[4]# / #currRegion[1]#)</td>
                            <td>#numberFormat(currRegion[5] / currRegion[2], ",.00") * 100#% (#currRegion[5]# / #currRegion[2]#)</td>
                        </tr>
                    </cfloop>
                </tbody>
            </table>
        </div>
    </div>
</div>
</cfoutput>
