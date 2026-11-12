component {

    function configure() {
        return {
            loadPaths              : ["#controller.getSetting("rootPath")#/lib/jsoup-1.23.2.jar"], // The jars to load - jsoup for html parsing
            loadColdFusionClassPath: false, // Do not load the engine's own classes with the loader
            parentClassLoader      : "", // No custom parent class loader
            sourceDirectories      : [], // No java source to compile
            compileDirectory       : "models/javaloader/tmp", // Only used when sourceDirectories is set
            trustedSource          : true // The jars do not change at runtime - skip checking them for changes
        }
    }

}
