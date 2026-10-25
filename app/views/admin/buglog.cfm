<cfoutput>
<div class="mt-3">
<table id="bugLog" class="table table-striped table-bordered table-hover align-middle">
    <thead>
        <tr>
            <th class="text-center">Timestamp</th>
            <th class="text-center">IP</th>
            <th class="text-center">Event</th>
            <th class="text-center">Message</th>
            <th class="text-center">Trainer</th>
            <th class="text-center">Details</th>
        </tr>
    </thead>
</table>
</div>

<div class="modal fade" id="bugModal" tabindex="-1" aria-labelledby="bugModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5 d-flex align-items-center gap-2" id="bugModalTitle">
                    <i class="bi bi-bug-fill text-danger"></i>
                    <span>Bug <span id="bugModalId"></span></span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body" id="bugModalBody"></div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" id="bugModalCopy">
                    <i class="bi bi-clipboard me-1"></i>Copy Raw
                </button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
</cfoutput>
