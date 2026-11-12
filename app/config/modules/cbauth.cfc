component {

    function configure() {
        return {
            // Finds trainers and checks credentials (implements cbsecurity.interfaces.IUserService)
            userServiceClass: "services.user",
            // Logged in trainer id - lives as long as the session
            sessionStorage  : "SessionStorage@cbstorages",
            // Loaded trainer - once per request
            requestStorage  : "RequestStorage@cbstorages"
        }
    }

}
