import { $blogListDiv, getBlogs } from 'blog';
import { layoutMasonry } from 'display';
import { getWrapper } from 'fetch';
import { $loading, addLoadMoreButton } from 'loading';
import { createPokemonSearch } from 'search';
import { $leaderboardDiv, getLeaderboard } from 'stats';

const $newsDiv = document.getElementById('newsDiv');
const $eventsDiv = document.getElementById('eventsDiv');
const scrapeMaxOffset = 25;

export function resizeHomeCards() {
    layoutMasonry('.homeCards', {
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

    // Only show load more button if we retrieved the maximum count and are within the max offset
    const canLoadMore = (returned) => {
        const offset = $list.querySelectorAll(itemSelector).length;
        return returned === count && offset <= scrapeMaxOffset;
    };

    if (!canLoadMore($list.querySelectorAll(itemSelector).length)) return;

    addLoadMoreButton(
        $list,
        async () => {
            const offset = $list.querySelectorAll(itemSelector).length;
            // A failed page keeps the button for a retry
            let more = true;

            await getWrapper({
                url: `${url}/offset/${offset}`,
                dataHandler: (data) => {
                    // Parsed off the page - only the items are moved into the list
                    const newDiv = document.createElement('div');
                    newDiv.innerHTML = data;
                    const $newItems = newDiv.querySelectorAll(itemSelector);
                    $list.append(...$newItems);

                    more = canLoadMore($newItems.length);
                },
            });

            return more;
        },
        // After the button is gone, so the card is measured at its final height
        { onSettled: resizeHomeCards }
    );
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
                // The first batch is server rendered
                offset: parseInt($blogListDiv.dataset.offset ?? '0'),
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
