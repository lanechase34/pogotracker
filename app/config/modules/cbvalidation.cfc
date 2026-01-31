component {

    function configure() {
        var loginHandler = {
            loginForm: {
                email: {
                    required: true,
                    size    : '3..100',
                    type    : 'email'
                },
                password: {
                    required: true,
                    size    : '10..50',
                    type    : 'string'
                }
            },
            registrationForm: {
                // Make sure username and email are unique
                username: {
                    required           : true,
                    size               : '5..30',
                    type               : 'string',
                    regex              : '^[a-zA-Z0-9_]+$',
                    uniqueDatabaseField: {table: 'trainer', column: 'username'}
                },
                email: {
                    required           : true,
                    size               : '3..100',
                    type               : 'email',
                    uniqueDatabaseField: {table: 'trainer', column: 'email'}
                },
                password: {
                    required: true,
                    size    : '10..50',
                    type    : 'string'
                },
                friendcode: {
                    required           : true,
                    size               : 12,
                    regex              : '^[0-9]+$',
                    type               : 'numeric',
                    uniqueDatabaseField: {table: 'trainer', column: 'friendcode'}
                },
                icon: {
                    required       : true,
                    type           : 'string',
                    fileExistsCheck: {
                        path     : '#controller.getSetting('rootPath')#/includes/images/icons/',
                        extension: controller.getSetting('imageExtension')
                    }
                }
            },
            verifyForm: {
                code: {
                    required: true,
                    size    : 8,
                    type    : 'string'
                }
            },
            forgotPasswordForm: {
                email: {
                    required: true,
                    size    : '3..100',
                    type    : 'email',
                    udf     : (value, target) => {
                        return entityLoad('trainer', {'email': lCase(arguments.value), 'verified': true}).len()
                    }
                }
            },
            resetPasswordForm: {
                password: {
                    required: true,
                    size    : '10..50',
                    type    : 'string'
                },
                resetCode: {required: true, type: 'string'}
            },
            verifyRecaptcha: {recaptchaToken: {required: true, type: 'string'}}
        };

        var homeHandler = {
            'home.contactForm': {
                subject: {
                    required: true,
                    type    : 'string',
                    size    : '1..100'
                },
                message: {
                    required: true,
                    type    : 'string',
                    size    : '1..2000'
                }
            }
        };

        var blogHandler = {
            'blog.get': {
                count: {
                    required: true,
                    type    : 'numeric',
                    min     : 1
                },
                offset: {
                    required: true,
                    type    : 'numeric',
                    min     : 0
                },
                showimage: {required: true, type: 'boolean'},
                exclude  : {required: true, type: 'numeric'},
                sidebar  : {required: true, type: 'boolean'}
            },
            'blog.read': {
                blogheader: {
                    required: true,
                    type    : 'string',
                    size    : '1..255'
                }
            },
            'blog.addComment': {
                comment: {
                    required: true,
                    type    : 'string',
                    size    : '1..1000'
                },
                blogid: {
                    required: true,
                    type    : 'numeric',
                    min     : 1
                }
            },
            'blog.write': {
                blogheader: {
                    required           : true,
                    type               : 'string',
                    uniqueDatabaseField: {table: 'blog', column: 'header'}
                },
                blogmeta: {
                    required: true,
                    type    : 'string',
                    size    : '1..150'
                },
                blogbodyjson: {required: true, type: 'string'},
                blogbody    : {required: true, type: 'string'},
                blogimage   : {required: true, type: 'string'},
                blogimagealt: {
                    required: true,
                    type    : 'string',
                    size    : '1..100'
                }
            },
            'blog.editForm': {
                blogid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'blog', pk: true}
                }
            },
            'blog.edit': {
                blogid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'blog', pk: true}
                },
                blogmeta: {
                    required: true,
                    type    : 'string',
                    size    : '1..150'
                },
                blogheader  : {required: true, type: 'string'},
                blogbodyjson: {required: true, type: 'string'},
                blogbody    : {required: true, type: 'string'},
                blogimage   : {required: false, type: 'string'},
                blogimagealt: {
                    required: true,
                    type    : 'string',
                    size    : '1..100'
                }
            }
        };

        var friendHandler = {
            'friend.decideFriendRequest': {
                friendrequestid: {
                    required: true,
                    type    : 'numeric',
                    udf     : (value, target) => {
                        if(isNull(arguments.value) || !isNumeric(arguments.value)) return false;

                        // Load friend request
                        var friendRequest = entityLoadByPK('friend', arguments.value);
                        if(isNull(friendRequest)) return false;

                        // check that this is the trainer that decides the friend request
                        return friendRequest.getFriend().getId() == session.trainerid;
                    }
                },
                accept: {required: true, type: 'boolean'}
            },
            'friend.sendFriendRequest': {
                trainerid: {
                    required     : true,
                    type         : 'numeric',
                    entityExists : {entityName: 'trainer', pk: true},
                    securityCheck: {}
                },
                friendid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true}
                }
            },
            'friend.searchFriends': {search: {required: false, type: 'string'}, page: {required: true, type: 'numeric'}}
        };

        var pokedexHandler = {
            'pokedex.myPokedex': {
                region: {
                    required    : true,
                    type        : 'string',
                    entityExists: {entityName: 'generation', column: 'region'}
                },
                shiny: {required: true, type: 'boolean'}
            },
            'pokedex.myShadowPokedex': {shiny: {required: true, type: 'boolean'}},
            'pokedex.getPokedex'     : {
                trainerid: {
                    required     : true,
                    type         : 'numeric',
                    entityExists : {entityName: 'trainer', pk: true},
                    securityCheck: {}
                },
                region: {required: false, type: 'string'},
                form  : {required: true, type: 'boolean'},
                shiny : {required: true, type: 'boolean'},
                hundo : {required: true, type: 'boolean'},
                shadow: {required: true, type: 'boolean'}
            },
            'pokedex.myCustomPokedex': {
                trainerid: {
                    required     : true,
                    type         : 'numeric',
                    entityExists : {entityName: 'trainer', pk: true},
                    securityCheck: {}
                },
                customid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'custom', pk: true}
                },
                shiny: {required: true, type: 'boolean'}
            },
            'pokedex.getCustomPokedex': {
                trainerid: {
                    required     : true,
                    type         : 'numeric',
                    entityExists : {entityName: 'trainer', pk: true},
                    securityCheck: {}
                },
                customid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'custom', pk: true}
                },
                shiny: {required: true, type: 'boolean'},
                hundo: {required: true, type: 'boolean'}
            },
            'pokedex.customPokedexList': {
                offset: {
                    required: true,
                    type    : 'numeric',
                    min     : 0
                }
            },
            'pokedex.addCustomPokedex': {
                name: {
                    required: true,
                    type    : 'string',
                    min     : 10
                },
                public : {required: true, type: 'boolean'},
                pokemon: {
                    required: true,
                    type    : 'array',
                    size    : '1..100'
                }
            },
            'pokedex.editCustomPokedexForm': {
                customid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {
                        entityName   : 'custom',
                        pk           : true,
                        belongsToUser: true
                    }
                }
            },
            'pokedex.editCustomPokedex': {
                customid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {
                        entityName   : 'custom',
                        pk           : true,
                        belongsToUser: true
                    }
                },
                name: {
                    required: true,
                    type    : 'string',
                    min     : 10
                },
                public : {required: true, type: 'boolean'},
                pokemon: {
                    required: true,
                    type    : 'array',
                    size    : '1..100'
                }
            },
            'pokedex.deleteCustomPokedex': {
                customid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {
                        entityName   : 'custom',
                        pk           : true,
                        belongsToUser: true
                    }
                }
            },
            'pokedex.register': {
                pokemonid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'pokemon', pk: true}
                },
                caught     : {required: true, type: 'boolean'},
                shiny      : {required: true, type: 'boolean'},
                hundo      : {required: true, type: 'boolean'},
                shadow     : {required: true, type: 'boolean'},
                shadowshiny: {required: true, type: 'boolean'}
            },
            'pokedex.registerAll': {
                region: {
                    required    : true,
                    type        : 'string',
                    entityExists: {entityName: 'generation', column: 'region'}
                },
                shiny: {required: true, type: 'boolean'}
            },
            'pokedex.searchCustom': {search: {required: false, type: 'string'}, page: {required: true, type: 'numeric'}}
        };

        var statHandler = {
            'stats.track': {
                trainerid: {
                    required     : true,
                    type         : 'numeric',
                    entityExists : {entityName: 'trainer', pk: true},
                    securityCheck: {}
                },
                xp    : {required: true, type: 'numeric'},
                caught: {required: true, type: 'numeric'},
                spun  : {required: true, type: 'numeric'},
                walked: {required: true, type: 'numeric'}
            },
            'stat.trackMedalProgress': {
                medal: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'medal', pk: true}
                },
                current: {
                    required: true,
                    type    : 'numeric',
                    udf     : (value, target) => {
                        return arguments.value >= 0;
                    }
                }
            },
            'stats.overview': {
                trainerid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true}
                },
                startDate: {required: true, type: 'date'},
                endDate  : {required: true, type: 'date'},
                summary  : {required: true, type: 'boolean'}
            },
            'stats.leaderboard': {
                epochdate: {required: true, type: 'numeric'},
                stat     : {
                    required: true,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['xp', 'caught', 'spun', 'walked'].contains(lCase(arguments.value));
                    }
                }
            }
        };

        var tradeHandler = {
            'trade.tradePlan': {
                friend: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true},
                    friendCheck : {accepted: true}
                },
                region: {
                    required    : false,
                    type        : 'string',
                    entityExists: {entityName: 'generation', column: 'region'}
                },
                customid: {
                    required    : false,
                    type        : 'numeric',
                    entityExists: {entityName: 'custom', pk: true}
                },
                shiny: {
                    required: true,
                    type    : 'string',
                    udf     : (value, target) => {
                        return arguments.value == 'off' || arguments.value == 'on';
                    }
                }
            }
        };

        var trainerHandler = {
            'trainer.viewProfile': {
                trainerid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true},
                    friendCheck : {accepted: true}
                }
            },
            'trainer.updateProfile': {
                trainerid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true}
                },
                username: {
                    required: true,
                    size    : '5..30',
                    type    : 'string'
                },
                email: {
                    required: true,
                    size    : '3..100',
                    type    : 'email'
                },
                password: {
                    type: 'string',
                    udf : (value, target) => {
                        if(isNull(arguments.value)) return true; // users don't have to update password here
                        return arguments.value.len() <= 50 && arguments.value.len() >= 10; // if they are, check length
                    }
                },
                friendcode: {
                    size : 12,
                    regex: '^[0-9]+$',
                    type : 'string'
                },
                securityLevel: {type: 'numeric'},
                icon         : {
                    required       : true,
                    type           : 'string',
                    fileExistsCheck: {
                        path     : '#controller.getSetting('rootPath')#/includes/images/icons/',
                        extension: controller.getSetting('imageExtension')
                    }
                },
                verified: {
                    type: 'string',
                    udf : (value, target) => {
                        if(isNull(arguments.value)) return true;
                        return ['off', 'on'].contains(arguments.value);
                    }
                },
                defaultView: {
                    required: true,
                    type    : 'string',
                    udf     : (value, target) => {
                        return controller.getSetting('viewMap').keyExists(arguments.value);
                    }
                },
                defaultRegion: {
                    required    : true,
                    type        : 'string',
                    entityExists: {entityName: 'generation', column: 'region'}
                },
                defaultPage: {
                    required: true,
                    type    : 'string',
                    udf     : (value, target) => {
                        return controller.getSetting('pageMap').keyExists(arguments.value);
                    }
                }
            }
        };

        var pokemonHandler = {
            'pokemon.detail': {
                ses: {
                    required: true,
                    type    : 'string',
                    size    : '1..150'
                }
            },
            'pokemon.updateDetail': {
                pokemonid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'pokemon', pk: true}
                },
                liveSwitch: {
                    required: false,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['off', 'on'].contains(arguments.value);
                    }
                },
                shinySwitch: {
                    required: false,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['off', 'on'].contains(arguments.value);
                    }
                },
                shadowSwitch: {
                    required: false,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['off', 'on'].contains(arguments.value);
                    }
                },
                shinyShadowSwitch: {
                    required: false,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['off', 'on'].contains(arguments.value);
                    }
                },
                tradableSwitch: {
                    required: false,
                    type    : 'string',
                    udf     : (value, target) => {
                        return ['off', 'on'].contains(arguments.value);
                    }
                }
            }
        };

        var adminHandler = {
            editTrainer: {
                trainerid: {
                    required    : true,
                    type        : 'numeric',
                    entityExists: {entityName: 'trainer', pk: true}
                }
            }
        };

        var generic = {
            audit: {
                ip: {
                    required: true,
                    type    : 'string',
                    size    : '1..45',
                    regex   : '[0-9a-f.:]+'
                },
                event: {
                    required: true,
                    type    : 'string',
                    size    : '1..250'
                },
                detail   : {required: false, type: 'string'},
                agent    : {required: true, type: 'string'},
                trainerid: {required: true, type: 'numeric'}
            },
            bug: {
                ip: {
                    required: true,
                    type    : 'string',
                    size    : '1..45',
                    regex   : '[0-9a-f.:]+'
                },
                event: {
                    required: true,
                    type    : 'string',
                    size    : '1..250'
                },
                message: {
                    required: true,
                    type    : 'string',
                    size    : '1..250'
                },
                stack    : {required: true, type: 'string'},
                trainerid: {required: true, type: 'numeric'}
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
