const currentHandler = document.getElementById('currentEvent').dataset.handler;
const currentAction = document.getElementById('currentEvent').dataset.action;

const APP = (window.__APP__ ??= {});
APP.runtimeExecuted ??= false;

/**
 * Each module(handler) has a runtime struct contain an 'all' function that runs for
 * all actions under handler, specific action functions as well.
 */
export function runtime() {
    /**
     * Safeguard runtime to only run once
     */
    if (APP.runtimeExecuted) return;
    APP.runtimeExecuted = true;

    import(currentHandler).then((module) => {
        module.runtime?.all?.();
        module.runtime?.[currentAction]?.();
    });
}
