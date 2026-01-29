<cfoutput>
<div class="row mt-3">
    <div class="col-2 d-flex align-items-start">
        <div class="list-group w-100">
            <cfloop query="#prc.testEmails#" startRow="1" endRow="20">
                <a href="/dev/viewEmail/filename/#left(name, name.len()-5)#" class="<cfif rc.filename EQ left(name, name.len()-5)>active</cfif> list-group-item list-group-item-action d-flex gap-2 py-3">
                    <div class="d-flex gap-2 w-100 justify-content-between">
                        #dateTimeFormat(dateLastModified, "short")#
                    </div>
                </a>
            </cfloop>
        </div>
    </div>
    <div class="col-10 overflow-x-scroll">
        #prc.mailContent#
    </div>
</div>
</cfoutput>