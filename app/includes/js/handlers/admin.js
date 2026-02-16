import { createAlert } from 'alert';
import { initCopyIcons } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
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
    return getWrapper({
        url: `/admin/editTrainer/trainerid/${trainerid}`,
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            globalModals.$editProfileModal = new bootstrap.Modal(document.getElementById('editProfileModal'), {});

            let $editProfileForm = document.getElementById('editProfileForm');
            let $submitEditProfileForm = document.getElementById('submitEditProfileForm');

            $submitEditProfileForm.addEventListener('click', async (evt) => {
                let valid = $editProfileForm.checkValidity();
                $editProfileForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                let formData = new FormData($editProfileForm);
                let packet = Object.fromEntries(formData.entries());
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
    return postWrapper({
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
                    render: function (data, type, full, meta) {
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
        let listTrainers = new DataTable($listTrainers, {
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
            rowId: (data) => {
                return data.trainerid;
            },
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
                    render: (data, type, full) => {
                        return `
                            <button type="button" class="editTrainer btn btn-secondary" data-trainerid="${full.trainerid}">
                                <i class="bi bi-wrench"></i>
                            </button>
                        `;
                    },
                },
                {
                    targets: 1,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) => {
                        return `<img class="profileIcon" src="${full.icon}" alt="${full.iconAltText}" loading="lazy">`;
                    },
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

        listTrainers.on('page.dt', function () {
            attachEditProfileHandler();
        });
        listTrainers.on('draw.dt', function () {
            attachEditProfileHandler();
        });
    },
    listpokemon: () => {
        new DataTable($listPokemon, {
            ajax: {
                url: '/admin/getPokemon',
                type: 'GET',
                dataSrc: 'data',
            },
            columns: [
                { data: 'generation' },
                { data: 'number' },
                { data: 'gender' },
                { data: 'name' },
                { data: 'sprite' },
                { data: 'shiny' },
                { data: 'shadow' },
                { data: 'shadowshiny' },
                { data: 'fastmoves' },
                { data: 'chargemoves' },
                { data: 'evolutiontext' },
            ],
            rowId: (data) => {
                return data.pokemonid;
            },
            order: [
                [0, 'asc'],
                [1, 'asc'],
            ],
            columnDefs: [
                {
                    targets: [4, 5, 6, 7, 8, 9, 10],
                    orderable: false,
                    searchable: false,
                },
                {
                    targets: 3,
                    render: (data, type, full) => {
                        return `<a href='/pokemon/${full.ses}' target='_blank'>${full.name}</a>`;
                    },
                },
                {
                    targets: 4,
                    className: 'text-center',
                    render: (data, type, full) => {
                        return `<img class='pokemonIcon' src='${full.sprite}' loading='lazy'>`;
                    },
                },
                {
                    target: 5,
                    className: 'text-center',
                    render: (data, type, full) => {
                        if (!full.shiny.length) return '';
                        return `<img class='pokemonIcon' src='${full.shiny}' loading='lazy'>`;
                    },
                },
                {
                    target: 6,
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
                    target: 7,
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
            lengthMenu: [25, 50, 100],
            scrollY: 'calc(100vh - 250px)',
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
        new DataTable($cacheData, {
            order: [[0, 'asc']],
            pageLength: 50,
            scrollY: 'calc(30vh)',
        });

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
                let $clicked = event.currentTarget;
                let $active = document.querySelector('.moveLink.active');

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
};
