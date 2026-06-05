import { copyString, lockButtonWidth, lockCopyButtonWidth } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
import { $loading, $loadingModal } from 'loading';
import { getLocalStorage, setLocalStorage } from 'localstorage';
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
    scrollHandler: () => {},
    resizeHandler: () => {},
};

const pokedexStruct = {
    shiny: false,
    mega: false,
    shadow: false,
    view: '',
    registered: 0,
    total: 0,
    lock: getLocalStorage('pokedexLock') ?? 'false',
    mousedown: false,
    catching: false,
    active: '',
    temp: { region: '', shiny: false },
};

const $pokedexLoading = {
    customEdit: false,
    customAdd: false,
};

function submitCustomPokedexModal(e, type, $form, $btn, $modal) {
    const valid = $form.checkValidity();
    $form.classList.add('was-validated');
    if (!valid) {
        e.preventDefault();
        e.stopPropagation();
        return;
    }

    const formData = new FormData($form);
    const packet = Object.fromEntries(formData.entries());

    const pokemonList = formData.getAll('pokemon[]');
    packet.pokemon = pokemonList;
    delete packet['pokemon[]'];

    if (!packet.name.length || !packet.pokemon.length) {
        return;
    }

    submitHandler($modal, $btn);

    if ('public' in packet) {
        packet.public = packet.public === 'on' ? true : false;
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
            if (type === 'delete') {
                window.location.reload();
            } else {
                window.location = `/mycustompokedex/${result.data.id}`;
            }
        },
    });
}

async function getCustomPokedexModal(type, customidLoad) {
    let url = `/pokedex/${type}Custompokedexform`;
    if (customidLoad.length) {
        url += `/customid/${customidLoad}`;
    }

    return await getWrapper({
        url,
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
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

            if (type === 'edit') {
                const $deleteCustomBtn = document.getElementById('deleteCustomForm');
                $deleteCustomBtn.addEventListener('click', (e) => {
                    submitCustomPokedexModal(e, 'delete', $customPokedexForm, $deleteCustomBtn, $customPokedexModal);
                });
            }
        },
    });
}

function toggleLock() {
    pokedexStruct.lock = pokedexStruct.lock === 'true' ? 'false' : 'true';
    setLocalStorage('pokedexLock', pokedexStruct.lock);
    document.body.classList.toggle('pokedex-locked', pokedexStruct.lock === 'true');

    Array.from($pokedexLock).forEach((btn) => {
        if (pokedexStruct.lock === 'true') {
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
    const $editCustomPokedexBtn = document.querySelectorAll(`.editCustomPokedex${count}`);
    Array.from($editCustomPokedexBtn).forEach((btn) => {
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
    const $nextGroup = document.getElementById(`nextGroup${counter}`);
    if (!$nextGroup) return;

    return await getWrapper({
        url: `/pokedex/customPokedexList/offset/${counter}`,
        $loadingDiv: $nextGroup,
        loading: $loading,
        dataHandler: async (data) => {
            $nextGroup.insertAdjacentHTML('afterend', data);
            $nextGroup.remove();

            createEditEvent(counter);

            fetchStruct.counter += fetchStruct.count;

            if (window.innerHeight > document.getElementById('mainSection').scrollHeight) {
                await fetchCustomPokedexList(fetchStruct.counter);
            }
        },
    });
}

async function switchCustomPokedex() {
    return await getWrapper({
        url: `/pokedex/getCustomPokedex/trainerid/${customtrainerid}/customid/${customid}/shiny/${pokedexStruct.shiny}/hundo/false`,
        $loadingDiv: $customPokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $customPokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            const $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            const currRegistered = document.getElementById('registeredCount').dataset;

            pokedexStruct.registered = currRegistered.registered;
            pokedexStruct.total = currRegistered.total;
            updateRegistered();
        },
    });
}

async function register(evt) {
    const cell = evt.currentTarget;
    const dataset = cell.dataset;
    const body = {
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
    cell.setAttribute('aria-checked', cell.classList.contains('caught') ? 'true' : 'false');
    updateRegistered();

    await postWrapper({
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
        ['mousedown'].forEach((event) => {
            cell.addEventListener(event, async (evt) => {
                evt.preventDefault();
                if (pokedexStruct.lock === 'false') {
                    pokedexStruct.mousedown = true;
                    pokedexStruct.catching = await register(evt);
                }
            });
        });

        cell.addEventListener('mouseenter', (evt) => {
            evt.preventDefault();
            if (
                pokedexStruct.lock === 'false' &&
                pokedexStruct.mousedown &&
                pokedexStruct.catching === !evt.currentTarget.classList.contains('caught')
            ) {
                evt.currentTarget.classList.add('registering');
                register(evt);
            }
        });

        cell.addEventListener('mouseleave', (evt) => {
            evt.currentTarget.classList.remove('registering');
        });

        cell.addEventListener('keydown', async (evt) => {
            if ((evt.key === ' ' || evt.key === 'Enter') && pokedexStruct.lock === 'false') {
                evt.preventDefault();
                await register(evt);
            }
        });
    });
}

async function switchPokedex(region) {
    // Register all btn disabled for mega, giga
    Array.from($registerAllBtn).forEach((btn) => {
        btn.disabled = region === 'mega' || region === 'giga';
    });

    // Shiny btn disabled for mega
    Array.from($shinyToggle).forEach((btn) => {
        btn.disabled = region === 'mega';
    });

    // Store shiny state in temp struct when viewing mega
    if (region === 'mega') {
        pokedexStruct.temp.region = 'mega';
        pokedexStruct.temp.shiny = pokedexStruct.shiny;
        pokedexStruct.shiny = false;
    }
    // If we were viewing mega, restore the shiny state
    else if (pokedexStruct.temp.region === 'mega') {
        pokedexStruct.temp.region = '';
        pokedexStruct.shiny = pokedexStruct.temp.shiny;
    }

    const activeNavButton = document.querySelector('.pokedex-link.active');
    if (activeNavButton) activeNavButton.classList.remove('active');
    const navButton = document.querySelector(`.${region}link`);
    navButton.classList.add('active');

    let url = `/pokedex/getPokedex`;
    if (region.length) {
        url += `/region/${region}`;
    }
    if (trainerid.length) {
        url += `/trainerid/${trainerid}`;
    }
    url += `/shiny/${pokedexStruct.shiny}`;

    return await getWrapper({
        url,
        $loadingDiv: $pokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $pokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            const $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            const currRegistered = document.getElementById('registeredCount').dataset;
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
    url += '/region/shadowRegion';

    return await getWrapper({
        url,
        $loadingDiv: $shadowPokedexTable,
        loading: $loading,
        dataHandler: (data) => {
            $shadowPokedexTable.innerHTML = data;

            pokedexStruct.view = document.querySelector('#pokedexGrid')?.dataset?.view ?? 'none';
            const $pokemonCells = document.querySelectorAll('#pokedexGrid>.pokemonCell');
            createRegisterEvent($pokemonCells);

            const currRegistered = document.getElementById('registeredCount').dataset;

            pokedexStruct.registered = currRegistered.registered;
            pokedexStruct.total = currRegistered.total;
            updateRegistered();
        },
    });
}

function updateRegistered() {
    $monsRegistered.innerHTML = `${pokedexStruct.registered} / ${pokedexStruct.total} Registered`;
    const percentage = pokedexStruct.registered / pokedexStruct.total;
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

    return await postWrapper({
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

    if (pokedexStruct.view === 'shadowshiny') {
        if (missing) condition = `[data-shadowshiny=false]`;
        string += 'shadow&shiny&';
    } else if (pokedexStruct.view === 'shadow') {
        if (missing) condition = `[data-shadow=false]`;
        string += 'shadow&';
    } else if (pokedexStruct.view === 'shiny') {
        if (missing) condition = `[data-shiny=false]`;
        string += 'shiny&';
    } else {
        if (missing) condition = `[data-caught=false]`;
        string += '';
    }

    const cells = document.querySelectorAll(`div.pokemonCell${condition}`);
    cells.forEach((cell) => {
        string += `${cell.dataset.number},`;
    });

    copyString(Array.from($btns), string);
}

export const runtime = {
    all: () => {
        Array.from($copySearchStringBtn).forEach((btn) => {
            lockCopyButtonWidth(btn);
            btn.addEventListener('click', () => {
                copySearchString($copySearchStringBtn, false);
            });
        });

        Array.from($copyMissingSearchStringBtn).forEach((btn) => {
            lockCopyButtonWidth(btn);
            btn.addEventListener('click', () => {
                copySearchString($copyMissingSearchStringBtn, true);
            });
        });

        document.body.classList.toggle('pokedex-locked', pokedexStruct.lock === 'true');

        Array.from($pokedexLock).forEach((btn) => {
            lockButtonWidth(btn, '<i class="bi bi-lock me-1"></i>Unlocked');
            if (pokedexStruct.lock === 'true') {
                btn.innerHTML = '<i class="bi bi-lock me-1"></i>Locked';
            }
            btn.addEventListener('click', () => {
                toggleLock();
            });
        });

        Array.from($shinyToggle).forEach((btn) => {
            btn.addEventListener('click', async () => {
                await toggleShiny();
            });
        });

        Array.from($registerAllBtn).forEach((btn) => {
            btn.addEventListener('click', () => {
                registerAllConfirm();
            });
        });

        ['mouseup'].forEach((event) => {
            document.addEventListener(event, (evt) => {
                evt.preventDefault();
                pokedexStruct.mousedown = false;
                pokedexStruct.catching = false;
            });
        });
    },
    mypokedex: () => {
        pokedexStruct.region = $pokedexTable.dataset.region;
        pokedexStruct.shiny = $pokedexTable.dataset.shiny === 'true';
        switchPokedex(pokedexStruct.region);

        Array.from(document.querySelectorAll('.pokedex-link')).forEach((navBtn) => {
            navBtn.addEventListener('click', () => {
                if (
                    !pokedexStruct.catching &&
                    !pokedexStruct.mousedown &&
                    pokedexStruct.region !== navBtn.dataset.region
                ) {
                    pokedexStruct.region = navBtn.dataset.region;
                    switchPokedex(pokedexStruct.region);
                }
            });
        });
    },
    mycustompokedex: () => {
        pokedexStruct.shiny = $customPokedexTable.dataset.shiny === 'true';
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

        if (window.innerHeight > document.getElementById('mainSection').scrollHeight) {
            fetchCustomPokedexList(fetchStruct.counter);
        }

        const scrollHandler = async () => {
            const atBottom =
                document.getElementById('mainSection').getBoundingClientRect().bottom <= window.innerHeight + 150;
            if (atBottom && !fetchStruct.loadingList) {
                fetchStruct.loadingList = true;
                await fetchCustomPokedexList(fetchStruct.counter);
                fetchStruct.loadingList = false;
            }
        };

        // Remove old listeners before adding new ones
        window.removeEventListener('scroll', fetchStruct.scrollHandler);
        window.removeEventListener('resize', fetchStruct.resizeHandler);

        fetchStruct.scrollHandler = scrollHandler;
        fetchStruct.resizeHandler = scrollHandler;

        // Listen on scroll and window resize
        window.addEventListener('scroll', fetchStruct.scrollHandler);
        window.addEventListener('resize', fetchStruct.resizeHandler);

        createCustomSearch('customSearch', 'Search a Pokedex...', true, '');
    },
    myshadowpokedex: () => {
        pokedexStruct.shiny = $shadowPokedexTable.dataset.shiny === 'true';
        pokedexStruct.shadow = true;
        switchShadowPokedex();
    },
};
