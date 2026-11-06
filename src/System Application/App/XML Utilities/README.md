Use this module to work with XML text and documents in ways that the native AL XML data types don't cover.

The module provides functions for:

- Escaping text for use as XML element content.
- Checking whether characters are valid in XML names and replacing invalid characters.
- Getting and removing the UTF-8 byte order mark.
- Computing the path of a node relative to a base path.
- Reading XML from a stream as text without insignificant whitespace.
- Formatting XML with indentation.
- Applying XSLT transformations and removing namespaces from XML.
- Loading XML documents that contain a document type definition (DTD). The native XmlDocument.ReadFrom method does not allow DTDs. External DTDs and external entities are never resolved.

The module replaces the non-DOM functions of the BaseApp codeunit 6224 "XML DOM Management", which is being retired. For DOM manipulation, use the native XmlDocument, XmlElement, XmlAttribute, XmlNode and XmlNamespaceManager data types.
