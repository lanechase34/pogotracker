<cfoutput>
#view("/views/admin/fragment/logRange")#
<div>
<table id="auditLog" class="table table-striped table-bordered align-middle">
    <thead>
        <tr>
            <th class="text-center">Details</th>
            <th class="text-center">Timestamp</th>
            <th class="text-center">IP</th>
            <th class="text-center">Event</th>
            <th class="text-center">Referer</th>
            <th class="text-center">Detail</th>
            <th class="text-center">Agent</th>
            <th class="text-center">Trainer</th>
        </tr>
    </thead>
</table>
</div>

<div class="modal fade" id="auditModal" tabindex="-1" aria-labelledby="auditModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5 d-flex align-items-center gap-2" id="auditModalTitle">
                    <i class="bi bi-journal-text"></i>
                    <span id="auditModalEvent"></span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <dl class="row mb-3">
                    <dt class="col-sm-2">Timestamp</dt>
                    <dd class="col-sm-10" id="auditModalTimestamp"></dd>
                    <dt class="col-sm-2">IP</dt>
                    <dd class="col-sm-10" id="auditModalIp"></dd>
                    <dt class="col-sm-2">Trainer</dt>
                    <dd class="col-sm-10" id="auditModalTrainer"></dd>
                    <dt class="col-sm-2">Referer</dt>
                    <dd class="col-sm-10 text-break" id="auditModalReferer"></dd>
                    <dt class="col-sm-2">Agent</dt>
                    <dd class="col-sm-10 text-break" id="auditModalAgent"></dd>
                </dl>
                <h6>Detail</h6>
                <pre class="bg-body-tertiary border rounded p-3 mb-0 text-wrap text-break" id="auditModalDetail"></pre>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" id="auditModalCopy">
                    <i class="bi bi-clipboard me-1"></i>Copy Detail
                </button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
            </div>
        </div>
    </div>
</div>
</cfoutput>
