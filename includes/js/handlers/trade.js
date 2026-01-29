import { createAlert } from 'alert';
import { postWrapper } from 'fetch';
import { checkFormValidity } from 'form';
import { $submitBtn } from 'loading';
import { createFriendsListSearch, createCustomSearch, createRegionSelect } from 'search';

const $tradePlanAlert = document.getElementById('tradePlanAlert');
const $submitTradePlan = document.getElementById('submitTradePlan');
const $resetTradePlan = document.getElementById('resetTradePlan');
const $tradePlanForm = document.getElementById('tradePlanForm');
const $tradePlanDiv = document.getElementById('tradePlanDiv');

async function getTradePlan($form, $btn, event) {
    let valid = await checkFormValidity($form, event, false);
    if (!valid) return;

    $tradePlanAlert.innerHTML = '';
    $tradePlanDiv.innerHTML = '';

    let temp = $btn.innerHTML;
    $btn.innerHTML = $submitBtn;
    $btn.disabled = true;

    let formData = new FormData($form);
    let packet = Object.fromEntries(formData.entries());

    await postWrapper({
        url: `/trade/tradePlan`,
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (data.message.length) {
                createAlert($tradePlanAlert, data.type, 'bi-exclamation-diamond-fill', data.message, 0);
            } else {
                $tradePlanDiv.innerHTML = data.data;
            }
        },
    });

    $btn.innerHTML = temp;
    $btn.disabled = false;
}

export const runtime = {
    all: () => {},
    tradeplanform: () => {
        createFriendsListSearch('inputFriend');
        createCustomSearch('inputCustomPokedex');
        createRegionSelect('inputRegion');

        $submitTradePlan.addEventListener('click', (event) => {
            getTradePlan($tradePlanForm, $submitTradePlan, event);
        });

        $resetTradePlan.addEventListener('click', () => {
            $tradePlanAlert.innerHTML = '';
            $tradePlanDiv.innerHTML = '';
            $('#inputFriend').val(null).trigger('change');
            $('#inputCustomPokedex').val(null).trigger('change');
            $('#inputRegion').val(null).trigger('change');
        });
    },
};
