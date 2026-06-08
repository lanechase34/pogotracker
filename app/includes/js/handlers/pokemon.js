import { getWrapper } from 'fetch';
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

        const $eventRows = document.getElementById('eventRows');
        if ($eventRows) {
            $eventRows.addEventListener('click', async (e) => {
                const $btn = e.target.closest('#loadMoreEvents');
                if (!$btn) return;

                const ses = $btn.dataset.ses;
                const offset = $btn.dataset.offset;

                $btn.disabled = true;

                await getWrapper({
                    url: `/pokemon/getPreviousEvents?ses=${encodeURIComponent(ses)}&offset=${offset}`,
                    dataHandler: (html) => {
                        const $row = document.getElementById('loadMoreEventsRow');
                        if ($row) $row.remove();

                        $eventRows.insertAdjacentHTML('beforeend', html);
                    },
                });
            });
        }
    },
};
