import { getWrapper } from 'fetch';

export async function getFriendRequestToast() {
    return getWrapper({
        url: '/friend/getFriendRequestToast',
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('toastsDiv').appendChild(newDiv);

            let $friendRequestToast = document.getElementById('friendRequestToast');
            if ($friendRequestToast) {
                let friendToast = new bootstrap.Toast($friendRequestToast);
                friendToast.show();
            }
        },
    });
}
