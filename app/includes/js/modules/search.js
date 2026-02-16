function pokemonSearch(params, data) {
    // data.text.toLowerCase().indexOf(params.term.toLowerCase()) == 0 beings with search
    if (data.text.toLowerCase().includes(params.term.toLowerCase())) {
        return data;
    }
    return null;
}

function formatPokemonSearch(option) {
    if (option.image == undefined || !option.image.length) {
        return option.text;
    }

    return $(
        `<span class='pokemonSearchOption'><img class='pokemonSearchIcon me-1' src='/includes/images/sprites/${option.image}' alt='${option.alt}' loading='lazy'>${option.text}</span>`
    );
}

function formatFriendSearchResults(option) {
    if (option.loading) return;

    return $(
        `<span><img class='searchIcon me-1' src='/includes/images/icons/${option.img}.webp' alt='${option.alt}' loading='lazy'>${option.text}</span>`
    );
}

function formatCustomSearchResults(option) {
    if (option.loading) return;

    return $(`<span>${option.text}</span>`);
}

function addFocusEvent() {
    $('.select2-container').on('click', function () {
        $('.select2-search__field').focus();
    });
}

export function createPokemonSearch(elementid) {
    let element = $(`#${elementid}`);

    element.select2({
        minimumInputLength: 1,
        maximumResultsForSearch: 20,
        maximumInputLength: 20,
        placeholder: 'Search a Pokemon...',
        matcher: pokemonSearch,
        theme: 'bootstrap-5',
        templateResult: formatPokemonSearch,
        data: pokemonSearchArray,
        width: '100%',
    });

    element.on('select2:select', function (e) {
        let ses = e.params.data.ses;
        window.location.href = `/pokemon/${ses}`;
    });

    addFocusEvent();
}

export function createAddFriendSearch(elementid) {
    let element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/friend/searchFriendsToAdd',
            dataType: 'json',
            data: function (params) {
                var query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults: function (data) {
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
    let element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/friend/searchFriendsList',
            dataType: 'json',
            data: function (params) {
                var query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults: function (data) {
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
    let element = $(`#${elementid}`);

    element.select2({
        ajax: {
            url: '/pokedex/searchCustomPokedexList',
            dataType: 'json',
            data: function (params) {
                var query = {
                    search: params.term,
                    page: params.page || 1,
                };
                return query; // Query parameters will be ?search=[term]&page=[page]
            },
            processResults: function (data) {
                return data.data;
            },
            cache: true,
            delay: 250, // wait 250 milliseconds before triggering the request
        },
        placeholder: placeHolder,
        theme: 'bootstrap-5',
        maximumInputLength: 15,
        templateResult: formatCustomSearchResults,
        width: width,
    });

    addFocusEvent();

    if (onclickCustom) {
        element.on('select2:select', function (e) {
            let customid = e.params.data.id;
            window.location.href = `/mycustompokedex/${customid}`;
        });
    }
}

export function createRegionSelect(elementid) {
    let element = $(`#${elementid}`);

    element.select2({
        minimumResultsForSearch: Infinity,
        placeholder: 'Select a Region',
        theme: 'bootstrap-5',
        width: '100%',
    });
}
