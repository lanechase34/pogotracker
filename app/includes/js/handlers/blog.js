import { createAlert } from 'alert';
import { isMobileDisplay } from 'display';
import { getWrapper, postWrapper } from 'fetch';
import { resizeHomeCards } from 'home';
import { $loading, $submitBtn } from 'loading';

export const $blogListDiv = document.getElementById('blogList');
const $submitBlogCommentBtn = document.getElementById('submitBlogComment');
const $blogComment = document.getElementById('blogComment');
const $blogData = document.getElementById('blogData');
const $blogList = document.getElementById('blogList');
const $blogBodyDiv = document.getElementById('blogDiv');
export const blogFetchStruct = {
    loadingBlogs: false,
    currOffset: 0,
    count: 4,
    max: 20,
    scrollHandler: () => {},
    resizeHandler: () => {},
};

export async function getBlogs({ $div, count, offset, showImage, exclude, sidebar }) {
    return await getWrapper({
        url: `/blog/get/count/${count}/offset/${offset}/showimage/${showImage}/exclude/${exclude}/sidebar/${sidebar}`,
        $loadingDiv: offset === 0 ? $div : null,
        loading: $loading,
        dataHandler: async (data) => {
            if (offset === 0) {
                // Blank the loading spinner
                $div.innerHTML = '';
            }

            // Append the blog
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            $div.appendChild(newDiv);

            if (document.getElementById('homeCards')) {
                resizeHomeCards();
            }

            blogFetchStruct.currOffset = offset + count;

            const fetchMoreBlogs = async (currentMax) => {
                if (blogFetchStruct.loadingBlogs || blogFetchStruct.currOffset >= currentMax) return;

                blogFetchStruct.loadingBlogs = true;
                await getBlogs({
                    $div,
                    count: blogFetchStruct.count,
                    offset: blogFetchStruct.currOffset,
                    showImage,
                    exclude,
                    sidebar,
                    max: currentMax,
                });
                blogFetchStruct.loadingBlogs = false;
            };

            // Check if the current blogs fill the current window size or we are near the bottom of page
            const checkAndLoad = async () => {
                const currentMax = isMobileDisplay() ? 4 : blogFetchStruct.max;
                const nearBottom = window.innerHeight + window.scrollY >= $blogList.scrollHeight - 500;
                const contentFillsWindow = $div.offsetHeight >= window.innerHeight;

                if (!contentFillsWindow || nearBottom) {
                    await fetchMoreBlogs(currentMax);
                }
            };

            // Remove old listeners before adding new ones
            window.removeEventListener('scroll', blogFetchStruct.scrollHandler);
            window.removeEventListener('resize', blogFetchStruct.resizeHandler);

            blogFetchStruct.scrollHandler = checkAndLoad;
            blogFetchStruct.resizeHandler = checkAndLoad;

            window.addEventListener('scroll', blogFetchStruct.scrollHandler);
            window.addEventListener('resize', blogFetchStruct.resizeHandler);

            // Check immediately in case the window is already large enough
            await checkAndLoad();
        },
    });
}

function rawParser(block) {
    return block.data.html;
}

function codeParser(block) {
    return `<pre style='margin-left: ${block.tunes.indentTune.indentLevel}rem'><code>${block.data.code}</code></pre>`;
}

function imageParser(block) {
    return `<img src='${block.data.file.url}' alt='${
        block.data?.caption ?? 'Extra blog image'
    }' class='extraBlogImage'/>`;
}

async function submitBlog($blogDivEditor, $blogSubmitBtn, submitUrl) {
    const header = document.getElementById('blogheader').value;
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

    const packet = new FormData(document.getElementById('writeblogform'));
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
                window.location = `/home`;
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
                count: blogFetchStruct.count,
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
