import { createAlert } from 'alert';
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
};

export async function getBlogs({ $div, count, offset, showImage, exclude, sidebar, max }) {
    return getWrapper({
        url: `/blog/get/count/${count}/offset/${offset}/showimage/${showImage}/exclude/${exclude}/sidebar/${sidebar}`,
        $loadingDiv: offset === 0 ? $div : null,
        loading: $loading,
        dataHandler: (data) => {
            if (offset === 0) {
                // Blank the loading spinner
                $div.innerHTML = '';
            }

            // Append the blog
            let newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            $div.appendChild(newDiv);

            if (document.getElementById('homeCards')) {
                resizeHomeCards();
            }

            blogFetchStruct.currOffset = offset + count;

            if (blogFetchStruct.currOffset < max && window.innerHeight > $div.offsetHeight) {
                getBlogs({
                    $div: $div,
                    count: blogFetchStruct.count,
                    offset: blogFetchStruct.currOffset,
                    showImage: showImage,
                    exclude: exclude,
                    sidebar: sidebar,
                    max: blogFetchStruct.max,
                });
            } else {
                // Load more blogs on scroll
                addEventListener('scroll', async () => {
                    let atBottom = window.innerHeight + window.scrollY >= $blogList.scrollHeight - 500; //document.body.scrollHeight - 500;
                    if (atBottom && !blogFetchStruct.loadingBlogs && blogFetchStruct.currOffset < max) {
                        blogFetchStruct.loadingBlogs = true;
                        await getBlogs({
                            $div: $div,
                            count: blogFetchStruct.count,
                            offset: blogFetchStruct.currOffset,
                            showImage: showImage,
                            exclude: exclude,
                            sidebar: sidebar,
                            max: blogFetchStruct.max,
                        });
                        blogFetchStruct.loadingBlogs = false;
                    }
                });
            }
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
    let header = document.getElementById('blogheader').value;
    let body = await $blogDivEditor.save();

    if (!header.length || !body.blocks.length) {
        createAlert(document.getElementById('blogAlert'), 'danger', 'bi-exclamation-diamond-fill', 'Invalid Blog Add');
        return false;
    }

    let bodyhtml = edjsHTML({
        raw: rawParser,
        code: codeParser,
        image: imageParser,
    }).parse(body);

    let packet = new FormData(document.getElementById('writeblogform'));
    packet.append('blogbodyjson', JSON.stringify(body));
    packet.append('blogbody', JSON.stringify(bodyhtml));

    return postWrapper({
        url: submitUrl,
        $loadingBtn: $blogSubmitBtn,
        loading: $submitBtn,
        packet: packet,
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

async function submitBlogComment($blogComment, $submitBlogCommentBtn) {
    if (!$blogComment.value.length) return;

    let packet = new FormData();
    packet.append('comment', JSON.stringify($blogComment.value));
    packet.append('blogid', $blogData.dataset.blogid);

    return postWrapper({
        url: '/blog/addComment',
        $loadingBtn: $submitBlogCommentBtn,
        loading: $submitBtn,
        packet: packet,
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                $submitBlogCommentBtn.disabled = false;
                $submitBlogCommentBtn.innerHTML = 'Add Comment';
                createAlert(
                    document.getElementById('commentAlert'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    'Error adding comment. Please try again in a few minutes.'
                );
                throw new Error(data.message);
            } else {
                $blogComment.value = '';
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
                max: blogFetchStruct.max,
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
