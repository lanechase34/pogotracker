import { createAlert } from 'alert';
import { copyString, initCopyIcons } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
import { format, validate } from 'json';
import { $submitBtn } from 'loading';
import { startMetricsSocket } from 'socket';

const $listTrainers = document.getElementById('listTrainers');
const tables = {};
const $fastMoveTable = document.getElementById('fastMoveTable');
const $chargeMoveTable = document.getElementById('chargeMoveTable');
const $moveLinks = document.querySelectorAll('.moveLink');
const $auditLog = document.getElementById('auditLog');
const $requestLog = document.getElementById('requestLog');
const $listPokemon = document.getElementById('listPokemon');
const $bugLog = document.getElementById('bugLog');
const $medalData = document.getElementById('medalData');
const $cacheData = document.getElementById('cacheData');
const $taskInfo = document.getElementById('taskInfo');

async function getEditTrainer(trainerid) {
    return await getWrapper({
        url: `/admin/editTrainer/trainerid/${trainerid}`,
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            globalModals.$editProfileModal = new bootstrap.Modal(document.getElementById('editProfileModal'), {});

            const $editProfileForm = document.getElementById('editProfileForm');
            const $submitEditProfileForm = document.getElementById('submitEditProfileForm');

            $submitEditProfileForm.addEventListener('click', async (evt) => {
                const valid = $editProfileForm.checkValidity();
                $editProfileForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                const formData = new FormData($editProfileForm);
                const packet = Object.fromEntries(formData.entries());
                await updateProfile(packet, $submitEditProfileForm);
            });

            initCopyIcons();
        },
    });
}

function initJsonEditor() {
    const editor = document.getElementById('jsonEditor');
    const formatBtn = document.getElementById('formatBtn');
    const saveBtn = document.getElementById('saveBtn');

    format(editor);

    formatBtn.addEventListener('click', () => {
        format(editor);
    });

    saveBtn.addEventListener('click', () => {
        format(editor);
        if (validate(editor)) {
            document.getElementById('overridesForm').submit();
        }
    });
}

function attachEditProfileHandler() {
    Array.from(document.querySelectorAll('.editTrainer')).forEach((btn) => {
        btn.addEventListener('click', async (evt) => {
            if (document.getElementById('editProfileModal')) {
                document.getElementById('editProfileModal').remove();
            }
            await getEditTrainer(evt.currentTarget.dataset.trainerid);
            globalModals.$editProfileModal.show();
        });
    });
}

async function updateProfile(packet, $btn) {
    return await postWrapper({
        url: '/trainer/updateProfile',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                // Show the validation error message
                createAlert(
                    document.getElementById('editProfileAlertDiv'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    data.message,
                    0
                );

                $btn.innerHTML = 'Submit';
                $btn.disabled = false;
            } else {
                window.location.reload();
            }
        },
    });
}

function buildRunTaskResult(response) {
    const $wrapper = document.createElement('div');
    const $alert = document.createElement('div');
    $wrapper.appendChild($alert);

    if (!response.success) {
        $alert.className = 'alert alert-danger';
        $alert.textContent = response.message || 'Unable to run task.';
        return $wrapper;
    }

    const task = response.data;
    $alert.className = `alert ${task.success ? 'alert-success' : 'alert-danger'}`;
    $alert.textContent = task.success ? 'Task completed successfully.' : task.errorMessage;

    const rows = [
        ['Last Run', task.lastRun],
        ['Execution Time (ms)', task.lastExecutionTime],
        ['Total Runs', task.totalRuns],
        ['Total Success', task.totalSuccess],
        ['Total Failures', task.totalFailures],
    ];
    const $table = document.createElement('table');
    $table.className = 'table table-striped table-bordered';
    const $tbody = $table.createTBody();
    rows.forEach(([label, value]) => {
        const $tr = $tbody.insertRow();
        $tr.insertCell().textContent = label;
        $tr.insertCell().textContent = value;
    });
    $wrapper.appendChild($table);

    if (task.success && String(task.result).length) {
        const $heading = document.createElement('h6');
        $heading.textContent = 'Result';
        const $pre = document.createElement('pre');
        $pre.className = 'border rounded p-2 bg-body-tertiary';
        $pre.textContent = task.result;
        $wrapper.append($heading, $pre);
    }

    return $wrapper;
}

function createEl(tag, className = '', text = null) {
    const $el = document.createElement(tag);
    if (className) $el.className = className;
    if (text !== null) $el.textContent = text;
    return $el;
}

/**
 * Classify a stack frame by its source file
 * app       - our cfc/cfm code
 * framework - coldbox/testbox/module cfc/cfm code
 * java      - everything else (lucee internals, jvm, etc)
 */
function frameKind(file) {
    if (!/\.(cfc|cfm|cfml)$/i.test(file)) return 'java';
    if (/[\\/](coldbox|testbox|wirebox|cachebox|logbox|modules|lucee-server)[\\/]/i.test(file)) return 'framework';
    return 'app';
}

/**
 * Split an exception header line into its class name and message
 * e.g. "lucee.runtime.exp.ExpressionException: key [x] doesn't exist"
 */
function splitHeader(header) {
    const match = header.match(/^([\w$]+(?:\.[\w$]+)+)(?::\s?([\s\S]*))?$/);
    if (!match) return { type: '', message: header };
    return { type: match[1], message: (match[2] || '').trim() };
}

/**
 * Parse a java stack trace string into sections (the thrown exception + each "Caused by")
 */
function parseStack(raw) {
    const sections = [];
    let current = null;

    const newSection = (header, isCause) => {
        current = { header, isCause, frames: [], omitted: 0 };
        sections.push(current);
    };

    raw.split(/\r?\n/).forEach((line) => {
        const trimmed = line.trim();
        if (!trimmed.length) return;

        const frame = trimmed.match(/^at\s+(.+?)\((.*)\)$/);
        if (frame) {
            if (!current) newSection('', false);
            const location = frame[2].match(/^(.*):(\d+)$/);
            const file = location ? location[1] : frame[2];
            current.frames.push({
                method: frame[1],
                file,
                line: location ? Number(location[2]) : null,
                kind: frameKind(file),
            });
            return;
        }

        const more = trimmed.match(/^\.\.\.\s*(\d+)\s+more$/);
        if (more && current) {
            current.omitted = Number(more[1]);
            return;
        }

        if (trimmed.startsWith('Caused by:')) {
            newSection(trimmed.slice('Caused by:'.length).trim(), true);
            return;
        }

        // Multi-line exception messages continue the header until the first frame
        if (current && !current.frames.length) {
            current.header += `\n${trimmed}`;
            return;
        }

        newSection(trimmed, sections.length > 0);
    });

    return sections.map((section) => ({ ...section, ...splitHeader(section.header) }));
}

function buildBugMeta(bug) {
    const $dl = createEl('dl', 'bugMeta row mb-0');
    const items = [
        ['Timestamp', bug.timestamp, 'col-sm-6 col-lg-3'],
        ['Trainer', bug.username || 'Anonymous', 'col-sm-6 col-lg-3'],
        ['IP', bug.ip || '---', 'col-sm-6 col-lg-3'],
        ['Bug ID', `#${bug.id}`, 'col-sm-6 col-lg-3'],
        ['Event', bug.event || '---', 'col-12'],
    ];
    items.forEach(([label, value, cols]) => {
        const $wrap = createEl('div', cols);
        const $dd = createEl('dd', label === 'Event' ? 'font-monospace' : '', value);
        $wrap.append(createEl('dt', '', label), $dd);
        $dl.appendChild($wrap);
    });

    const $card = createEl('div', 'card mb-3');
    const $body = createEl('div', 'card-body pb-0');
    $body.appendChild($dl);
    $card.appendChild($body);
    return $card;
}

function buildFrameItem(frame) {
    const kindClass = {
        app: 'bugFrameApp',
        framework: 'bugFrameFramework',
        java: 'bugFrameJava text-body-secondary',
    }[frame.kind];
    const $item = createEl('li', `list-group-item font-monospace ${kindClass}`);

    if (frame.kind === 'java') {
        $item.textContent = `${frame.method} (${frame.file}${frame.line !== null ? `:${frame.line}` : ''})`;
        return $item;
    }

    const $loc = createEl('div', frame.kind === 'app' ? 'fw-semibold' : '');
    $loc.textContent = frame.file;
    if (frame.line !== null) {
        $loc.appendChild(createEl('span', 'badge text-bg-secondary ms-2', `line ${frame.line}`));
    }
    $item.append($loc, createEl('div', 'text-body-secondary small', frame.method));
    return $item;
}

function buildSection(section, index) {
    const $section = createEl('div', 'mb-4');

    const $heading = createEl('div', 'd-flex align-items-center gap-2 mb-2');
    $heading.appendChild(
        createEl(
            'span',
            `badge ${section.isCause ? 'text-bg-warning' : 'text-bg-danger'}`,
            section.isCause ? 'Caused by' : 'Exception'
        )
    );
    if (section.type) $heading.appendChild(createEl('code', 'text-break', section.type));
    $section.appendChild($heading);

    if (section.message) {
        $section.appendChild(
            createEl('div', 'bugExceptionMessage border rounded p-2 mb-2 bg-body-tertiary', section.message)
        );
    }

    if (!section.frames.length) return $section;

    const javaCount = section.frames.filter((f) => f.kind === 'java').length;
    const cfmlCount = section.frames.length - javaCount;

    const $frames = createEl('ul', `bugFrames list-group ${cfmlCount ? '' : 'showAll'}`);
    section.frames.forEach((frame) => $frames.appendChild(buildFrameItem(frame)));

    const $toolbar = createEl(
        'div',
        'd-flex justify-content-between align-items-center mb-1 small text-body-secondary'
    );
    $toolbar.appendChild(
        createEl(
            'span',
            '',
            `${section.frames.length} frames (${cfmlCount} CFML, ${javaCount} Java)${section.omitted ? `, ${section.omitted} more omitted` : ''}`
        )
    );

    if (cfmlCount && javaCount) {
        const id = `bugShowJava-${index}`;
        const $switch = createEl('div', 'form-check form-switch mb-0');
        const $input = createEl('input', 'form-check-input');
        $input.type = 'checkbox';
        $input.id = id;
        $input.addEventListener('change', () => $frames.classList.toggle('showAll', $input.checked));
        const $label = createEl('label', 'form-check-label', 'Show Java frames');
        $label.htmlFor = id;
        $switch.append($input, $label);
        $toolbar.appendChild($switch);
    }

    $section.append($toolbar, $frames);
    return $section;
}

function buildBugDetail(bug) {
    const $wrapper = document.createDocumentFragment();
    const sections = parseStack(bug.stack);
    const hasFrames = sections.some((s) => s.frames.length);

    $wrapper.appendChild(buildBugMeta(bug));

    // The stored message is capped at 250 chars, prefer the full message from the trace
    const top = sections[0];
    const $alert = createEl('div', 'alert alert-danger');
    if (top?.type) $alert.appendChild(createEl('div', 'small font-monospace mb-1 text-break', top.type));
    $alert.appendChild(createEl('div', 'bugExceptionMessage fw-semibold', top?.message || bug.message || 'No message'));
    $wrapper.appendChild($alert);

    // Deepest root cause's first app frame is usually where the problem really is
    const origin = [...sections]
        .reverse()
        .flatMap((s) => s.frames)
        .find((f) => f.kind === 'app');
    if (origin) {
        const $origin = createEl('div', 'card border-danger-subtle mb-4');
        const $body = createEl('div', 'card-body py-2');
        $body.appendChild(createEl('div', 'small text-body-secondary', 'Originated in'));
        const $loc = createEl('div', 'font-monospace fw-semibold text-break', origin.file);
        if (origin.line !== null)
            $loc.appendChild(createEl('span', 'badge text-bg-danger ms-2', `line ${origin.line}`));
        $body.appendChild($loc);
        $origin.appendChild($body);
        $wrapper.appendChild($origin);
    }

    if (hasFrames) {
        $wrapper.appendChild(createEl('h6', 'border-bottom pb-1 mb-3', 'Stack Trace'));
        sections.forEach((section, i) => $wrapper.appendChild(buildSection(section, i)));
    }

    $wrapper.appendChild(createEl('h6', 'border-bottom pb-1 mb-2', 'Raw Output'));
    $wrapper.appendChild(createEl('pre', 'bugRaw border rounded p-2 bg-body-tertiary mb-0', bug.stack || '(empty)'));

    return $wrapper;
}

export const runtime = {
    all: () => {},
    auditlog: () => {
        new DataTable($auditLog, {
            ajax: {
                url: '/admin/getAudits',
                type: 'GET',
                dataSrc: 'data',
            },
            columnDefs: [{ searchable: false, targets: 0 }],
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    buglog: () => {
        const bugModal = new bootstrap.Modal(document.getElementById('bugModal'));
        const $bugModalId = document.getElementById('bugModalId');
        const $bugModalBody = document.getElementById('bugModalBody');
        const $bugModalCopy = document.getElementById('bugModalCopy');
        let currentBug = null;

        const dt = new DataTable($bugLog, {
            ajax: {
                url: '/admin/getBugs',
                type: 'GET',
                dataSrc: 'data',
            },
            columns: [
                { data: 'timestamp', className: 'text-nowrap' },
                { data: 'ip', render: DataTable.render.text() },
                { data: 'event', className: 'bugEventCell font-monospace small', render: DataTable.render.text() },
                { data: 'message', className: 'bugMessageCell', render: DataTable.render.text() },
                { data: 'username', render: DataTable.render.text() },
                {
                    data: null,
                    orderable: false,
                    className: 'text-center',
                    render: () => `
                        <button type="button" class="viewBug btn btn-sm btn-outline-danger" title="View details">
                            <i class="bi bi-bug"></i>
                        </button>
                    `,
                },
            ],
            createdRow: (row, data) => {
                row.querySelector('.bugMessageCell').title = data.message;
            },
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });

        $bugLog.addEventListener('click', (evt) => {
            const $btn = evt.target.closest('.viewBug');
            if (!$btn) return;

            currentBug = dt.row($btn.closest('tr')).data();
            $bugModalId.textContent = `#${currentBug.id}`;
            $bugModalBody.replaceChildren(buildBugDetail(currentBug));
            $bugModalBody.scrollTop = 0;
            bugModal.show();
        });

        $bugModalCopy.addEventListener('click', () => {
            if (currentBug) copyString([$bugModalCopy], currentBug.stack);
        });
    },
    listtrainers: () => {
        const listTrainers = new DataTable($listTrainers, {
            ajax: {
                url: '/admin/getTrainers',
                type: 'GET',
                dataSrc: 'data',
            },
            columns: [
                { data: 'edit' },
                { data: 'icon' },
                { data: 'username' },
                { data: 'email' },
                { data: 'verified' },
                { data: 'securitylevel' },
                { data: 'lastlogin' },
            ],
            rowId: (data) => data.trainerid,
            serverSide: true,
            order: [[6, 'desc']],
            columnDefs: [
                {
                    targets: '_all',
                    className: 'align-middle',
                },
                {
                    targets: 0,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) => `
                            <button type="button" class="editTrainer btn btn-secondary" data-trainerid="${full.trainerid}">
                                <i class="bi bi-wrench"></i>
                            </button>
                        `,
                },
                {
                    targets: 1,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) =>
                        `<img class="profileIcon" src="${full.icon}" alt="${full.iconAltText}" loading="lazy">`,
                },
                {
                    targets: 4,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) => {
                        if (full.verified) return `<i class="bi bi-check mx-1"></i>`;
                        return '';
                    },
                },
                {
                    targets: 5,
                    className: 'align-middle text-center',
                },
            ],
            pageLength: 25,
            lengthMenu: [25, 50, 100],
            scrollY: 'calc(100vh - 250px)',
        });

        listTrainers.on('page.dt', () => {
            attachEditProfileHandler();
        });
        listTrainers.on('draw.dt', () => {
            attachEditProfileHandler();
        });
    },
    listpokemon: () => {
        let isCostume = false;
        const $pokemonViewBtn = document.getElementById('pokemonViewBtn');
        const $costumeViewBtn = document.getElementById('costumeViewBtn');

        const dt = new DataTable($listPokemon, {
            ajax: {
                url: '/admin/getPokemon',
                type: 'GET',
                dataSrc: 'data',
                data: (d) => {
                    d.costume = isCostume;
                    return d;
                },
            },
            columns: [
                { data: 'generation' },
                { data: 'number' },
                { data: 'gender' },
                { data: 'name' },
                { data: 'costumetype' },
                { data: 'sprite' },
                { data: 'shiny' },
                { data: 'shadow' },
                { data: 'shadowshiny' },
                { data: 'fastmoves' },
                { data: 'chargemoves' },
                { data: 'evolutiontext' },
            ],
            rowId: (data) => data.pokemonid,
            order: [
                [0, 'asc'],
                [1, 'asc'],
            ],
            columnDefs: [
                {
                    targets: [5, 6, 7, 8, 9, 10, 11],
                    orderable: false,
                    searchable: false,
                },
                {
                    targets: 4,
                    visible: false,
                },
                {
                    targets: 3,
                    render: (data, type, full) => `<a href='/pokemon/${full.ses}' target='_blank'>${full.name}</a>`,
                },
                {
                    targets: 5,
                    className: 'text-center',
                    render: (data, type, full) => `<img class='pokemonIcon' src='${full.sprite}' loading='lazy'>`,
                },
                {
                    targets: 6,
                    className: 'text-center',
                    render: (data, type, full) => {
                        if (!full.shiny.length) return '';
                        return `<img class='pokemonIcon' src='${full.shiny}' loading='lazy'>`;
                    },
                },
                {
                    targets: 7,
                    className: 'text-center parent',
                    render: (data, type, full) => {
                        if (!full.shadow) return '';
                        return `
                            <img class='pokemonIcon' src='${full.sprite}' loading='lazy'>
                            <img class='shadowIcon' src='${full.shadowicon}' loading='lazy'>
                        `;
                    },
                },
                {
                    targets: 8,
                    className: 'text-center parent',
                    render: (data, type, full) => {
                        if (!full.shadowshiny) return '';
                        return `
                            <img class='pokemonIcon' src='${full.shiny}' loading='lazy'>
                            <img class='shadowIcon' src='${full.shadowicon}' loading='lazy'>
                        `;
                    },
                },
            ],
            serverSide: true,
            pageLength: 25,
            lengthMenu: [10, 25, 50, 100],
            scrollY: 'calc(100vh - 250px)',
        });

        $pokemonViewBtn?.addEventListener('click', () => {
            if (isCostume) {
                isCostume = false;
                dt.column(4).visible(false);
                dt.columns([7, 8, 9, 10]).visible(true);
                dt.ajax.reload();
                $pokemonViewBtn.classList.add('active');
                $costumeViewBtn.classList.remove('active');
            }
        });

        $costumeViewBtn?.addEventListener('click', () => {
            if (!isCostume) {
                isCostume = true;
                dt.column(4).visible(true);
                dt.columns([7, 8, 9, 10]).visible(false);
                dt.ajax.reload();
                $costumeViewBtn.classList.add('active');
                $pokemonViewBtn.classList.remove('active');
            }
        });
    },
    requestlog: () => {
        new DataTable($requestLog, {
            ajax: {
                url: '/admin/getRequests',
                type: 'GET',
                dataSrc: 'data',
            },
            columnDefs: [
                { searchable: false, targets: 0 },
                { className: 'long-cell', targets: [2, 5] },
            ],
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    serverinfo: () => {
        startMetricsSocket();

        const loadingSpinners = document.querySelectorAll('.metricsLoading');
        let firstLoad = true;

        /**
         * JVM Usage Pie Chart
         */
        const jvmChartCanvas = document.getElementById('jvmChart');
        let jvmChart;

        /**
         * Requests line chart
         */
        const requestChartCanvas = document.getElementById('requestChart');
        const MAX_POINTS = 30;
        let requestChart;

        /**
         * appCache donut chart
         */
        const appCacheChartCanvas = document.getElementById('appCacheChart');
        let appCacheChart;

        /**
         * Slow requests table
         */
        const slowRequestsTableBody = document.getElementById('slowRequestsBody');

        /**
         * System Information
         */
        const coresMetric = document.getElementById('coresMetric');
        const processMetric = document.getElementById('processMetric');
        const systemMetric = document.getElementById('systemMetric');

        /**
         * Cache DataTable
         */
        const cacheTable = new DataTable($cacheData, {
            columns: [
                { data: 'storage' },
                { data: 'key' },
                { data: 'created' },
                { data: 'hits', className: 'text-center' },
                { data: 'expired', className: 'text-center', render: (data) => (data ? 'Yes' : 'No') },
                { data: 'lastaccessed' },
                { data: 'lastaccesstimeout', className: 'text-center' },
                { data: 'timeout', className: 'text-center' },
            ],
            order: [[0, 'asc']],
            pageLength: 50,
            scrollY: 'calc(30vh)',
        });

        /**
         * Modal stats elements
         */
        const statLastReap = document.getElementById('statLastReap');
        const statHits = document.getElementById('statHits');
        const statMisses = document.getElementById('statMisses');
        const statEvictions = document.getElementById('statEvictions');
        const statGC = document.getElementById('statGarbageCollections');

        /**
         * Fetch cache data and update table, chart, and modal stats
         */
        async function updateCacheData() {
            try {
                const response = await fetch('/admin/getCacheData');
                const data = await response.json();

                cacheTable.clear().rows.add(data.data).draw(false);

                const appKeyCount = data.data.filter((d) => d.storage === 'appCache').length;
                const available = data.maxObjects - appKeyCount;

                if (!appCacheChart) {
                    appCacheChart = new Chart(appCacheChartCanvas, {
                        type: 'doughnut',
                        data: {
                            labels: ['Used', 'Available'],
                            datasets: [
                                {
                                    label: 'appCache Keys',
                                    data: [appKeyCount, available],
                                    backgroundColor: ['rgba(255, 99, 132, 0.8)', 'rgba(54, 162, 235, 0.8)'],
                                    hoverOffset: 4,
                                    borderWidth: 0,
                                },
                            ],
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                    labels: { color: '#000000' },
                                },
                            },
                            maintainAspectRatio: false,
                            devicePixelRatio: 3,
                            cutout: '50%',
                        },
                    });
                } else {
                    appCacheChart.data.datasets[0].data = [appKeyCount, available];
                    appCacheChart.update('none');
                }

                if (statLastReap) statLastReap.textContent = data.lastReapDateTime;
                if (statHits) statHits.textContent = data.hits;
                if (statMisses) statMisses.textContent = data.misses;
                if (statEvictions) statEvictions.textContent = data.evictionCount;
                if (statGC) statGC.textContent = data.garbageCollections;
            } catch (e) {
                console.error('Error fetching cache data', e);
            }
        }

        updateCacheData();
        setInterval(updateCacheData, 10000);

        /**
         * Listener for when metrics is updated
         */
        document.addEventListener('metricsUpdate', (e) => {
            const metrics = e.detail;
            if (!metrics) return;
            if (firstLoad) {
                /**
                 * Hide loading spinners
                 */
                loadingSpinners.forEach((el) => {
                    el.classList.add('d-none');
                });

                /**
                 * Show JVM Chart and initialize
                 */
                jvmChart = new Chart(jvmChartCanvas, {
                    type: 'doughnut',
                    data: {
                        labels: ['Used', 'Free', 'Max (Unallocated)'],
                        datasets: [
                            {
                                label: 'JVM Memory (MB)',
                                data: [],
                                backgroundColor: [
                                    'rgba(255, 99, 132, 0.8)', // Used
                                    'rgba(54, 162, 235, 0.8)', // Free
                                    'rgba(201, 203, 207, 0.8)', // Unallocated
                                ],
                                hoverOffset: 4,
                                borderWidth: 0,
                            },
                        ],
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: 'top',
                                labels: {
                                    color: '#000000',
                                },
                            },
                        },
                        maintainAspectRatio: false,
                        devicePixelRatio: 3,
                        cutout: '50%',
                    },
                });
                jvmChartCanvas.classList.remove('d-none');

                /**
                 * Show Request Chart and initialize
                 */
                requestChart = new Chart(requestChartCanvas, {
                    type: 'line',
                    data: {
                        labels: [],
                        datasets: [
                            {
                                label: 'Active Requests',
                                data: [],
                                tension: 0.3,
                                fill: false,
                                borderColor: 'rgba(54, 162, 235, 0.8)',
                                backgroundColor: 'rgba(54, 162, 235, 0.8)',
                            },
                        ],
                    },
                    options: {
                        responsive: true,
                        scales: {
                            x: {
                                ticks: { color: '#495057' },
                                grid: { color: '#FFFFFF' },
                                border: { color: 'rgba(108, 117, 125, 0.6)' },
                            },
                            y: {
                                ticks: { color: '#495057', precision: 0, stepSize: 1 },
                                grid: { color: '#FFFFFF' },
                                border: { color: 'rgba(108, 117, 125, 0.6)' },
                                beginAtZero: true,
                            },
                        },
                        plugins: {
                            legend: {
                                labels: {
                                    color: '#000000',
                                },
                            },
                        },
                        backgroundColor: 'transparent',
                        devicePixelRatio: 3,
                    },
                });
                requestChartCanvas.classList.remove('d-none');
                firstLoad = false;
            }

            /**
             * Update JVM Chart
             */
            const used = metrics.memory.usedMB;
            const allocated = metrics.memory.totalMB;
            const max = metrics.memory.maxMB;
            const free = allocated - used;
            const unallocated = max - allocated;

            jvmChart.data.datasets[0].data[0] = used;
            jvmChart.data.datasets[0].data[1] = free;
            jvmChart.data.datasets[0].data[2] = unallocated;
            jvmChart.update('none');

            /**
             * Update active requests chart
             */
            requestChart.data.labels = [
                ...requestChart.data.labels.slice(-MAX_POINTS),
                new Date().toLocaleTimeString(),
            ];
            requestChart.data.datasets[0].data = [
                ...requestChart.data.datasets[0].data.slice(-MAX_POINTS),
                metrics.concurrency.activeRequests,
            ];
            requestChart.update('none');

            /**
             * Slow requests table
             */
            slowRequestsTableBody.innerHTML = '';
            metrics.concurrency.slowRequests.forEach((r) => {
                const tr = document.createElement('tr');

                // Time
                const date = new Date(r.time.replace(',', ''));
                const tdTime = document.createElement('td');
                tdTime.textContent = date.toLocaleString();
                tr.appendChild(tdTime);

                // URL Path
                const tdUrl = document.createElement('td');
                tdUrl.textContent = r.urlpath;
                tdUrl.style.whiteSpace = 'normal';
                tdUrl.style.wordBreak = 'break-word';
                tr.appendChild(tdUrl);

                // Method
                const tdMethod = document.createElement('td');
                tdMethod.textContent = r.method;
                tr.appendChild(tdMethod);

                // Delta
                const tdDelta = document.createElement('td');
                tdDelta.textContent = r.delta;
                tr.appendChild(tdDelta);

                // Trainer ID
                const tdUser = document.createElement('td');
                tdUser.textContent = r.trainerid;
                tr.appendChild(tdUser);

                // Append row to tbody
                slowRequestsTableBody.appendChild(tr);
            });

            /**
             * System Information
             */
            coresMetric.innerHTML = metrics.cpu.cores;
            processMetric.innerHTML = `${metrics.cpu.processPercent}%`;
            systemMetric.innerHTML = `${metrics.cpu.systemPercent}%`;
        });
    },
    showmedaldata: () => {
        new DataTable($medalData, {
            ordering: false,
            paging: false,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    showmovedata: () => {
        tables.fastMoveTable = new DataTable($fastMoveTable, {
            order: [[0, 'asc']],
            pageLength: 25,
            scrollY: 'calc(100vh - 355px)',
        });

        tables.chargeMoveTable = new DataTable($chargeMoveTable, {
            order: [[0, 'asc']],
            pageLength: 25,
            scrollY: 'calc(100vh - 355px)',
        });

        Array.from($moveLinks).forEach((link) => {
            link.addEventListener('click', (event) => {
                const $clicked = event.currentTarget;
                const $active = document.querySelector('.moveLink.active');

                document.getElementById(`${$active.dataset.type}MoveWrapper`).classList.add('d-none');
                document.getElementById(`${$clicked.dataset.type}MoveWrapper`).classList.remove('d-none');

                tables[`${$clicked.dataset.type}MoveTable`].columns.adjust().draw();

                $active.classList.remove('active');
                $clicked.classList.add('active');
            });
        });
    },
    taskmanager: () => {
        new DataTable($taskInfo, {
            order: [[1, 'asc']],
            columnDefs: [{ orderable: false, targets: 0 }],
            paging: false,
            searching: false,
            scrollX: true,
        });

        const $runTaskModalEl = document.getElementById('runTaskModal');
        const runTaskModal = new bootstrap.Modal($runTaskModalEl);
        const $runTaskModalTitle = document.getElementById('runTaskModalTitle');
        const $runTaskModalBody = document.getElementById('runTaskModalBody');

        document.getElementById('runTaskModalReload').addEventListener('click', () => {
            window.location.reload();
        });

        document.querySelectorAll('.runTask').forEach((btn) => {
            btn.addEventListener('click', async (evt) => {
                const $btn = evt.currentTarget;
                const { scheduler, name } = $btn.dataset;
                const originalHtml = $btn.innerHTML;

                await postWrapper({
                    url: '/admin/runTask',
                    $loadingBtn: $btn,
                    loading: $submitBtn,
                    packet: JSON.stringify({ scheduler, name }),
                    responseType: 'json',
                    dataHandler: (data) => {
                        $btn.innerHTML = originalHtml;
                        $btn.disabled = false;

                        $runTaskModalTitle.textContent = name;
                        $runTaskModalBody.replaceChildren(buildRunTaskResult(data));
                        runTaskModal.show();
                    },
                });
            });
        });
    },
    readoverrides: () => {
        initJsonEditor();
    },
    readeventoverrides: () => {
        initJsonEditor();
    },
    readnameoverrides: () => {
        initJsonEditor();
    },
};
