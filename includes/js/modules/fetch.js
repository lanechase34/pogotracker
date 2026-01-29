export async function getWrapper({ url, $loadingDiv, loading, dataHandler }) {
    if ($loadingDiv) {
        $loadingDiv.innerHTML = loading;
    }

    await fetch(url, {
        method: 'GET',
    })
        .then((response) => {
            if (response.status == 401) {
                location.href = '/login';
            } else if (!response.ok) {
                throw new Error(`Server error`);
            }
            return response.text();
        })
        .then(dataHandler)
        .catch((error) => {
            console.error('Fetch error:', error);
        });

    return true;
}

export async function postWrapper({ url, $loadingBtn, loading, packet, responseType, dataHandler }) {
    let temp;
    if ($loadingBtn) {
        temp = $loadingBtn.innerHTML;
        $loadingBtn.innerHTML = loading;
        $loadingBtn.disabled = true;
    }

    await fetch(url, {
        method: 'POST',
        headers: {
            Accept: responseType == 'json' ? 'application/json' : 'text/html',
        },
        body: packet,
    })
        .then((response) => {
            return response[responseType]();
        })
        .then(dataHandler)
        .catch((error) => {
            if ($loadingBtn) {
                $loadingBtn.innerHTML = temp;
                $loadingBtn.disabled = false;
            }
            console.error('Fetch error:', error);
        });
}
