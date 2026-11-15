component extends="tests.resources.baseTest" asyncAll="true" {

    function beforeAll() {
        super.beforeAll();
        profanityService = getInstance("services.profanity");
    }

    function run() {
        describe("Profanity service", () => {
            it("Blocks banned words in any case", () => {
                expect(profanityService.containsProfanity("this is shit")).toBeTrue();
                expect(profanityService.containsProfanity("SHIT happens")).toBeTrue();
                expect(profanityService.containsProfanity("what a bunch of shits")).toBeTrue();
            });

            it("Blocks the usual ways around a word list", () => {
                // Stretched letters, punctuation between letters, leetspeak, accents and zero width characters
                expect(profanityService.containsProfanity("fuuuuck")).toBeTrue();
                expect(profanityService.containsProfanity("f.u.c.k this")).toBeTrue();
                expect(profanityService.containsProfanity("sh1t")).toBeTrue();
                expect(profanityService.containsProfanity("a$$hole")).toBeTrue();
                expect(profanityService.containsProfanity("fück")).toBeTrue();
                expect(profanityService.containsProfanity("fu#chr(8203)#ck")).toBeTrue();
            });

            it("Blocks compound and multi word entries from the list", () => {
                expect(profanityService.containsProfanity("motherfucker")).toBeTrue();
                expect(profanityService.containsProfanity("a blow   job")).toBeTrue();
            });

            it("Lets through the words the profanity.allowedWords setting allows", () => {
                // Poke Balls - balls is on the package's list
                expect(profanityService.containsProfanity("Out of Ultra Balls again")).toBeFalse();
                expect(profanityService.containsProfanity("Pawniard evolves at the pawn shop")).toBeFalse();
            });

            it("Leaves innocent words that contain a banned one alone", () => {
                for(
                    var text in [
                        "I passed my class",
                        "Scunthorpe",
                        "shiitake mushrooms",
                        "an assassin",
                        "assess the grass",
                        "cocktail hour",
                        "a cumulative total",
                        "Great raid today, thanks all!",
                        ""
                    ]
                ) {
                    expect(profanityService.containsProfanity(text)).toBeFalse(text);
                }
            });
        });
    }

}
