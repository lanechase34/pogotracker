function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

function encodePath(path) {
    // encodeURIComponent intentionally skips ' (apostrophe), so replace it manually
    return path
        .split('/')
        .map((s) => encodeURIComponent(s).replace(/'/g, '%27'))
        .join('/');
}

function formatPokemonSearch(option) {
    if (!option.image?.length) {
        return option.text;
    }

    return $(
        `<span class='pokemonSearchOption'><img class='pokemonSearchIcon me-1' src='/includes/images/sprites/${encodePath(option.image)}' alt='${escapeHtml(option.alt)}' loading='lazy'>${option.text}</span>`
    );
}

function formatFriendSearchResults(option) {
    if (option.loading) return;

    return $(
        `<span class='trainerSearchOption'><img class='searchIcon me-1' src='/includes/images/icons/${encodePath(option.img)}.webp' alt='${escapeHtml(option.alt)}' loading='lazy'>${option.text}</span>`
    );
}

function formatCustomSearchResults(option) {
    if (option.loading) return;

    return $(`<span>${option.text}</span>`);
}

function addFocusEvent() {
    $('.select2-container').on('click', () => {
        $('.select2-search__field').focus();
    });
}

export function createPokemonSearch(elementid) {
    const element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/pokemon/search',
            dataType: 'json',
            data(params) {
                return {
                    search: params.term,
                    page: params.page || 1,
                };
            },
            processResults(data) {
                return data.data;
            },
            cache: true,
            delay: 100,
        },
        minimumInputLength: 1,
        maximumInputLength: 20,
        placeholder: 'Search a Pokemon...',
        theme: 'bootstrap-5',
        templateResult: formatPokemonSearch,
        width: '100%',
    });

    element.on('select2:select', (e) => {
        const ses = e.params.data.ses;
        window.location.href = `/pokemon/${ses}`;
    });

    addFocusEvent();
}

export function createAddFriendSearch(elementid) {
    const element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/friend/searchFriendsToAdd',
            dataType: 'json',
            data(params) {
                const query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults(data) {
                return data.data;
            },
            cache: true,
            delay: 250, // wait 250 milliseconds before triggering the request
        },
        placeholder: 'Search a Trainer...',
        theme: 'bootstrap-5',
        maximumInputLength: 15,
        templateResult: formatFriendSearchResults,
        width: '100%',
        dropdownParent: $('#addFriendModal'),
    });

    addFocusEvent();
}

export function createFriendsListSearch(elementid) {
    const element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/friend/searchFriendsList',
            dataType: 'json',
            data(params) {
                const query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults(data) {
                return data.data;
            },
            cache: true,
            delay: 250, // wait 250 milliseconds before triggering the request
        },
        placeholder: 'Select a Friend',
        theme: 'bootstrap-5',
        maximumInputLength: 15,
        templateResult: formatFriendSearchResults,
        width: '100%',
    });

    addFocusEvent();
}

export function createCustomSearch(
    elementid,
    placeHolder = 'Select a Custom Pokedex',
    onclickCustom = false,
    width = '100%'
) {
    const element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/pokedex/searchCustomPokedexList',
            dataType: 'json',
            data(params) {
                const query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults(data) {
                return data.data;
            },
            cache: true,
            delay: 250, // wait 250 milliseconds before triggering the request
        },
        placeholder: placeHolder,
        theme: 'bootstrap-5',
        maximumInputLength: 15,
        templateResult: formatCustomSearchResults,
        width,
    });

    addFocusEvent();

    if (onclickCustom) {
        element.on('select2:select', (e) => {
            const customid = e.params.data.id;
            window.location.href = `/mycustompokedex/${customid}`;
        });
    }
}

export function createRegionSelect(elementid) {
    const element = $(`#${elementid}`);

    element.select2({
        minimumResultsForSearch: Infinity,
        placeholder: 'Select a Region',
        theme: 'bootstrap-5',
        width: '100%',
    });
}
