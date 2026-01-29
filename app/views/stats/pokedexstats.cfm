<cfoutput>
<div 
    id="pokedexStatsCard" 
    class="card shadow-sm"
    data-missingstring="#args.missingString#"
    data-missingshinystring="#args.missingshinystring#"
>
    <div class="card-body mx-1">
        <div class="d-flex align-items-center justify-content-center mb-3">
            <h5 class="m-0">
                <i class="bi bi-ui-checks-grid me-1"></i>
                Pokedex Summary
            </h5>
        </div>
        <div class="tableDiv">
        <table class="table table-bordered table-hover">
            <thead>
                <tr>
                    <th>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-start">Region</span>
                            <div>
                                <button type="button" class="btn btn-sm invisible" disabled>
                                    a
                                </button>
                            </div>
                        </div>
                    </th>
                    <th>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-start">Caught</span>
                            <div>
                                <button type="button" class="btn btn-dark btn-sm" id="copyMissingString">
                                    <i class="bi bi-copy me-2"></i>Missing
                                </button>
                            </div>
                        </div>
                    </th>
                    <th>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="text-start">Shiny</span>
                            <div>
                                <button type="button" class="btn btn-dark btn-sm" id="copyMissingShinyString">
                                    <i class="bi bi-copy me-2"></i>Missing
                                </button>
                            </div>
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