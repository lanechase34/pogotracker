component {

    function configure() {
        // Paginated select2 searches - page numbers start at 1
        var searchConstraint = {
            required: false,
            type    : "string",
            size    : "1..100"
        };
        var pageConstraint = {
            required: true,
            type    : "integer",
            min     : 1,
            max     : 100000
        };

        // Your own stats, or a friend's
        var friendStatsConstraint = {
            trainerid: {
                required    : true,
                type        : "numeric",
                entityExists: {entityName: "trainer", pk: true},
                friendCheck : {accepted: true, allowSelf: true}
            }
        };

        // A log from the log viewer's list - only listed names resolve, so a crafted name can't reach outside the log folders
        var logFileConstraint = {
            required: true,
            type    : "string",
            size    : "1..255",
            udf     : (value, target) => {
                return application.wirebox
                    .getInstance("services.admin")
                    .resolveLogPath(arguments.value)
                    .len() > 0;
            }
        };


        // Largest value an integer column holds
        var maxInt = 2147483647;

        // A log table's time range - a key of pagination.getRanges
        var rangeConstraint = {
            required: true,
            type    : "string",
            udf     : (value, target) => {
                return application.wirebox
                    .getInstance("services.pagination")
                    .getRanges()
                    .keyExists(arguments.value);
            }
        };

        // A custom pokedex the trainerid param's trainer created, or a public one
        var customAccessConstraint = {
            required    : true,
            type        : "numeric",
            entityExists: {
                entityName  : "custom",
                pk          : true,
                ownerField  : "trainerid",
                publicColumn: "public"
            }
        };

        // The pokemon ids in a custom pokedex
        var customPokemonConstraint = {
            required : true,
            type     : "array",
            size     : "1..100",
            arrayItem: {type: "integer", min: 1}
        };

        var loginHandler = {
            loginForm: {
                email: {
                    required: true,
                    size    : "3..100",
                    type    : "email"
                },
                password: {
                    required: true,
                    size    : "10..50",
                    type    : "string"
                }
            },
            registrationForm: {
                // Make sure username and email are unique
                username: {
                    required           : true,
                    size               : "5..30",
                    type               : "string",
                    regex              : "^[a-zA-Z0-9_]+$",
                    uniqueDatabaseField: {table: "trainer", column: "username"}
                },
                email: {
                    required           : true,
                    size               : "3..100",
                    type               : "email",
                    uniqueDatabaseField: {
                        table          : "trainer",
                        column         : "email",
                        storedLowercase: true
                    }
                },
                password: {
                    required: true,
                    size    : "10..50",
                    type    : "string"
                },
                friendcode: {
                    required           : true,
                    size               : 12,
                    regex              : "^[0-9]+$",
                    type               : "numeric",
                    uniqueDatabaseField: {
                        table          : "trainer",
                        column         : "friendcode",
                        storedLowercase: true
                    }
                },
                icon: {
                    required       : true,
                    type           : "string",
                    fileExistsCheck: {
                        path     : "#controller.getSetting("rootPath")#/includes/images/icons/",
                        extension: controller.getSetting("imageExtension")
                    },
                    // New trainers pick from the base icons only
                    udf: (value, target) => {
                        return application.wirebox.getInstance("services.trainer").isAllowedIcon(arguments.value);
                    }
                }
            },
            verifyForm: {
                code: {
                    required: true,
                    size    : 8,
                    type    : "string"
                }
            },
            forgotPasswordForm: {
                email: {
                    required: true,
                    size    : "3..100",
                    type    : "email",
                    udf     : (value, target) => {
                        return queryExecute(
                            "SELECT 1 FROM trainer WHERE email = :email AND verified = true",
                            {email: {value: lCase(trim(arguments.value)), cfsqltype: "varchar"}}
                        ).recordCount > 0;
                    }
                }
            },
            resetPasswordForm: {
                password: {
                    required: true,
                    size    : "10..50",
                    type    : "string"
                },
                resetCode: {
                    required: true,
                    type    : "string",
                    size    : "1..75"
                }
            },
            resetPasswordLink: {
                resetCode: {
                    required: true,
                    type    : "string",
                    size    : "1..75"
                }
            },
            verifyResend   : {resend: {required: true, type: "boolean"}},
            logout         : {idle: {required: true, type: "boolean"}},
            verifyRecaptcha: {recaptchaToken: {required: true, type: "string"}}
        };

        var homeHandler = {
            "home.contactForm": {
                subject: {
                    required: true,
                    type    : "string",
                    size    : "1..100"
                },
                message: {
                    required: true,
                    type    : "string",
                    size    : "1..2000"
                }
            }
        };

        var blogHandler = {
            "blog.getBlogs": {
                // Each count/offset pair is its own cache entry, so only the pairs the page requests are allowed
                // (blog.js blogFetchStruct count 6 / max 8, and the 6 home.home renders with the page):
                // - 6 or 8 from 0: the sidebar, and the first batch
                // - 2 from 6: home desktop fills its server rendered 6 up to the max of 8
                // - 6 from 6, 12, 18...: Load More on mobile, and from 8, 14, 20... on desktop
                count: {
                    required: true,
                    type    : "integer",
                    inList  : "2,6,8"
                },
                offset: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt,
                    udf     : (value, target) => {
                        if(
                            !isValid("integer", arguments.value) || !isValid(
                                "integer",
                                arguments.target.getCount() ?: ""
                            )
                        ) {
                            return false;
                        }
                        var offset   = val(arguments.value);
                        var pageSize = val(arguments.target.getCount());
                        switch(pageSize) {
                            case 8:
                                return offset == 0;
                            case 2:
                                return offset == 6;
                            case 6:
                                return offset == 0 || (offset >= 6 && [0, 2].contains(offset % 6));
                        }
                        return false;
                    }
                },
                showimage: {required: true, type: "boolean"},
                exclude  : {required: true, type: "numeric"},
                sidebar  : {required: true, type: "boolean"}
            },
            "blog.read": {
                // blog.header is a varchar(100)
                blogheader: {
                    required: true,
                    type    : "string",
                    size    : "1..100"
                }
            },
            "blog.addComment": {
                // comment.comment is a varchar(1000) - checked after blogService.normalizeComment
                comment: {
                    required       : true,
                    type           : "string",
                    size           : "1..1000",
                    requiredMessage: "Please write a comment first.",
                    sizeMessage    : "Comments can be at most 1000 characters.",
                    // The handler counts these toward a comment ban (comments.profanityStrikes)
                    profanityCheck : {}
                },
                blogid: {
                    required    : true,
                    type        : "numeric",
                    min         : 1,
                    entityExists: {entityName: "blog", pk: true}
                }
            },
            "blog.getComments": {
                blogid: {
                    required    : true,
                    type        : "numeric",
                    min         : 1,
                    entityExists: {entityName: "blog", pk: true}
                },
                // Load the comments older than this one
                beforeid: {
                    required: true,
                    type    : "integer",
                    min     : 1,
                    max     : maxInt
                }
            },
            "blog.deleteComment": {
                commentid: {
                    required    : true,
                    type        : "numeric",
                    min         : 1,
                    entityExists: {entityName: "comment", pk: true}
                }
            },
            "blog.write": {
                // The header is the blog's url (blogService.getSlug) - no / or \, which servers refuse even encoded
                blogheader: {
                    required           : true,
                    type               : "string",
                    size               : "1..100",
                    regex              : "^[^/\\]+$",
                    regexMessage       : "The header can't have / or \ in it.",
                    uniqueDatabaseField: {table: "blog", column: "header"}
                },
                blogmeta: {
                    required: true,
                    type    : "string",
                    size    : "1..150"
                },
                blogbodyjson: {
                    required: true,
                    type    : "string",
                    size    : "1..1000000"
                },
                blogbody: {
                    required: true,
                    type    : "string",
                    size    : "1..1000000"
                },
                blogimage   : {required: true, type: "string"},
                blogimagealt: {
                    required: true,
                    type    : "string",
                    size    : "1..100"
                }
            },
            "blog.editForm": {
                blogid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "blog", pk: true}
                }
            },
            "blog.edit": {
                blogid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "blog", pk: true}
                },
                blogmeta: {
                    required: true,
                    type    : "string",
                    size    : "1..150"
                },
                // Unique, ignoring the blog being edited - no / or \ (see blog.write)
                blogheader: {
                    required           : true,
                    type               : "string",
                    size               : "1..100",
                    regex              : "^[^/\\]+$",
                    regexMessage       : "The header can't have / or \ in it.",
                    uniqueDatabaseField: {
                        table       : "blog",
                        column      : "header",
                        excludeField: "blogid"
                    }
                },
                blogbodyjson: {
                    required: true,
                    type    : "string",
                    size    : "1..1000000"
                },
                blogbody: {
                    required: true,
                    type    : "string",
                    size    : "1..1000000"
                },
                blogimage   : {required: false, type: "string"},
                blogimagealt: {
                    required: true,
                    type    : "string",
                    size    : "1..100"
                }
            },
            "blog.getNews": {
                offset: {
                    required    : false,
                    type        : "numeric",
                    min         : 0,
                    max         : 25,
                    defaultValue: 0
                }
            },
            "blog.getEvents": {
                offset: {
                    required    : false,
                    type        : "numeric",
                    min         : 0,
                    max         : 25,
                    defaultValue: 0
                }
            }
        };

        var friendHandler = {
            "friend.decideFriendRequest": {
                friendrequestid: {
                    required: true,
                    type    : "numeric",
                    udf     : (value, target) => {
                        if(isNull(arguments.value) || !isNumeric(arguments.value)) return false;

                        // Load friend request
                        var friendRequest = queryExecute(
                            "SELECT friendid FROM friend WHERE id = :id AND accepted = false",
                            {id: {value: arguments.value, cfsqltype: "integer"}}
                        );
                        if(!friendRequest.recordCount) return false;

                        // Only a pending request, and only the trainer it was sent to can decide it
                        var auth = application.wirebox.getInstance("authenticationService@cbauth");
                        return auth.isLoggedIn() && friendRequest.friendid == auth.getUserId();
                    }
                },
                accept: {required: true, type: "boolean"}
            },
            "friend.sendFriendRequest": {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {}
                },
                // Not yourself, and no friend request either way yet (accepted or pending)
                friendid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "trainer", pk: true},
                    friendCheck : {
                        accepted    : false,
                        isFriend    : false,
                        trainerField: "trainerid"
                    }
                }
            },
            "friend.searchFriends": {search: searchConstraint, page: pageConstraint}
        };

        var pokedexHandler = {
            "pokedex.myPokedex": {
                region: {
                    required    : true,
                    type        : "string",
                    entityExists: {entityName: "generation", column: "region"}
                },
                shiny: {required: true, type: "boolean"}
            },
            "pokedex.myShadowPokedex" : {shiny: {required: true, type: "boolean"}},
            "pokedex.myCostumePokedex": {shiny: {required: true, type: "boolean"}},
            "pokedex.getPokedex"      : {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {}
                },
                // A region, or the Mega/Giga pokedex - the shadow and costume pokedexes aren't split by region, so theirs is ignored
                region: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        var ignored = [
                            arguments.target.getShadow() ?: false,
                            arguments.target.getCostume() ?: false
                        ].some((flag) => {
                            return isBoolean(flag) && flag;
                        });
                        return ignored
                        || ["mega", "giga"].contains(lCase(arguments.value))
                        || !isNull(
                            application.wirebox.getInstance("services.generation").getFromRegion(arguments.value)
                        );
                    }
                },
                form   : {required: true, type: "boolean"},
                shiny  : {required: true, type: "boolean"},
                hundo  : {required: true, type: "boolean"},
                shadow : {required: true, type: "boolean"},
                costume: {required: true, type: "boolean"}
            },
            "pokedex.myCustomPokedex": {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {}
                },
                customid: customAccessConstraint,
                shiny   : {required: true, type: "boolean"}
            },
            "pokedex.getCustomPokedex": {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {}
                },
                customid: customAccessConstraint,
                shiny   : {required: true, type: "boolean"},
                hundo   : {required: true, type: "boolean"}
            },
            "pokedex.customPokedexList": {
                offset: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                }
            },
            "pokedex.addCustomPokedex": {
                name: {
                    required: true,
                    type    : "string",
                    size    : "5..100"
                },
                public : {required: true, type: "boolean"},
                pokemon: customPokemonConstraint
            },
            "pokedex.editCustomPokedexForm": {
                customid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {
                        entityName   : "custom",
                        pk           : true,
                        belongsToUser: true
                    }
                }
            },
            "pokedex.editCustomPokedex": {
                customid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {
                        entityName   : "custom",
                        pk           : true,
                        belongsToUser: true
                    }
                },
                name: {
                    required: true,
                    type    : "string",
                    size    : "5..100"
                },
                public : {required: true, type: "boolean"},
                pokemon: customPokemonConstraint
            },
            "pokedex.deleteCustomPokedex": {
                customid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {
                        entityName   : "custom",
                        pk           : true,
                        belongsToUser: true
                    }
                }
            },
            "pokedex.register": {
                pokemonid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "pokemon", pk: true},
                    // At least one flag has to be sent
                    udf         : (value, target) => {
                        var sent = arguments.target.getMemento();
                        return [
                            "caught",
                            "shiny",
                            "hundo",
                            "shadow",
                            "shadowshiny"
                        ].some((flag) => {
                            return sent.keyExists(flag) && isSimpleValue(sent[flag]) && len(sent[flag]);
                        });
                    }
                },
                // Only the flags being changed are sent
                caught     : {required: false, type: "boolean"},
                shiny      : {required: false, type: "boolean"},
                hundo      : {required: false, type: "boolean"},
                shadow     : {required: false, type: "boolean"},
                shadowshiny: {required: false, type: "boolean"}
            },
            "pokedex.registerAll": {
                region: {
                    required    : true,
                    type        : "string",
                    entityExists: {entityName: "generation", column: "region"}
                },
                shiny: {required: true, type: "boolean"}
            },
            "pokedex.searchCustom": {search: searchConstraint, page: pageConstraint}
        };

        var statHandler = {
            "stats.track": {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {},
                    // Stats are tracked once a day
                    udf          : (value, target) => {
                        if(!isValid("integer", arguments.value)) return true; // entityExists reports a bad trainer
                        return isNull(
                            application.wirebox
                                .getInstance("services.stats")
                                .getFromDay(trainerid = arguments.value, suppliedDate = now())
                        );
                    }
                },
                // Column limits - xp is a bigint, walked a numeric(10, 2)
                xp: {
                    required: true,
                    type    : "numeric",
                    min     : 0,
                    max     : 9007199254740991
                },
                caught: {
                    required: true,
                    type    : "numeric",
                    min     : 0,
                    max     : maxInt
                },
                spun: {
                    required: true,
                    type    : "numeric",
                    min     : 0,
                    max     : maxInt
                },
                walked: {
                    required: true,
                    type    : "numeric",
                    min     : 0,
                    max     : 99999999.99
                }
            },
            "stat.trackMedalProgress": {
                medal: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "medal", pk: true}
                },
                current: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                }
            },
            "stats.overview": {
                trainerid: friendStatsConstraint.trainerid,
                startDate: {required: true, type: "date"},
                // On or after startDate - a bad date is reported by type
                endDate  : {
                    required: true,
                    type    : "date",
                    udf     : (value, target) => {
                        var startDate = arguments.target.getStartDate() ?: "";
                        if(!isDate(arguments.value) || !isDate(startDate)) return true;
                        return dateCompare(arguments.value, startDate) >= 0;
                    }
                },
                summary: {required: true, type: "boolean"}
            },
            // getPokedexStats, getMedalSummary, getMedalProgress, topDeltas
            "stats.friendStats": friendStatsConstraint,
            "stats.leaderboard": {
                // Goes into the leaderboard SQL as a column - only the stat columns
                stat: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["xp", "caught", "spun", "walked"].contains(lCase(arguments.value));
                    }
                }
            }
        };

        var tradeHandler = {
            "trade.tradePlan": {
                friend: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "trainer", pk: true},
                    friendCheck : {accepted: true}
                },
                region: {
                    required    : false,
                    type        : "string",
                    entityExists: {entityName: "generation", column: "region"}
                },
                // Yours or public - and exactly one of region or customid (-1 when not given)
                customid: {
                    required    : false,
                    type        : "numeric",
                    entityExists: {
                        entityName   : "custom",
                        pk           : true,
                        belongsToUser: true,
                        publicColumn : "public"
                    },
                    udf: (value, target) => {
                        var hasCustom = isNumeric(arguments.value) && arguments.value > 0;
                        var hasRegion = len(arguments.target.getRegion() ?: "") > 0;
                        return hasCustom != hasRegion;
                    }
                },
                shiny: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return arguments.value == "off" || arguments.value == "on";
                    }
                }
            }
        };

        // A username/email/friendcode in use, or a security level that can't be given
        var profileTakenMessage = "Username/email already taken. Please use another.";

        var trainerHandler = {
            "trainer.viewProfile": {
                trainerid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "trainer", pk: true},
                    friendCheck : {accepted: true}
                }
            },
            // Trainers edit their own profile, admins can edit anyone's (but no one who outranks them) plus the admin only fields
            "trainer.updateProfile": {
                trainerid: {
                    required     : true,
                    type         : "numeric",
                    entityExists : {entityName: "trainer", pk: true},
                    securityCheck: {noHigherLevel: true}
                },
                username: {
                    required           : true,
                    size               : "5..30",
                    type               : "string",
                    regex              : "^[a-zA-Z0-9_]+$",
                    uniqueDatabaseField: {
                        table       : "trainer",
                        column      : "username",
                        excludeField: "trainerid"
                    },
                    uniqueDatabaseFieldMessage: profileTakenMessage
                },
                email: {
                    required           : true,
                    size               : "3..100",
                    type               : "email",
                    uniqueDatabaseField: {
                        table          : "trainer",
                        column         : "email",
                        excludeField   : "trainerid",
                        storedLowercase: true
                    },
                    uniqueDatabaseFieldMessage: profileTakenMessage
                },
                password: {
                    type: "string",
                    udf : (value, target) => {
                        if(isNull(arguments.value)) return true; // optional - a blank password keeps the current one
                        return arguments.value.len() <= 50 && arguments.value.len() >= 10; // if it is set, check length
                    }
                },
                // Changing your own email or password - prove it's you first
                currentPassword: {
                    passwordCheck       : {trainerField: "trainerid"},
                    passwordCheckMessage: "Current password is incorrect."
                },
                friendcode: {
                    required           : false,
                    size               : 12,
                    regex              : "^[0-9]+$",
                    type               : "numeric",
                    securityCheck      : {adminOnly: true},
                    uniqueDatabaseField: {
                        table          : "trainer",
                        column         : "friendcode",
                        excludeField   : "trainerid",
                        storedLowercase: true
                    },
                    uniqueDatabaseFieldMessage: profileTakenMessage
                },
                // Everything below developer - developer is only ever set in the database
                securityLevel: {
                    type         : "numeric",
                    securityCheck: {adminOnly: true},
                    udf          : (value, target) => {
                        return application.wirebox
                            .getInstance("services.trainer")
                            .getAssignableLevels()
                            .keyExists(arguments.value);
                    },
                    udfMessage: profileTakenMessage
                },
                // Only icons the edit form offers this trainer - base icons plus their unlocked ones
                icon: {
                    required       : true,
                    type           : "string",
                    fileExistsCheck: {
                        path     : "#controller.getSetting("rootPath")#/includes/images/icons/",
                        extension: controller.getSetting("imageExtension")
                    },
                    udf: (value, target) => {
                        var trainerid = arguments.target.getTrainerid() ?: "";
                        if(!isValid("integer", trainerid)) return true; // entityExists reports a bad trainer

                        var trainerService = application.wirebox.getInstance("services.trainer");
                        try {
                            return trainerService.isAllowedIcon(arguments.value, trainerid);
                        }
                        catch(TrainerNotFound e) {
                            return true;
                        }
                    },
                    udfMessage: "Invalid profile update. That icon is not unlocked."
                },
                verified: {
                    type         : "string",
                    securityCheck: {adminOnly: true},
                    udf          : (value, target) => {
                        if(isNull(arguments.value)) return true;
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                commentBanned: {
                    type         : "string",
                    securityCheck: {adminOnly: true},
                    udf          : (value, target) => {
                        if(isNull(arguments.value)) return true;
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                defaultView: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return controller.getSetting("viewMap").keyExists(arguments.value);
                    }
                },
                defaultRegion: {
                    required    : true,
                    type        : "string",
                    entityExists: {entityName: "generation", column: "region"}
                },
                defaultPage: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return controller.getSetting("pageMap").keyExists(arguments.value);
                    }
                }
            }
        };

        var pokemonHandler = {
            "pokemon.search"           : {search: searchConstraint, page: pageConstraint},
            "pokemon.getPreviousEvents": {
                ses: {
                    required: true,
                    type    : "string",
                    size    : "1..150"
                },
                offset: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                }
            },
            "pokemon.detail": {
                ses: {
                    required: true,
                    type    : "string",
                    size    : "1..150"
                }
            },
            "pokemon.updateDetail": {
                pokemonid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "pokemon", pk: true}
                },
                liveSwitch: {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                shinySwitch: {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                shadowSwitch: {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                shinyShadowSwitch: {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["off", "on"].contains(arguments.value);
                    }
                },
                tradableSwitch: {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["off", "on"].contains(arguments.value);
                    }
                }
            }
        };

        var adminHandler = {
            editTrainer: {
                trainerid: {
                    required    : true,
                    type        : "numeric",
                    entityExists: {entityName: "trainer", pk: true}
                }
            },
            "admin.getPokemon": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                costume           : {required: false, type: "boolean"},
                "search[value]"   : searchConstraint,
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 4
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                },
                "order[1][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 4
                },
                "order[1][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                }
            },
            "admin.getLogChunk": {
                filename: logFileConstraint,
                offset  : {
                    required: true,
                    type    : "integer",
                    min     : -1
                },
                direction: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["forward", "backward"].contains(arguments.value);
                    }
                }
            },
            "admin.searchLog": {
                filename: logFileConstraint,
                query   : {
                    required: true,
                    type    : "string",
                    size    : "1..200"
                },
                offset: {
                    required: true,
                    type    : "integer",
                    min     : -1
                },
                direction: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["forward", "backward"].contains(arguments.value);
                    }
                }
            },
            "admin.getAudits": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                range             : rangeConstraint,
                "search[value]"   : searchConstraint,
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 6
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                }
            },
            "admin.getComments": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                "search[value]"   : searchConstraint,
                // Sortable columns - posted, post, trainer (blogService.getCommentTable)
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 2
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                },
                // 0 for every post
                blogid: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                }
            },
            "admin.getTrainers": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                "search[value]"   : searchConstraint,
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 1,
                    max     : 6
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                }
            },
            "admin.getRequests": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                range             : rangeConstraint,
                "search[value]"   : searchConstraint,
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 8
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                }
            },
            "admin.getBugs": {
                draw: {
                    required: true,
                    type    : "numeric",
                    min     : 1
                },
                length: {
                    required: true,
                    type    : "integer",
                    min     : 10,
                    max     : 100
                },
                start: {
                    required: true,
                    type    : "integer",
                    min     : 0,
                    max     : maxInt
                },
                range             : rangeConstraint,
                "search[value]"   : searchConstraint,
                "order[0][column]": {
                    required: false,
                    type    : "integer",
                    min     : 0,
                    max     : 5
                },
                "order[0][dir]": {
                    required: false,
                    type    : "string",
                    udf     : (value, target) => {
                        return ["asc", "desc"].contains(arguments.value);
                    }
                }
            },
            "admin.runTask": {
                scheduler: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        return application.wirebox.getInstance("coldbox:schedulerService").hasScheduler(arguments.value);
                    }
                },
                // A task of that scheduler
                name: {
                    required: true,
                    type    : "string",
                    udf     : (value, target) => {
                        var schedulerService = application.wirebox.getInstance("coldbox:schedulerService");
                        var scheduler        = arguments.target.getScheduler() ?: "";
                        return isSimpleValue(scheduler)
                        && schedulerService.hasScheduler(scheduler)
                        && schedulerService.getSchedulers()[scheduler].hasTask(arguments.value);
                    }
                }
            }
        };

        var generic = {
            audit: {
                ip: {
                    required: true,
                    type    : "string",
                    size    : "1..45",
                    regex   : "^[0-9a-fA-F.:]+$"
                },
                event: {
                    required: true,
                    type    : "string",
                    size    : "1..250"
                },
                detail   : {required: false, type: "string"},
                agent    : {required: true, type: "string"},
                trainerid: {required: true, type: "numeric"}
            }
        };

        var result = {};
        result.append(loginHandler);
        result.append(homeHandler);
        result.append(blogHandler);
        result.append(friendHandler);
        result.append(pokedexHandler);
        result.append(statHandler);
        result.append(tradeHandler);
        result.append(trainerHandler);
        result.append(pokemonHandler);
        result.append(adminHandler);
        result.append(generic);
        return {sharedConstraints: result};
    }

}
