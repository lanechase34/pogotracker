<cfoutput>
<div class="row mt-3">
    <div class="accordion" id="sessionAccordion">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="##sessionCollapse" aria-expanded="false">
                    Session
                </button>
            </h2>
        </div>
        <div id="sessionCollapse" class="accordion-collapse collapse" data-bs-parent="##sessionAccordion">
            <div class="accordion-body">
                <cfdump var="#session#" top="1"/>
            </div>
        </div>
    </div>
    <div class="accordion" id="serverAccordion">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="##serverCollapse" aria-expanded="false">
                    Server
                </button>
            </h2>
        </div>
        <div id="serverCollapse" class="accordion-collapse collapse" data-bs-parent="##serverAccordion">
            <div class="accordion-body">
                <cfdump var="#server#"/>
            </div>
        </div>
    </div>
    <div class="accordion" id="cgiAccordion">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="##cgiCollapse" aria-expanded="false">
                    CGI
                </button>
            </h2>
        </div>
        <div id="cgiCollapse" class="accordion-collapse collapse" data-bs-parent="##cgiAccordion">
            <div class="accordion-body">
                <cfdump var="#cgi#"/>
            </div>
        </div>
    </div>
    <div class="accordion" id="sessionAccordion">
        <div class="accordion-item">
            <h2 class="accordion-header">
                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="##requestCollapse" aria-expanded="false">
                    Request
                </button>
            </h2>
        </div>
        <div id="requestCollapse" class="accordion-collapse collapse" data-bs-parent="##requestAccordion">
            <div class="accordion-body">
                <cfdump var="#request#"/>
            </div>
        </div>
    </div>
</div>
</cfoutput>