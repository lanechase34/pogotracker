import { createPokemonSearch } from 'search';

export const runtime = {
    detail: () => {
        createPokemonSearch('pokemonSearch');

        const $costumesCollapse = document.getElementById('costumesCollapse');
        if ($costumesCollapse) {
            $costumesCollapse.addEventListener('shown.bs.collapse', (e) => {
                const icon = document.querySelector(`[data-bs-target="#${e.target.id}"] .collapse-chevron`);
                icon?.classList.replace('bi-chevron-down', 'bi-chevron-up');
            });
            $costumesCollapse.addEventListener('hidden.bs.collapse', (e) => {
                const icon = document.querySelector(`[data-bs-target="#${e.target.id}"] .collapse-chevron`);
                icon?.classList.replace('bi-chevron-up', 'bi-chevron-down');
            });
        }
    },
};
