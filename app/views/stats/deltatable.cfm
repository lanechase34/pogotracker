<cfoutput>
<div class="card shadow-sm">
    <div class="card-body p-3">
        <div class="home-section-label">
            <i class="bi bi-triangle fs-5"></i><span id="deltaLabel">Delta XP</span>
            <button
                class="btn btn-sm p-0 border-0 ms-auto text-muted"
                type="button"
                data-bs-toggle="collapse"
                data-bs-target="##deltaCollapse"
                aria-expanded="true"
                aria-controls="deltaCollapse"
            >
                <i class="bi bi-chevron-up collapse-chevron"></i>
            </button>
        </div>
        <div class="collapse show" id="deltaCollapse">
            <div class="tableDiv pt-2">
                <table class="table table-hover table-sm mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>Day</th>
                            <th id="deltaStatHeader">XP</th>
                            <th>Delta</th>
                        </tr>
                    </thead>
                    <tbody id="deltaTableBody"></tbody>
                </table>
            </div>
        </div>
    </div>
</div>
</cfoutput>
