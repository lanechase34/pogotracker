import { getWrapper } from 'fetch';
import { createPokemonSearch } from 'search';

/**
 * Update (or drop) a query param in place so filtered views can be shared, without adding history entries
 * @param {string} name
 * @param {string} value
 */
const setUrlParam = (name, value) => {
    const url = new URL(location.href);
    if (value) url.searchParams.set(name, value);
    else url.searchParams.delete(name);
    if (url.href !== location.href) history.replaceState(history.state, '', url);
};

/**
 * Keep CSS vars in sync with the sticky main navbar + pokedex toolbar heights
 * so the toolbar docks right under the navbar and anchor jumps clear both
 * @param {HTMLElement} $toolbar
 */
const trackStickyOffsets = ($toolbar) => {
    const $nav = /** @type {HTMLElement | null} */ (document.querySelector('#mainbody > nav.sticky-top'));
    const root = document.documentElement.style;
    const update = () => {
        root.setProperty('--main-nav-height', `${$nav?.offsetHeight ?? 0}px`);
        root.setProperty('--pokedex-toolbar-height', `${$toolbar.offsetHeight}px`);
    };
    update();
    const observer = new ResizeObserver(update);
    if ($nav) observer.observe($nav);
    observer.observe($toolbar);

    // Shadow once the toolbar is docked - sentinel sits just above it in normal flow
    const $sentinel = document.createElement('div');
    $sentinel.setAttribute('aria-hidden', 'true');
    $toolbar.before($sentinel);
    new IntersectionObserver(([entry]) => {
        $toolbar.classList.toggle('is-stuck', !entry.isIntersecting && entry.boundingClientRect.top < 0);
    }).observe($sentinel);
};

/**
 * Highlight the generation currently in view and keep its button visible in the (mobile) scroll strip
 * @param {HTMLElement} $jump
 * @param {HTMLElement[]} $sections
 */
const trackActiveGeneration = ($jump, $sections) => {
    const $links = new Map(
        [...$jump.querySelectorAll('a[href^="#"]')].map(($a) => [
            /** @type {HTMLAnchorElement} */ ($a).hash.slice(1),
            /** @type {HTMLElement} */ ($a),
        ])
    );
    const visible = new Set();

    const setActive = () => {
        // First section (in document order) that is on screen wins
        const $current = $sections.find(($s) => visible.has($s.id) && !$s.hidden);
        $links.forEach(($a, id) => {
            const active = id === $current?.id;
            $a.classList.toggle('active', active);
            if (active) {
                $a.setAttribute('aria-current', 'location');
                // scroll the strip only, never the page
                if ($jump.scrollWidth > $jump.clientWidth) {
                    $jump.scrollTo({
                        left: $a.offsetLeft - ($jump.clientWidth - $a.offsetWidth) / 2,
                        behavior: 'smooth',
                    });
                }
            } else {
                $a.removeAttribute('aria-current');
            }
        });
    };

    // Band below the sticky bars down to ~mid screen counts as "in view"
    const offset =
        parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--main-nav-height')) +
            parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--pokedex-toolbar-height')) || 0;
    const observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) visible.add(entry.target.id);
                else visible.delete(entry.target.id);
            });
            setActive();
        },
        { rootMargin: `-${Math.round(offset + 16)}px 0px -50% 0px` }
    );
    $sections.forEach(($s) => observer.observe($s));

    return { $links, refresh: setActive };
};

/**
 * Client side filter over the server rendered grid - matches name, dex number, or type
 * @param {HTMLInputElement} $input
 * @param {HTMLElement[]} $sections
 * @param {Map<string, HTMLElement>} $links
 * @param {() => void} refreshActive
 */
const createPokedexFilter = ($input, $sections, $links, refreshActive) => {
    const $noResults = document.getElementById('pokedexNoResults');
    const groups = $sections.map(($section) => ({
        $section,
        $count: $section.querySelector('.pokedex-gen-count'),
        entries: [...$section.querySelectorAll('li[data-search]')].map(($li) => ({
            $li: /** @type {HTMLElement} */ ($li),
            text: /** @type {HTMLElement} */ ($li).dataset.search ?? '',
        })),
    }));

    const apply = () => {
        // every whitespace separated term must match, '#' prefix allowed for numbers
        const terms = $input.value.toLowerCase().replaceAll('#', '').split(/\s+/).filter(Boolean);
        let total = 0;
        groups.forEach(({ $section, $count, entries }) => {
            let shown = 0;
            entries.forEach(({ $li, text }) => {
                const match = terms.every((t) => text.includes(t));
                $li.hidden = !match;
                if (match) shown++;
            });
            total += shown;
            $section.hidden = shown === 0;
            if ($count) $count.textContent = terms.length ? `${shown} / ${entries.length}` : `${entries.length}`;
            $links.get($section.id)?.classList.toggle('is-empty', shown === 0);
        });
        $noResults?.classList.toggle('d-none', total > 0);
        setUrlParam('q', $input.value.trim());
        refreshActive();
    };

    let timer = 0;
    $input.addEventListener('input', () => {
        clearTimeout(timer);
        timer = window.setTimeout(apply, 120);
    });
    $input.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && $input.value) {
            $input.value = '';
            apply();
        }
    });
    // Shared ?q= link, or a restored form value on back/forward navigation
    const initial = new URLSearchParams(location.search).get('q');
    if (initial) $input.value = initial;
    if ($input.value) apply();
};

/**
 * Swap every tile with a shiny to its shiny sprite, fade the rest. State lives in ?shiny=1
 * @param {HTMLButtonElement} $btn
 */
const createShinyToggle = ($btn) => {
    const $sprites = /** @type {HTMLImageElement[]} */ ([...document.querySelectorAll('img[data-shiny-src]')]);

    /** @param {boolean} on */
    const set = (on) => {
        $btn.setAttribute('aria-pressed', String(on));
        $btn.title = on ? 'Show normal sprites' : 'Show shiny sprites';
        document.body.classList.toggle('pokedex-shiny-mode', on);
        $sprites.forEach(($img) => {
            const src = on ? $img.dataset.shinySrc : $img.dataset.normalSrc;
            if (src && $img.getAttribute('src') !== src) $img.src = src;
        });
        setUrlParam('shiny', on ? '1' : '');
    };

    $btn.addEventListener('click', () => set($btn.getAttribute('aria-pressed') !== 'true'));
    if (new URLSearchParams(location.search).get('shiny') === '1') set(true);
};

export const runtime = {
    index: () => {
        createPokemonSearch('pokemonSearch');

        const $toolbar = document.getElementById('pokedexToolbar');
        const $jump = document.getElementById('pokedexJump');
        const $filter = /** @type {HTMLInputElement | null} */ (document.getElementById('pokedexFilter'));
        if (!$toolbar || !$jump || !$filter) return;

        const $sections = /** @type {HTMLElement[]} */ ([...document.querySelectorAll('section.pokedex-section')]);

        trackStickyOffsets($toolbar);
        const { $links, refresh } = trackActiveGeneration($jump, $sections);
        createPokedexFilter($filter, $sections, $links, refresh);

        const $shiny = /** @type {HTMLButtonElement | null} */ (document.getElementById('pokedexShiny'));
        if ($shiny) createShinyToggle($shiny);
    },
    detail: () => {
        createPokemonSearch('pokemonSearch');

        const $costumesCollapse = document.getElementById('costumesCollapse');
        if ($costumesCollapse) {
            $costumesCollapse.addEventListener('shown.bs.collapse', (e) => {
                const icon = document.querySelector(
                    `[data-bs-target="#${/** @type {HTMLElement} */ (e.target).id}"] .collapse-chevron`
                );
                icon?.classList.replace('bi-chevron-down', 'bi-chevron-up');
            });
            $costumesCollapse.addEventListener('hidden.bs.collapse', (e) => {
                const icon = document.querySelector(
                    `[data-bs-target="#${/** @type {HTMLElement} */ (e.target).id}"] .collapse-chevron`
                );
                icon?.classList.replace('bi-chevron-up', 'bi-chevron-down');
            });
        }

        const $eventRows = document.getElementById('eventRows');
        if ($eventRows) {
            $eventRows.addEventListener('click', async (e) => {
                const $btn = /** @type {HTMLButtonElement} */ (
                    /** @type {HTMLElement} */ (e.target).closest('#loadMoreEvents')
                );
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
