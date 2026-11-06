/**
 * Libraries loaded from CDN <script> tags in layouts/default.cfm and views/blog/writeform.cfm
 */
declare const bootstrap: any;
declare const $: any;
declare const jQuery: any;
declare const Masonry: any;
declare const DataTable: any;
declare const Chart: any;
declare const moment: any;
declare const grecaptcha: any;

// Editor.js and its tools (blog write form)
declare const EditorJS: any;
declare const Paragraph: any;
declare const Header: any;
declare const RawTool: any;
declare const ImageTool: any;
declare const EditorjsList: any;
declare const Quote: any;
declare const CodeTool: any;
declare const edjsHTML: any;

// Inline page data (layouts/default.cfm, views/stats/overview.cfm, views/blog/writeform.cfm)
declare let globalModals: Record<string, any>;
declare const statDataset: any;
declare const bodyJson: any;

interface Window {
    __APP__: Record<string, any>;
    jQuery?: any;
}
