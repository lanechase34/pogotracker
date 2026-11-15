<cfoutput>
<cfset hasSelected = !prc.selected.isEmpty()/>
<cfset utilService = getInstance("services.util")/>
<div id="logViewer" class="logViewer row gx-3 mt-2 mb-3" data-filename="#encodeForHTMLAttribute(hasSelected ? prc.selected.name : '')#">
    <!--- File list - large screens --->
    <aside class="logSidebar col-lg-4 col-xl-3 col-xxl-2 d-none d-lg-flex flex-column">
        <div class="input-group input-group-sm mb-2">
            <input type="search" id="logFilter" class="form-control" placeholder="Filter #prc.logs.recordCount# logs" aria-label="Filter logs" autocomplete="off">
            <button type="button" id="logListRefresh" class="btn btn-outline-secondary" title="Refresh log list">
                <i class="bi bi-arrow-clockwise"></i>
            </button>
        </div>
        <div id="logList" class="logList list-group">
            <cfloop query="#prc.logs#">
                <a
                    href="/admin/logViewer?filename=#encodeForUrl(prc.logs.name)#"
                    class="logLink list-group-item list-group-item-action<cfif hasSelected AND prc.selected.name EQ prc.logs.name> active</cfif>"
                    data-filename="#encodeForHTMLAttribute(prc.logs.name)#"
                    data-size="#prc.logs.size#"
                    data-modified="#encodeForHTMLAttribute(dateTimeFormat(prc.logs.dateLastModified, 'mmm d, yyyy h:nn tt'))#"
                    <cfif hasSelected AND prc.selected.name EQ prc.logs.name>aria-current="true"</cfif>
                >
                    <div class="d-flex justify-content-between align-items-baseline gap-2">
                        <span class="logLinkName text-truncate" title="#encodeForHTMLAttribute(prc.logs.name)#">#encodeForHTML(prc.logs.name)#</span>
                        <small class="logLinkSize text-nowrap">#utilService.formatBytes(prc.logs.size)#</small>
                    </div>
                    <div class="small logLinkMeta text-nowrap">#dateTimeFormat(prc.logs.dateLastModified, 'mmm d, h:nn tt')#</div>
                </a>
            </cfloop>
        </div>
        <div id="logFilterEmpty" class="text-body-secondary small px-1 py-2<cfif prc.logs.recordCount> d-none</cfif>">
            #prc.logs.recordCount ? 'No logs match' : 'No log files found'#
        </div>
    </aside>

    <section class="logPane col-12 col-lg-8 col-xl-9 col-xxl-10 d-flex flex-column">
        <!--- File picker - small screens --->
        <div class="d-flex gap-2 mb-2 d-lg-none">
            <select id="logSelect" class="form-select" aria-label="Choose a log">
                <option value="" <cfif !hasSelected>selected</cfif> disabled>Choose a log (#prc.logs.recordCount#)</option>
                <cfloop query="#prc.logs#">
                    <option
                        value="#encodeForHTMLAttribute(prc.logs.name)#"
                        <cfif hasSelected AND prc.selected.name EQ prc.logs.name>selected</cfif>
                    >#encodeForHTML(prc.logs.name)# (#utilService.formatBytes(prc.logs.size)#)</option>
                </cfloop>
            </select>
            <button type="button" id="logSelectRefresh" class="btn btn-outline-secondary" title="Refresh log list" aria-label="Refresh log list">
                <i class="bi bi-arrow-clockwise"></i>
            </button>
        </div>

        <div class="logCard card flex-grow-1">
            <div class="logToolbar card-header d-flex flex-column gap-2">
                <div class="d-flex flex-wrap align-items-center gap-2">
                    <div class="logTitle me-auto">
                        <div id="logName" class="fw-semibold font-monospace text-truncate">
                            #hasSelected ? encodeForHTML(prc.selected.name) : 'No log selected'#
                        </div>
                        <div id="logMeta" class="small text-body-secondary text-truncate"></div>
                    </div>
                    <div class="d-flex flex-wrap align-items-center gap-2">
                        <div class="btn-group btn-group-sm" role="group" aria-label="Jump">
                            <button type="button" id="logJumpStart" class="btn btn-outline-secondary logNeedsFile" title="Jump to start" disabled>
                                <i class="bi bi-chevron-bar-up"></i><span class="d-none d-sm-inline ms-1">Start</span>
                            </button>
                            <button type="button" id="logJumpEnd" class="btn btn-outline-secondary logNeedsFile" title="Jump to end" disabled>
                                <i class="bi bi-chevron-bar-down"></i><span class="d-none d-sm-inline ms-1">End</span>
                            </button>
                        </div>
                        <input type="checkbox" class="btn-check logNeedsFile" id="logFollow" autocomplete="off" disabled>
                        <label class="btn btn-sm btn-outline-success" for="logFollow" title="Follow new lines as they're written">
                            <i class="bi bi-broadcast"></i><span class="d-none d-sm-inline ms-1">Follow</span>
                        </label>
                        <input type="checkbox" class="btn-check" id="logWrap" autocomplete="off">
                        <label class="btn btn-sm btn-outline-secondary" for="logWrap" title="Wrap long lines">
                            <i class="bi bi-text-wrap"></i><span class="d-none d-sm-inline ms-1">Wrap</span>
                        </label>
                        <a
                            id="logDownload"
                            class="btn btn-sm btn-outline-primary<cfif !hasSelected> disabled</cfif>"
                            href="<cfif hasSelected>/admin/downloadLog?filename=#encodeForUrl(prc.selected.name)#<cfelse>##</cfif>"
                            title="Download this log"
                            <cfif !hasSelected>aria-disabled="true" tabindex="-1"</cfif>
                        >
                            <i class="bi bi-download"></i><span class="d-none d-sm-inline ms-1">Download</span>
                        </a>
                    </div>
                </div>
                <div class="d-flex flex-wrap align-items-center gap-2">
                    <form id="logSearchForm" class="logSearch input-group input-group-sm me-auto" role="search">
                        <span class="input-group-text"><i class="bi bi-search"></i></span>
                        <input type="search" id="logSearch" class="form-control logNeedsFile" placeholder="Search this log" aria-label="Search this log" autocomplete="off" maxlength="200" disabled>
                        <button type="button" id="logSearchPrev" class="btn btn-outline-secondary logNeedsFile" title="Previous match (Shift+Enter)" aria-label="Previous match" disabled>
                            <i class="bi bi-chevron-up"></i>
                        </button>
                        <button type="submit" id="logSearchNext" class="btn btn-outline-secondary logNeedsFile" title="Next match (Enter)" aria-label="Next match" disabled>
                            <i class="bi bi-chevron-down"></i>
                        </button>
                    </form>
                    <span id="logSearchStatus" class="small text-body-secondary" aria-live="polite"></span>
                    <div class="btn-group btn-group-sm" role="group" aria-label="Show levels">
                        <input type="radio" class="btn-check" name="logLevel" id="logLevelAll" value="all" autocomplete="off" checked>
                        <label class="btn btn-outline-secondary" for="logLevelAll">All</label>
                        <input type="radio" class="btn-check" name="logLevel" id="logLevelWarn" value="warn" autocomplete="off">
                        <label class="btn btn-outline-warning" for="logLevelWarn" title="Warnings and errors">Warn+</label>
                        <input type="radio" class="btn-check" name="logLevel" id="logLevelError" value="error" autocomplete="off">
                        <label class="btn btn-outline-danger" for="logLevelError" title="Errors only">Errors</label>
                    </div>
                </div>
            </div>
            <div id="logScroller" class="logScroller" tabindex="0" aria-label="Log contents">
                <div id="logTopStatus" class="logStatus d-none"></div>
                <div id="logLines" class="logLines"></div>
                <div id="logBottomStatus" class="logStatus mb-3 d-none"></div>
                <div id="logEmpty" class="logEmpty<cfif hasSelected> d-none</cfif>">
                    <i class="bi bi-file-earmark-text fs-1 d-block mb-2"></i>
                    <cfif prc.logs.recordCount>
                        Select a log to view it
                    <cfelse>
                        No log files found
                    </cfif>
                </div>
            </div>
        </div>
    </section>
</div>
</cfoutput>
