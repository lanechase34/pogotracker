export const isMobileDisplay = () => window.matchMedia('(max-width: 767px)').matches;

/**
 * Create an element with an optional class and text
 *
 * @template {keyof HTMLElementTagNameMap} K
 * @param {K} tag
 * @param {string} [className]
 * @param {any} [text] - set as textContent when given
 * @returns {HTMLElementTagNameMap[K]}
 */
export function createEl(tag, className = '', text = null) {
    const $el = document.createElement(tag);
    if (className) $el.className = className;
    if (text !== null) $el.textContent = text;
    return $el;
}

/**
 * Append fetched markup to $parent inside a new wrapper div
 *
 * @param {HTMLElement} $parent
 * @param {string} html
 * @returns {HTMLDivElement} the wrapper holding the new markup
 */
export function appendHtml($parent, html) {
    const $wrapper = document.createElement('div');
    $wrapper.innerHTML = html;
    $parent.appendChild($wrapper);
    return $wrapper;
}

/**
 * One listener on $container for every element matching selector inside it, including ones added later
 *
 * @param {HTMLElement} $container
 * @param {string} type - the event type, it must bubble
 * @param {string} selector
 * @param {(evt: Event, $match: HTMLElement) => any} handler
 * @param {string} [onceKey] - dataset key marking the container as bound, so a container re-rendered into is only bound once
 */
export function delegate($container, type, selector, handler, onceKey = '') {
    if (onceKey) {
        if ($container.dataset[onceKey] === 'true') return;
        $container.dataset[onceKey] = 'true';
    }

    $container.addEventListener(type, (evt) => {
        const $target = evt.target;
        if (!($target instanceof Element)) return;
        const $match = /** @type {HTMLElement | null} */ ($target.closest(selector));
        if ($match && $container.contains($match)) handler(evt, $match);
    });
}

/**
 * Delay fn until wait ms have passed without another call
 *
 * @template {(...args: any[]) => void} T
 * @param {T} fn
 * @param {number} wait - ms
 * @returns {T & { cancel: () => void }} the debounced fn, cancel() drops a pending call
 */
export function debounce(fn, wait) {
    let timer = 0;
    const debounced = /** @type {T & { cancel: () => void }} */ (
        (...args) => {
            window.clearTimeout(timer);
            timer = window.setTimeout(() => fn(...args), wait);
        }
    );
    debounced.cancel = () => window.clearTimeout(timer);
    return debounced;
}
