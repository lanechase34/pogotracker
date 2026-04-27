export function createMultiSelect(element, placeholder, max, search) {
    new MultiSelect(element, {
        placeholder,
        max,
        search,
        selectAll: false,
        onSelect() {},
    });
}
