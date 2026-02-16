import { createAlert } from 'alert';
import { copyString } from 'copy';
import { getWrapper, postWrapper } from 'fetch';
import { $loading, $submitBtn, $loadingCard } from 'loading';
import { submitHandler, resetHandler } from 'modals';

export const $leaderboardDiv = document.getElementById('leaderboardDiv');

const $trackStatsBtn = document.getElementById('trackStats');
const $medalProgressDiv = document.getElementById('medalProgressDiv');
const statLineChartCanvas = document.getElementById('statLineChart');
const chartStruct = {
    currStat: 'xp',
    statLineChart: null,
};
const lineColor = '#0d6efd'; //'#333333'; //'rgb(75, 192, 192)';

let $statsLoading = {
    trackStats: false,
};

export async function getLeaderboard($div) {
    return getWrapper({
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
    let packet = {
        startDate: $profilerow.dataset.startdate,
        endDate: $profilerow.dataset.enddate,
        summary: true,
    };

    return postWrapper({
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
    return getWrapper({
        url: `/stats/getPokedexStats/trainerid/${trainerid}`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;

            // Add copy missing string handlers
            const $pokedexStatsCard = document.getElementById('pokedexStatsCard');
            document.getElementById('copyMissingString').addEventListener('click', (e) => {
                copyString([e.currentTarget], $pokedexStatsCard.dataset.missingstring);
            });

            document.getElementById('copyMissingShinyString').addEventListener('click', (e) => {
                copyString([e.currentTarget], $pokedexStatsCard.dataset.missingshinystring);
            });
        },
    });
}

export async function getMedalSummary(trainerid, $div) {
    return getWrapper({
        url: `/stats/getMedalSummary/trainerid/${trainerid}`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;
        },
    });
}

async function getTrackStats() {
    return getWrapper({
        url: '/stats/trackForm',
        $loadingDiv: null,
        loading: $loading,
        dataHandler: (data) => {
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            const $trackStatsModal = document.getElementById('trackStatsModal');
            globalModals.$trackStatsModal = new bootstrap.Modal($trackStatsModal, {});
            let $trackStatsForm = document.getElementById('trackStatsForm');
            let $submitTrackStatsForm = document.getElementById('submitTrackStatsForm');

            $submitTrackStatsForm.addEventListener('click', async (evt) => {
                let valid = $trackStatsForm.checkValidity();
                $trackStatsForm.classList.add('was-validated');

                if (!valid) {
                    evt.preventDefault();
                    evt.stopPropagation();
                    return;
                }

                submitHandler($trackStatsModal, $submitTrackStatsForm, false);

                let formData = new FormData($trackStatsForm);
                let packet = Object.fromEntries(formData.entries());

                await submitTrackStats(packet, $submitTrackStatsForm, $trackStatsModal);
            });
        },
    });
}

async function getMedalProgress($medalProgressDiv) {
    return getWrapper({
        url: '/stats/getMedalProgress',
        $loadingDiv: $medalProgressDiv,
        loading: $loading,
        dataHandler: (data) => {
            $medalProgressDiv.innerHTML = data;

            let $medalFields = document.querySelectorAll('.medalInput');
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
    let calls = [getLeaderboard($leaderboardDiv), getMedalProgress($medalProgressDiv)];

    await Promise.all(calls);
    resizeStatCards();
}

function changeStat(stat) {
    if (chartStruct.statLineChart) {
        chartStruct.statLineChart.destroy();
    }

    renderChart(statLineChartCanvas, stat);

    document.getElementById(`delta${chartStruct.currStat}div`).classList.add('d-none');
    document.getElementById(`delta${stat}div`).classList.remove('d-none');

    chartStruct.currStat = stat;
}

function resizeStatCards() {
    new Masonry('.statCards', {
        itemSelector: '.statCard',
        columnWidth: '.col-xl-4', // define min column width if not all card columns have same width
    });
}

async function submitTrackStats(packet, $btn, $modal) {
    return postWrapper({
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
    let regex = /^\d+$/;
    let value = $input.value.trim();
    let $invalidFeedback = $input.nextElementSibling;
    if (value.length == 0) {
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
    let $parentRow = $input.parentElement.parentElement;
    let medal = $parentRow.dataset.id;
    let value = $input.value.trim();

    return postWrapper({
        url: '/stats/trackMedalProgress',
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify({ medal: medal, current: value }),
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
            let $medalImg = document.getElementById(`${medal}icon`);
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
    let labels = statDataset.labels;
    let data = [];
    for (let i = 0; i < labels.length; i++) {
        data.push(statDataset.data[labels[i]][stat]);
    }
    chartStruct.statLineChart = new Chart(canvas, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [
                {
                    label: stat,
                    data: data,
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
                let $activeBtn = document.querySelector('.changeStat.active');
                $activeBtn.classList.remove('active');
                $activeBtn.disabled = false;

                changeStat(evt.currentTarget.dataset.stat);

                evt.currentTarget.classList.add('active');
                evt.currentTarget.disabled = true;
            });
        });

        let startDateInput = document.getElementById('startDate');
        let endDateInput = document.getElementById('endDate');
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
            function (start, end) {
                startDateInput.value = start.format(dateMask);
                endDateInput.value = end.format(dateMask);
                document.getElementById('statsOverviewForm').submit();
            }
        );
    },
};
