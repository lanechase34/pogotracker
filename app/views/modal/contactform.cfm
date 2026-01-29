<cfoutput>
<div class="modal fade" 
    id="contactFormModal" 
    data-bs-backdrop="static" 
    data-bs-keyboard="false" 
    tabindex="-1" 
    aria-labelledby="contactFormLabel" 
    aria-hidden="true"
>
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title fs-5">Contact</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form name="contactForm" id="contactForm" class="needs-validation row g-3" novalidate autocomplete="off">
                    <input type="hidden" id="trainerid" name="trainerid" value="#EncodeForHTML(session.trainerid)#">

                    <div class="col-12">
                        <label for="inputEmail" class="form-label">Email</label>
                        <input name="email" type="text" class="form-control" id="inpuEmail" value="#EncodeForHTML(session.email)#" disabled required>
                    </div>

                    <div class="col-12">
                        <label for="inputSubject" class="form-label">Subject</label>
                        <input name="subject" type="text" class="form-control" id="inputSubject" value="" maxlength="100" required>
                    </div>

                    <div class="col-12">
                        <label for="inputMessage" class="form-label">Message</label>
                        <textarea name="message" rows="8" class="form-control" id="inputMessage" required maxlength="2000"></textarea>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <div class="btn-group" role="group">
                    <button type="button" id="closeContactForm" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    <button type="submit" id="submitContactForm" class="btn btn-primary">
                        <i class="bi bi-mailbox me-1"></i>
                        Send
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
</cfoutput>