<cfoutput>
<script type="importmap">
    {
        "imports": {
            "alert": "#args.jsPath#/modules/alert#args.minifiedJS#.js#args.cacheBuster#",
            "contact": "#args.jsPath#/modules/contact#args.minifiedJS#.js#args.cacheBuster#",
            "cookie": "#args.jsPath#/modules/cookie#args.minifiedJS#.js#args.cacheBuster#",
            "copy": "#args.jsPath#/modules/copy#args.minifiedJS#.js#args.cacheBuster#",
            "display": "#args.jsPath#/modules/display#args.minifiedJS#.js#args.cacheBuster#",
            "fetch": "#args.jsPath#/modules/fetch#args.minifiedJS#.js#args.cacheBuster#",
            "form": "#args.jsPath#/modules/form#args.minifiedJS#.js#args.cacheBuster#",
            "loading": "#args.jsPath#/modules/loading#args.minifiedJS#.js#args.cacheBuster#",
            "modals": "#args.jsPath#/modules/modals#args.minifiedJS#.js#args.cacheBuster#",
            "multiselect": "#args.jsPath#/modules/multiselect#args.minifiedJS#.js#args.cacheBuster#",
            "search": "#args.jsPath#/modules/search#args.minifiedJS#.js#args.cacheBuster#",
            "socket": "#args.jsPath#/modules/socket#args.minifiedJS#.js#args.cacheBuster#",
            "toast": "#args.jsPath#/modules/toast#args.minifiedJS#.js#args.cacheBuster#",

            "admin": "#args.jsPath#/handlers/admin#args.minifiedJS#.js#args.cacheBuster#",
            "blog": "#args.jsPath#/handlers/blog#args.minifiedJS#.js#args.cacheBuster#",
            "home": "#args.jsPath#/handlers/home#args.minifiedJS#.js#args.cacheBuster#",
            "login": "#args.jsPath#/handlers/login#args.minifiedJS#.js#args.cacheBuster#",
            "pokedex": "#args.jsPath#/handlers/pokedex#args.minifiedJS#.js#args.cacheBuster#",
            "pokemon": "#args.jsPath#/handlers/pokemon#args.minifiedJS#.js#args.cacheBuster#",
            "stats": "#args.jsPath#/handlers/stats#args.minifiedJS#.js#args.cacheBuster#",
            "trade": "#args.jsPath#/handlers/trade#args.minifiedJS#.js#args.cacheBuster#",
            "trainer": "#args.jsPath#/handlers/trainer#args.minifiedJS#.js#args.cacheBuster#",

            "runtime": "#args.jsPath#/runtime#args.minifiedJS#.js#args.cacheBuster#",
            "@stomp/stompjs": "https://ga.jspm.io/npm:@stomp/stompjs@7.0.0/esm6/index.js"
        }
    }
</script>
</cfoutput>