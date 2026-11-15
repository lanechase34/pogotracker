import { createAlert } from 'alert';
import { appendHtml, delegate, isMobileDisplay } from 'display';
import { escapeHtml } from 'escape';
import { csrfToken, getWrapper, HandledError, postWrapper, RequestError, requestErrorMessage } from 'fetch';
import { resizeHomeCards } from 'home';
import { $loading, $submitBtn, addLoadMoreButton } from 'loading';
import { confirmModal } from 'modals';
import { createToast } from 'toast';

export const $blogListDiv = document.getElementById('blogList');
const $submitBlogCommentBtn = /** @type {HTMLButtonElement} */ (document.getElementById('submitBlogComment'));
const $blogComment = /** @type {HTMLTextAreaElement} */ (document.getElementById('blogComment'));
const $blogData = document.getElementById('blogData');
const $blogBodyDiv = document.getElementById('blogDiv');
const blogFetchStruct = {
    loadingBlogs: false,
    currOffset: 0,
    count: 6,
    max: 8,
    // False once a batch comes back short - there are no more blogs to load
    hasMore: true,
    /** @type {IntersectionObserver | null} */
    observer: null,
};

/**
 * Load More fetches blogFetchStruct.count more cards per click, until a batch comes back short
 */
function showLoadMoreButton($div, { showImage, exclude, sidebar }) {
    addLoadMoreButton(
        $div,
        async () => {
            const loaded = await fetchBlogBatch({
                $div,
                count: blogFetchStruct.count,
                offset: blogFetchStruct.currOffset,
                showImage,
                exclude,
                sidebar,
            });
            // A failed batch keeps the button for a retry
            return !loaded || blogFetchStruct.hasMore;
        },
        { id: 'blogLoadMoreBtn' }
    );
}

/**
 * Fetch one batch of blog cards and append it - offset 0 replaces whatever is in the list
 */
async function fetchBlogBatch({ $div, count, offset, showImage, exclude, sidebar }) {
    return await getWrapper({
        url: `/blog/getBlogs/count/${count}/offset/${offset}/showimage/${showImage}/exclude/${exclude}/sidebar/${sidebar}`,
        $loadingDiv: offset === 0 ? $div : null,
        loading: $loading,
        dataHandler: (data) => {
            if (offset === 0) {
                $div.innerHTML = '';
                document.getElementById('blogLoadMoreBtn')?.remove();
            }

            const newDiv = appendHtml($div, data);

            if (document.getElementById('homeCards')) {
                resizeHomeCards();
            }

            blogFetchStruct.currOffset = offset + count;
            blogFetchStruct.hasMore = newDiv.querySelectorAll('.blogCard').length === count;
        },
    });
}

/**
 * Fill the blog list up to the page max,
 * then hand off to the Load More button, which fetches blogFetchStruct.count more per click
 * offset is how many cards were requested for the server rendered list - 0 fetches everything up to the max
 * in one request, otherwise the rest is fetched in one request once the end of the list nears the viewport.
 */
export async function getBlogs({ $div, offset, showImage, exclude, sidebar }) {
    const currentMax = isMobileDisplay() ? blogFetchStruct.count : blogFetchStruct.max;
    blogFetchStruct.observer?.disconnect();

    const finish = () => {
        if (!sidebar && blogFetchStruct.hasMore) {
            showLoadMoreButton($div, { showImage, exclude, sidebar });
        }
    };

    if (offset === 0) {
        await fetchBlogBatch({ $div, count: currentMax, offset: 0, showImage, exclude, sidebar });
    } else {
        blogFetchStruct.currOffset = offset;
        // Server rendered fewer cards than it asked for - that was every blog
        blogFetchStruct.hasMore = $div.querySelectorAll('.blogCard').length === offset;
    }

    if (!blogFetchStruct.hasMore || blogFetchStruct.currOffset >= currentMax) {
        finish();
        return;
    }

    const $sentinel = document.createElement('div');
    $div.after($sentinel);

    const observer = new IntersectionObserver(
        async (entries) => {
            if (!entries.some((entry) => entry.isIntersecting) || blogFetchStruct.loadingBlogs) return;
            observer.disconnect();
            $sentinel.remove();

            blogFetchStruct.loadingBlogs = true;
            await fetchBlogBatch({
                $div,
                count: currentMax - blogFetchStruct.currOffset,
                offset: blogFetchStruct.currOffset,
                showImage,
                exclude,
                sidebar,
            });
            blogFetchStruct.loadingBlogs = false;
            finish();
        },
        { rootMargin: '0px 0px 500px 0px' }
    );
    blogFetchStruct.observer = observer;
    observer.observe($sentinel);
}

function rawParser(block) {
    return block.data.html;
}

function codeParser(block) {
    return `<pre style='margin-left: ${Number(block.tunes?.indentTune?.indentLevel) || 0}rem'><code>${escapeHtml(block.data.code)}</code></pre>`;
}

function imageParser(block) {
    // Captions are inline HTML in Editor.js - strip tags for the alt text
    const caption = new DOMParser().parseFromString(block.data?.caption ?? '', 'text/html').body.textContent;
    return `<img src='${escapeHtml(block.data.file.url)}' alt='${escapeHtml(caption || 'Extra blog image')}' class='extraBlogImage'/>`;
}

async function submitBlog($blogDivEditor, $blogSubmitBtn, submitUrl) {
    const header = /** @type {HTMLInputElement} */ (document.getElementById('blogheader')).value;
    const body = await $blogDivEditor.save();

    if (!header.length || !body.blocks.length) {
        createAlert(document.getElementById('blogAlert'), 'danger', 'bi-exclamation-diamond-fill', 'Invalid Blog Add');
        return false;
    }

    const bodyhtml = edjsHTML({
        raw: rawParser,
        code: codeParser,
        image: imageParser,
    }).parse(body);

    const packet = new FormData(/** @type {HTMLFormElement} */ (document.getElementById('writeblogform')));
    packet.append('blogbodyjson', JSON.stringify(body));
    packet.append('blogbody', JSON.stringify(bodyhtml));

    return postWrapper({
        url: submitUrl,
        $loadingBtn: $blogSubmitBtn,
        loading: $submitBtn,
        packet,
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                $blogSubmitBtn.disabled = false;
                $blogSubmitBtn.innerHTML = 'Write Blog';
                createAlert(
                    document.getElementById('blogAlert'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    'Invalid Blog Add'
                );
                throw new HandledError();
            } else {
                window.location.href = '/';
            }
        },
    });
}

const COMMENT_MAX_LENGTH = 1000;
const ADD_COMMENT_LABEL = '<i class="bi bi-chat-left-text me-1"></i>Add Comment';

/**
 * Show the comment count, and the empty message when there are none
 *
 * @param {number} change - comments added (+) or removed (-)
 */
function setCommentCount(change) {
    const $count = document.getElementById('commentCount');
    const total = Math.max(0, Number($count.textContent) + change);
    $count.textContent = String(total);
    document.getElementById('noComments').classList.toggle('d-none', total > 0);
}

/**
 * Character counter under the comment box - the button only enables with something to post
 */
function updateCommentCounter() {
    const length = $blogComment.value.length;
    const $counter = document.getElementById('blogCommentCount');
    $counter.textContent = `${length} / ${COMMENT_MAX_LENGTH}`;
    $counter.classList.toggle('text-danger', length >= COMMENT_MAX_LENGTH);
    $submitBlogCommentBtn.disabled = !$blogComment.value.trim().length;
}

async function submitBlogComment() {
    const comment = $blogComment.value.trim();
    if (!comment.length || $submitBlogCommentBtn.disabled) return;

    const packet = new FormData();
    packet.append('comment', comment);
    packet.append('blogid', $blogData.dataset.blogid);

    return await postWrapper({
        url: '/blog/addComment',
        $loadingBtn: $submitBlogCommentBtn,
        loading: $submitBtn,
        packet,
        responseType: 'json',
        dataHandler: (data) => {
            // Just banned (or already) - the comment box goes, leaving the notice
            if (data.banned) {
                document.getElementById('commentAlert').innerHTML = '';
                document.getElementById('commentCompose').outerHTML =
                    `<p class="text-muted small mb-0">${escapeHtml(data.message)}</p>`;
                throw new HandledError();
            }
            // The server's message says what to fix (too long, banned words, rate limited)
            if (!data.success) throw new RequestError(data.message);

            const $commentList = document.getElementById('commentList');
            document.getElementById('commentAlert').innerHTML = '';
            $commentList.insertAdjacentHTML('beforeend', data.data.html);
            setCommentCount(1);

            $blogComment.value = '';
            $submitBlogCommentBtn.innerHTML = ADD_COMMENT_LABEL;
            updateCommentCounter();
            $commentList.lastElementChild?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        },
        errorHandler: (error) => {
            if (error instanceof HandledError) return;
            createAlert(
                document.getElementById('commentAlert'),
                'danger',
                'bi-exclamation-diamond-fill',
                escapeHtml(requestErrorMessage(error))
            );
            updateCommentCounter();
        },
    });
}

/**
 * Put the page of comments before the oldest one shown above the list
 *
 * @param {HTMLButtonElement} $btn - the show older comments button, holding the oldest shown id
 */
async function loadOlderComments($btn) {
    if ($btn.disabled) return;
    $btn.disabled = true;

    const params = new URLSearchParams({ blogid: $blogData.dataset.blogid, beforeid: $btn.dataset.beforeid });
    await getWrapper({
        url: `/blog/getComments?${params}`,
        $loadingDiv: null,
        loading: '',
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) throw new RequestError(data.message);

            document.getElementById('commentList').insertAdjacentHTML('afterbegin', data.data.html);
            $btn.dataset.beforeid = String(data.data.oldestid);
            document.getElementById('olderCommentCount').textContent = String(data.data.remaining);
            $btn.classList.toggle('d-none', data.data.remaining <= 0);
        },
    });
    $btn.disabled = false;
}

/**
 * @param {HTMLButtonElement} $btn - the comment's delete button
 */
function deleteCommentConfirm($btn) {
    confirmModal(
        'Delete this comment? Its author will be banned from commenting.',
        '<i class="bi bi-trash me-1"></i>Delete',
        async () => {
            await deleteComment($btn);
        }
    );
}

/**
 * @param {HTMLButtonElement} $btn - the comment's delete button
 */
async function deleteComment($btn) {
    const packet = new FormData();
    packet.append('commentid', $btn.dataset.commentid);

    return await postWrapper({
        url: '/blog/deleteComment',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet,
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) throw new RequestError(data.message);

            document.getElementById(`comment${$btn.dataset.commentid}`)?.remove();
            setCommentCount(-1);
            createToast('Comment deleted. Its author can no longer comment.', 'success', 'bi-check-square-fill');
        },
    });
}

export const runtime = {
    all: () => {
        if ($blogBodyDiv) {
            const $blogDivEditor = new EditorJS({
                holder: 'blogDiv',
                placeholder: 'Blog content...',
                tools: {
                    paragraph: {
                        class: Paragraph,
                        config: {
                            preserveBlank: true,
                        },
                    },
                    header: {
                        class: Header,
                        config: {
                            levels: [1, 2, 3, 4, 5, 6],
                            defaultLevel: 3,
                        },
                    },
                    raw: RawTool,
                    image: {
                        class: ImageTool,
                        config: {
                            endpoints: {
                                byFile: '/blog/addImage',
                            },
                            // ImageTool uploads with its own request, not postWrapper - cbcsrf needs the token on it
                            additionalRequestHeaders: { 'x-csrf-token': csrfToken() },
                            types: 'images/webp',
                        },
                    },
                    list: {
                        class: EditorjsList,
                        inlineToolbar: true,
                        config: {
                            defaultStyle: 'unordered',
                        },
                    },
                    quote: {
                        class: Quote,
                        config: {
                            quotePlaceholder: 'Enter a quote',
                            captionPlaceholder: "Quote's author",
                        },
                    },
                    code: CodeTool,
                },
                data: bodyJson,
            });

            const $blogSubmitBtn = document.getElementById('submitBlog');
            $blogSubmitBtn.addEventListener('click', () => {
                submitBlog($blogDivEditor, $blogSubmitBtn, document.getElementById('writeblogform').dataset.submit);
            });
        }

        if ($blogListDiv) {
            getBlogs({
                $div: $blogListDiv,
                offset: 0,
                showImage: true,
                exclude: $blogListDiv.dataset.blogid,
                sidebar: true,
            });
        }
    },
    read: () => {
        if ($submitBlogCommentBtn) {
            updateCommentCounter();
            $blogComment.addEventListener('input', updateCommentCounter);
            $blogComment.addEventListener('keydown', (evt) => {
                if (evt.key === 'Enter' && (evt.ctrlKey || evt.metaKey)) {
                    evt.preventDefault();
                    submitBlogComment();
                }
            });
            $submitBlogCommentBtn.addEventListener('click', () => {
                submitBlogComment();
            });
        }

        const $olderComments = /** @type {HTMLButtonElement | null} */ (document.getElementById('olderComments'));
        $olderComments?.addEventListener('click', () => loadOlderComments($olderComments));

        // One listener for every delete button, including comments added after load
        const $commentList = document.getElementById('commentList');
        if ($commentList) {
            delegate($commentList, 'click', '.deleteComment', (evt, $btn) =>
                deleteCommentConfirm(/** @type {HTMLButtonElement} */ ($btn))
            );
        }
    },
};
