import { createAlert } from 'alert';
import { delegate } from 'display';
import { encodePath, escapeHtml } from 'escape';
import { getWrapper, postWrapper, RequestError, requestErrorMessage } from 'fetch';
import { validatedPacket } from 'form';
import { $loadingCard, $submitBtn } from 'loading';
import { appendLoadedModal, openLoadedModal, resetHandler, submitHandler, toggleCurrentPassword } from 'modals';
import { createAddFriendSearch } from 'search';
import { getMedalSummary, getPokedexStats, getSummaryStats, getTopDeltas, initStatsTracker } from 'stats';

const $friendsListDiv = document.getElementById('friendsListDiv');
const $medalSummaryDiv = document.getElementById('medalSummaryDiv');
const $pendingRequestsDiv = document.getElementById('friendRequestsDiv');
const $pokedexStatsDiv = document.getElementById('pokedexStatsDiv');
const $profilerow = document.getElementById('profilerow');
const $summaryStatsDiv = document.getElementById('summaryStatsDiv');
const trainerid = document.getElementById('mainProfileUsername').dataset.trainerid;
const $editProfile = document.getElementById('editProfile');
const $topDeltasDiv = document.getElementById('topDeltasDiv');

/**
 * @returns {Promise<boolean>} whether the add friend modal loaded
 */
async function getFriendsToAdd() {
    return await getWrapper({
        url: '/friend/getFriendsToAdd',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const $addFriendModal = appendLoadedModal(data, 'addFriendModal');
            globalModals.$addFriendModal = new bootstrap.Modal($addFriendModal, {});

            createAddFriendSearch('friendsToAddSearch');

            const $addFriendForm = /** @type {HTMLFormElement} */ (document.getElementById('addFriendForm'));
            const $submitAddFriendForm = document.getElementById('submitAddFriendForm');

            $submitAddFriendForm.addEventListener('click', async (event) => {
                const packet = validatedPacket($addFriendForm, event);
                if (!packet) return;

                const temp = $submitAddFriendForm.innerHTML;
                submitHandler($addFriendModal, $submitAddFriendForm);

                const sent = await sendFriendRequest(packet, $submitAddFriendForm);

                resetHandler($addFriendModal, $submitAddFriendForm, temp);
                // The wrapper toasts why it failed - keep the modal open so the trainer can retry
                if (!sent) return;

                globalModals.$addFriendModal.hide();
                document.getElementById('addFriendModal').remove();
            });
        },
    });
}

async function getFriendsList($div) {
    return await getWrapper({
        url: `/friend/getFriendsList`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;

            const $addFriendBtn = document.getElementById('addFriendBtn');
            $addFriendBtn.addEventListener('click', () => openLoadedModal('addFriendModal', getFriendsToAdd));

            // One listener for every row - the list reloads into the same div, so only bind it once
            delegate(
                $div,
                'click',
                '.trainerRow',
                (evt, $row) => {
                    window.location.href = $row.dataset.profilelink;
                },
                'rowsBound'
            );
        },
    });
}

async function getFriendRequests($div) {
    return await getWrapper({
        url: `/friend/getFriendRequests`,
        $loadingDiv: $div,
        loading: $loadingCard,
        dataHandler: (data) => {
            $div.innerHTML = data;

            // One listener for every accept/decline button - the requests reload into the same div, so only bind it once
            delegate(
                $div,
                'click',
                '.decideRequest',
                async (evt, $match) => {
                    const $btn = /** @type {HTMLButtonElement} */ ($match);

                    // Accept and deny are decided once - both buttons stay disabled while the request runs
                    const $choices = /** @type {NodeListOf<HTMLButtonElement>} */ (
                        $btn.parentElement.querySelectorAll('.decideRequest')
                    );
                    if (Array.from($choices).some(($choice) => $choice.disabled)) return;
                    $choices.forEach(($choice) => {
                        $choice.disabled = true;
                    });

                    const packet = {};
                    packet.friendrequestid = $btn.parentElement.dataset.friendrequestid;
                    packet.accept = $btn.dataset.accept;
                    const decided = await decideFriendRequest(packet, $btn);

                    // On success the cards reload - on failure let the trainer try again
                    if (!decided) {
                        $choices.forEach(($choice) => {
                            $choice.disabled = false;
                        });
                    }
                },
                'decideBound'
            );
        },
    });
}

async function getEditProfile() {
    return await getWrapper({
        url: '/trainer/editProfile',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const $editProfileModal = appendLoadedModal(data, 'editProfileModal');
            globalModals.$editProfileModal = new bootstrap.Modal($editProfileModal, {});

            const $editProfileForm = /** @type {HTMLFormElement} */ (document.getElementById('editProfileForm'));
            const $submitEditProfileForm = document.getElementById('submitEditProfileForm');
            toggleCurrentPassword($editProfileForm);

            $submitEditProfileForm.addEventListener('click', async (evt) => {
                const packet = validatedPacket($editProfileForm, evt);
                if (!packet) return;
                await updateProfile(packet, $submitEditProfileForm, $editProfileModal);
            });
        },
    });
}

function resizeProfileCards() {
    new Masonry('.profileCards', {
        itemSelector: '.profileCard',
    });
}

// Loads the profile cards and resizes the grid using masonry
// Waits for all profile cards to load before resizing the dom
async function loadProfileCards() {
    const calls = [
        getSummaryStats(trainerid, $summaryStatsDiv, $profilerow),
        getPokedexStats(trainerid, $pokedexStatsDiv),
        getMedalSummary(trainerid, $medalSummaryDiv),
        getTopDeltas(trainerid, $topDeltasDiv),
    ];
    if ($profilerow.dataset.myprofile === 'true') {
        calls.push(getFriendsList($friendsListDiv));
        calls.push(getFriendRequests($pendingRequestsDiv));
        initStatsTracker();
    }
    await Promise.all(calls);
    resizeProfileCards();
}

async function decideFriendRequest(packet, $btn) {
    return await postWrapper({
        url: '/friend/decideFriendRequest',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                throw new RequestError(data.message);
            }
            loadFriendCards();
        },
    });
}

async function sendFriendRequest(packet, $btn) {
    return await postWrapper({
        url: '/friend/sendFriendRequest',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                throw new RequestError(data.message);
            }
            loadFriendCards();
        },
    });
}

async function updateProfile(packet, $btn, $modal) {
    const temp = $btn.innerHTML;
    submitHandler($modal, $btn);
    return await postWrapper({
        url: '/trainer/updateProfile',
        $loadingBtn: null,
        loading: '',
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            resetHandler($modal, $btn, temp);
            if (!data.success) {
                // Show the validation error message
                createAlert(
                    document.getElementById('editProfileAlertDiv'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    escapeHtml(data.message),
                    0
                );
            } else if (data.reverify) {
                // A new email has to be verified before the account can be used again
                location.href = '/verify';
            } else {
                // Update the profile fields
                document.getElementById('profileUsername').textContent = packet.username;
                document.getElementById('mainProfileUsername').textContent = packet.username;
                document.getElementById('sidebarUsername').textContent = packet.username;
                document.getElementById('profileEmail').textContent = packet.email;
                /** @type {HTMLImageElement} */ (document.getElementById('profileIcon')).src =
                    `/includes/images/icons/${encodePath(packet.icon)}.webp`;
                /** @type {HTMLImageElement} */ (document.getElementById('sidebarIcon')).src =
                    `/includes/images/icons/${encodePath(packet.icon)}.webp`;

                globalModals.$editProfileModal.hide();
                document.getElementById('editProfileModal').remove();
            }
        },
        errorHandler: (error) => {
            // Unlock the modal so the trainer can retry or close it
            resetHandler($modal, $btn, temp);
            createAlert(
                document.getElementById('editProfileAlertDiv'),
                'danger',
                'bi-exclamation-diamond-fill',
                escapeHtml(requestErrorMessage(error)),
                0
            );
        },
    });
}

async function loadFriendCards() {
    await Promise.all([getFriendsList($friendsListDiv), getFriendRequests($pendingRequestsDiv)]);
    resizeProfileCards();
}

export const runtime = {
    all: () => {},
    viewprofile: () => {
        loadProfileCards();

        if ($editProfile) {
            $editProfile.addEventListener('click', () => openLoadedModal('editProfileModal', getEditProfile));
        }
    },
};
