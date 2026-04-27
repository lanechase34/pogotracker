import { createAlert } from 'alert';
import { postWrapper } from 'fetch';
import { checkFormValidity } from 'form';
import { $submitBtn } from 'loading';
import { createCustomSearch, createFriendsListSearch, createRegionSelect } from 'search';

const $tradePlanAlert = document.getElementById('tradePlanAlert');
const $submitTradePlan = document.getElementById('submitTradePlan');
const $resetTradePlan = document.getElementById('resetTradePlan');
const $tradePlanForm = document.getElementById('tradePlanForm');
const $tradePlanDiv = document.getElementById('tradePlanDiv');

async function getTradePlan($form, $btn, event) {
    const valid = await checkFormValidity($form, event, false);
    if (!valid) return;

    $tradePlanAlert.innerHTML = '';
    $tradePlanDiv.innerHTML = '';

    const temp = $btn.innerHTML;
    $btn.innerHTML = $submitBtn;
    $btn.disabled = true;

    const formData = new FormData($form);
    const packet = Object.fromEntries(formData.entries());

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
