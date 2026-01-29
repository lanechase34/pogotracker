<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <title>#prc.title.len() ? prc.title : getSetting("title")#</title>
    <meta charset="UTF-8">
    <meta name="description" content="#encodeForHTMLAttribute(prc.metaDescription.len() ? prc.metaDescription : getSetting('metaDescription'))#">
    <meta name="keywords" content="#encodeForHTMLAttribute(prc.metaKeywords.len() ? prc.metaKeywords : getSetting('metaKeywords'))#">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
    <meta name="theme-color" content="rgb(33, 37, 41)">
    
    <!--- Favicon --->
    <link rel="icon" type="image/x-icon" sizes="32x32" href="/includes/images/favicon.ico?v=#getSetting('favIcoVersion')#">
    <link rel="icon" type="image/svg+xml" href="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#">
    <link rel="apple-touch-icon" href="/includes/images/apple-touch-icon.png?v=#getSetting('favIcoVersion')#">

    <!--- CSS Lib --->
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

    <!--- Global styles --->
    <link rel="stylesheet" type="text/css" href="#getSetting('cssPath')#/global#getSetting('minifiedCSS')#.css#getSetting('cacheBuster')#"/>
    
    #view(view="/views/fragment/importmap", args={jsPath: getSetting('jsPath'), minifiedJS: getSetting('minifiedJS'), cacheBuster: getSetting('cacheBuster')})#

    <script>0</script>
</head>
<body>
    <div class="container-fluid">
        #view()#
    </div>

    #view(view="/views/modal/loading")#
    #view(view="/views/fragment/data")#
</body>

<!--- JS Lib --->
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>
<script type="text/javascript" src="https://www.google.com/recaptcha/api.js?render=#getSetting('reCaptchaSiteKey')#"></script>

<script type="module">
    import { runtime } from 'runtime';
    runtime();
</script>
</cfoutput>