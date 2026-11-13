component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        assetsService = getInstance("services.assets");

        imports   = deserializeJSON(assetsService.getImportMapJSON()).imports;
        globalURL = "#assetsService.getJsPath()#/global#assetsService.getMinifiedJS()#.js#assetsService.getCacheBuster()#";

        // URL -> module name, so preload results can be asserted by name
        urlToName = {};
        imports.each((name, moduleURL) => {
            urlToName[moduleURL] = name;
        });
        urlToName[globalURL] = "global";
    }

    function afterAll() {
        super.afterAll();
    }

    /**
     * Module names getModulePreloads returns, in order
     */
    private array function preloadNames(required string entry, string handler = "") {
        return assetsService
            .getModulePreloads(entry = arguments.entry, handler = arguments.handler)
            .map((moduleURL) => urlToName[moduleURL] ?: "unmapped:#moduleURL#");
    }

    /**
     * Disk path behind a URL from the import map
     */
    private string function fileForURL(required string moduleURL) {
        return assetsService.getRootPath() & listFirst(arguments.moduleURL, "?");
    }

    /**
     * Module names for every built JS file in a folder under jsPath
     */
    private array function modulesOnDisk(required string folder) {
        var suffix = "#assetsService.getMinifiedJS()#.js";
        return directoryList(
            path     = "#assetsService.getRootPath()##assetsService.getJsPath()#/#arguments.folder#",
            recurse  = false,
            listInfo = "name",
            filter   = "*#suffix#"
        ).map((fileName) => left(fileName, len(fileName) - len(suffix)));
    }

    function run() {
        describe("Assets Service", () => {
            describe("getImportMapJSON", () => {
                it("Is valid JSON with an imports struct", () => {
                    var json = assetsService.getImportMapJSON();
                    expect(isJSON(json)).toBeTrue("Import map is not valid JSON: #json#");
                    expect(deserializeJSON(json)).toHaveKey("imports");
                });

                it("Lists every module and handler script on disk", () => {
                    for(var folder in ["modules", "handlers"]) {
                        for(var name in modulesOnDisk(folder)) {
                            expect(imports).toHaveKey(
                                name,
                                "#folder#/#name# exists on disk but is missing from the import map"
                            );
                            expect(imports[name]).toInclude("/#folder#/#name#");
                        }
                    }
                });

                it("Points every entry at a file that exists", () => {
                    imports.each((name, moduleURL) => {
                        expect(fileExists(fileForURL(moduleURL))).toBeTrue("Import map entry #name# points at a missing file: #moduleURL#");
                    });
                });

                it("Includes the vendored stompjs module without a cache buster", () => {
                    expect(imports).toHaveKey("@stomp/stompjs");
                    expect(imports["@stomp/stompjs"]).toBe("/includes/js/vendor/stompjs-7.0.0.esm.js");
                });

                it("Leaves the global entry module out", () => {
                    expect(imports).notToHaveKey("global");
                });

                it("Gives local modules the cache buster", () => {
                    expect(imports.alert).toBe("#assetsService.getJsPath()#/modules/alert#assetsService.getMinifiedJS()#.js#assetsService.getCacheBuster()#");
                });
            });

            describe("getStaticImports", () => {
                it("Finds named, default, namespace and side effect imports", () => {
                    var source = "import { a } from 'alert';#chr(10)#import b from ""form"";#chr(10)#import * as c from 'fetch';#chr(10)#import 'toast';";
                    expect(assetsService.getStaticImports(source)).toBe(["alert", "form", "fetch", "toast"]);
                });

                it("Finds imports in minified source with no whitespace", () => {
                    expect(assetsService.getStaticImports("import{a as b}from""alert"";import""form"";const x=1;")).toBe(["alert", "form"]);
                });

                it("Finds re-exports", () => {
                    expect(assetsService.getStaticImports("export * from 'alert'; export { x } from ""form"";")).toBe(["alert", "form"]);
                });

                it("Keeps scoped package specifiers whole", () => {
                    expect(assetsService.getStaticImports("import { Client } from '@stomp/stompjs';")).toBe(["@stomp/stompjs"]);
                });

                it("Skips imports inside line and block comments", () => {
                    var source = "// import a from 'alert'#chr(10)#/* import b from 'form'#chr(10)#import c from 'fetch' */#chr(10)#import d from 'toast';";
                    expect(assetsService.getStaticImports(source)).toBe(["toast"]);
                });

                it("Skips imports inside strings and template literals", () => {
                    var source = "const a = ""import x from 'alert'""; const b = 'import y from ""form""'; const c = `import z from 'fetch'`; import d from 'toast';";
                    expect(assetsService.getStaticImports(source)).toBe(["toast"]);
                });

                it("Skips dynamic import() calls", () => {
                    expect(assetsService.getStaticImports("import('admin').then(() => {}); import(name);")).toBeEmpty();
                });

                it("Is not thrown off by // inside a string", () => {
                    expect(assetsService.getStaticImports("const u = ""https://example.com""; import a from 'alert';")).toBe(["alert"]);
                });
            });

            describe("getModulePreloads", () => {
                it("Returns the global entry first, then everything it statically imports", () => {
                    var names = preloadNames("global");
                    expect(names[1]).toBe("global");
                    for(
                        var name in [
                            "contact",
                            "form",
                            "loading",
                            "login",
                            "runtime",
                            "toast",
                            "fetch",
                            "alert",
                            "escape"
                        ]
                    ) {
                        expect(names).toInclude(name);
                    }
                });

                it("Leaves out handler modules nothing on the page imports", () => {
                    var names = preloadNames("global");
                    for(
                        var name in [
                            "admin",
                            "pokedex",
                            "stats",
                            "socket",
                            "@stomp/stompjs"
                        ]
                    ) {
                        expect(names).notToInclude(name);
                    }
                });

                it("Adds the handler module and its tree, including vendored modules", () => {
                    var names = preloadNames("global", "admin");
                    for(
                        var name in [
                            "admin",
                            "socket",
                            "@stomp/stompjs",
                            "json",
                            "copy",
                            "localstorage"
                        ]
                    ) {
                        expect(names).toInclude(name);
                    }
                });

                it("Follows a handler that imports another handler", () => {
                    var names = preloadNames("global", "home");
                    for(var name in ["home", "blog", "stats", "search"]) {
                        expect(names).toInclude(name);
                    }
                });

                it("Ignores a handler with no module", () => {
                    expect(preloadNames("global", "dev")).toBe(preloadNames("global"));
                    expect(preloadNames("global", "notahandler")).toBe(preloadNames("global"));
                });

                it("Starts from runtime for the basic layout", () => {
                    var names = preloadNames("runtime", "login");
                    expect(names[1]).toBe("runtime");
                    for(var name in ["login", "form", "fetch"]) {
                        expect(names).toInclude(name);
                    }
                    expect(names).notToInclude("global");
                });

                it("Never repeats a URL", () => {
                    for(
                        var handler in [
                            "admin",
                            "home",
                            "pokedex",
                            "stats",
                            "trade",
                            "trainer",
                            "pokemon",
                            "blog"
                        ]
                    ) {
                        var urls = assetsService.getModulePreloads(entry = "global", handler = handler);
                        var seen = {};
                        for(var moduleURL in urls) {
                            expect(seen).notToHaveKey(moduleURL, "#moduleURL# preloaded twice for #handler#");
                            seen[moduleURL] = true;
                        }
                    }
                });

                it("Only returns URLs the import map serves, plus the global entry", () => {
                    for(
                        var handler in [
                            "admin",
                            "home",
                            "pokedex",
                            "stats",
                            "trade",
                            "trainer",
                            "pokemon",
                            "blog"
                        ]
                    ) {
                        for(var name in preloadNames("global", handler)) {
                            expect(name).notToInclude("unmapped:", "Preload for #handler# is not an import map URL");
                        }
                    }
                });

                it("Returns nothing for an unknown entry", () => {
                    expect(assetsService.getModulePreloads(entry = "notamodule")).toBeEmpty();
                });
            });

            describe("getVendorLibs", () => {
                it("Matches a handler wildcard for any action", () => {
                    var libs = assetsService.getVendorLibs("admin.auditlog");
                    expect(libs.datatables).toBeTrue();
                    expect(libs.jquery).toBeTrue();
                });

                it("Pulls in moment and jQuery for daterangepicker", () => {
                    var libs = assetsService.getVendorLibs("stats.overview");
                    expect(libs.chart).toBeTrue();
                    expect(libs.masonry).toBeTrue();
                    expect(libs.daterangepicker).toBeTrue();
                    expect(libs.moment).toBeTrue();
                    expect(libs.jquery).toBeTrue();
                });

                it("Pulls in jQuery but not moment for select2", () => {
                    var libs = assetsService.getVendorLibs("home.home");
                    expect(libs.select2).toBeTrue();
                    expect(libs.jquery).toBeTrue();
                    expect(libs.moment).toBeFalse();
                });

                it("Loads nothing for an event that needs no libraries", () => {
                    var libs = assetsService.getVendorLibs("pokedex.mypokedex");
                    libs.each((lib, needed) => {
                        expect(needed).toBeFalse("#lib# should not load for pokedex.mypokedex");
                    });
                });

                it("Does not match an action from another handler", () => {
                    expect(assetsService.getVendorLibs("trade.tradeplan").select2).toBeFalse();
                });
            });

            describe("hasHandlerCSS", () => {
                it("Is true for a handler with its own stylesheet", () => {
                    expect(assetsService.hasHandlerCSS("pokedex")).toBeTrue();
                });

                it("Is false for a handler without one", () => {
                    expect(assetsService.hasHandlerCSS("notahandler")).toBeFalse();
                });
            });
        });
    }

}
