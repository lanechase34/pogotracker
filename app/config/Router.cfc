/**
 * This is your application router.  From here you can controll all the incoming routes to your application. 
 *
 * https://coldbox.ortusbooks.com/the-basics/routing
 */
component {

    function configure() {
        setFullRewrites(true);

        // Healthcheck
        route('/healthcheck').to('main.healthCheck');

        // Unauthorized
        route('/unauthorized').to('error.unauthorized');

        // Exception
        route('/exception').to('error.displayException');

        // Login
        route('/register').to('login.registrationForm');
        route('/login/:action').toHandler('login');
        route('/login').to('login.loginForm');
        route('/forgot').to('login.forgotPasswordForm');
        route('/reset/:resetCode').to('login.resetPasswordForm');
        route('/verify').to('login.verifyForm');
        route('/verifyrecaptcha').to('login.verifyRecaptcha');
        route('/logout').to('login.logout');

        // Home
        route('/home/:action').toHandler('home');
        route('/home').to('home.home');
        route('/contact').to('home.contactForm');

        // Blog
        route('/readblog/:blogheader?').to('blog.read');
        route('/editblog/:blogid?').to('blog.editForm');
        route('/blog/:action?').toHandler('blog');

        // Trade
        route('/buildtradeplan').to('trade.tradePlanForm');
        route('/tradeplan').to('trade.tradePlan');
        route('/trade/:action?').toHandler('trade');

        // Pokedex
        route('/mypokedex').to('pokedex.myPokedex');
        route('/myshadowpokedex').to('pokedex.myShadowPokedex');
        route('/custompokedexlist').to('pokedex.customPokedexList');
        route('/mycustompokedex/:customid').to('pokedex.myCustomPokedex');
        route('/pokedex/:action?').toHandler('pokedex');

        // Stats
        route('/overview/:trainerid?').to('stats.overview');
        route('/stats/:action?').toHandler('stats');

        // Trainer
        route('/profile/:trainerid?').to('trainer.viewProfile');
        route('/trainer/:action?').toHandler('trainer');

        // Friend
        route('/friend/:action?').toHandler('friend');

        // Pokemon
        route('/pokemon/updateDetail').to('pokemon.updateDetail');
        route('/pokemon/:ses').to('pokemon.detail');
        route('/pokemon/:action?').toHandler('pokemon');

        // Admin
        route('/admin/:action?').toHandler('admin');

        // Dev
        route('/dev/:action?').toHandler('dev');

        // Main
        route('/main/:action?').toHandler('main');

        // Empty route -> home page
        route('/').to('home.home');

        // Anything else - not found
        route('{wildcard}').to('main.notFound');
    }

}
