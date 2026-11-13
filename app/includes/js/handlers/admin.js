import { createAlert } from 'alert';
import { copyString } from 'copy';
import { escapeHtml } from 'escape';
import { getWrapper, postWrapper } from 'fetch';
import { format, validate } from 'json';
import { $submitBtn } from 'loading';
import { getLocalStorage, setLocalStorage } from 'localstorage';
import { startMetricsSocket, stopMetricsSocket } from 'socket';

const $listTrainers = document.getElementById('listTrainers');
const tables = {};
const $fastMoveTable = document.getElementById('fastMoveTable');
const $chargeMoveTable = document.getElementById('chargeMoveTable');
const $moveLinks = document.querySelectorAll('.moveLink');
const $auditLog = document.getElementById('auditLog');
const $requestLog = document.getElementById('requestLog');
const $listPokemon = document.getElementById('listPokemon');
const $bugLog = document.getElementById('bugLog');
const $medalData = document.getElementById('medalData');
const $cacheData = document.getElementById('cacheData');
const $taskInfo = document.getElementById('taskInfo');

async function getEditTrainer(trainerid) {
    return await getWrapper({
        url: `/admin/editTrainer/trainerid/${trainerid}`,
        $loadingDiv: null,
        loading: '',
        dataHandler: (data) => {
            const newDiv = document.createElement('div');
            newDiv.innerHTML = data;
            document.getElementById('loadedModal').appendChild(newDiv);
            globalModals.$editProfileModal = new bootstrap.Modal(document.getElementById('editProfileModal'), {});

            const $editProfileForm = /** @type {HTMLFormElement} */ (document.getElementById('editProfileForm'));
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
                await updateProfile(packet, $submitEditProfileForm);
            });
        },
    });
}

function initJsonEditor() {
    const editor = document.getElementById('jsonEditor');
    const formatBtn = document.getElementById('formatBtn');
    const saveBtn = document.getElementById('saveBtn');

    format(editor);

    formatBtn.addEventListener('click', () => {
        format(editor);
    });

    saveBtn.addEventListener('click', () => {
        format(editor);
        if (validate(editor)) {
            /** @type {HTMLFormElement} */ (document.getElementById('overridesForm')).submit();
        }
    });
}

/**
 * One listener on the trainer table for every .editTrainer button - survives DataTables redraws
 */
function attachEditProfileHandler($table) {
    $table.addEventListener('click', async (evt) => {
        const $btn = /** @type {HTMLElement | null} */ (
            /** @type {HTMLElement} */ (evt.target).closest('.editTrainer')
        );
        if (!$btn || !$table.contains($btn)) return;

        if (document.getElementById('editProfileModal')) {
            document.getElementById('editProfileModal').remove();
        }
        await getEditTrainer($btn.dataset.trainerid);
        globalModals.$editProfileModal.show();
    });
}

async function updateProfile(packet, $btn) {
    return await postWrapper({
        url: '/trainer/updateProfile',
        $loadingBtn: $btn,
        loading: $submitBtn,
        packet: JSON.stringify(packet),
        responseType: 'json',
        dataHandler: (data) => {
            if (!data.success) {
                // Show the validation error message
                createAlert(
                    document.getElementById('editProfileAlertDiv'),
                    'danger',
                    'bi-exclamation-diamond-fill',
                    escapeHtml(data.message),
                    0
                );

                $btn.innerHTML = 'Submit';
                $btn.disabled = false;
            } else {
                window.location.reload();
            }
        },
    });
}

function buildRunTaskResult(response) {
    const $wrapper = document.createElement('div');
    const $alert = document.createElement('div');
    $wrapper.appendChild($alert);

    if (!response.success) {
        $alert.className = 'alert alert-danger';
        $alert.textContent = response.message || 'Unable to run task.';
        return $wrapper;
    }

    const task = response.data;
    $alert.className = `alert ${task.success ? 'alert-success' : 'alert-danger'}`;
    $alert.textContent = task.success ? 'Task completed successfully.' : task.errorMessage;

    const rows = [
        ['Last Run', task.lastRun],
        ['Execution Time (ms)', task.lastExecutionTime],
        ['Total Runs', task.totalRuns],
        ['Total Success', task.totalSuccess],
        ['Total Failures', task.totalFailures],
    ];
    const $table = document.createElement('table');
    $table.className = 'table table-striped table-bordered';
    const $tbody = $table.createTBody();
    rows.forEach(([label, value]) => {
        const $tr = $tbody.insertRow();
        $tr.insertCell().textContent = label;
        $tr.insertCell().textContent = value;
    });
    $wrapper.appendChild($table);

    if (task.success && String(task.result).length) {
        const $heading = document.createElement('h6');
        $heading.textContent = 'Result';
        const $pre = document.createElement('pre');
        $pre.className = 'border rounded p-2 bg-body-tertiary';
        $pre.textContent = task.result;
        $wrapper.append($heading, $pre);
    }

    return $wrapper;
}

function createEl(tag, className = '', text = null) {
    const $el = document.createElement(tag);
    if (className) $el.className = className;
    if (text !== null) $el.textContent = text;
    return $el;
}

/**
 * Classify a stack frame by its source file
 * app       - our cfc/cfm code
 * framework - coldbox/testbox/module cfc/cfm code
 * java      - everything else (lucee internals, jvm, etc)
 */
function frameKind(file) {
    if (!/\.(cfc|cfm|cfml)$/i.test(file)) return 'java';
    if (/[\\/](coldbox|testbox|wirebox|cachebox|logbox|modules|lucee-server)[\\/]/i.test(file)) return 'framework';
    return 'app';
}

/**
 * Split an exception header line into its class name and message
 * e.g. "lucee.runtime.exp.ExpressionException: key [x] doesn't exist"
 */
function splitHeader(header) {
    const match = header.match(/^([\w$]+(?:\.[\w$]+)+)(?::\s?([\s\S]*))?$/);
    if (!match) return { type: '', message: header };
    return { type: match[1], message: (match[2] || '').trim() };
}

/**
 * Parse a java stack trace string into sections (the thrown exception + each "Caused by")
 */
function parseStack(raw) {
    const sections = [];
    let current = null;

    const newSection = (header, isCause) => {
        current = { header, isCause, frames: [], omitted: 0 };
        sections.push(current);
    };

    raw.split(/\r?\n/).forEach((line) => {
        const trimmed = line.trim();
        if (!trimmed.length) return;

        const frame = trimmed.match(/^at\s+(.+?)\((.*)\)$/);
        if (frame) {
            if (!current) newSection('', false);
            const location = frame[2].match(/^(.*):(\d+)$/);
            const file = location ? location[1] : frame[2];
            current.frames.push({
                method: frame[1],
                file,
                line: location ? Number(location[2]) : null,
                kind: frameKind(file),
            });
            return;
        }

        const more = trimmed.match(/^\.\.\.\s*(\d+)\s+more$/);
        if (more && current) {
            current.omitted = Number(more[1]);
            return;
        }

        if (trimmed.startsWith('Caused by:')) {
            newSection(trimmed.slice('Caused by:'.length).trim(), true);
            return;
        }

        // Multi-line exception messages continue the header until the first frame
        if (current && !current.frames.length) {
            current.header += `\n${trimmed}`;
            return;
        }

        newSection(trimmed, sections.length > 0);
    });

    return sections.map((section) => ({ ...section, ...splitHeader(section.header) }));
}

function buildBugMeta(bug) {
    const $dl = createEl('dl', 'bugMeta row mb-0');
    const items = [
        ['Timestamp', bug.timestamp, 'col-sm-6 col-lg-3'],
        ['Trainer', bug.username || 'Anonymous', 'col-sm-6 col-lg-3'],
        ['IP', bug.ip || '---', 'col-sm-6 col-lg-3'],
        ['Bug ID', `#${bug.id}`, 'col-sm-6 col-lg-3'],
        ['Event', bug.event || '---', 'col-12'],
    ];
    items.forEach(([label, value, cols]) => {
        const $wrap = createEl('div', cols);
        const $dd = createEl('dd', label === 'Event' ? 'font-monospace' : '', value);
        $wrap.append(createEl('dt', '', label), $dd);
        $dl.appendChild($wrap);
    });

    const $card = createEl('div', 'card mb-3');
    const $body = createEl('div', 'card-body pb-0');
    $body.appendChild($dl);
    $card.appendChild($body);
    return $card;
}

function buildFrameItem(frame) {
    const kindClass = {
        app: 'bugFrameApp',
        framework: 'bugFrameFramework',
        java: 'bugFrameJava text-body-secondary',
    }[frame.kind];
    const $item = createEl('li', `list-group-item font-monospace ${kindClass}`);

    if (frame.kind === 'java') {
        $item.textContent = `${frame.method} (${frame.file}${frame.line !== null ? `:${frame.line}` : ''})`;
        return $item;
    }

    const $loc = createEl('div', frame.kind === 'app' ? 'fw-semibold' : '');
    $loc.textContent = frame.file;
    if (frame.line !== null) {
        $loc.appendChild(createEl('span', 'badge text-bg-secondary ms-2', `line ${frame.line}`));
    }
    $item.append($loc, createEl('div', 'text-body-secondary small', frame.method));
    return $item;
}

function buildSection(section, index) {
    const $section = createEl('div', 'mb-4');

    const $heading = createEl('div', 'd-flex align-items-center gap-2 mb-2');
    $heading.appendChild(
        createEl(
            'span',
            `badge ${section.isCause ? 'text-bg-warning' : 'text-bg-danger'}`,
            section.isCause ? 'Caused by' : 'Exception'
        )
    );
    if (section.type) $heading.appendChild(createEl('code', 'text-break', section.type));
    $section.appendChild($heading);

    if (section.message) {
        $section.appendChild(
            createEl('div', 'bugExceptionMessage border rounded p-2 mb-2 bg-body-tertiary', section.message)
        );
    }

    if (!section.frames.length) return $section;

    const javaCount = section.frames.filter((f) => f.kind === 'java').length;
    const cfmlCount = section.frames.length - javaCount;

    const $frames = createEl('ul', `bugFrames list-group ${cfmlCount ? '' : 'showAll'}`);
    section.frames.forEach((frame) => $frames.appendChild(buildFrameItem(frame)));

    const $toolbar = createEl(
        'div',
        'd-flex justify-content-between align-items-center mb-1 small text-body-secondary'
    );
    $toolbar.appendChild(
        createEl(
            'span',
            '',
            `${section.frames.length} frames (${cfmlCount} CFML, ${javaCount} Java)${section.omitted ? `, ${section.omitted} more omitted` : ''}`
        )
    );

    if (cfmlCount && javaCount) {
        const id = `bugShowJava-${index}`;
        const $switch = createEl('div', 'form-check form-switch mb-0');
        const $input = createEl('input', 'form-check-input');
        $input.type = 'checkbox';
        $input.id = id;
        $input.addEventListener('change', () => $frames.classList.toggle('showAll', $input.checked));
        const $label = createEl('label', 'form-check-label', 'Show Java frames');
        $label.htmlFor = id;
        $switch.append($input, $label);
        $toolbar.appendChild($switch);
    }

    $section.append($toolbar, $frames);
    return $section;
}

function buildBugDetail(bug) {
    const $wrapper = document.createDocumentFragment();
    const sections = parseStack(bug.stack);
    const hasFrames = sections.some((s) => s.frames.length);

    $wrapper.appendChild(buildBugMeta(bug));

    // The stored message is capped at 250 chars, prefer the full message from the trace
    const top = sections[0];
    const $alert = createEl('div', 'alert alert-danger');
    if (top?.type) $alert.appendChild(createEl('div', 'small font-monospace mb-1 text-break', top.type));
    $alert.appendChild(createEl('div', 'bugExceptionMessage fw-semibold', top?.message || bug.message || 'No message'));
    $wrapper.appendChild($alert);

    // Deepest root cause's first app frame is usually where the problem really is
    const origin = [...sections]
        .reverse()
        .flatMap((s) => s.frames)
        .find((f) => f.kind === 'app');
    if (origin) {
        const $origin = createEl('div', 'card border-danger-subtle mb-4');
        const $body = createEl('div', 'card-body py-2');
        $body.appendChild(createEl('div', 'small text-body-secondary', 'Originated in'));
        const $loc = createEl('div', 'font-monospace fw-semibold text-break', origin.file);
        if (origin.line !== null)
            $loc.appendChild(createEl('span', 'badge text-bg-danger ms-2', `line ${origin.line}`));
        $body.appendChild($loc);
        $origin.appendChild($body);
        $wrapper.appendChild($origin);
    }

    if (hasFrames) {
        $wrapper.appendChild(createEl('h6', 'border-bottom pb-1 mb-3', 'Stack Trace'));
        sections.forEach((section, i) => $wrapper.appendChild(buildSection(section, i)));
    }

    $wrapper.appendChild(createEl('h6', 'border-bottom pb-1 mb-2', 'Raw Output'));
    $wrapper.appendChild(createEl('pre', 'bugRaw border rounded p-2 bg-body-tertiary mb-0', bug.stack || '(empty)'));

    return $wrapper;
}

/**
 * Human readable file size - mirrors services.util formatBytes
 *
 * @param {number} bytes
 */
function formatBytes(bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let value = bytes;
    let unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
    }
    return unit === 0 ? `${value} B` : `${value.toFixed(value < 10 ? 1 : 0)} ${units[unit]}`;
}

const LOG_LEVELS = [
    { pattern: /\b(FATAL|SEVERE|ERROR)\b/, level: 'error' },
    { pattern: /\bWARN(ING)?\b/, level: 'warn' },
    { pattern: /\b(DEBUG|TRACE)\b/, level: 'debug' },
];

/**
 * Lines that belong to the entry above them - indented stack frames, "Caused by", "... 12 more" and exception class lines
 */
const LOG_CONTINUATION = /^(\s|Caused by:|Suppressed:|\.\.\. \d+ more|[\w$]+(\.[\w$]+)+(Exception|Error|Throwable)\b)/;

// Entries with more continuation lines than this start collapsed
const LOG_COLLAPSE_AFTER = 3;

const utf8 = new TextEncoder();

/**
 * @param {string} line
 */
function logLineLevel(line) {
    return LOG_LEVELS.find((l) => l.pattern.test(line))?.level ?? '';
}

/**
 * Fill $text with line, each case-insensitive match of query wrapped in <mark>
 * Text nodes only - log lines carry request data (urls, agents) and must never be parsed as html
 *
 * @param {HTMLElement} $text
 * @param {string} line
 * @param {string} query
 */
function highlightLogText($text, line, query) {
    const lower = line.toLowerCase();
    const needle = query.toLowerCase();
    let at = needle ? lower.indexOf(needle) : -1;
    if (at === -1) {
        $text.textContent = line;
        return;
    }

    const parts = [];
    let from = 0;
    while (at !== -1) {
        if (at > from) parts.push(document.createTextNode(line.slice(from, at)));
        parts.push(createEl('mark', 'logMark', line.slice(at, at + needle.length)));
        from = at + needle.length;
        at = lower.indexOf(needle, from);
    }
    if (from < line.length) parts.push(document.createTextNode(line.slice(from)));
    $text.replaceChildren(...parts);
}

/**
 * @param {string} line
 * @param {number} offset byte offset of the line in the file
 * @param {string} className
 * @param {string} query
 */
function buildLogLine(line, offset, className, query) {
    const $line = createEl('div', className);
    $line.dataset.offset = String(offset);
    const $text = createEl('span', 'logText');
    highlightLogText($text, line, query);
    $line.appendChild($text);
    return $line;
}

/**
 * Collapsed entries get a toggle row between the first line and the rest
 *
 * @param {HTMLElement} $entry
 * @param {number} count lines hidden behind the toggle
 */
function addLogToggle($entry, count) {
    const $toggle = createEl('button', 'logToggle', `+ ${count} more lines`);
    $toggle.type = 'button';
    $toggle.dataset.count = String(count);
    $toggle.setAttribute('aria-expanded', 'false');
    $entry.classList.add('collapsed');
    $entry.insertBefore($toggle, $entry.querySelector('.logDetail'));
}

/**
 * @param {HTMLElement} $entry
 * @param {boolean} open
 */
function setLogEntryOpen($entry, open) {
    const $toggle = /** @type {HTMLElement | null} */ ($entry.querySelector('.logToggle'));
    if (!$toggle) return;
    $entry.classList.toggle('collapsed', !open);
    $toggle.setAttribute('aria-expanded', String(open));
    $toggle.textContent = open ? `− hide ${$toggle.dataset.count} lines` : `+ ${$toggle.dataset.count} more lines`;
}

/**
 * One chunk of lines grouped into entries - a line plus the stack trace lines under it
 * Every line records its byte offset (counted from the chunk start) so search matches can be found on the page
 *
 * @param {string[]} lines raw lines, carriage returns included
 * @param {number} start byte offset of the first line
 * @param {number} end byte offset just past the last line
 * @param {string} query text to highlight
 */
function buildLogChunk(lines, start, end, query) {
    const $chunk = createEl('div', 'logChunk');
    $chunk.dataset.start = String(start);
    $chunk.dataset.end = String(end);

    let offset = start;
    let $entry = null;
    let $detail = null;
    let detailCount = 0;

    const finishEntry = () => {
        if ($entry && detailCount > LOG_COLLAPSE_AFTER) addLogToggle($entry, detailCount);
    };

    for (const raw of lines) {
        const line = raw.endsWith('\r') ? raw.slice(0, -1) : raw;
        const lineOffset = offset;
        offset += utf8.encode(raw).length + 1;

        const continuation = LOG_CONTINUATION.test(line);
        if ($entry && continuation) {
            if (!$detail) {
                $detail = createEl('div', 'logDetail');
                $entry.appendChild($detail);
            }
            $detail.appendChild(buildLogLine(line, lineOffset, 'logLine logTrace', query));
            detailCount++;
            continue;
        }

        finishEntry();
        // A chunk can start partway through a stack trace - those lines stand alone, dimmed
        const level = continuation ? '' : logLineLevel(line);
        $entry = createEl('div', 'logEntry');
        $entry.dataset.level = level;
        let className = 'logLine logHead';
        if (level) className += ` log-${level}`;
        if (continuation) className += ' logTrace';
        $entry.appendChild(buildLogLine(line, lineOffset, className, query));
        $chunk.appendChild($entry);
        $detail = null;
        detailCount = 0;
    }
    finishEntry();

    return $chunk;
}

/**
 * Log viewer - byte offset paging in both directions, so the start or the end of any size log opens instantly
 * Only MAX_CHUNKS stay in the DOM, chunks scrolled far out of view are dropped and fetched again on the way back
 * Search runs on the server across the whole file, follow polls for new lines, the file list refreshes itself
 */
function initLogViewer() {
    const MAX_CHUNKS = 12;
    const EDGE_PX = 800;
    const FOLLOW_MS = 3000;
    const LIST_MS = 30000;

    const $viewer = document.getElementById('logViewer');
    const $scroller = document.getElementById('logScroller');
    const $lines = document.getElementById('logLines');
    const $topStatus = document.getElementById('logTopStatus');
    const $bottomStatus = document.getElementById('logBottomStatus');
    const $empty = document.getElementById('logEmpty');
    const $name = document.getElementById('logName');
    const $meta = document.getElementById('logMeta');
    const $download = /** @type {HTMLAnchorElement} */ (document.getElementById('logDownload'));
    const $jumpStart = document.getElementById('logJumpStart');
    const $jumpEnd = document.getElementById('logJumpEnd');
    const $follow = /** @type {HTMLInputElement} */ (document.getElementById('logFollow'));
    const $wrap = /** @type {HTMLInputElement} */ (document.getElementById('logWrap'));
    const $select = /** @type {HTMLSelectElement} */ (document.getElementById('logSelect'));
    const $filter = /** @type {HTMLInputElement} */ (document.getElementById('logFilter'));
    const $filterEmpty = document.getElementById('logFilterEmpty');
    const $list = document.getElementById('logList');
    const $refreshBtns = [document.getElementById('logListRefresh'), document.getElementById('logSelectRefresh')];
    const $searchForm = /** @type {HTMLFormElement} */ (document.getElementById('logSearchForm'));
    const $search = /** @type {HTMLInputElement} */ (document.getElementById('logSearch'));
    const $searchPrev = document.getElementById('logSearchPrev');
    const $searchStatus = document.getElementById('logSearchStatus');
    const $levels = /** @type {HTMLInputElement[]} */ (Array.from(document.querySelectorAll('input[name="logLevel"]')));

    const state = {
        filename: '',
        top: 0,
        bottom: 0,
        size: 0,
        loadingUp: false,
        loadingDown: false,
        failed: false,
        follow: false,
        query: '',
        // Byte offset of the current search match, -1 when there isn't one
        match: -1,
        searching: false,
        // Bumped on every open so responses for a log that is no longer shown are ignored
        token: 0,
    };

    // Programmatic scrolls record where they left the scroller, so the scroll listener only reacts to the user
    let lastScrollTop = 0;
    function setScrollTop(value) {
        $scroller.scrollTop = value;
        lastScrollTop = $scroller.scrollTop;
    }

    /**
     * Fill the viewport below the navbar - the list and the log scroll on their own, the page doesn't
     */
    function fitHeight() {
        const top = $viewer.getBoundingClientRect().top + window.scrollY;
        $viewer.style.height = `${Math.max(360, window.innerHeight - top - 16)}px`;
    }

    function setStatus($el, html) {
        $el.innerHTML = html;
        $el.classList.toggle('d-none', !html);
    }

    function setSearchStatus(text, isError = false) {
        $searchStatus.textContent = text;
        $searchStatus.classList.toggle('text-danger', isError);
        $searchStatus.classList.toggle('text-body-secondary', !isError);
    }

    function logLinks() {
        return /** @type {HTMLAnchorElement[]} */ (Array.from($list.querySelectorAll('.logLink')));
    }

    function selectedLink() {
        return logLinks().find((l) => l.dataset.filename === state.filename);
    }

    function renderStatus() {
        const loading = `<span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>Loading`;
        const hasLines = $lines.childElementCount > 0;

        if (state.loadingUp) setStatus($topStatus, loading);
        else if (state.top === 0 && hasLines) setStatus($topStatus, 'Start of file');
        else setStatus($topStatus, '');

        if (state.loadingDown && !state.follow) setStatus($bottomStatus, loading);
        else if (state.failed) setStatus($bottomStatus, '<span class="text-danger">Could not load this log</span>');
        else if (state.follow) {
            setStatus(
                $bottomStatus,
                '<span class="text-success"><i class="bi bi-broadcast me-1"></i>Following new lines</span>'
            );
        } else if (state.bottom >= state.size && hasLines) {
            setStatus(
                $bottomStatus,
                `End of file <button type="button" class="btn btn-link btn-sm p-0 ms-2 align-baseline logRefresh">Check for new lines</button>`
            );
        } else setStatus($bottomStatus, '');

        $meta.textContent = state.filename
            ? `${formatBytes(state.size)} · ${selectedLink()?.dataset.modified ?? ''}`
            : '';
    }

    /**
     * @param {number} offset
     * @param {'forward' | 'backward'} direction
     * @param {(data: { lines: string[], start: number, end: number, size: number }) => void} onChunk
     */
    async function fetchChunk(offset, direction, onChunk) {
        const token = state.token;
        const params = new URLSearchParams({ filename: state.filename, offset: String(offset), direction });

        await getWrapper({
            url: `/admin/getLogChunk?${params}`,
            $loadingDiv: null,
            loading: '',
            dataHandler: (text) => {
                if (token !== state.token) return;
                const { data } = JSON.parse(text);
                onChunk({
                    lines: data.lines,
                    start: Number(data.start),
                    end: Number(data.end),
                    size: Number(data.size),
                });
            },
            errorHandler: () => {
                if (token !== state.token) return;
                state.failed = true;
            },
        });
    }

    /**
     * @param {{ force?: boolean }} [options] force reads past the known end of file - picks up newly written lines
     */
    async function loadDown({ force = false } = {}) {
        if (state.loadingDown || state.failed) return;
        if (!force && state.bottom >= state.size) return;
        state.loadingDown = true;
        renderStatus();

        await fetchChunk(state.bottom, 'forward', ({ lines, start, end, size }) => {
            state.size = size;
            if (end > start) {
                $lines.appendChild(buildLogChunk(lines, start, end, state.query));
                state.bottom = end;
            }

            // Drop the oldest chunks above - keep what's on screen where it is
            while ($lines.childElementCount > MAX_CHUNKS) {
                const $first = /** @type {HTMLElement} */ ($lines.firstElementChild);
                const height = $first.offsetHeight;
                $first.remove();
                setScrollTop($scroller.scrollTop - height);
                state.top = Number(/** @type {HTMLElement} */ ($lines.firstElementChild).dataset.start);
            }

            if (state.follow) setScrollTop($scroller.scrollHeight);
        });

        state.loadingDown = false;
        renderStatus();
        requestAnimationFrame(() => checkEdges('down'));
    }

    async function loadUp() {
        if (state.loadingUp || state.failed || state.top <= 0) return;
        state.loadingUp = true;
        renderStatus();

        await fetchChunk(state.top, 'backward', ({ lines, start, end, size }) => {
            state.size = size;
            if (end > start) {
                // Prepending pushes the content down - shift the scroll by the same amount so nothing jumps
                const before = $scroller.scrollHeight;
                $lines.prepend(buildLogChunk(lines, start, end, state.query));
                setScrollTop($scroller.scrollTop + $scroller.scrollHeight - before);
                state.top = start;
            }

            while ($lines.childElementCount > MAX_CHUNKS) {
                /** @type {HTMLElement} */ ($lines.lastElementChild).remove();
                state.bottom = Number(/** @type {HTMLElement} */ ($lines.lastElementChild).dataset.end);
            }
        });

        state.loadingUp = false;
        renderStatus();
        requestAnimationFrame(() => checkEdges('up'));
    }

    /**
     * Load more when within EDGE_PX of an end. After a load only the same direction is checked again, so a short
     * page (everything hidden by the level filter) can't bounce between loading the top and the bottom forever
     *
     * @param {'up' | 'down' | 'both'} direction
     */
    function checkEdges(direction) {
        // One load at a time - an up and a down load racing could each trim the chunk the other is extending
        if (!state.filename || state.failed || state.loadingUp || state.loadingDown) return;

        const fromBottom = $scroller.scrollHeight - $scroller.scrollTop - $scroller.clientHeight;
        if (direction !== 'up' && fromBottom < EDGE_PX && state.bottom < state.size) loadDown();
        else if (direction !== 'down' && $scroller.scrollTop < EDGE_PX && state.top > 0) loadUp();
    }

    /**
     * Clear the view and point every control at filename - callers load the first chunk
     *
     * @param {string} filename
     */
    function resetView(filename) {
        state.token++;
        Object.assign(state, {
            filename,
            top: 0,
            bottom: 0,
            size: 0,
            loadingUp: false,
            loadingDown: false,
            failed: false,
        });

        $lines.replaceChildren();
        $empty.classList.add('d-none');
        $name.textContent = filename;
        $name.title = filename;
        $download.href = `/admin/downloadLog?${new URLSearchParams({ filename })}`;
        $download.classList.remove('disabled');
        $download.removeAttribute('aria-disabled');
        $download.removeAttribute('tabindex');
        document.querySelectorAll('.logNeedsFile').forEach(($el) => {
            /** @type {HTMLInputElement} */ ($el).disabled = false;
        });
        markActive();
    }

    function markActive() {
        logLinks().forEach((l) => {
            const active = l.dataset.filename === state.filename;
            l.classList.toggle('active', active);
            if (active) l.setAttribute('aria-current', 'true');
            else l.removeAttribute('aria-current');
        });
        if (state.filename) $select.value = state.filename;
    }

    /**
     * @param {string} filename
     * @param {boolean} [fromEnd] open at the end of the file instead of the start
     */
    async function openLog(filename, fromEnd = false) {
        resetView(filename);
        state.match = -1;

        const onFirst = ({ lines, start, end, size }) => {
            $lines.appendChild(buildLogChunk(lines, start, end, state.query));
            Object.assign(state, { top: start, bottom: end, size });
        };

        if (fromEnd) {
            state.loadingUp = true;
            renderStatus();
            await fetchChunk(-1, 'backward', onFirst);
            state.loadingUp = false;
            setScrollTop($scroller.scrollHeight);
        } else {
            state.loadingDown = true;
            renderStatus();
            await fetchChunk(0, 'forward', onFirst);
            state.loadingDown = false;
            setScrollTop(0);
        }

        renderStatus();
        requestAnimationFrame(() => checkEdges(fromEnd ? 'up' : 'down'));
    }

    /**
     * Open the log with lineStart in view - one chunk from there down and one above it for context
     *
     * @param {number} lineStart
     */
    async function openAt(lineStart) {
        const filename = state.filename;
        resetView(filename);

        state.loadingDown = true;
        renderStatus();
        await fetchChunk(lineStart, 'forward', ({ lines, start, end, size }) => {
            $lines.appendChild(buildLogChunk(lines, start, end, state.query));
            Object.assign(state, { top: start, bottom: end, size });
        });
        state.loadingDown = false;

        if (state.top > 0 && !state.failed) {
            state.loadingUp = true;
            renderStatus();
            await fetchChunk(state.top, 'backward', ({ lines, start, end }) => {
                if (end > start) {
                    $lines.prepend(buildLogChunk(lines, start, end, state.query));
                    state.top = start;
                }
            });
            state.loadingUp = false;
        }
        renderStatus();
    }

    /**
     * The loaded line holding a byte offset - the last line starting at or before it
     *
     * @param {number} offset
     */
    function lineAt(offset) {
        const $chunk = /** @type {HTMLElement[]} */ (Array.from($lines.children)).find(
            ($c) => offset >= Number($c.dataset.start) && offset < Number($c.dataset.end)
        );
        if (!$chunk) return null;

        let $found = null;
        for (const $line of /** @type {NodeListOf<HTMLElement>} */ ($chunk.querySelectorAll('.logLine'))) {
            if (Number($line.dataset.offset) > offset) break;
            $found = $line;
        }
        return $found;
    }

    /**
     * Byte offset of the first line showing at the top of the scroller - where a fresh search starts from
     */
    function firstVisibleOffset() {
        const top = $scroller.getBoundingClientRect().top;
        for (const $line of /** @type {NodeListOf<HTMLElement>} */ ($lines.querySelectorAll('.logLine'))) {
            // Hidden lines (collapsed, filtered) measure as zero and are skipped
            if ($line.getBoundingClientRect().bottom > top) return Number($line.dataset.offset);
        }
        return state.top;
    }

    function rehighlight() {
        $lines.querySelectorAll('.logText').forEach(($text) => {
            highlightLogText(/** @type {HTMLElement} */ ($text), $text.textContent, state.query);
        });
    }

    /**
     * @param {number} match byte offset of the match
     * @param {number} lineStart byte offset of the line holding it
     */
    async function showMatch(match, lineStart) {
        if (state.follow) setFollow(false);
        if (!lineAt(match)) await openAt(lineStart);

        const $line = lineAt(match);
        if (!$line) return;

        // Make sure the match isn't hidden by the level filter or a collapsed stack trace
        const $entry = /** @type {HTMLElement} */ ($line.closest('.logEntry'));
        const level = $entry.dataset.level;
        const filter = $levels.find((l) => l.checked)?.value ?? 'all';
        if ((filter === 'error' && level !== 'error') || (filter === 'warn' && level !== 'error' && level !== 'warn')) {
            setLevel('all');
        }
        if ($line.closest('.logDetail')) setLogEntryOpen($entry, true);

        $lines.querySelector('.logCurrent')?.classList.remove('logCurrent');
        $line.classList.add('logCurrent');
        $line.scrollIntoView({ block: 'center' });
        lastScrollTop = $scroller.scrollTop;
        requestAnimationFrame(() => checkEdges('both'));
    }

    /**
     * Find the next or previous match on the server - searches the whole file, not just what's loaded
     *
     * @param {'forward' | 'backward'} direction
     */
    async function search(direction) {
        const query = $search.value;
        if (!query.trim() || !state.filename || state.searching) return;

        if (query !== state.query) {
            state.query = query;
            state.match = -1;
            rehighlight();
        }

        let offset;
        if (state.match >= 0) offset = direction === 'forward' ? state.match + 1 : state.match;
        else offset = firstVisibleOffset();

        state.searching = true;
        setSearchStatus('Searching…');
        const token = state.token;
        const params = new URLSearchParams({ filename: state.filename, query, offset: String(offset), direction });
        let result = /** @type {{ found: boolean, offset: number, lineStart: number } | null} */ (null);

        await getWrapper({
            url: `/admin/searchLog?${params}`,
            $loadingDiv: null,
            loading: '',
            dataHandler: (text) => {
                result = JSON.parse(text).data;
            },
            errorHandler: () => setSearchStatus('Search failed', true),
        });
        state.searching = false;

        if (!result || token !== state.token || query !== state.query) return;
        if (!result.found) {
            setSearchStatus(direction === 'forward' ? 'No more matches below' : 'No more matches above', true);
            return;
        }

        setSearchStatus('');
        state.match = Number(result.offset);
        await showMatch(state.match, Number(result.lineStart));
    }

    /**
     * @param {string} level all, warn or error
     */
    function setLevel(level) {
        const $radio = $levels.find((l) => l.value === level);
        if ($radio) $radio.checked = true;
        $scroller.classList.toggle('logLevelWarn', level === 'warn');
        $scroller.classList.toggle('logLevelError', level === 'error');
        // Fewer lines showing - fill the gap below
        requestAnimationFrame(() => checkEdges('down'));
    }

    let followTimer = 0;
    /**
     * @param {boolean} on
     */
    function setFollow(on) {
        state.follow = on;
        $follow.checked = on;
        clearInterval(followTimer);
        renderStatus();
        if (!on || !state.filename) return;

        if (state.bottom < state.size || !$lines.childElementCount) openLog(state.filename, true);
        else setScrollTop($scroller.scrollHeight);

        followTimer = window.setInterval(() => {
            if (document.hidden || state.loadingUp || state.loadingDown) return;
            loadDown({ force: true });
        }, FOLLOW_MS);
    }

    /**
     * @param {string} filename
     */
    function selectLog(filename) {
        if (!filename) return;
        setFollow(false);
        history.pushState({ filename }, '', `/admin/logViewer?${new URLSearchParams({ filename })}`);
        openLog(filename);
    }

    function applyListFilter() {
        const term = $filter.value.trim().toLowerCase();
        let shown = 0;
        logLinks().forEach((l) => {
            const match = l.dataset.filename.toLowerCase().includes(term);
            l.classList.toggle('d-none', !match);
            if (match) shown++;
        });
        $filterEmpty.textContent = logLinks().length ? 'No logs match' : 'No log files found';
        $filterEmpty.classList.toggle('d-none', shown > 0);
    }

    /**
     * @param {{ name: string, size: number, sizeLabel: string, modifiedLabel: string, modifiedFull: string }[]} logs
     */
    function renderList(logs) {
        const $links = logs.map((log) => {
            const $link = /** @type {HTMLAnchorElement} */ (
                createEl('a', 'logLink list-group-item list-group-item-action')
            );
            $link.href = `/admin/logViewer?${new URLSearchParams({ filename: log.name })}`;
            $link.dataset.filename = log.name;
            $link.dataset.size = String(log.size);
            $link.dataset.modified = log.modifiedFull;

            const $top = createEl('div', 'd-flex justify-content-between align-items-baseline gap-2');
            const $linkName = createEl('span', 'logLinkName text-truncate', log.name);
            $linkName.title = log.name;
            $top.append($linkName, createEl('small', 'logLinkSize text-nowrap', log.sizeLabel));
            $link.append($top, createEl('div', 'small logLinkMeta text-nowrap', log.modifiedLabel));
            return $link;
        });
        $list.replaceChildren(...$links);

        const $placeholder = /** @type {HTMLOptionElement} */ ($select.options[0]);
        $placeholder.textContent = `Choose a log (${logs.length})`;
        const $options = logs.map((log) => {
            const $option = /** @type {HTMLOptionElement} */ (createEl('option', '', `${log.name} (${log.sizeLabel})`));
            $option.value = log.name;
            return $option;
        });
        $select.replaceChildren($placeholder, ...$options);
        if (!state.filename) $select.value = '';
        $filter.placeholder = `Filter ${logs.length} logs`;

        markActive();
        applyListFilter();

        // The open log grew - let scrolling (or follow) pick up the new lines
        const current = logs.find((log) => log.name === state.filename);
        if (current && current.size > state.size && !state.loadingDown) {
            state.size = current.size;
            renderStatus();
            if (!state.follow) checkEdges('down');
        }
    }

    let listLoading = false;
    async function refreshList() {
        if (listLoading) return;
        listLoading = true;
        $refreshBtns.forEach(($btn) => $btn.classList.add('logSpinning'));

        await getWrapper({
            url: '/admin/listLogs',
            $loadingDiv: null,
            loading: '',
            dataHandler: (text) => renderList(JSON.parse(text).data),
        });

        $refreshBtns.forEach(($btn) => $btn.classList.remove('logSpinning'));
        listLoading = false;
    }

    // Layout
    fitHeight();
    window.addEventListener('resize', fitHeight);

    // Infinite scroll - rAF keeps it to one check per frame, the scroll direction picks which edge to check
    let edgeFrame = 0;
    $scroller.addEventListener(
        'scroll',
        () => {
            if (edgeFrame) return;
            edgeFrame = requestAnimationFrame(() => {
                edgeFrame = 0;
                const delta = $scroller.scrollTop - lastScrollTop;
                lastScrollTop = $scroller.scrollTop;
                if (delta === 0) return;

                // Scrolling up to read stops following
                const fromBottom = $scroller.scrollHeight - $scroller.scrollTop - $scroller.clientHeight;
                if (delta < 0 && state.follow && fromBottom > 40) setFollow(false);

                checkEdges(delta > 0 ? 'down' : 'up');
            });
        },
        { passive: true }
    );

    // File switching without a page load - delegated, the list is rebuilt on refresh
    $list.addEventListener('click', (evt) => {
        const $link = /** @type {HTMLAnchorElement | null} */ (
            /** @type {HTMLElement} */ (evt.target).closest('.logLink')
        );
        // Let modified clicks open a new tab as a normal link would
        if (!$link || evt.ctrlKey || evt.metaKey || evt.shiftKey || evt.button !== 0) return;
        evt.preventDefault();
        selectLog($link.dataset.filename);
    });
    $select.addEventListener('change', () => selectLog($select.value));
    window.addEventListener('popstate', () => {
        const filename = new URLSearchParams(location.search).get('filename');
        if (filename && logLinks().some((l) => l.dataset.filename === filename)) {
            setFollow(false);
            openLog(filename);
        }
    });

    $jumpStart.addEventListener('click', () => {
        setFollow(false);
        openLog(state.filename);
    });
    $jumpEnd.addEventListener('click', () => openLog(state.filename, true));
    $follow.addEventListener('change', () => setFollow($follow.checked));

    // Picks up lines written since the end was reached
    $bottomStatus.addEventListener('click', (evt) => {
        if (!(/** @type {HTMLElement} */ (evt.target).closest('.logRefresh'))) return;
        loadDown({ force: true });
    });

    // Collapsed stack traces
    $lines.addEventListener('click', (evt) => {
        const $toggle = /** @type {HTMLElement} */ (evt.target).closest('.logToggle');
        if (!$toggle) return;
        const $entry = /** @type {HTMLElement} */ ($toggle.closest('.logEntry'));
        setLogEntryOpen($entry, $entry.classList.contains('collapsed'));
    });

    // Search - Enter for next, Shift+Enter for previous, highlights update as you type
    $searchForm.addEventListener('submit', (evt) => {
        evt.preventDefault();
        search('forward');
    });
    $search.addEventListener('keydown', (evt) => {
        if (evt.key === 'Enter' && evt.shiftKey) {
            evt.preventDefault();
            search('backward');
        }
    });
    $searchPrev.addEventListener('click', () => search('backward'));
    let highlightTimer = 0;
    $search.addEventListener('input', () => {
        clearTimeout(highlightTimer);
        highlightTimer = window.setTimeout(() => {
            if ($search.value === state.query) return;
            state.query = $search.value.trim() ? $search.value : '';
            state.match = -1;
            $lines.querySelector('.logCurrent')?.classList.remove('logCurrent');
            setSearchStatus('');
            rehighlight();
        }, 250);
    });

    // Level filter
    $levels.forEach(($radio) => $radio.addEventListener('change', () => setLevel($radio.value)));

    // Line wrap - remembered per browser
    const WRAP_KEY = 'logViewerWrap';
    try {
        $wrap.checked = getLocalStorage(WRAP_KEY) === 'true';
    } catch {
        // storage blocked - default to no wrap
    }
    $scroller.classList.toggle('logWrap', $wrap.checked);
    $wrap.addEventListener('change', () => {
        $scroller.classList.toggle('logWrap', $wrap.checked);
        try {
            setLocalStorage(WRAP_KEY, String($wrap.checked));
        } catch {
            // storage blocked - wrap still applies for this page
        }
    });

    // File list - filter, manual refresh, and a quiet refresh every LIST_MS while the tab is visible
    $filter.addEventListener('input', applyListFilter);
    $refreshBtns.forEach(($btn) => $btn.addEventListener('click', refreshList));
    window.setInterval(() => {
        if (!document.hidden) refreshList();
    }, LIST_MS);
    document.addEventListener('visibilitychange', () => {
        if (!document.hidden) refreshList();
    });

    if ($viewer.dataset.filename) {
        history.replaceState({ filename: $viewer.dataset.filename }, '');
        openLog($viewer.dataset.filename);
        selectedLink()?.scrollIntoView({ block: 'nearest' });
    }
}

export const runtime = {
    all: () => {},
    logviewer: () => {
        initLogViewer();
    },
    auditlog: () => {
        new DataTable($auditLog, {
            ajax: {
                url: '/admin/getAudits',
                type: 'GET',
                dataSrc: 'data',
            },
            // Audit data (agent, referer, path) is attacker controlled - always render as text
            columnDefs: [
                { searchable: false, targets: 0 },
                { render: DataTable.render.text(), targets: '_all' },
            ],
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    buglog: () => {
        const bugModal = new bootstrap.Modal(document.getElementById('bugModal'));
        const $bugModalId = document.getElementById('bugModalId');
        const $bugModalBody = document.getElementById('bugModalBody');
        const $bugModalCopy = document.getElementById('bugModalCopy');
        let currentBug = null;

        const dt = new DataTable($bugLog, {
            ajax: {
                url: '/admin/getBugs',
                type: 'GET',
                dataSrc: 'data',
            },
            columns: [
                { data: 'timestamp', className: 'text-nowrap' },
                { data: 'ip', render: DataTable.render.text() },
                { data: 'event', className: 'bugEventCell font-monospace small', render: DataTable.render.text() },
                { data: 'message', className: 'bugMessageCell', render: DataTable.render.text() },
                { data: 'username', render: DataTable.render.text() },
                {
                    data: null,
                    orderable: false,
                    className: 'text-center',
                    render: () => `
                        <button type="button" class="viewBug btn btn-sm btn-outline-danger" title="View details">
                            <i class="bi bi-bug"></i>
                        </button>
                    `,
                },
            ],
            createdRow: (row, data) => {
                row.querySelector('.bugMessageCell').title = data.message;
            },
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });

        $bugLog.addEventListener('click', (evt) => {
            const $btn = /** @type {HTMLElement} */ (evt.target).closest('.viewBug');
            if (!$btn) return;

            currentBug = dt.row($btn.closest('tr')).data();
            $bugModalId.textContent = `#${currentBug.id}`;
            $bugModalBody.replaceChildren(buildBugDetail(currentBug));
            $bugModalBody.scrollTop = 0;
            bugModal.show();
        });

        $bugModalCopy.addEventListener('click', () => {
            if (currentBug) copyString([$bugModalCopy], currentBug.stack);
        });
    },
    listtrainers: () => {
        new DataTable($listTrainers, {
            ajax: {
                url: '/admin/getTrainers',
                type: 'GET',
                dataSrc: 'data',
            },
            columns: [
                { data: 'edit' },
                { data: 'icon' },
                { data: 'username', render: DataTable.render.text() },
                { data: 'email', render: DataTable.render.text() },
                { data: 'verified' },
                { data: 'securitylevel', render: DataTable.render.text() },
                { data: 'lastlogin', render: DataTable.render.text() },
            ],
            rowId: (data) => data.trainerid,
            serverSide: true,
            order: [[6, 'desc']],
            columnDefs: [
                {
                    targets: '_all',
                    className: 'align-middle',
                },
                {
                    targets: 0,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) => `
                            <button type="button" class="editTrainer btn btn-secondary" data-trainerid="${escapeHtml(full.trainerid)}">
                                <i class="bi bi-wrench"></i>
                            </button>
                        `,
                },
                {
                    targets: 1,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) =>
                        `<img class="profileIcon" src="${escapeHtml(full.icon)}" alt="${escapeHtml(full.iconAltText)}" loading="lazy">`,
                },
                {
                    targets: 4,
                    orderable: false,
                    searchable: false,
                    className: 'align-middle text-center',
                    render: (data, type, full) => {
                        if (full.verified) return `<i class="bi bi-check mx-1"></i>`;
                        return '';
                    },
                },
                {
                    targets: 5,
                    className: 'align-middle text-center',
                },
            ],
            pageLength: 25,
            lengthMenu: [25, 50, 100],
            scrollY: 'calc(100vh - 250px)',
        });

        attachEditProfileHandler($listTrainers);
    },
    listpokemon: () => {
        let isCostume = false;
        const $pokemonViewBtn = document.getElementById('pokemonViewBtn');
        const $costumeViewBtn = document.getElementById('costumeViewBtn');

        const dt = new DataTable($listPokemon, {
            ajax: {
                url: '/admin/getPokemon',
                type: 'GET',
                dataSrc: 'data',
                data: (d) => {
                    d.costume = isCostume;
                    return d;
                },
            },
            columns: [
                { data: 'generation' },
                { data: 'number' },
                { data: 'gender' },
                { data: 'name' },
                { data: 'costumetype' },
                { data: 'sprite' },
                { data: 'shiny' },
                { data: 'shadow' },
                { data: 'shadowshiny' },
                { data: 'fastmoves' },
                { data: 'chargemoves' },
                { data: 'evolutiontext' },
            ],
            rowId: (data) => data.pokemonid,
            order: [
                [0, 'asc'],
                [1, 'asc'],
            ],
            columnDefs: [
                {
                    targets: [5, 6, 7, 8, 9, 10, 11],
                    orderable: false,
                    searchable: false,
                },
                {
                    targets: 4,
                    visible: false,
                },
                {
                    targets: 3,
                    render: (data, type, full) =>
                        `<a href='/pokemon/${encodeURIComponent(full.ses)}' target='_blank'>${escapeHtml(full.name)}</a>`,
                },
                {
                    targets: 5,
                    className: 'text-center',
                    render: (data, type, full) =>
                        `<img class='pokemonIcon' src='${escapeHtml(full.sprite)}' loading='lazy'>`,
                },
                {
                    targets: 6,
                    className: 'text-center',
                    render: (data, type, full) => {
                        if (!full.shiny.length) return '';
                        return `<img class='pokemonIcon' src='${escapeHtml(full.shiny)}' loading='lazy'>`;
                    },
                },
                {
                    targets: 7,
                    className: 'text-center parent',
                    render: (data, type, full) => {
                        if (!full.shadow) return '';
                        return `
                            <img class='pokemonIcon' src='${escapeHtml(full.sprite)}' loading='lazy'>
                            <img class='shadowIcon' src='${escapeHtml(full.shadowicon)}' loading='lazy'>
                        `;
                    },
                },
                {
                    targets: 8,
                    className: 'text-center parent',
                    render: (data, type, full) => {
                        if (!full.shadowshiny) return '';
                        return `
                            <img class='pokemonIcon' src='${escapeHtml(full.shiny)}' loading='lazy'>
                            <img class='shadowIcon' src='${escapeHtml(full.shadowicon)}' loading='lazy'>
                        `;
                    },
                },
            ],
            serverSide: true,
            pageLength: 25,
            lengthMenu: [10, 25, 50, 100],
            scrollY: 'calc(100vh - 250px)',
        });

        $pokemonViewBtn?.addEventListener('click', () => {
            if (isCostume) {
                isCostume = false;
                dt.column(4).visible(false);
                dt.columns([7, 8, 9, 10]).visible(true);
                dt.ajax.reload();
                $pokemonViewBtn.classList.add('active');
                $costumeViewBtn.classList.remove('active');
            }
        });

        $costumeViewBtn?.addEventListener('click', () => {
            if (!isCostume) {
                isCostume = true;
                dt.column(4).visible(true);
                dt.columns([7, 8, 9, 10]).visible(false);
                dt.ajax.reload();
                $costumeViewBtn.classList.add('active');
                $pokemonViewBtn.classList.remove('active');
            }
        });
    },
    requestlog: () => {
        new DataTable($requestLog, {
            ajax: {
                url: '/admin/getRequests',
                type: 'GET',
                dataSrc: 'data',
            },
            // Request data (url, agent, referer) is attacker controlled - always render as text
            columnDefs: [
                { searchable: false, targets: 0 },
                { className: 'long-cell', targets: [2, 5] },
                { render: DataTable.render.text(), targets: '_all' },
            ],
            order: [[0, 'desc']],
            serverSide: true,
            pageLength: 50,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    serverinfo: () => {
        startMetricsSocket();

        const loadingSpinners = document.querySelectorAll('.metricsLoading');
        let firstLoad = true;

        /**
         * JVM Usage Pie Chart
         */
        const jvmChartCanvas = document.getElementById('jvmChart');
        let jvmChart;

        /**
         * Requests line chart
         */
        const requestChartCanvas = document.getElementById('requestChart');
        const MAX_POINTS = 30;
        let requestChart;

        /**
         * appCache donut chart
         */
        const appCacheChartCanvas = document.getElementById('appCacheChart');
        let appCacheChart;

        /**
         * Slow requests table
         */
        const slowRequestsTableBody = document.getElementById('slowRequestsBody');

        /**
         * System Information
         */
        const coresMetric = document.getElementById('coresMetric');
        const processMetric = document.getElementById('processMetric');
        const systemMetric = document.getElementById('systemMetric');

        /**
         * Cache DataTable
         */
        const cacheTable = new DataTable($cacheData, {
            columns: [
                { data: 'storage' },
                { data: 'key' },
                { data: 'created' },
                { data: 'hits', className: 'text-center' },
                { data: 'expired', className: 'text-center', render: (data) => (data ? 'Yes' : 'No') },
                { data: 'lastaccessed' },
                { data: 'lastaccesstimeout', className: 'text-center' },
                { data: 'timeout', className: 'text-center' },
            ],
            order: [[0, 'asc']],
            pageLength: 50,
            scrollY: 'calc(30vh)',
        });

        /**
         * Modal stats elements
         */
        const statLastReap = document.getElementById('statLastReap');
        const statHits = document.getElementById('statHits');
        const statMisses = document.getElementById('statMisses');
        const statEvictions = document.getElementById('statEvictions');
        const statGC = document.getElementById('statGarbageCollections');

        /**
         * Fetch cache data and update table, chart, and modal stats
         */
        async function updateCacheData() {
            try {
                const response = await fetch('/admin/getCacheData');
                const data = await response.json();

                cacheTable.clear().rows.add(data.data).draw(false);

                const appKeyCount = data.data.filter((d) => d.storage === 'appCache').length;
                const available = data.maxObjects - appKeyCount;

                if (!appCacheChart) {
                    appCacheChart = new Chart(appCacheChartCanvas, {
                        type: 'doughnut',
                        data: {
                            labels: ['Used', 'Available'],
                            datasets: [
                                {
                                    label: 'appCache Keys',
                                    data: [appKeyCount, available],
                                    backgroundColor: ['rgba(255, 99, 132, 0.8)', 'rgba(54, 162, 235, 0.8)'],
                                    hoverOffset: 4,
                                    borderWidth: 0,
                                },
                            ],
                        },
                        options: {
                            responsive: true,
                            plugins: {
                                legend: {
                                    position: 'top',
                                    labels: { color: '#000000' },
                                },
                            },
                            maintainAspectRatio: false,
                            cutout: '50%',
                        },
                    });
                } else {
                    appCacheChart.data.datasets[0].data = [appKeyCount, available];
                    appCacheChart.update('none');
                }

                if (statLastReap) statLastReap.textContent = data.lastReapDateTime;
                if (statHits) statHits.textContent = data.hits;
                if (statMisses) statMisses.textContent = data.misses;
                if (statEvictions) statEvictions.textContent = data.evictionCount;
                if (statGC) statGC.textContent = data.garbageCollections;
            } catch (e) {
                console.error('Error fetching cache data', e);
            }
        }

        updateCacheData();
        let cacheTimer = setInterval(updateCacheData, 10000);

        // Hidden tab - stop polling and drop the websocket, catch up and resume once it's visible again
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                clearInterval(cacheTimer);
                stopMetricsSocket();
            } else {
                updateCacheData();
                clearInterval(cacheTimer);
                cacheTimer = setInterval(updateCacheData, 10000);
                startMetricsSocket();
            }
        });

        /**
         * Listener for when metrics is updated
         */
        document.addEventListener('metricsUpdate', (e) => {
            const metrics = /** @type {CustomEvent} */ (e).detail;
            if (!metrics) return;
            if (firstLoad) {
                /**
                 * Hide loading spinners
                 */
                loadingSpinners.forEach((el) => {
                    el.classList.add('d-none');
                });

                /**
                 * Show JVM Chart and initialize
                 */
                jvmChart = new Chart(jvmChartCanvas, {
                    type: 'doughnut',
                    data: {
                        labels: ['Used', 'Free', 'Max (Unallocated)'],
                        datasets: [
                            {
                                label: 'JVM Memory (MB)',
                                data: [],
                                backgroundColor: [
                                    'rgba(255, 99, 132, 0.8)', // Used
                                    'rgba(54, 162, 235, 0.8)', // Free
                                    'rgba(201, 203, 207, 0.8)', // Unallocated
                                ],
                                hoverOffset: 4,
                                borderWidth: 0,
                            },
                        ],
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            legend: {
                                position: 'top',
                                labels: {
                                    color: '#000000',
                                },
                            },
                        },
                        maintainAspectRatio: false,
                        cutout: '50%',
                    },
                });
                jvmChartCanvas.classList.remove('d-none');

                /**
                 * Show Request Chart and initialize
                 */
                requestChart = new Chart(requestChartCanvas, {
                    type: 'line',
                    data: {
                        labels: [],
                        datasets: [
                            {
                                label: 'Active Requests',
                                data: [],
                                tension: 0.3,
                                fill: false,
                                borderColor: 'rgba(54, 162, 235, 0.8)',
                                backgroundColor: 'rgba(54, 162, 235, 0.8)',
                            },
                        ],
                    },
                    options: {
                        responsive: true,
                        scales: {
                            x: {
                                ticks: { color: '#495057' },
                                grid: { color: '#FFFFFF' },
                                border: { color: 'rgba(108, 117, 125, 0.6)' },
                            },
                            y: {
                                ticks: { color: '#495057', precision: 0, stepSize: 1 },
                                grid: { color: '#FFFFFF' },
                                border: { color: 'rgba(108, 117, 125, 0.6)' },
                                beginAtZero: true,
                            },
                        },
                        plugins: {
                            legend: {
                                labels: {
                                    color: '#000000',
                                },
                            },
                        },
                        backgroundColor: 'transparent',
                    },
                });
                requestChartCanvas.classList.remove('d-none');
                firstLoad = false;
            }

            /**
             * Update JVM Chart
             */
            const used = metrics.memory.usedMB;
            const allocated = metrics.memory.totalMB;
            const max = metrics.memory.maxMB;
            const free = allocated - used;
            const unallocated = max - allocated;

            jvmChart.data.datasets[0].data[0] = used;
            jvmChart.data.datasets[0].data[1] = free;
            jvmChart.data.datasets[0].data[2] = unallocated;
            jvmChart.update('none');

            /**
             * Update active requests chart
             */
            requestChart.data.labels = [
                ...requestChart.data.labels.slice(-MAX_POINTS),
                new Date().toLocaleTimeString(),
            ];
            requestChart.data.datasets[0].data = [
                ...requestChart.data.datasets[0].data.slice(-MAX_POINTS),
                metrics.concurrency.activeRequests,
            ];
            requestChart.update('none');

            /**
             * Slow requests table
             */
            slowRequestsTableBody.innerHTML = '';
            metrics.concurrency.slowRequests.forEach((r) => {
                const tr = document.createElement('tr');

                // Time
                const date = new Date(r.time.replace(',', ''));
                const tdTime = document.createElement('td');
                tdTime.textContent = date.toLocaleString();
                tr.appendChild(tdTime);

                // URL Path
                const tdUrl = document.createElement('td');
                tdUrl.textContent = r.urlpath;
                tdUrl.style.whiteSpace = 'normal';
                tdUrl.style.wordBreak = 'break-word';
                tr.appendChild(tdUrl);

                // Method
                const tdMethod = document.createElement('td');
                tdMethod.textContent = r.method;
                tr.appendChild(tdMethod);

                // Delta
                const tdDelta = document.createElement('td');
                tdDelta.textContent = r.delta;
                tr.appendChild(tdDelta);

                // Trainer ID
                const tdUser = document.createElement('td');
                tdUser.textContent = r.trainerid;
                tr.appendChild(tdUser);

                // Append row to tbody
                slowRequestsTableBody.appendChild(tr);
            });

            /**
             * System Information
             */
            coresMetric.innerHTML = metrics.cpu.cores;
            processMetric.innerHTML = `${metrics.cpu.processPercent}%`;
            systemMetric.innerHTML = `${metrics.cpu.systemPercent}%`;
        });
    },
    showmedaldata: () => {
        new DataTable($medalData, {
            ordering: false,
            paging: false,
            scrollY: 'calc(100vh - 250px)',
        });
    },
    showmovedata: () => {
        tables.fastMoveTable = new DataTable($fastMoveTable, {
            order: [[0, 'asc']],
            pageLength: 25,
            scrollY: 'calc(100vh - 355px)',
        });

        tables.chargeMoveTable = new DataTable($chargeMoveTable, {
            order: [[0, 'asc']],
            pageLength: 25,
            scrollY: 'calc(100vh - 355px)',
        });

        Array.from($moveLinks).forEach((link) => {
            link.addEventListener('click', (event) => {
                const $clicked = /** @type {HTMLElement} */ (event.currentTarget);
                const $active = /** @type {HTMLElement} */ (document.querySelector('.moveLink.active'));

                document.getElementById(`${$active.dataset.type}MoveWrapper`).classList.add('d-none');
                document.getElementById(`${$clicked.dataset.type}MoveWrapper`).classList.remove('d-none');

                tables[`${$clicked.dataset.type}MoveTable`].columns.adjust().draw();

                $active.classList.remove('active');
                $clicked.classList.add('active');
            });
        });
    },
    taskmanager: () => {
        new DataTable($taskInfo, {
            order: [[1, 'asc']],
            columnDefs: [{ orderable: false, targets: 0 }],
            paging: false,
            searching: false,
            scrollX: true,
        });

        const $runTaskModalEl = document.getElementById('runTaskModal');
        const runTaskModal = new bootstrap.Modal($runTaskModalEl);
        const $runTaskModalTitle = document.getElementById('runTaskModalTitle');
        const $runTaskModalBody = document.getElementById('runTaskModalBody');

        document.getElementById('runTaskModalReload').addEventListener('click', () => {
            window.location.reload();
        });

        document.querySelectorAll('.runTask').forEach((btn) => {
            btn.addEventListener('click', async (evt) => {
                const $btn = /** @type {HTMLButtonElement} */ (evt.currentTarget);
                const { scheduler, name } = $btn.dataset;
                const originalHtml = $btn.innerHTML;

                await postWrapper({
                    url: '/admin/runTask',
                    $loadingBtn: $btn,
                    loading: $submitBtn,
                    packet: JSON.stringify({ scheduler, name }),
                    responseType: 'json',
                    dataHandler: (data) => {
                        $btn.innerHTML = originalHtml;
                        $btn.disabled = false;

                        $runTaskModalTitle.textContent = name;
                        $runTaskModalBody.replaceChildren(buildRunTaskResult(data));
                        runTaskModal.show();
                    },
                });
            });
        });
    },
    readoverrides: () => {
        initJsonEditor();
    },
    readeventoverrides: () => {
        initJsonEditor();
    },
    readnameoverrides: () => {
        initJsonEditor();
    },
};
