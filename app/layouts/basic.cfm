<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    #view(view='/layouts/header', args={moduleEntry: 'runtime'})#
</head>
<body class="d-flex flex-column min-vh-100">
    <div class="container-fluid flex-grow-1 d-flex flex-column">
        #view()#
    </div>

    #view(view='/layouts/footer')#

    #view(view="/views/modal/loading")#
    #view(view="/views/fragment/data")#


    <!--- JS Lib --->
    <script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>

    <cfif prc.loadRecaptcha ?: false>
        <script type="text/javascript" defer src="https://www.google.com/recaptcha/api.js?render=#getSetting('reCaptchaSiteKey')#"></script>
    </cfif>

    <script type="module">
        import { runtime } from 'runtime';
        runtime();

        document.querySelectorAll('[data-history-back]').forEach(($btn) => {
            $btn.addEventListener('click', () => history.back());
        });
    </script>
</body>
</cfoutput>