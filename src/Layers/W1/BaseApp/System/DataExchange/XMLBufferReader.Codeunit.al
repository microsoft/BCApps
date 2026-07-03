namespace System.IO;

using System;
using System.Utilities;
using System.Xml;

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
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDocument: DotNet XmlDocument;
        RootElement: DotNet XmlNode;
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

        XMLDOMManagement.LoadXMLDocumentFromText(Header, XmlDocument);
        RootElement := XmlDocument.DocumentElement;

        SaveChildElements(TempXMLBuffer, RootElement, XmlDocument);

        TempBlob.CreateOutStream(OutStr);
        XmlDocument.Save(OutStr);
    end;

    local procedure SaveChildElements(var TempParentElementXMLBuffer: Record "XML Buffer" temporary; XMLCurrElement: DotNet XmlNode; XmlDocument: DotNet XmlDocument)
    var
        TempElementXMLBuffer: Record "XML Buffer" temporary;
        ChildElement: DotNet XmlNode;
        NamespaceURI: Text;
        ElementValue: Text;
    begin
        if TempParentElementXMLBuffer.FindChildElements(TempElementXMLBuffer) then
            repeat
                if TempElementXMLBuffer.Namespace = '' then
                    NamespaceURI := DefaultNamespace
                else
                    NamespaceURI := TempParentElementXMLBuffer.GetNamespaceUriByPrefixAsText(TempElementXMLBuffer.Namespace);
                ChildElement := XmlDocument.CreateElement(TempElementXMLBuffer.GetElementName(), NamespaceURI);
                ElementValue := TempElementXMLBuffer.GetValue();
                if ElementValue <> '' then
                    ChildElement.InnerText := ElementValue;
                XMLCurrElement.AppendChild(ChildElement);
                SaveProcessingInstructions(TempElementXMLBuffer, ChildElement, XmlDocument);
                SaveAttributes(TempElementXMLBuffer, ChildElement, XmlDocument);
                SaveChildElements(TempElementXMLBuffer, ChildElement, XmlDocument);
            until TempElementXMLBuffer.Next() = 0;
    end;

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
}

