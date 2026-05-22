<cfoutput>
<title>#prc.title.len() ? prc.title : getSetting("title")#</title>
<meta charset="UTF-8">
<meta name="description" content="#encodeForHTMLAttribute(prc.metaDescription.len() ? prc.metaDescription : getSetting('metaDescription'))#">
<meta name="viewport" content="width=device-width, initial-scale=1.0"> 
<meta name="theme-color" content="rgb(33, 37, 41)">
<link rel="canonical" href="#encodeForHTMLAttribute(prc.canonicalURL)#">
<meta name="robots" content="#prc.keyExists('metaRobots') ? prc.metaRobots : 'index, follow'#">

<!--- Open Graph --->
<meta property="og:title" content="#encodeForHTMLAttribute(prc.title.len() ? prc.title : getSetting('title'))#">
<meta property="og:description" content="#encodeForHTMLAttribute(prc.metaDescription.len() ? prc.metaDescription : getSetting('metaDescription'))#">
<meta property="og:url" content="#encodeForHTMLAttribute(prc.canonicalURL)#">
<meta property="og:type" content="#prc.keyExists('ogType') ? encodeForHTMLAttribute(prc.ogType) : 'website'#">
<meta property="og:site_name" content="POGO Tracker">
<cfif prc.keyExists('ogImage')>
    <meta property="og:image" content="#encodeForHTMLAttribute(prc.ogImage)#">
    <cfelse>
    <meta property="og:image" content="https://pogotracker.app/includes/images/og-default.webp">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
</cfif>

<!--- Twitter Card --->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="#encodeForHTMLAttribute(prc.title.len() ? prc.title : getSetting('title'))#">
<meta name="twitter:description" content="#encodeForHTMLAttribute(prc.metaDescription.len() ? prc.metaDescription : getSetting('metaDescription'))#">
<meta name="twitter:image" content="#prc.keyExists('ogImage') ? encodeForHTMLAttribute(prc.ogImage) : 'https://pogotracker.app/includes/images/og-default.webp'#">

<!--- Structured Data --->
<cfif prc.keyExists('structuredData')>
    <script type="application/ld+json">#prc.structuredData#</script>
<cfelse>
    <script type="application/ld+json">
    {
        "@context": "https://schema.org",
        "@type": "WebApplication",
        "name": "POGO Tracker",
        "url": "https://pogotracker.app",
        "description": "#encodeForJavaScript(getSetting('metaDescription'))#",
        "applicationCategory": "GameApplication",
        "operatingSystem": "Web"
    }
    </script>
</cfif>

<!--- Favicon --->
<link rel="icon" type="image/x-icon" sizes="32x32" href="/includes/images/favicon.ico?v=#getSetting('favIcoVersion')#">
<link rel="icon" type="image/svg+xml" href="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#">
<link rel="apple-touch-icon" href="/includes/images/apple-touch-icon.png?v=#getSetting('favIcoVersion')#">

<!--- CSS Lib --->
<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
<link rel="preload" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/fonts/bootstrap-icons.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">

<!--- Global styles --->
<link rel="stylesheet" type="text/css" href="#getSetting('cssPath')#/global#getSetting('minifiedCSS')#.css#getSetting('cacheBuster')#"/>

#view(view="/views/fragment/importmap", args={jsPath: getSetting('jsPath'), minifiedJS: getSetting('minifiedJS'), cacheBuster: getSetting('cacheBuster')})#
</cfoutput>