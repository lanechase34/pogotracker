import { createAlert } from 'alert';
import { copyString, lockCopyButtonWidth } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
import { $loading, $loadingCard, $submitBtn } from 'loading';
import { resetHandler, submitHandler } from 'modals';

export const $leaderboardDiv = document.getElementById('leaderboardDiv');

const $trackStatsBtn = document.getElementById('trackStats');
const $deltaDiv = document.getElementById('deltaDiv');
const $medalProgressDiv = document.getElementById('medalProgressDiv');
const statLineChartCanvas = document.getElementById('statLineChart');
const chartStruct = {
    currStat: 'xp',
    statLineChart: null,
};
const $chartLabel = document.getElementById('chartLabel');
const lineColor = '#0d6efd'; //'#333333'; //'rgb(75, 192, 192)';

const $statsLoading = {
    trackStats: false,
};

const STAT_UNITS = {
    walked: ' km',
};

export async function getLeaderboard($div) {
    return await getWrapper({
        url: `/stats/leaderboard/stat/XP`,
        $loadingDiv: $div,
        loading: $loading,
        dataHandler: (data) => {
            $div.innerHTML = data;
        },
    });
}

export function initStatsTracker() {
    $trackStatsBtn.addEventListener('click', async () => {
        if ($statsLoading.trackStats) return;

        if (!document.getElementById('trackStatsModal')) {
            $statsLoading.trackStats = true;
            await getTrackStats();
        }
        globalModals.$trackStatsModal.show();
        $statsLoading.trackStats = false;
    });
}

export async function getSummaryStats(trainerid, $div, $profilerow) {
    $div.innerHTML = $loadingCard;
    const packet = {
        startDate: $profilerow.dataset.startdate,
        endDate: $profilerow.dataset.enddate,
        summary: true,
    };

    return await postWrapper({
        url: `/overview/${trainerid}`,
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify(packet),
        responseType: 'text',
        dataHandler: (data) => {
            $div.innerHTML = data;
        },
    });
}

export async function getPokedexStats(trainerid, $div) {
    return await getWrapper({
        url: `/stats/getPokedexStats/trainerid/${trainerid}`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;

            // Add copy missing string handlers
            const $pokedexStatsCard = document.getElementById('pokedexStatsCard');
            const $copyMissing = document.getElementById('copyMissingString');
            const $copyMissingShiny = document.getElementById('copyMissingShinyString');

            lockCopyButtonWidth($copyMissing);
            lockCopyButtonWidth($copyMissingShiny);

            $copyMissing.addEventListener('click', (e) => {
                copyString([e.currentTarget], $pokedexStatsCard.dataset.missingstring);
            });

            $copyMissingShiny.addEventListener('click', (e) => {
                copyString([e.currentTarget], $pokedexStatsCard.dataset.missingshinystring);
            });
        },
    });
}

export async function getMedalSummary(trainerid, $div) {
    return await getWrapper({
        url: `/stats/getMedalSummary/trainerid/${trainerid}`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;
        },
    });
}

/**
 * Loads the trainer's top stat days card
 * @param {number} trainerid
 * @param {HTMLElement} $div
 */
export async function getTopDeltas(trainerid, $div) {
    return await getWrapper({
        url: `/stats/topDeltas/trainerid/${trainerid}`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;

            const buttons = document.querySelectorAll('.topDeltaStat');
            const list = document.getElementById('topDeltaList');
            const deltas = JSON.parse(document.getElementById('topDeltaData').dataset.deltas);

            buttons.forEach((btn) => {
                btn.addEventListener('click', () => {
                    buttons.forEach((b) => {
                        b.classList.remove('active');
                        b.disabled = false;
                    });
                    btn.classList.add('active');
                    btn.disabled = true;

                    list.innerHTML = renderStat(deltas[btn.dataset.stat] ?? [], btn.dataset.stat);
                });
            });

            list.innerHTML = renderStat(deltas['xp'] ?? [], 'xp');
        },
    });
}

/**
 * Renders list items for a stat's top days
 * @param {Array<{date: string, delta: number}>} rows
 * @param {string} stat
 * @returns {string}
 */
function renderStat(rows, stat) {
    if (!rows.length) {
        return `
            <div class="d-grid gap-2 px-3 py-2 rounded shadow-sm bg-body-secondary text-center">
                <span class="text-center text-muted py-3">No data available</span>
            </div>
            `;
    }

    const unit = STAT_UNITS[stat] ?? '';

    return rows
        .map(
            (row, i) => `
                <div class="d-flex align-items-center gap-2 px-3 py-2 rounded shadow-sm bg-body-secondary">
                    <span class="text-muted small" style="min-width: 1rem; text-align: right;">${i + 1}.</span>
                    <span class="text-muted small flex-grow-1">${row.date}</span>
                    <span class="fw-semibold small">${fmtStatValue(row.delta)}${unit}</span>
                </div>
            `
        )
        .join('');
}

async function getTrackStats() {
    return await getWrapper({
        url: '/stats/trackForm',
        $loadingDiv: null,
        loading: $loading,
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            const $trackStatsModal = document.getElementById('trackStatsModal');
            globalModals.$trackStatsModal = new bootstrap.Modal($trackStatsModal, {});
            const $trackStatsForm = document.getElementById('trackStatsForm');
            const $submitTrackStatsForm = document.getElementById('submitTrackStatsForm');

            $submitTrackStatsForm.addEventListener('click', async (evt) => {
                const valid = $trackStatsForm.checkValidity();
                $trackStatsForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                const formData = new FormData($trackStatsForm);
                const packet = Object.fromEntries(formData.entries());

                // Warn if any entered value is lower than the latest tracked stat
                if (!$submitTrackStatsForm.dataset.confirmed) {
                    const dataset = $trackStatsForm.dataset;
                    const checks = [
                        { key: 'xp', label: 'Total XP', latest: dataset.latestXp },
                        { key: 'caught', label: 'Pokemon Caught', latest: dataset.latestCaught },
                        { key: 'spun', label: 'Pokestops Spun', latest: dataset.latestSpun },
                        { key: 'walked', label: 'Distance Walked', latest: dataset.latestWalked },
                    ];

                    const warnings = checks
                        .filter(({ key, latest }) => latest !== undefined && Number(packet[key]) < Number(latest))
                        .map(
                            ({ label, latest, key }) =>
                                `<li>${label}: Entered <strong>${packet[key]}</strong>, last entry was <strong>${latest}</strong></li>`
                        )
                        .join('');

                    if (warnings) {
                        createAlert(
                            document.getElementById('statAlert'),
                            'warning',
                            'bi-exclamation-triangle',
                            `Some stats are lower than your last entry - are you sure these are correct?<ul class="mb-0 mt-1">${warnings}</ul>`
                        );

                        $submitTrackStatsForm.textContent = 'Submit Anyway';
                        $submitTrackStatsForm.dataset.confirmed = 'true';
                        return;
                    }
                }

                submitHandler($trackStatsModal, $submitTrackStatsForm, false);
                await submitTrackStats(packet, $submitTrackStatsForm, $trackStatsModal);
            });

            $trackStatsForm.addEventListener('input', () => {
                if ($submitTrackStatsForm.dataset.confirmed) {
                    document.getElementById('statAlert').innerHTML = '';
                    $submitTrackStatsForm.textContent = 'Submit';
                    delete $submitTrackStatsForm.dataset.confirmed;
                }
            });
        },
    });
}

async function getMedalProgress($medalProgressDivToLoad) {
    return await getWrapper({
        url: '/stats/getMedalProgress',
        $loadingDiv: $medalProgressDivToLoad,
        loading: $loading,
        dataHandler: (data) => {
            $medalProgressDivToLoad.innerHTML = data;

            const $medalFields = document.querySelectorAll('.medalInput');
            Array.from($medalFields).forEach((input) => {
                input.addEventListener('blur', () => {
                    if (validateMedalInput(input)) {
                        trackMedalProgress(input);
                    }
                });
                input.addEventListener('input', () => {
                    validateMedalInput(input);
                });
            });
        },
    });
}

async function loadStatCards() {
    const calls = [getLeaderboard($leaderboardDiv), getMedalProgress($medalProgressDiv)];

    await Promise.all(calls);
    resizeStatCards();
}

function statLabel(stat) {
    return stat === 'xp' ? 'XP' : stat.charAt(0).toUpperCase() + stat.slice(1);
}

function fmtStatValue(v) {
    const n = Number(v);
    return v !== null && v !== undefined && v !== '' && !isNaN(n)
        ? n.toLocaleString(undefined, { maximumFractionDigits: 0 })
        : (v ?? '--');
}

function renderDeltaTable(stat) {
    const label = statLabel(stat);
    document.getElementById('deltaLabel').textContent = `Delta ${label}`;
    document.getElementById('deltaStatHeader').textContent = label;

    document.getElementById('deltaTableBody').innerHTML = statDataset.labels
        .map((date) => {
            const val = statDataset.data[date][stat];
            const delta = statDataset.data[date][`delta${stat}`];
            return `<tr><td>${date}</td><td>${fmtStatValue(val)}</td><td>${fmtStatValue(delta)}</td></tr>`;
        })
        .join('');
}

function changeStat(stat) {
    if (chartStruct.statLineChart) {
        chartStruct.statLineChart.destroy();
    }

    renderChart(statLineChartCanvas, stat);
    renderDeltaTable(stat);

    $chartLabel.textContent = `${statLabel(stat)} Overview`;

    chartStruct.currStat = stat;
}

function resizeStatCards() {
    const msnry = new Masonry('.statCards', {
        itemSelector: '.statCard',
        columnWidth: '.col-xl-4', // define min column width if not all card columns have same width
    });

    // Relayout after Bootstrap collapse animations complete so Masonry
    // recalculates card positions when a card is expanded/collapsed.
    // Also swap the chevron icon direction to reflect the new state.
    function onCollapseShown(e) {
        msnry.layout();
        const icon = document.querySelector(`[data-bs-target="#${e.target.id}"] .collapse-chevron`);
        icon?.classList.replace('bi-chevron-down', 'bi-chevron-up');
    }
    function onCollapseHidden(e) {
        msnry.layout();
        const icon = document.querySelector(`[data-bs-target="#${e.target.id}"] .collapse-chevron`);
        icon?.classList.replace('bi-chevron-up', 'bi-chevron-down');
    }

    $deltaDiv.addEventListener('shown.bs.collapse', onCollapseShown);
    $deltaDiv.addEventListener('hidden.bs.collapse', onCollapseHidden);
    $medalProgressDiv.addEventListener('shown.bs.collapse', onCollapseShown);
    $medalProgressDiv.addEventListener('hidden.bs.collapse', onCollapseHidden);
}

async function submitTrackStats(packet, $btn, $modal) {
    return await postWrapper({
        url: '/stats/track',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                createAlert(
                    document.getElementById('statAlert'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    `${data.message}`
                );
                resetHandler($modal);
                throw new Error(data.message);
            }
            location.reload();
        },
    });
}

function validateMedalInput($input) {
    const regex = /^\d+$/;
    const value = $input.value.trim();
    const $invalidFeedback = $input.nextElementSibling;
    if (value.length === 0) {
        return false;
    }

    if (isNaN(value) || !regex.test(value)) {
        $invalidFeedback.classList.add('showFeedback');
        return false;
    }

    $invalidFeedback.classList.remove('showFeedback');
    return true;
}

async function trackMedalProgress($input) {
    $input.disabled = true;
    const $parentRow = $input.parentElement.parentElement;
    const medal = $parentRow.dataset.id;
    const value = $input.value.trim();

    return await postWrapper({
        url: '/stats/trackMedalProgress',
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify({ medal, current: value }),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                throw new Error(data.message);
            }

            // Update progress bar
            document.getElementById(`${medal}progressBar`).style.width = `${
                (value * 100) / $parentRow.dataset.platinum
            }%`;

            // Update medal icon
            const $medalImg = document.getElementById(`${medal}icon`);
            if ($medalImg) {
                $medalImg.classList.remove('platinumMedal');
                $medalImg.classList.remove('goldMedal');
                $medalImg.classList.remove('silverMedal');
                $medalImg.classList.remove('bronzeMedal');
                if (value >= parseInt($parentRow.dataset.platinum)) {
                    $medalImg.classList.add('platinumMedal');
                } else if (value >= parseInt($parentRow.dataset.gold)) {
                    $medalImg.classList.add('goldMedal');
                } else if (value >= parseInt($parentRow.dataset.silver)) {
                    $medalImg.classList.add('silverMedal');
                } else if (value >= parseInt($parentRow.dataset.bronze)) {
                    $medalImg.classList.add('bronzeMedal');
                }
            }

            // Re-enable the input
            $input.disabled = false;
        },
    });
}

function renderChart(canvas, stat) {
    const labels = statDataset.labels;
    const data = labels.map((l) => statDataset.data[l][stat]);
    chartStruct.statLineChart = new Chart(canvas, {
        type: 'line',
        data: {
            labels,
            datasets: [
                {
                    label: stat,
                    data,
                    fill: false,
                    borderColor: lineColor,
                    tension: 0.5,
                },
            ],
        },
    });
}

export const runtime = {
    all: () => {},
    overview: () => {
        changeStat(chartStruct.currStat);
        loadStatCards();
        initStatsTracker();

        // Add the change stat handler
        Array.from(document.querySelectorAll('.changeStat')).forEach((stat) => {
            stat.addEventListener('click', (evt) => {
                const $activeBtn = document.querySelector('.changeStat.active');
                $activeBtn.classList.remove('active');
                $activeBtn.disabled = false;

                changeStat(evt.currentTarget.dataset.stat);

                evt.currentTarget.classList.add('active');
                evt.currentTarget.disabled = true;
            });
        });

        const startDateInput = document.getElementById('startDate');
        const endDateInput = document.getElementById('endDate');
        const dateMask = 'MM-DD-YYYY';

        $('#dateRangePicker').daterangepicker(
            {
                startDate: startDateInput.value,
                endDate: endDateInput.value,
                opens: 'center',
                alwaysShowCalendars: true,
                ranges: {
                    'This Week': [moment().startOf('week'), moment().endOf('week')],
                    'Last Week': [
                        moment().subtract(7, 'days').startOf('week'),
                        moment().subtract(7, 'days').endOf('week'),
                    ],
                    'This Month': [moment().startOf('month'), moment().endOf('month')],
                    'Last Month': [
                        moment().subtract(1, 'month').startOf('month'),
                        moment().subtract(1, 'month').endOf('month'),
                    ],
                    'This Year': [moment().startOf('year'), moment().endOf('year')],
                    'Last Year': [
                        moment().subtract(1, 'year').startOf('year'),
                        moment().subtract(1, 'year').endOf('year'),
                    ],
                },
            },
            (start, end) => {
                startDateInput.value = start.format(dateMask);
                endDateInput.value = end.format(dateMask);
                document.getElementById('statsOverviewForm').submit();
            }
        );
    },
};
