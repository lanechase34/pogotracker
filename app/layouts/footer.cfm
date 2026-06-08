<cfoutput>
<div class="mt-auto pt-3">
<footer class="container-fluid text-secondary border-top border-secondary py-3">
    <div class="mx-lg-3">
        <p class="mb-1 small text-center">
            &copy; #year(now())# POGO Tracker. All rights reserved.
        </p>
        <p class="mb-1 small text-center">
            POGO Tracker is not affiliated with, endorsed by, or connected to Niantic, Nintendo, or The Pok&eacute;mon Company.
            This site is a fan-made tool intended to fall under Fair Use doctrine.
        </p>
        <p class="mb-0 small text-center">
            Pok&eacute;mon and all related names and trademarks are &copy;1995&ndash;#year(now())# Nintendo, Creatures, Inc., and GAMEFREAK Inc.
            All Pok&eacute;mon images, names, and data are property of their respective owners.
        </p>
        <cfif session?.authenticated ?: false>
            <p class="mb-0 mt-2 text-center">
                <button role="button" id="contactBtn" class="btn btn-outline-dark">
                    <i class="bi bi-mailbox me-2"></i>Contact
                </button>
            </p>
        </cfif>
    </div>
</footer>
</div>
</cfoutput>
