// Installs the QA automation bridge. Resolves to the web implementation
// (window.shelfRushQa) on web and a no-op everywhere else.
export 'qa_install_stub.dart'
    if (dart.library.js_interop) 'qa_install_web.dart';
