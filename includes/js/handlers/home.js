import { blogFetchStruct, $blogListDiv, getBlogs } from 'blog';
import { getWrapper } from 'fetch';
import { $loading } from 'loading';
import { createPokemonSearch } from 'search';
import { $leaderboardDiv, getLeaderboard } from 'stats';
import { isMobileDisplay } from 'display';

const $newsDiv = document.getElementById('newsDiv');
const $eventsDiv = document.getElementById('eventsDiv');

export function resizeHomeCards() {
    new Masonry('.homeCards', {
        itemSelector: '.homeCard',
        columnWidth: '.col-md-4',
    });
}

async function getNews() {
    return getWrapper({
        url: '/blog/getNews',
        $loadingDiv: $newsDiv,
        loading: $loading,
        dataHandler: (data) => {
            $newsDiv.innerHTML = data;
        },
    });
}

async function getEvents() {
    return getWrapper({
        url: '/blog/getEvents',
        $loadingDiv: $eventsDiv,
        loading: $loading,
        dataHandler: (data) => {
            $eventsDiv.innerHTML = data;
        },
    });
}

async function loadHomeCards() {
    let calls = [];
    if ($blogListDiv)
        calls.push(
            getBlogs({
                $div: $blogListDiv,
                count: blogFetchStruct.count,
                offset: 0,
                showImage: true,
                exclude: -1,
                sidebar: false,
                max: isMobileDisplay ? 4 : blogFetchStruct.max,
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
