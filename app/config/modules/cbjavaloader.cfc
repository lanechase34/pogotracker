component {

    function configure() {
        return {
            loadPaths              : ['#controller.getSetting('basePath')#/lib/jsoup-1.21.2.jar'], // A single path, and array of paths or a single Jar
            loadColdFusionClassPath: false, // Load ColdFusion classes with loader
            parentClassLoader      : '', // Attach a custom class loader as a parent
            sourceDirectories      : [], // Directories that contain Java source code that are to be dynamically compiled
            compileDirectory       : 'models/javaloader/tmp', // the directory to build the .jar file for dynamic compilation in, defaults to ./tmp
            trustedSource          : true // Whether or not the source is trusted, i.e. it is going to change? Defaults to false, so changes will be recompiled and loaded
        }
    }

}
