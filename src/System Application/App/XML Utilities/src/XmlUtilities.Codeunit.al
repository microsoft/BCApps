// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Xml;

/// <summary>
/// Provides helper functions for working with XML: escaping text, validating XML names, handling the UTF-8 byte order mark,
/// computing relative XPaths, formatting XML, applying XSLT transformations and loading XML documents that contain a DTD.
/// </summary>
codeunit 3016 "XML Utilities"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        XmlUtilitiesImpl: Codeunit "XML Utilities Impl.";

    /// <summary>
    /// Escapes a text so that it can be used as the text content of an XML element.
    /// The characters &amp;, &lt; and &gt; are replaced with entity references and restricted control characters are replaced with character references.
    /// </summary>
    /// <param name="InputText">The text to escape.</param>
    /// <returns>The escaped text.</returns>
    procedure XmlEscape(InputText: Text): Text
    begin
        exit(XmlUtilitiesImpl.XmlEscape(InputText));
    end;

    /// <summary>
    /// Checks whether a character can be used as the first character of an XML name.
    /// </summary>
    /// <param name="InputChar">The character to check.</param>
    /// <returns>True if the character is a valid XML name start character; otherwise, false.</returns>
    procedure IsValidXmlNameStartCharacter(InputChar: Char): Boolean
    begin
        exit(XmlUtilitiesImpl.IsValidXmlNameStartCharacter(InputChar));
    end;

    /// <summary>
    /// Checks whether a character can be used in an XML name.
    /// </summary>
    /// <param name="InputChar">The character to check.</param>
    /// <returns>True if the character is a valid XML name character; otherwise, false.</returns>
    procedure IsValidXmlNameCharacter(InputChar: Char): Boolean
    begin
        exit(XmlUtilitiesImpl.IsValidXmlNameCharacter(InputChar));
    end;

    /// <summary>
    /// Checks whether a character is a restricted XML character.
    /// </summary>
    /// <param name="InputChar">The character to check.</param>
    /// <returns>True if the character is restricted in XML; otherwise, false.</returns>
    procedure IsXmlRestrictedCharacter(InputChar: Char): Boolean
    begin
        exit(XmlUtilitiesImpl.IsXmlRestrictedCharacter(InputChar));
    end;

    /// <summary>
    /// Replaces all characters that are not valid in an XML name.
    /// </summary>
    /// <param name="InputText">The text to convert to a valid XML name.</param>
    /// <param name="ReplaceChar">The character that replaces each invalid character.</param>
    /// <returns>The text where every invalid XML name character is replaced with ReplaceChar.</returns>
    procedure ReplaceXmlInvalidCharacters(InputText: Text; ReplaceChar: Char): Text
    begin
        exit(XmlUtilitiesImpl.ReplaceXmlInvalidCharacters(InputText, ReplaceChar));
    end;

    /// <summary>
    /// Gets the UTF-8 byte order mark as text.
    /// </summary>
    /// <returns>A text that contains the UTF-8 byte order mark character.</returns>
    procedure GetUtf8BomSymbols(): Text
    begin
        exit(XmlUtilitiesImpl.GetUtf8BomSymbols());
    end;

    /// <summary>
    /// Removes the UTF-8 byte order mark from the beginning of a text, if present.
    /// </summary>
    /// <param name="XmlText">The text to remove the byte order mark from.</param>
    procedure ClearUtf8BomSymbols(var XmlText: Text)
    begin
        XmlUtilitiesImpl.ClearUtf8BomSymbols(XmlText);
    end;

    /// <summary>
    /// Gets the path of a node relative to a base path. Both paths are XPaths separated by '/'. The comparison is case-insensitive.
    /// </summary>
    /// <example>GetRelativePath('/a/b/c/@d', '/a/b/e') returns '../c/@d'.</example>
    /// <param name="NodePath">The full path of the node.</param>
    /// <param name="BasePath">The full base path.</param>
    /// <returns>The relative path, or '.' if both paths are the same.</returns>
    /// <error>Node path cannot be empty.</error>
    /// <error>Base path cannot be empty.</error>
    procedure GetRelativePath(NodePath: Text; BasePath: Text): Text
    begin
        exit(XmlUtilitiesImpl.GetRelativePath(NodePath, BasePath));
    end;

    /// <summary>
    /// Reads XML from a stream and returns it as text without insignificant whitespace.
    /// </summary>
    /// <param name="InStream">The stream that contains the XML.</param>
    /// <param name="Xml">The XML as text.</param>
    /// <error>The stream is empty.</error>
    [TryFunction]
    procedure TryGetXmlAsText(InStream: InStream; var Xml: Text)
    begin
        XmlUtilitiesImpl.GetXmlAsText(InStream, Xml);
    end;

    /// <summary>
    /// Formats XML text with indentation. The XML text must contain an XML declaration.
    /// </summary>
    /// <param name="XmlText">The XML text to format.</param>
    /// <param name="FormattedXmlText">The formatted XML text.</param>
    [TryFunction]
    procedure TryFormatXml(XmlText: Text; var FormattedXmlText: Text)
    begin
        XmlUtilitiesImpl.FormatXml(XmlText, FormattedXmlText);
    end;

    /// <summary>
    /// Applies an XSLT stylesheet to an XML document. DTDs in the XML document and in the stylesheet are ignored.
    /// </summary>
    /// <param name="XmlInStream">The stream that contains the XML document.</param>
    /// <param name="XslInStream">The stream that contains the XSLT stylesheet.</param>
    /// <param name="XmlOutStream">The stream to write the result of the transformation to.</param>
    [TryFunction]
    procedure TryTransformXmlToOutStream(var XmlInStream: InStream; var XslInStream: InStream; var XmlOutStream: OutStream)
    begin
        XmlUtilitiesImpl.TransformXmlToOutStream(XmlInStream, XslInStream, XmlOutStream);
    end;

    /// <summary>
    /// Applies an XSLT stylesheet to an XML text.
    /// </summary>
    /// <param name="XmlInText">The XML text.</param>
    /// <param name="XslInText">The XSLT stylesheet.</param>
    /// <returns>The result of the transformation as text.</returns>
    /// <error>The XML cannot be transformed.</error>
    /// <error>The XML cannot be loaded.</error>
    procedure TransformXmlText(XmlInText: Text; XslInText: Text): Text
    begin
        exit(XmlUtilitiesImpl.TransformXmlText(XmlInText, XslInText));
    end;

    /// <summary>
    /// Removes all namespaces and namespace prefixes from elements and attributes in an XML text.
    /// </summary>
    /// <param name="XmlText">The XML text.</param>
    /// <returns>The XML text without namespaces.</returns>
    /// <error>The XML cannot be transformed.</error>
    /// <error>The XML cannot be loaded.</error>
    procedure RemoveNamespaces(XmlText: Text): Text
    begin
        exit(XmlUtilitiesImpl.RemoveNamespaces(XmlText));
    end;

    /// <summary>
    /// Loads an XML document that contains a document type definition (DTD).
    /// The native XmlDocument.ReadFrom method does not allow DTDs. This procedure parses the internal DTD subset, expands the entities it defines,
    /// and keeps the document type declaration in the returned document. External DTDs and external entities are not resolved.
    /// </summary>
    /// <param name="InStream">The stream that contains the XML document.</param>
    /// <param name="XmlDocument">The loaded XML document.</param>
    /// <error>The stream is empty.</error>
    /// <error>The XML cannot be loaded.</error>
    [TryFunction]
    procedure TryLoadXmlDocumentWithDtd(InStream: InStream; var XmlDocument: XmlDocument)
    begin
        XmlUtilitiesImpl.LoadXmlDocumentWithDtd(InStream, XmlDocument);
    end;
}
