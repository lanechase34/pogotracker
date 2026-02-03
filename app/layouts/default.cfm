<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <title>#prc.title.len() ? prc.title : getSetting("title")#</title>
    <meta charset="UTF-8">
    <meta name="description" content="#encodeForHTMLAttribute(prc.metaDescription.len() ? prc.metaDescription : getSetting('metaDescription'))#">
    <meta name="keywords" content="#encodeForHTMLAttribute(getSetting('metaKeywords'))#">
    <meta name="viewport" content="width=device-width, initial-scale=1.0"> 
    <meta name="theme-color" content="rgb(33, 37, 41)">

    <!--- Favicon --->
    <link rel="icon" type="image/x-icon" sizes="32x32" href="/includes/images/favicon.ico?v=#getSetting('favIcoVersion')#">
    <link rel="icon" type="image/svg+xml" href="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#">
    <link rel="apple-touch-icon" href="/includes/images/apple-touch-icon.png?v=#getSetting('favIcoVersion')#">

    <!--- CSS Lib --->
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css" integrity="sha384-sRIl4kxILFvY47J16cr9ZwB07vP4J8+LH7qKQnuqkuIAvNWLzeN8tE5YBujZqJLB" crossorigin="anonymous">
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
    <link rel="stylesheet" type="text/css" href="/includes/build/css/lib/multiselect.min.css" media="print" onload="this.media='all'; this.onload=null;"/>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.css" crossorigin="anonymous" media="print" onload="this.media='all'; this.onload=null;"/>
    <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/v/bs5/dt-2.1.8/b-3.2.0/fh-4.0.1/r-3.0.3/datatables.min.css" crossorigin="anonymous" media="print" onload="this.media='all'; this.onload=null;"/>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" crossorigin="anonymous" media="print" onload="this.media='all'; this.onload=null;"/>
    <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/select2-bootstrap-5-theme@1.3.0/dist/select2-bootstrap-5-theme.min.css" crossorigin="anonymous" media="print" onload="this.media='all'; this.onload=null;"/>

    <!--- Global styles --->
    <link rel="stylesheet" type="text/css" href="#getSetting('cssPath')#/global#getSetting('minifiedCSS')#.css#getSetting('cacheBuster')#"/>

    <!--- Handler styles --->
    <cfif fileExists("#getSetting('rootPath')##getSetting('cssPath')#/#prc.currHandler##getSetting('minifiedCSS')#.css")>
        <link rel="stylesheet" type="text/css" href="#getSetting('cssPath')#/#prc.currHandler##getSetting('minifiedCSS')#.css#getSetting('cacheBuster')#"/>
    </cfif>

    #view(view="/views/fragment/importmap", args={jsPath: getSetting('jsPath'), minifiedJS: getSetting('minifiedJS'), cacheBuster: getSetting('cacheBuster')})#

    <script>let globalModals = {'init': true};</script>
</head>
<body class="mb-3">
<div id="mainbody">
    <!--- Navbar and header --->
    <nav class="bg-dark sticky-top container-fluid d-block">
        <div class="mx-lg-3 py-2 py-md-1">
            <div class="row">
                <!--- offcanvas hamburger --->
                <div class="col-2 col-xl-4 d-flex align-items-center">
                    <button 
                        class="my-auto d-flex align-items-center hamburgerButton iconHover" 
                        type="button" 
                        data-bs-toggle="offcanvas" 
                        data-bs-target="##sideNavbar" 
                        aria-controls="sideNavbar" 
                        aria-label="Toggle navigation"
                    >
                        <i class="bi bi-list hamburgerIcon"></i>
                    </button>
                    <h2 class="hfs-5 text-light m-0 p-0" id="navHeader">
                        #prc?.header ?: ''#
                    </h2>
                </div>

                <!--- custom header buttons section --->
                <div class="col-10 col-xl-8 d-flex align-items-center justify-content-end">
                    <cfif "pokedex.mycustompokedex,pokedex.mypokedex,pokedex.myshadowpokedex".contains(prc.currEvent)>
                        <div id="monsRegistered" class="ms-auto basic me-3 my-auto hfs-6">-- Registered</div>

                        <!--- btn dropdown for small screens --->
                        <div class="d-block d-md-none btn-group" role="group">
                            <button type="button" class="btn btn-primary dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false">
                                Actions
                            </button>
                            <ul class="dropdown-menu dropdown-menu-dark dropdown-menu-start">
                                <li>
                                    <button class="copySearchString dropdown-item">
                                        <i class="bi bi-copy me-2"></i>String
                                    </button>
                                </li>
                                <li><hr class="dropdown-divider"></li>
                                <li>
                                    <button class="copyMissingSearchString dropdown-item">
                                        <i class="bi bi-copy me-2"></i>Missing
                                    </button>
                                </li>
                                <li><hr class="dropdown-divider"></li>
                                <cfif prc.currEvent EQ "pokedex.mycustompokedex" AND !isNull(prc.custom.getLink()) AND prc.custom.getLink().len()>
                                    <li>
                                        <a href="#prc.custom.getLink()#" target="_blank" class="dropdown-item" role="button">
                                            <i class="bi bi-link-45deg me-2"></i>Leekduck
                                        </a>
                                    </li>
                                    <li><hr class="dropdown-divider"></li>
                                </cfif>
                                <cfif prc.currEvent EQ "pokedex.mypokedex">
                                    <li>
                                        <button class="registerAll dropdown-item">
                                            <i class="bi bi-list-check me-2"></i>Register All
                                        </button>
                                    </li>
                                    <li><hr class="dropdown-divider"></li>
                                </cfif>
                                <li>
                                    <button class="pokedexLock dropdown-item">
                                        <i class="bi bi-<cfif cookie.keyExists('pokedexLock') AND cookie.pokedexLock EQ true>lock<cfelse>unlock</cfif>"></i>
                                        <cfif cookie.keyExists('pokedexLock') AND cookie.pokedexLock EQ true>Locked<cfelse>Unlocked</cfif>
                                    </button>
                                </li>
                                <li><hr class="dropdown-divider"></li>
                                <li>
                                    <button class="shinyToggle dropdown-item">
                                        <i class="bi bi-stars me-2"></i>Shiny
                                    </button>
                                </li>
                            </ul>
                        </div>

                        <!--- btn group for large screens --->
                        <div id="pokedexBtnGroup" class="d-none d-md-flex btn-group" role="group">
                            <button class="copySearchString btn btn-adjust btn-primary" type="button">
                                <i class="bi bi-copy me-2"></i>String
                            </button>
                            <button class="copyMissingSearchString btn btn-adjust btn-primary" type="button">
                                <i class="bi bi-copy me-2"></i>Missing
                            </button>
                            <cfif prc.currEvent EQ "pokedex.mypokedex">
                                <button class="registerAll btn btn-adjust btn-primary" type="button">
                                    <i class="bi bi-list-check me-2"></i>Register All
                                </button>
                            </cfif>
                            <cfif prc.currEvent EQ "pokedex.mycustompokedex" AND !isNull(prc.custom.getLink()) AND prc.custom.getLink().len()>
                                <a href="#prc.custom.getLink()#" target="_blank" class="btn btn-adjust btn-primary" role="button">
                                    <i class="bi bi-link-45deg me-2"></i>Leekduck
                                </a>
                            </cfif>
                            <button class="pokedexLock btn btn-adjust btn-secondary" type="button">
                                <i class="bi bi-<cfif cookie.keyExists('pokedexLock') AND cookie.pokedexLock EQ true>lock<cfelse>unlock</cfif>"></i>
                                <cfif cookie.keyExists('pokedexLock') AND cookie.pokedexLock EQ true>Locked<cfelse>Unlocked</cfif>
                            </button>
                            <button class="shinyToggle btn btn-adjust <cfif rc.keyExists('shiny') AND rc.shiny>btn-success<cfelse>btn-danger</cfif>" type="button">
                                <i class="bi bi-stars me-2"></i>Shiny
                            </button>
                        </div>
                    <cfelseif prc.currEvent EQ "pokedex.custompokedexlist">
                        <div class="col-11 col-xl-8">
                            <div class="input-group flex-wrap">
                                <select id="customSearch" class="form-select optionalSelect flex-grow-1 flex-sm-grow-0" name="customid"></select>
                                <button id="addCustomPokedex" class="btn btn-primary input-group-btn flex-grow-1 flex-sm-grow-0" data-count="#prc.count#" role="button" type="button">
                                    <i class="bi bi-plus-square me-1"></i>Add
                                </button>
                            </div>
                        </div>
                    <cfelseif "blog.writeform,blog.editform".contains(prc.currEvent)>
                        <button id="submitBlog" role="button" class="ms-auto btn btn-primary">
                            <i class="bi bi-pencil-fill me-2"></i>Write
                        </button>
                    <cfelseif prc.currEvent EQ "stats.overview">
                        <button id="trackStats" role="button" class="btn btn-primary" <cfif dateDiff("d", prc.trainerStatStruct.dateTracked, now()) LT 1>disabled</cfif>>
                            <i class="bi bi-graph-up me-2"></i>Track Stats
                        </button>
                    <cfelseif prc.currEvent EQ "blog.read" AND (session?.securityLevel ?: -10) GTE 50>
                        <a href="/editblog/#encodeForHTML(prc.blog.getId())#" id="editBlog" role="button" class="btn btn-primary">
                            <i class="bi bi-pencil-fill me-2"></i>Edit
                        </a>
                    <cfelseif "home.home,pokemon.detail".contains(prc.currEvent)>
                        <div class="col-11 col-xl-8">
                            <select id="pokemonSearch" class="form-control" name="pokemonid" autocomplete="off">
                                <option></option>
                            </select>
                        </div>
                    <cfelseif prc.currEvent EQ "admin.serverinfo">
                        <button id="showServerInfo" class="btn btn-secondary" role="button" data-bs-toggle="modal" data-bs-target="##serverInfoModal">
                            More Info
                        </button>
                    <cfelse>
                        <button id="placeHolder" role="button" class="btn btn-primary invisible" disabled>
                            place
                        </button>
                    </cfif>
                </div>
            </div>
        </div>
    </nav>

    <!--- Main content --->
    <main class="container-fluid">
        <div class="row">
            <div id="mainSection" class="col-12">
                <div class="mx-sm-1 mx-lg-3">
                    <cfif prc.keyExists('header') AND prc.header.len()>
                        <h2 class="text-center hfs-5 m-0 p-0 fw-bold" id="bodyHeader">
                            #prc?.header ?: ''#
                        </h2>
                    </cfif>
                    #view("/views/fragment/alert")#
                    #view()#
                </div>
            </div>
        </div>
    </main>
    
    #view(view="/views/modal/loading")#

    <div id="confirmModalDiv"></div>

    <!--- Dont manipulate the entire dom body! this overrides everything in js --->
    <div id="loadedModal"></div>
    
    <!--- toasts live here --->
    <div id="toastsDiv"></div>
    
    <!--- Offcanvas side bar --->
    <nav class="navbar navbar-dark offcanvas-nav-wrapper">
    <div 
        class="offcanvas offcanvas-start text-bg-dark " 
        data-bs-scroll="false" 
        tabindex="-1" 
        id="sideNavbar"
        aria-labelledby="sideNavbarLabel"
    >
        <div class="offcanvas-header pe-0 pt-sm-3 pt-md-2 pb-2 d-flex align-items-center">
            <img src="/includes/images/favicon.svg?v=#getSetting('favIcoVersion')#" alt="POGO Tracker Logo" class="logo me-1">
            <h1 class="fs-4 m-0" id="sideNavbarLabel">POGO Tracker</h1> 
            <button type="button" id="closeSideNavbar" class="btn-close btn-close-white ms-auto me-3" data-bs-dismiss="offcanvas" aria-label="Close"></button>
        </div>
        <div class="offcanvas-body d-flex pt-0">
            <ul class="navbar-nav flex-grow-1">
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currHandler EQ "home">active</cfif>" href="/">
                        <i class="bi bi-house-fill me-2 navIcon"></i>Home
                    </a>
                </li>
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currEvent EQ "pokedex.mypokedex">active</cfif>" href="/mypokedex">
                        <i class="bi bi-ui-checks-grid me-2 navIcon"></i>Pokedex
                    </a>
                </li>
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currEvent EQ "pokedex.myshadowpokedex">active</cfif>" href="/myshadowpokedex">
                        <i class="bi bi-fire me-2 navIcon"></i>Shadow Pokedex
                    </a>
                </li>
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currEvent EQ "pokedex.custompokedexlist" OR prc.currEvent EQ "pokedex.mycustompokedex">active</cfif>" href="/custompokedexlist">
                        <i class="bi bi-pencil-fill me-2 navIcon"></i>Custom Pokedex
                    </a>
                </li>
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currHandler EQ "trade">active</cfif>" href="/buildtradeplan">
                        <i class="bi bi-arrow-left-right me-2 navIcon"></i>Trade Plan
                    </a>
                </li>
                <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currHandler EQ "stats">active</cfif>" href="/overview">
                        <i class="bi bi-graph-up me-2 navIcon"></i>Stats
                    </a>
                </li>
                <!--- <li class="nav-item d-flex">
                    <a class="nav-link fs-6 w-100 iconHover text-start <cfif prc.currHandler EQ "pvp">active</cfif>" href="/pvp">
                        <i class="bi bi-trophy me-2 navIcon"></i>PVP
                    </a>
                </li> --->
                <cfif (session?.securityLevel ?: -10) GTE 50>
                    <li class="nav-item d-flex">
                        <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currHandler EQ "admin">active</cfif>" href="/admin">
                            <i class="bi bi-tools me-2 navIcon"></i>Admin
                        </a>
                    </li>
                </cfif>
                <cfif (session?.securityLevel ?: -10) GTE 60 AND getSetting('environment') NEQ "production">
                    <li class="nav-item d-flex">
                        <a class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center <cfif prc.currHandler EQ "dev">active</cfif>" href="/dev">
                            <i class="bi bi-code-slash me-2 navIcon"></i>Dev
                        </a>
                    </li>
                </cfif>
                <cfif session?.authenticated ?: false>
                    <li class="nav-item d-flex">
                        <button role="button" id="contactBtn" class="nav-link fs-6 w-100 iconHover text-start d-flex align-items-center">
                            <i class="bi bi-mailbox me-2 navIcon"></i>Contact
                        </button>
                    </li>
                </cfif>
                <cfif session?.authenticated ?: false>
                    <li class="nav-item mt-auto dropup" data-bs-theme="dark">
                        <div id="profileGroup" class="d-flex align-items-center iconHover" data-bs-toggle="dropdown" aria-expanded="false">
                            <img class="profileIcon me-2" id="sidebarIcon" src="#session.iconPath#" alt="#session.iconAlt#">
                            <span id="sidebarUsername">#session.username#</span>
                            <i class="bi bi-three-dots ms-auto navIcon"></i>
                        </div>
                        <ul class="dropdown-menu dropdown-menu-dark mb-2">
                            <li><a class="dropdown-item" href="/profile"><i class="bi bi-person me-1"></i>Profile</a></li>
                            <li><a class="dropdown-item" id="logoutBtn" role="button" href="/logout"><i class="bi bi-door-open me-1"></i>Log Out</a></li>
                        </ul>
                    </li>
                <cfelse>
                    <li class="nav-item mt-auto w-100">
                        <a id="loginBtn" class="btn btn-dark border border-light-subtle w-100 fs-6 d-flex justify-content-left align-items-center" href="/login">
                            <i class="bi bi-person me-2 navIcon"></i>Log In
                        </a>
                    </li>
                </cfif>
            </ul>
        </div>
    </div>
    </nav> 
</div>
#view(view="/views/fragment/data")#
</body>

<!--- JS Lib --->
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>
<script type="text/javascript" defer src="/includes/build/js/lib/multiselect.min.js"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/chart.js@4.4.4/dist/chart.umd.min.js"></script>
<script type="text/javascript" defer src="https://cdnjs.cloudflare.com/ajax/libs/masonry/4.2.2/masonry.pkgd.min.js" integrity="sha512-JRlcvSZAXT8+5SQQAvklXGJuxXTouyq8oIMaYERZQasB8SBDHZaUbeASsJWpk0UUrf89DP3/aefPPrlMR1h1yQ==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script type="text/javascript" defer src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.7.1/jquery.min.js" integrity="sha512-v2CJ7UaYy4JwqLDIrZUI/4hqeoQieOmAZNXBeQyjo21dadnwR+8ZaIJVT8EE2iyI61OV8e6M8PP2/4hpQINQ/g==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script type="text/javascript" defer src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.30.1/moment.min.js" integrity="sha512-QoJS4DOhdmG8kbbHkxmB/rtPdN62cGWXAdAFWWJPvUFF1/zxcPSdAnn4HhYZSIlVoLVEJ0LesfNlusgm2bPfnA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/daterangepicker/daterangepicker.min.js"></script> 
<script type="text/javascript" defer src="https://cdn.datatables.net/v/bs5/dt-2.1.8/b-3.2.0/fh-4.0.1/r-3.0.3/datatables.min.js"></script>
<script type="text/javascript" defer src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

<cfif prc.keyExists('pokemonSearch')><script>var pokemonSearchArray = #prc.pokemonSearch#;</script></cfif>
<cfif getSetting('minifiedJS').len()>
    <script type="module" src="/includes/build/js/global.min.js#getSetting('cacheBuster')#"></script>
<cfelse>
    <script type="module" src="/includes/js/global.js#getSetting('cacheBuster')#"></script>
</cfif>
</html>
</cfoutput>