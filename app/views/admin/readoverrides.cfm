<cfoutput>
<div class="container-fluid mt-4">
    <div class="row justify-content-center">
        <div class="col-12 col-xl-10">
            <div class="d-flex align-items-center justify-content-between mb-3">
                <h4 class="m-0">
                    <i class="bi bi-pencil-square me-1"></i>
                    #encodeForHTML(prc.description)#
                </h4>
                <div class="d-flex gap-2">
                    <button id="formatBtn" class="btn btn-sm btn-secondary">
                        <i class="bi bi-braces me-1"></i>Format JSON
                    </button>
                    <button id="saveBtn" class="btn btn-sm btn-dark">
                        <i class="bi bi-floppy me-1"></i>Save
                    </button>
                </div>
            </div>

            <div class="card shadow-sm">
                <div class="card-body p-2">
                    <form id="overridesForm" method="post" action="#event.buildLink(prc.submitAction)#" autocomplete="off">
                        <textarea
                            id="jsonEditor"
                            name="json"
                            class="form-control font-monospace"
                            style="min-height: 80vh; resize: vertical; font-size: .8rem;"
                            spellcheck="false"
                        >#encodeForHTML(prc.overridesJSON)#</textarea>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>