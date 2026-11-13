component singleton accessors="true" {

    property name="cacheBuster" inject="coldbox:setting:cacheBuster";
    property name="cssPath"     inject="coldbox:setting:cssPath";
    property name="environment" inject="coldbox:setting:environment";
    property name="jsPath"      inject="coldbox:setting:jsPath";
    property name="minifiedCSS" inject="coldbox:setting:minifiedCSS";
    property name="minifiedJS"  inject="coldbox:setting:minifiedJS";
    property name="rootPath"    inject="coldbox:setting:rootPath";

    /**
     * Events (handler.action, or handler.* for every action) that need each CDN library
     * jQuery and moment are pulled in by the libraries that depend on them in getVendorLibs
     */
    variables.vendorEvents = {
        chart          : "stats.overview,admin.serverinfo",
        masonry        : "home.home,trainer.viewprofile,stats.overview",
        daterangepicker: "stats.overview",
        datatables     : "admin.*",
        select2        : "home.home,pokemon.index,pokemon.detail,pokedex.custompokedexlist,trade.tradeplanform,trainer.viewprofile",
        multiselect    : "pokedex.custompokedexlist"
    };

    // Our modules, path under jsPath without the minified suffix - rendered into the import map
    variables.jsModules = [
        "alert"       : "/modules/alert",
        "contact"     : "/modules/contact",
        "localstorage": "/modules/localstorage",
        "copy"        : "/modules/copy",
        "escape"      : "/modules/escape",
        "display"     : "/modules/display",
        "fetch"       : "/modules/fetch",
        "form"        : "/modules/form",
        "json"        : "/modules/json",
        "loading"     : "/modules/loading",
        "modals"      : "/modules/modals",
        "multiselect" : "/modules/multiselect",
        "search"      : "/modules/search",
        "socket"      : "/modules/socket",
        "toast"       : "/modules/toast",
        "admin"       : "/handlers/admin",
        "blog"        : "/handlers/blog",
        "home"        : "/handlers/home",
        "login"       : "/handlers/login",
        "pokedex"     : "/handlers/pokedex",
        "pokemon"     : "/handlers/pokemon",
        "stats"       : "/handlers/stats",
        "trade"       : "/handlers/trade",
        "trainer"     : "/handlers/trainer",
        "runtime"     : "/runtime"
    ];

    // Vendored modules, full web path served as is - rendered into the import map
    variables.vendorModules = ["@stomp/stompjs": "/includes/js/vendor/stompjs-7.0.0.esm.js"];

    // Entry modules loaded by a <script src> in a layout - preloadable but left out of the import map
    variables.entryModules = ["global": "/global"];

    function init() {
        variables.preloadMemo = {};
        variables.cssMemo     = {};

        // Comments and strings are matched and thrown away so an import inside them isn't followed.
        // Only the last branch captures, and it wins over the string branch because it starts before the quote.
        variables.importPattern = createObject("java", "java.util.regex.Pattern").compile(
            "//[^\n]*|/\*[\s\S]*?\*/|""(?:[^""\\\n]|\\.)*""|'(?:[^'\\\n]|\\.)*'|`(?:[^`\\]|\\.)*`|\b(?:from|import)\s*[""']([^""'\s]+)[""']"
        );
        return this;
    }

    /**
     * Build each module's URL (exactly as the import map serves it) and file on disk once the settings are injected
     */
    function onDIComplete() {
        variables.modules = [:];

        var localModules = [:];
        localModules.append(variables.jsModules);
        localModules.append(variables.entryModules);
        localModules.each((name, path) => {
            variables.modules[name] = {
                url : "#getJsPath()##path##getMinifiedJS()#.js#getCacheBuster()#",
                file: "#getRootPath()##getJsPath()##path##getMinifiedJS()#.js"
            };
        });

        variables.vendorModules.each((name, path) => {
            variables.modules[name] = {url: path, file: "#getRootPath()##path#"};
        });

        var imports = [:];
        variables.jsModules.each((name) => {
            imports[name] = variables.modules[name].url;
        });
        variables.vendorModules.each((name) => {
            imports[name] = variables.modules[name].url;
        });
        variables.importMapJSON = serializeJSON({"imports": imports});
    }

    /**
     * The import map JSON for <script type="importmap"> - our modules plus vendored ones
     */
    public string function getImportMapJSON() {
        return variables.importMapJSON;
    }

    /**
     * Whether the handler has its own stylesheet - checked on disk once per handler instead of every page render
     *
     * @handler lowercased handler name
     */
    public boolean function hasHandlerCSS(required string handler) {
        if(variables.cssMemo.keyExists(arguments.handler)) {
            return variables.cssMemo[arguments.handler];
        }

        var exists = fileExists("#getRootPath()##getCssPath()#/#arguments.handler##getMinifiedCSS()#.css");

        // Re-checked each time in development so a new stylesheet shows up without a reinit
        if(getEnvironment() != "development") {
            variables.cssMemo[arguments.handler] = exists;
        }
        return exists;
    }

    /**
     * Which CDN libraries the default layout should load for this event
     *
     * @currEvent lowercased handler.action
     */
    public struct function getVendorLibs(required string currEvent) {
        var thisEvent       = arguments.currEvent;
        var handlerWildcard = listFirst(thisEvent, ".") & ".*";
        var libs            = {};
        variables.vendorEvents.each((lib, events) => {
            libs[lib] = listFindNoCase(events, thisEvent) > 0 || listFindNoCase(events, handlerWildcard) > 0;
        });

        libs.moment = libs.daterangepicker;
        libs.jquery = libs.select2 || libs.daterangepicker || libs.datatables;
        return libs;
    }

    /**
     * Module URLs to <link rel="modulepreload"> - the entry module, the current handler's module and everything they statically import
     * Dynamic import() calls are left alone so lazy modules stay lazy
     * URLs are the same ones getImportMapJSON serves so the browser reuses the preloaded copy
     *
     * @entry   module the layout starts from (global or runtime)
     * @handler current handler, skipped when it has no module - same check runtime.js makes against the import map
     */
    public array function getModulePreloads(required string entry, string handler = "") {
        var memoKey = "#arguments.entry#|#arguments.handler#";
        if(variables.preloadMemo.keyExists(memoKey)) return variables.preloadMemo[memoKey];

        var found = [:]; // ordered name -> url
        collectModule(arguments.entry, found);
        if(arguments.handler.len()) collectModule(arguments.handler, found);

        var urls = found.reduce((result, name, moduleURL) => result.append(moduleURL), []);

        // Re-read each time in development so edited imports show up without a reinit
        if(getEnvironment() != "development") variables.preloadMemo[memoKey] = urls;
        return urls;
    }

    /**
     * Add a module and its static imports to found, depth first
     * Names outside the import map (relative paths, missing builds) are skipped since the browser couldn't resolve them either
     */
    private void function collectModule(required string name, required struct found) {
        if(arguments.found.keyExists(arguments.name) || !variables.modules.keyExists(arguments.name)) return;

        var module = variables.modules[arguments.name];
        if(!fileExists(module.file)) return;
        arguments.found[arguments.name] = module.url;

        for(var specifier in getStaticImports(fileRead(module.file, "utf-8"))) {
            collectModule(specifier, arguments.found);
        }
    }

    /**
     * Specifiers a module statically imports (import/export ... from, side effect imports), in source order
     * Imports inside comments or strings and dynamic import() calls are skipped
     *
     * @source JavaScript module source
     */
    public array function getStaticImports(required string source) {
        var specifiers = [];
        var matcher    = variables.importPattern.matcher(arguments.source);
        while(matcher.find()) {
            var specifier = matcher.group(1);
            if(!isNull(specifier)) specifiers.append(specifier);
        }
        return specifiers;
    }

}
