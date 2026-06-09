import { createAlert } from 'alert';
import { initCopyIcons } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
import { $submitBtn } from 'loading';
import { startMetricsSocket } from 'socket';
import { createToast } from 'toast';

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
        new DataTable($bugLog, {
            ajax: {
                url: '/admin/getBugs',
                type: 'GET',
                dataSrc: 'data',
            },
            order: [[0, 'desc']],
            columnDefs: [
                {
                    orderable: false,
                    targets: 5,
                    render(data, type, full, meta) {
                        return `
                        <button type="button" class="extendedInfo btn btn-secondary" data-bs-toggle="modal" data-bs-target="#bug-${meta.row}">
                            <i class="bi bi-bug"></i>
                        </button>
                        <div 
                            class="modal fade" 
                            id="bug-${meta.row}" 
                            tabindex="-1"
                            data-bs-backdrop="static" 
                            data-bs-keyboard="false"
                            aria-hidden="true"
                        >
                        <div class="modal-dialog modal-xl modal-dialog-scrollable">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title fs-5"><strong>${full[3]}</strong></h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                                </div>
                                <div class="modal-body">
                                    ${data}
                                </div>
                            </div>
                        </div>
                    `;
                    },
                },
            ],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
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
            order: [[0, 'asc']],
            paging: false,
            searching: false,
            scrollX: true,
        });
    },
    readoverrides: () => {
        const editor = document.getElementById('jsonEditor');
        const formatBtn = document.getElementById('formatBtn');
        const saveBtn = document.getElementById('saveBtn');

        function validate() {
            try {
                JSON.parse(editor.value);
                return true;
            } catch (e) {
                createToast(`Invalid JSON: ${e.message}`, 'danger', 'bi-exclamation-triangle');
                return false;
            }
        }

        function format() {
            try {
                const parsed = JSON.parse(editor.value);
                editor.value = JSON.stringify(parsed, null, 4);
            } catch (e) {
                createToast(`Invalid JSON: ${e.message}`, 'danger', 'bi-exclamation-triangle');
            }
        }

        format();

        formatBtn.addEventListener('click', format);

        saveBtn.addEventListener('click', () => {
            if (validate()) {
                document.getElementById('overridesForm').submit();
            }
        });

        editor.addEventListener('input', () => {
            try {
                JSON.parse(editor.value);
            } catch (e) {
                console.error('Error saving', e);
            }
        });
    },
};
