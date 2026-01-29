component singleton accessors="true" {

    property name="cacheService" inject="services.cache";

    private void function create(required struct moveProperties) {
        var newMove = entityNew('move', arguments.moveProperties);
        entitySave(newMove);
        return;
    }

    public void function update(required struct moveProperties) {
        // Attempt to load move
        var currMove = entityLoad('move', {'nameid': arguments.moveProperties.nameid});

        // Create if this is a new move
        if(!currMove.len()) {
            create(arguments.moveProperties);
        }
        // Otherwise, update
        else {
            currMove = currMove[1];
            currMove.setName(arguments.moveProperties.name);
            currMove.setType(arguments.moveProperties.type);
            currMove.setDamage(arguments.moveProperties.damage);
            currMove.setEnergy(arguments.moveProperties.energy);
            currMove.setTurns(arguments.moveProperties.turns);
            currMove.setBuffSelf(arguments.moveProperties.buffSelf);
            currMove.setBuffChance(arguments.moveProperties.buffChance);
            currMove.setBuffEffect(arguments.moveProperties.buffEffect);
            entitySave(currMove);
        }

        return;
    }

    public array function getAllFastMoves() {
        var cacheKey     = 'move.getAllFastMoves';
        var allFastMoves = cacheService.get(cacheKey);
        if(isNull(allFastMoves)) {
            allFastMoves = ormExecuteQuery('from move as move where move.turns > 0 order by move.name asc');
            cacheService.put(cacheKey, allFastMoves, 720, 720);
        }
        return allFastMoves;
    }

    public array function getAllChargeMoves() {
        var cacheKey       = 'move.getAllChargeMoves';
        var allChargeMoves = cacheService.get(cacheKey);
        if(isNull(allChargeMoves)) {
            allChargeMoves = ormExecuteQuery('from move as move where move.turns = 0 order by move.name asc');
            cacheService.put(cacheKey, allChargeMoves, 720, 720);
        }
        return allChargeMoves;
    }

    public component function get(required string name) {
        return entityLoad('move', {'nameid': arguments.name}, true);
    }

    public boolean function check(required string name) {
        return !isNull(entityLoad('move', {'nameid': arguments.name}, true));
    }

    public void function updatePokemonMoves(required component pokemon, required array moves) {
        var abstractedMoves = {};
        // Find which records to add
        arguments.moves.each((move) => {
            if(
                isNull(
                    entityLoad(
                        'pokemonmove',
                        {'pokemon': pokemon, 'move': move.move},
                        true
                    )
                )
            ) {
                createPokemonMove(pokemon, move.move, move.shadow, move.legacy);
            }
        });

        // Find which records to delete - is this needed?

        return;
    }

    private void function createPokemonMove(
        required component pokemon,
        required component move,
        required boolean shadow,
        required boolean legacy
    ) {
        var pokemonMove = entityNew(
            'pokemonMove',
            {
                'pokemon': arguments.pokemon,
                'move'   : arguments.move,
                'shadow' : arguments.shadow,
                'legacy' : arguments.legacy
            }
        );
        entitySave(pokemonMove);
        return;
    }

}
