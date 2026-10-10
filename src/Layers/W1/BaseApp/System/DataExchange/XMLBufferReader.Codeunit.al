namespace System.IO;

#if not CLEAN30
using System;
#endif
using System.Utilities;

codeunit 1239 "XML Buffer Reader"
{

    trigger OnRun()
    begin
    end;

    var
        DefaultNamespace: Text;

    [TryFunction]
    [Scope('OnPrem')]
    procedure SaveToFile(FilePath: Text; var XMLBuffer: Record "XML Buffer")
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        SaveToTempBlobWithEncoding(TempBlob, XMLBuffer, 'UTF-8');
        FileMgt.BLOBExportToServerFile(TempBlob, FilePath);
    end;

    [TryFunction]
    procedure SaveToTempBlob(var TempBlob: Codeunit "Temp Blob"; var XMLBuffer: Record "XML Buffer")
    begin
        SaveToTempBlobWithEncoding(TempBlob, XMLBuffer, 'UTF-8');
    end;

    [TryFunction]
    procedure SaveToTempBlobWithEncoding(var TempBlob: Codeunit "Temp Blob"; var XMLBuffer: Record "XML Buffer"; Encoding: Text)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        TempAttributeXMLBuffer: Record "XML Buffer" temporary;
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        OutStr: OutStream;
        Header: Text;
    begin
        TempXMLBuffer.CopyImportFrom(XMLBuffer);
        TempXMLBuffer := XMLBuffer;
        TempXMLBuffer.SetCurrentKey("Parent Entry No.", Type, "Node Number");
        Header := '<?xml version="1.0" encoding="' + Encoding + '"?>' +
          '<' + TempXMLBuffer.GetElementName() + ' ';
        DefaultNamespace := TempXMLBuffer.GetAttributeValueAsText('xmlns');
        if TempXMLBuffer.FindAttributes(TempAttributeXMLBuffer) then
            repeat
                Header += TempAttributeXMLBuffer.Name + '="' + TempAttributeXMLBuffer.GetValue() + '" ';
            until TempAttributeXMLBuffer.Next() = 0;
        Header += '/>';

        XmlDocument.ReadFrom(Header, XmlDoc);
        XmlDoc.GetRoot(RootElement);

        SaveChildElements(TempXMLBuffer, RootElement, DefaultNamespace);


        TempBlob.CreateOutStream(OutStr);
        XmlDoc.WriteTo(OutStr);
    end;

    local procedure SaveChildElements(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: XmlElement; ParentDefaultNamespace: Text)
    var
        TempElementXMLBuffer: Record "XML Buffer" temporary;
        ChildElement: XmlElement;
        NamespaceURI: Text;
        ElementDefaultNamespace: Text;
        ElementValue: Text;
    begin
        if TempParentElementXMLBuffer.FindChildElements(TempElementXMLBuffer) then
            repeat
                // An xmlns attribute on the element itself sets the default namespace for the element and its children
                ElementDefaultNamespace := TempElementXMLBuffer.GetAttributeValueAsText('xmlns');
                if ElementDefaultNamespace = '' then
                    ElementDefaultNamespace := ParentDefaultNamespace;
                if TempElementXMLBuffer.Namespace = '' then
                    NamespaceURI := ElementDefaultNamespace
                else
                    NamespaceURI := TempParentElementXMLBuffer.GetNamespaceUriByPrefixAsText(TempElementXMLBuffer.Namespace);
                ChildElement := XmlElement.Create(TempElementXMLBuffer.Name, NamespaceURI);
                ElementValue := TempElementXMLBuffer.GetValue();
                if ElementValue <> '' then
                    ChildElement.Add(XmlText.Create(ElementValue));
                XMLCurrElement.Add(ChildElement);
                SaveProcessingInstructions(TempElementXMLBuffer, ChildElement);
                SaveAttributes(TempElementXMLBuffer, ChildElement);
                SaveChildElements(TempElementXMLBuffer, ChildElement, ElementDefaultNamespace);
            until TempElementXMLBuffer.Next() = 0;
    end;

#if not CLEAN30
    [Obsolete('Use SaveAttributes with an XmlElement parameter instead.', '30.0')]
    procedure SaveAttributes(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: DotNet XmlNode; XmlDocument: DotNet XmlDocument)
    var
        TempAttributeXMLBuffer: Record "XML Buffer" temporary;
        Attribute: DotNet XmlAttribute;
        NamespaceURI: Text;
    begin
        NamespaceURI := '';
        if TempParentElementXMLBuffer.FindAttributes(TempAttributeXMLBuffer) then
            repeat
                if TempAttributeXMLBuffer.Namespace <> '' then
                    NamespaceURI := TempParentElementXMLBuffer.GetNamespaceUriByPrefixAsText(TempAttributeXMLBuffer.Namespace);
                if NamespaceURI <> '' then
                    Attribute := XmlDocument.CreateAttribute(TempAttributeXMLBuffer.Name, NamespaceURI)
                else
                    Attribute := XmlDocument.CreateAttribute(TempAttributeXMLBuffer.Name);
                Attribute.InnerText := TempAttributeXMLBuffer.GetValue();
                XMLCurrElement.Attributes.SetNamedItem(Attribute);
            until TempAttributeXMLBuffer.Next() = 0;
    end;
#endif

    procedure SaveAttributes(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: XmlElement)
    var
        TempAttributeXMLBuffer: Record "XML Buffer" temporary;
        NamespaceURI: Text;
        AttributeName: Text;
        ColonPosition: Integer;
    begin
        NamespaceURI := '';
        if TempParentElementXMLBuffer.FindAttributes(TempAttributeXMLBuffer) then
            repeat
                if TempAttributeXMLBuffer.Namespace <> '' then
                    NamespaceURI := TempParentElementXMLBuffer.GetNamespaceUriByPrefixAsText(TempAttributeXMLBuffer.Namespace);
                AttributeName := TempAttributeXMLBuffer.Name;
                ColonPosition := StrPos(AttributeName, ':');
                case true of
                    AttributeName = 'xmlns':
                        XMLCurrElement.Add(XmlAttribute.Create(AttributeName, TempAttributeXMLBuffer.GetValue()));
                    ColonPosition = 0:
                        if NamespaceURI <> '' then
                            XMLCurrElement.SetAttribute(AttributeName, NamespaceURI, TempAttributeXMLBuffer.GetValue())
                        else
                            XMLCurrElement.SetAttribute(AttributeName, TempAttributeXMLBuffer.GetValue());
                    CopyStr(AttributeName, 1, ColonPosition - 1) = 'xmlns':
                        XMLCurrElement.Add(
                          XmlAttribute.CreateNamespaceDeclaration(CopyStr(AttributeName, ColonPosition + 1), TempAttributeXMLBuffer.GetValue()));
                    NamespaceURI <> '':
                        XMLCurrElement.SetAttribute(CopyStr(AttributeName, ColonPosition + 1), NamespaceURI, TempAttributeXMLBuffer.GetValue());
                    CopyStr(AttributeName, 1, ColonPosition - 1) = 'xml':
                        XMLCurrElement.SetAttribute(
                          CopyStr(AttributeName, ColonPosition + 1), 'http://www.w3.org/XML/1998/namespace', TempAttributeXMLBuffer.GetValue());
                    else
                        // Without a namespace URI the prefix cannot be kept, which is also how the attribute was saved before
                        XMLCurrElement.SetAttribute(CopyStr(AttributeName, ColonPosition + 1), TempAttributeXMLBuffer.GetValue());
                end;
            until TempAttributeXMLBuffer.Next() = 0;
    end;

#if not CLEAN30
    [Obsolete('Use SaveProcessingInstructions with an XmlElement parameter instead.', '30.0')]
    procedure SaveProcessingInstructions(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: DotNet XmlNode; XmlDocument: DotNet XmlDocument)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
        ProcessingInstruction: DotNet XmlProcessingInstruction;
    begin
        if TempParentElementXMLBuffer.FindProcessingInstructions(TempXMLBuffer) then
            repeat
                ProcessingInstruction := XmlDocument.CreateProcessingInstruction(TempXMLBuffer.Name, TempXMLBuffer.GetValue());
                XMLCurrElement.AppendChild(ProcessingInstruction);
            until TempXMLBuffer.Next() = 0;
    end;
#endif

    procedure SaveProcessingInstructions(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: XmlElement)
    var
        TempXMLBuffer: Record "XML Buffer" temporary;
    begin
        if TempParentElementXMLBuffer.FindProcessingInstructions(TempXMLBuffer) then
            repeat
                XMLCurrElement.Add(XmlProcessingInstruction.Create(TempXMLBuffer.Name, TempXMLBuffer.GetValue()));
            until TempXMLBuffer.Next() = 0;
    end;
}