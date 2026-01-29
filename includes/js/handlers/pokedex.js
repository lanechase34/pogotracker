import { getCookie, setCookie } from 'cookie';
import { copyString } from 'copy';
import { postWrapper, getWrapper } from 'fetch';
import { $loading, $loadingModal } from 'loading';
import { confirmModal, submitHandler } from 'modals';
import { createMultiSelect } from 'multiselect';
import { createCustomSearch } from 'search';

const $pokedexTable = document.getElementById('pokedexTable');
const $customPokedexTable = document.getElementById('customPokedexTable');
const $shadowPokedexTable = document.getElementById('shadowPokedexTable');

const $addCustomPokedexBtn = document.getElementById('addCustomPokedex');
const customtrainerid = $customPokedexTable?.dataset?.trainerid ?? -1;
const customid = $customPokedexTable?.dataset?.customid ?? -1;

const $copySearchStringBtn = document.querySelectorAll('button.copySearchString');
const $copyMissingSearchStringBtn = document.querySelectorAll('button.copyMissingSearchString');
const $shinyToggle = document.querySelectorAll('button.shinyToggle');
const $monsRegistered = document.getElementById('monsRegistered');
const $pokedexLock = document.querySelectorAll('button.pokedexLock');
const $registerAllBtn = document.querySelectorAll('button.registerAll');

const trainerid = $pokedexTable?.dataset?.trainerid ?? -1;

const fetchStruct = {
    count: 0,
    counter: 0,
    loadingList: false,
};

const pokedexStruct = {
    shiny: false,
    mega: false,
    shadow: false,
    view: '',
    registered: 0,
    total: 0,
    lock: getCookie('pokedexLock') ?? 'false',
    mousedown: false,
    catching: false,
    active: '',
};

let $pokedexLoading = {
    customEdit: false,
    customAdd: false,
};

function submitCustomPokedexModal(e, type, $form, $btn, $modal) {
    let valid = $form.checkValidity();
    $form.classList.add('was-validated');
    if (!valid) {
        e.preventDefault();
        e.stopPropagation();
        return;
    }

    let formData = new FormData($form);
    let packet = Object.fromEntries(formData.entries());

    let pokemonList = formData.getAll('pokemon[]');
    packet.pokemon = pokemonList;
    delete packet['pokemon[]'];

    if (!packet.name.length || !packet.pokemon.length) {
        return;
    }

    submitHandler($modal, $btn);

    if ('public' in packet) {
        packet.public = packet.public == 'on' ? true : false;
    } else {
        packet.public = false;
    }

    Array.from(document.querySelectorAll('.closeCustomForm')).forEach((btn) => {
        btn.style.display = 'none';
    });

    return postWrapper({
        url: `/pokedex/${type}CustomPokedex`,
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (result) => {
            if (type == 'delete') {
                window.location.reload();
            } else {
                window.location = `/mycustompokedex/${result.data.id}`;
            }
        },
    });
}

async function getCustomPokedexModal(type, customid) {
    let url = `/pokedex/${type}Custompokedexform`;
    if (customid.length) {
        url += `/customid/${customid}`;
    }

    return getWrapper({
        url: url,
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);

            const $customPokedexModal = document.getElementById('customPokedexModal');
            globalModals.$customPokedexModal = new bootstrap.Modal($customPokedexModal, {});
            createMultiSelect(document.getElementById('pokemonList'), 'Select Pokemon', 100, true);

            const $customPokedexForm = document.getElementById('customPokedexForm');
            const $submitCustomBtn = document.getElementById('submitCustomForm');
            $submitCustomBtn.addEventListener('click', (e) => {
                submitCustomPokedexModal(e, type, $customPokedexForm, $submitCustomBtn, $customPokedexModal);
            });

            if (type == 'edit') {
                const $deleteCustomBtn = document.getElementById('deleteCustomForm');
                $deleteCustomBtn.addEventListener('click', (e) => {
                    submitCustomPokedexModal(e, 'delete', $customPokedexForm, $deleteCustomBtn, $customPokedexModal);
                });
            }
        },
    });
}

function toggleLock() {
    pokedexStruct.lock = pokedexStruct.lock == 'true' ? 'false' : 'true';
    setCookie('pokedexLock', pokedexStruct.lock, 100);

    Array.from($pokedexLock).forEach((btn) => {
        if (pokedexStruct.lock == 'true') {
            btn.innerHTML = '<i class="bi bi-lock me-1"></i>Locked';
        } else {
            btn.innerHTML = '<i class="bi bi-unlock me-1"></i>Unlocked';
        }
    });
}

async function toggleShiny() {
    pokedexStruct.shiny = !pokedexStruct.shiny;
    if ($pokedexTable) {
        await switchPokedex(pokedexStruct.region);
    } else if ($customPokedexTable) {
        await switchCustomPokedex();
    } else if ($shadowPokedexTable) {
        await switchShadowPokedex();
    }

    Array.from($shinyToggle).forEach((btn) => {
        if (pokedexStruct.shiny) {
            btn.classList.remove('btn-danger');
            btn.classList.add('btn-success');
        } else {
            btn.classList.remove('btn-success');
            btn.classList.add('btn-danger');
        }
    });
}

function registerAllConfirm() {
    confirmModal(
        `This will register ALL ${pokedexStruct.shiny ? 'Shiny ' : ''}pokemon currently unregistered for the ${
            pokedexStruct.region
        } region. Proceed?`,
        '<i class="bi bi-arrow-right me-1"></i>Proceed',
        () => {
            registerAll();
        }
    );
}

function createEditEvent(count) {
    let $editCustomPokedexBtn = document.querySelectorAll(`.editCustomPokedex${count}`);
    Array.from($editCustomPokedexBtn).forEach(async (btn) => {
        btn.addEventListener('click', async (evt) => {
            if ($pokedexLoading.customEdit) return;

            if (document.getElementById('customPokedexModal')) {
                document.getElementById('customPokedexModal').remove();
            }

            $pokedexLoading.customEdit = true;
            await getCustomPokedexModal('edit', evt.currentTarget.dataset.customid);

            document.getElementById('customPokedexModal').addEventListener('hidden.bs.modal', () => {
                document.getElementById('customPokedexModal').remove();
            });
            globalModals.$customPokedexModal.show();
            $pokedexLoading.customEdit = false;
        });
    });
}

async function fetchCustomPokedexList(counter) {
    let $nextGroup = document.getElementById(`nextGroup${counter}`);
    if (!$nextGroup) return;

    return getWrapper({
        url: `/pokedex/customPokedexList/offset/${counter}`,
        $loadingDiv: $nextGroup,
        loading: $loading,
        dataHandler: async (data) => {
            $nextGroup.insertAdjacentHTML('afterend', data);
            $nextGroup.remove();

            createEditEvent(counter);

            fetchStruct.counter += fetchStruct.count;

            if (window.innerHeight > document.body.scrollHeight) {
                await fetchCustomPokedexList(fetchStruct.counter);
            }
        },
    });
}

async function switchCustomPokedex() {
    return getWrapper({
        url: `/pokedex/getCustomPokedex/trainerid/${customtrainerid}/customid/${customid}/shiny/${pokedexStruct.shiny}/hundo/false`,
        $loadingDiv: $customPokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $customPokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            let $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            let currRegistered = document.getElementById('registeredCount').dataset;

            pokedexStruct.registered = currRegistered.registered;
            pokedexStruct.total = currRegistered.total;
            updateRegistered();
        },
    });
}

async function register(evt) {
    let cell = evt.currentTarget;
    let dataset = cell.dataset;
    let body = {
        pokemonid: dataset.id,
        caught: dataset.caught,
        shiny: dataset.shiny,
        hundo: dataset.hundo,
        shadow: dataset.shadow,
        shadowshiny: dataset.shadowshiny,
    };

    // Depending on view, this flips that respective flag aka 'catch' / 'uncatch'
    body[pokedexStruct.view] = body[pokedexStruct.view] === 'true' ? false : true;

    // Always show positive feedback and process in the background
    // Update the cell's dataset, mark caught/remove caught, and update register tally
    dataset[pokedexStruct.view] = body[pokedexStruct.view];
    if (dataset[pokedexStruct.view] === 'true') {
        cell.classList.add('caught');
        pokedexStruct.registered++;
    } else {
        cell.classList.remove('caught');
        pokedexStruct.registered--;
    }
    updateRegistered();

    postWrapper({
        url: '/pokedex/register',
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify(body),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                throw new Error(data.message);
            }
        },
    });

    return body[pokedexStruct.view];
}

function createRegisterEvent(pokemonCells) {
    pokemonCells.forEach((cell) => {
        ['mousedown', 'ontouchstart'].forEach((event) => {
            cell.addEventListener(event, async (evt) => {
                evt.preventDefault();
                if (pokedexStruct.lock == 'false') {
                    // only allow updates while unlocked
                    pokedexStruct.mousedown = true;
                    pokedexStruct.catching = await register(evt);
                }
            });
        });

        ['mouseenter'].forEach((event) => {
            cell.addEventListener(event, (evt) => {
                evt.preventDefault();
                if (
                    pokedexStruct.lock == 'false' &&
                    pokedexStruct.mousedown &&
                    pokedexStruct.catching == !evt.currentTarget.classList.contains('caught')
                ) {
                    register(evt);
                }
            });
        });
    });
}

async function switchPokedex(region) {
    Array.from($registerAllBtn).forEach((btn) => {
        btn.disabled = region == 'mega' || region == 'giga';
    });

    let activeNavButton = document.querySelector('.pokedex-link.active');
    if (activeNavButton) activeNavButton.classList.remove('active');
    let navButton = document.querySelector(`.${region}link`);
    navButton.classList.add('active');

    let url = `/pokedex/getPokedex`;
    if (region.length) {
        url += `/region/${region}`;
    }
    if (trainerid.length) {
        url += `/trainerid/${trainerid}`;
    }
    url += `/shiny/${pokedexStruct.shiny}`;

    return getWrapper({
        url: url,
        $loadingDiv: $pokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $pokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            let $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            let currRegistered = document.getElementById('registeredCount').dataset;
            pokedexStruct.registered = currRegistered.registered;
            pokedexStruct.total = currRegistered.total;

            updateRegistered();
        },
    });
}

async function switchShadowPokedex() {
    let url = `/pokedex/getPokedex`;
    if (trainerid.length) {
        url += `/trainerid/${trainerid}`;
    }
    url += `/shiny/${pokedexStruct.shiny}`;
    url += `/shadow/${pokedexStruct.shadow}`;

    return getWrapper({
        url: url,
        $loadingDiv: $shadowPokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $shadowPokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            let $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            let currRegistered = document.getElementById('registeredCount').dataset;

            pokedexStruct.registered = currRegistered.registered;
            pokedexStruct.total = currRegistered.total;
            updateRegistered();
        },
    });
}

function updateRegistered() {
    $monsRegistered.innerHTML = `${pokedexStruct.registered} / ${pokedexStruct.total} Registered`;
    let percentage = pokedexStruct.registered / pokedexStruct.total;
    $monsRegistered.classList.remove('basic', 'bronze', 'silver', 'gold', 'diamond');
    if (percentage < 0.25) {
        $monsRegistered.classList.add('basic');
    } else if (percentage < 0.5) {
        $monsRegistered.classList.add('bronze');
    } else if (percentage < 0.75) {
        $monsRegistered.classList.add('silver');
    } else if (percentage < 1) {
        $monsRegistered.classList.add('gold');
    } else {
        $monsRegistered.classList.add('diamond');
    }
}

async function registerAll() {
    $loadingModal.show();

    return postWrapper({
        url: `/pokedex/registerAll`,
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify({
            region: pokedexStruct.region,
            shiny: pokedexStruct.shiny,
        }),
        responseType: 'json',
        dataHandler: () => {
            location.href = `/mypokedex/region/${pokedexStruct.region}/shiny/${pokedexStruct.shiny}`;
        },
    });
}

function copySearchString($btns, missing) {
    let condition = '';
    let string = '';

    if ('region' in pokedexStruct) {
        string += `${pokedexStruct.region}&`;
    }

    if (pokedexStruct.view == 'shadowshiny') {
        if (missing) condition = `[data-shadowshiny=false]`;
        string += 'shadow&shiny&';
    } else if (pokedexStruct.view == 'shadow') {
        if (missing) condition = `[data-shadow=false]`;
        string += 'shadow&';
    } else if (pokedexStruct.view == 'shiny') {
        if (missing) condition = `[data-shiny=false]`;
        string += 'shiny&';
    } else {
        if (missing) condition = `[data-caught=false]`;
        string += '';
    }

    let cells = document.querySelectorAll(`div.pokemonCell${condition}`);
    cells.forEach((cell) => {
        string += `${cell.dataset.number},`;
    });

    copyString(Array.from($btns), string);
}

export const runtime = {
    all: () => {
        Array.from($copySearchStringBtn).forEach((btn) => {
            btn.addEventListener('click', () => {
                copySearchString($copySearchStringBtn, false);
            });
        });

        Array.from($copyMissingSearchStringBtn).forEach((btn) => {
            btn.addEventListener('click', () => {
                copySearchString($copyMissingSearchStringBtn, true);
            });
        });

        Array.from($pokedexLock).forEach((btn) => {
            btn.addEventListener('click', () => {
                toggleLock();
            });
        });

        Array.from($shinyToggle).forEach((btn) => {
            btn.addEventListener('click', async () => {
                toggleShiny();
            });
        });

        Array.from($registerAllBtn).forEach((btn) => {
            btn.addEventListener('click', () => {
                registerAllConfirm();
            });
        });

        ['mouseup', 'ontouchend'].forEach((event) => {
            document.addEventListener(event, (evt) => {
                evt.preventDefault();
                pokedexStruct.mousedown = false;
                pokedexStruct.catching = false;
            });
        });
    },
    mypokedex: () => {
        pokedexStruct.region = $pokedexTable.dataset.region;
        pokedexStruct.shiny = $pokedexTable.dataset.shiny == 'true';
        switchPokedex(pokedexStruct.region);

        Array.from(document.querySelectorAll('.pokedex-link')).forEach((navBtn) => {
            navBtn.addEventListener('click', () => {
                if (
                    !pokedexStruct.catching &&
                    !pokedexStruct.mousedown &&
                    pokedexStruct.region != navBtn.dataset.region
                ) {
                    pokedexStruct.region = navBtn.dataset.region;
                    switchPokedex(pokedexStruct.region);
                }
            });
        });
    },
    mycustompokedex: () => {
        pokedexStruct.shiny = $customPokedexTable.dataset.shiny == 'true';
        switchCustomPokedex();
    },
    custompokedexlist: () => {
        $addCustomPokedexBtn.addEventListener('click', async () => {
            if ($pokedexLoading.customAdd) return;
            if (!document.getElementById('customPokedexModal')) {
                $pokedexLoading.customAdd = true;
                await getCustomPokedexModal('add', '');
            }
            globalModals.$customPokedexModal.show();
            $pokedexLoading.customAdd = false;
        });

        fetchStruct.count = parseInt(document.getElementById('addCustomPokedex').dataset.count);
        createEditEvent(0);

        // start at defined count
        fetchStruct.counter = fetchStruct.count;

        if (window.innerHeight > document.getElementById('mainSection').offsetHeight) {
            fetchCustomPokedexList(fetchStruct.counter);
        }

        addEventListener('scroll', async () => {
            let atBottom = window.innerHeight + window.scrollY >= document.body.scrollHeight;
            if (atBottom && !fetchStruct.loadingList) {
                fetchStruct.loadingList = true;
                await fetchCustomPokedexList(fetchStruct.counter);
                fetchStruct.loadingList = false;
            }
        });

        createCustomSearch('customSearch', 'Search a Pokedex...', true, '');
    },
    myshadowpokedex: () => {
        pokedexStruct.shiny = $shadowPokedexTable.dataset.shiny == 'true';
        pokedexStruct.shadow = true;
        switchShadowPokedex();
    },
};
