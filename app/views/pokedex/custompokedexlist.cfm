<cfoutput>
<cfif prc.offset EQ 0><div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 row-cols-xxl-5 mt-3"></cfif>
<cfif args.customPokedexes.len()>
    <cfloop index="i" item="currCustom" array="#args.customPokedexes#">
        <div class="d-flex justify-content-center col mb-3 ">
            <div class="card h-100 w-100 shadow-sm">        
                <div class="d-flex flex-column card-body">
                    <h5 class="card-title">
                        #encodeForHTML(currCustom.name)#
                    </h5>
                    <div class="mt-auto">
                        <p class="card-text text-muted m-0">
                            <i class="bi bi-person-circle me-1"></i>
                            #encodeForHTML(currCustom.username)#
                        </p>
                        <p class="text-muted">
                            <i class="bi bi-calendar3 me-1"></i>
                            #currCustom.formattedbegins#<cfif isDate(currCustom.ends ?: "")> - #currCustom.formattedends#</cfif>
                        </p>
                        <div class="row p-0">
                            <div class="btn-group" role="group">
                                <a href="/mycustompokedex/#currCustom.id#" class="mt-auto btn btn-dark w-100">View</a>
                                <cfif currCustom.trainerid EQ args.trainerid>
                                    <button class="editCustomPokedex#args.offset# mt-auto btn btn-warning w-100" type="button" data-customid="#encodeForHTML(currCustom.id)#">
                                        <i class="bi bi-wrench me-1"></i>Edit
                                    </button>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </cfloop>
    <div id="nextGroup#args.nextOffset#">
    </div>
</cfif>
<cfif prc.offset EQ 0></div></cfif>
</cfoutput>