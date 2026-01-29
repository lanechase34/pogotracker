export function createMultiSelect(element, placeholder, max, search) {
    new MultiSelect(element, {
        placeholder: placeholder,
        max: max,
        search: search,
        selectAll: false,
        onSelect: function () {},
    });
}
