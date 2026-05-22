import { createAlert } from 'alert';
import { getWrapper, postWrapper } from 'fetch';
import { $loadingCard, $submitBtn } from 'loading';
import { resetHandler, submitHandler } from 'modals';
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

const $trainerLoading = {
    editProfile: false,
    addFriend: false,
};

async function getFriendsToAdd() {
    return await getWrapper({
        url: '/friend/getFriendsToAdd',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);

            const $addFriendModal = document.getElementById('addFriendModal');
            globalModals.$addFriendModal = new bootstrap.Modal($addFriendModal, {});

            createAddFriendSearch('friendsToAddSearch');

            const $addFriendForm = document.getElementById('addFriendForm');
            const $submitAddFriendForm = document.getElementById('submitAddFriendForm');

            $submitAddFriendForm.addEventListener('click', async (event) => {
                const valid = $addFriendForm.checkValidity();
                $addFriendForm.classList.add('was-validated');

                if (!valid) {
                    event.preventDefault();
                    event.stopPropagation();
                    return;
                }

                const temp = $submitAddFriendForm.innerHTML;
                submitHandler($addFriendModal, $submitAddFriendForm);

                const formData = new FormData($addFriendForm);
                const packet = Object.fromEntries(formData.entries());
                await sendFriendRequest(packet, $submitAddFriendForm);

                resetHandler($addFriendModal, $submitAddFriendForm, temp);
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
            $addFriendBtn.addEventListener('click', async (evt) => {
                if ($trainerLoading.addFriend) return;

                if (!document.getElementById('addFriendModal')) {
                    $trainerLoading.addFriend = true;
                    await getFriendsToAdd(evt);
                }
                globalModals.$addFriendModal.show();
                $trainerLoading.addFriend = false;
            });

            const trainerRows = document.querySelectorAll('.trainerRow');
            Array.from(trainerRows).forEach((row) => {
                row.addEventListener('click', (evt) => {
                    window.location.href = evt.currentTarget.dataset.profilelink;
                });
            });
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
            const $decideBtns = document.querySelectorAll('.decideRequest');
            if ($decideBtns) {
                Array.from($decideBtns).forEach((btn) => {
                    btn.addEventListener('click', async (evt) => {
                        const $btn = evt.currentTarget;
                        const packet = {};
                        packet.friendrequestid = $btn.parentElement.dataset.friendrequestid;
                        packet.accept = $btn.dataset.accept;
                        await decideFriendRequest(packet, $btn);
                    });
                });
            }
        },
    });
}

async function getEditProfile() {
    return await getWrapper({
        url: '/trainer/editProfile',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            const $editProfileModal = document.getElementById('editProfileModal');
            globalModals.$editProfileModal = new bootstrap.Modal($editProfileModal, {});

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
                throw new Error(data.message);
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
                throw new Error(data.message);
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
        $loadingBtn: '',
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
                    data.message,
                    0
                );
            } else {
                // Update the profile fields
                document.getElementById('profileUsername').innerHTML = packet.username;
                document.getElementById('mainProfileUsername').innerHTML = packet.username;
                document.getElementById('sidebarUsername').innerHTML = packet.username;
                document.getElementById('profileEmail').innerHTML = packet.email;
                document.getElementById('profileIcon').src = `/includes/images/icons/${packet.icon}.webp`;
                document.getElementById('sidebarIcon').src = `/includes/images/icons/${packet.icon}.webp`;

                globalModals.$editProfileModal.hide();
                document.getElementById('editProfileModal').remove();
            }
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
            $editProfile.addEventListener('click', async () => {
                if ($trainerLoading.editProfile) return;

                if (!document.getElementById('editProfileModal')) {
                    $trainerLoading.editProfile = true;
                    await getEditProfile();
                }

                globalModals.$editProfileModal.show();
                $trainerLoading.editProfile = false;
            });
        }
    },
};
