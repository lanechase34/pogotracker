<cfoutput>
<div class="row mt-3">
    <div class="col-2 d-flex align-items-start">
        <div class="list-group w-100">
            <cfloop query="#prc.logs#" startRow="1">
                <a href="/admin/logViewer/filename/#encodeForUrl(name)#" class="<cfif rc.filename EQ name>active </cfif>list-group-item list-group-item-action py-3">
                    <div class="d-flex w-100 justify-content-between">
                        #encodeForHTML(name)#
                        <small>
                            #round(size / 1024)#KB
                        </small>
                    </div>
                    #dateTimeFormat(dateLastModified, 'short')#
                </a>
            </cfloop>
        </div>
    </div>
    <div class="card col-10 overflow-x-scroll">
        #paragraphFormat(prc.logContent)#
    </div>
</div>
</cfoutput>