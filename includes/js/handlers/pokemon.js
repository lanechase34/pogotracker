import { createPokemonSearch } from 'search';

function resizePokemonCards() {
    new Masonry('.pokemonCards', {
        itemSelector: '.pokemonCard',
    });
}

export const runtime = {
    detail: () => {
        resizePokemonCards();
        createPokemonSearch('pokemonSearch');
    },
};
