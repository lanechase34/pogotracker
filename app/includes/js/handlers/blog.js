import { createAlert } from 'alert';
import { isMobileDisplay } from 'display';
import { escapeHtml } from 'escape';
import { csrfToken, getWrapper, postWrapper } from 'fetch';
import { resizeHomeCards } from 'home';
import { $loading, $submitBtn } from 'loading';

export const $blogListDiv = document.getElementById('blogList');
const $submitBlogCommentBtn = document.getElementById('submitBlogComment');
const $blogComment = document.getElementById('blogComment');
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

function showLoadMoreButton($div, { showImage, exclude, sidebar }) {
    document.getElementById('blogLoadMoreBtn')?.remove();

    const $btn = document.createElement('button');
    $btn.id = 'blogLoadMoreBtn';
    $btn.type = 'button';
    $btn.className = 'btn btn-outline-dark w-100 mt-2';
    $btn.innerHTML = '<i class="bi bi-arrow-down-circle me-2"></i>Load More';

    $btn.addEventListener('click', async () => {
        $btn.disabled = true;
        $btn.innerHTML =
            '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Loading...';

        const offset = blogFetchStruct.currOffset;

        await getWrapper({
            url: `/blog/get/count/${blogFetchStruct.count}/offset/${offset}/showimage/${showImage}/exclude/${exclude}/sidebar/${sidebar}`,
            dataHandler: (data) => {
                const newDiv = document.createElement('div');
                newDiv.innerHTML = data;
                $div.appendChild(newDiv);
                blogFetchStruct.currOffset = offset + blogFetchStruct.count;

                if (document.getElementById('homeCards')) {
                    resizeHomeCards();
                }

                // Only show load more button if we retrieved the maximum count for the current offset back
                if (newDiv.querySelectorAll('.blogCard').length === blogFetchStruct.count) {
                    $btn.disabled = false;
                    $btn.innerHTML = '<i class="bi bi-arrow-down-circle me-2"></i>Load More';
                } else {
                    $btn.remove();
                }
            },
        });
    });

    $div.after($btn);
}

/**
 * Fetch one batch of blog cards and append it - offset 0 replaces whatever is in the list
 */
async function fetchBlogBatch({ $div, count, offset, showImage, exclude, sidebar }) {
    return await getWrapper({
        url: `/blog/get/count/${count}/offset/${offset}/showimage/${showImage}/exclude/${exclude}/sidebar/${sidebar}`,
        $loadingDiv: offset === 0 ? $div : null,
        loading: $loading,
        dataHandler: (data) => {
            if (offset === 0) {
                $div.innerHTML = '';
                document.getElementById('blogLoadMoreBtn')?.remove();
            }

            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            $div.appendChild(newDiv);

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
                throw new Error(data.message);
            } else {
                window.location.href = '/';
            }
        },
    });
}

async function submitBlogComment($blogCommentSubmit, $submitBlogCommentBtnClicked) {
    if (!$blogCommentSubmit.value.length) return;

    const packet = new FormData();
    packet.append('comment', $blogCommentSubmit.value.trim());
    packet.append('blogid', $blogData.dataset.blogid);

    return await postWrapper({
        url: '/blog/addComment',
        $loadingBtn: $submitBlogCommentBtnClicked,
        loading: $submitBtn,
        packet,
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                $submitBlogCommentBtnClicked.disabled = false;
                $submitBlogCommentBtnClicked.innerHTML = 'Add Comment';
                createAlert(
                    document.getElementById('commentAlert'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    'Error adding comment. Please try again in a few minutes.'
                );
                throw new Error(data.message);
            } else {
                $blogCommentSubmit.value = '';
                window.location.reload();
            }
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
            $submitBlogCommentBtn.addEventListener('click', () => {
                submitBlogComment($blogComment, $submitBlogCommentBtn);
            });
        }
    },
};
