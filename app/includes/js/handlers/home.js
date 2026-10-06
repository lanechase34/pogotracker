import { $blogListDiv, blogFetchStruct, getBlogs } from 'blog';
import { getWrapper } from 'fetch';
import { $loading } from 'loading';
import { createPokemonSearch } from 'search';
import { $leaderboardDiv, getLeaderboard } from 'stats';

const $newsDiv = document.getElementById('newsDiv');
const $eventsDiv = document.getElementById('eventsDiv');
const scrapeMaxOffset = 25;

export function resizeHomeCards() {
    new Masonry('.homeCards', {
        itemSelector: '.homeCard',
        columnWidth: '.col-md-4',
    });
}

async function getNews() {
    return await getWrapper({
        url: '/blog/getNews',
        $loadingDiv: $newsDiv,
        loading: $loading,
        dataHandler: (data) => {
            $newsDiv.innerHTML = data;

            const $list = document.getElementById('newsList');
            if ($list) showLoadMoreButton($list, { url: '/blog/getNews', itemSelector: '.newsItem' });
        },
    });
}

function showLoadMoreButton($list, { url, itemSelector }) {
    const count = parseInt($list.dataset.count);
    const loadMoreHtml = '<i class="bi bi-arrow-down-circle me-2"></i>Load More';

    // Only show load more button if we retrieved the maximum count and are within the max offset
    const canLoadMore = (returned) => {
        const offset = $list.querySelectorAll(itemSelector).length;
        return returned === count && offset <= scrapeMaxOffset;
    };

    if (!canLoadMore($list.querySelectorAll(itemSelector).length)) return;

    const $btn = document.createElement('button');
    $btn.type = 'button';
    $btn.className = 'btn btn-outline-dark w-100 mt-2';
    $btn.innerHTML = loadMoreHtml;

    $btn.addEventListener('click', async () => {
        $btn.disabled = true;
        $btn.innerHTML =
            '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Loading...';

        const offset = $list.querySelectorAll(itemSelector).length;

        await getWrapper({
            url: `${url}/offset/${offset}`,
            dataHandler: (data) => {
                const newDiv = document.createElement('div');
                newDiv.innerHTML = data;
                const $newItems = newDiv.querySelectorAll(itemSelector);
                $list.append(...$newItems);

                if (canLoadMore($newItems.length)) {
                    $btn.disabled = false;
                    $btn.innerHTML = loadMoreHtml;
                } else {
                    $btn.remove();
                }

                resizeHomeCards();
            },
        });
    });

    $list.after($btn);
}

async function getEvents() {
    return await getWrapper({
        url: '/blog/getEvents',
        $loadingDiv: $eventsDiv,
        loading: $loading,
        dataHandler: (data) => {
            $eventsDiv.innerHTML = data;

            const $list = document.getElementById('eventsList');
            if ($list) showLoadMoreButton($list, { url: '/blog/getEvents', itemSelector: '.eventItem' });
        },
    });
}

async function loadHomeCards() {
    const calls = [];
    if ($blogListDiv)
        calls.push(
            getBlogs({
                $div: $blogListDiv,
                count: blogFetchStruct.count,
                offset: 0,
                showImage: true,
                exclude: -1,
                sidebar: false,
            })
        );
    if ($leaderboardDiv) calls.push(getLeaderboard($leaderboardDiv));
    if ($newsDiv) calls.push(getNews());
    if ($eventsDiv) calls.push(getEvents());

    await Promise.all(calls);
    resizeHomeCards();
}

export const runtime = {
    all: () => {},
    home: () => {
        loadHomeCards();
        createPokemonSearch('pokemonSearch');
    },
};
