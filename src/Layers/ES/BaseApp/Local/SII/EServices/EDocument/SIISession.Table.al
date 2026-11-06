// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Reflection;
using System.Utilities;

table 10753 "SII Session"
{
    Caption = 'SII Session';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            NotBlank = true;
        }
        field(2; "Request XML"; BLOB)
        {
            Caption = 'Request XML';
        }
        field(3; "Response XML"; BLOB)
        {
            Caption = 'Response XML';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure StoreRequestXml(RequestText: Text)
    var
        OutStream: OutStream;
    begin
        "Request XML".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XMLTextIndent(RequestText));
        CalcFields("Request XML");
        Modify();
    end;

    [Scope('OnPrem')]
    procedure StoreResponseXml(ResponseText: Text)
    var
        OutStream: OutStream;
    begin
        "Response XML".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(XMLTextIndent(ResponseText));
        CalcFields("Response XML");
        Modify();
    end;

    [Scope('OnPrem')]
    procedure XMLTextIndent(InputXMLText: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        FormattedXmlDocument: XmlDocument;
        RootXmlElement: XmlElement;
        XmlDeclaration: XmlDeclaration;
        OutStream: OutStream;
        InStream: InStream;
        FormattedXmlText: Text;
    begin
        // Format input XML text: append indentations
        if XmlDocument.ReadFrom(InputXMLText, FormattedXmlDocument) then begin
            RemoveWhitespaceNodes(FormattedXmlDocument.AsXmlNode());
            if not FormattedXmlDocument.GetDeclaration(XmlDeclaration) then begin
                FormattedXmlDocument.GetRoot(RootXmlElement);
                RootXmlElement.WriteTo(FormattedXmlText);
                exit(FormattedXmlText);
            end;
            TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
            FormattedXmlDocument.WriteTo(OutStream);
            TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
            exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
        end;
        ClearLastError();
        exit(InputXMLText);
    end;

    local procedure RemoveWhitespaceNodes(ParentXmlNode: XmlNode)
    var
        ChildXmlNode: XmlNode;
        ChildXmlNodeList: XmlNodeList;
        i: Integer;
    begin
        if ParentXmlNode.IsXmlDocument() then
            ChildXmlNodeList := ParentXmlNode.AsXmlDocument().GetChildNodes()
        else
            if ParentXmlNode.IsXmlElement() then
                ChildXmlNodeList := ParentXmlNode.AsXmlElement().GetChildNodes()
            else
                exit;
        for i := ChildXmlNodeList.Count() downto 1 do begin
            ChildXmlNodeList.Get(i, ChildXmlNode);
            if ChildXmlNode.IsXmlText() then begin
                if ChildXmlNode.AsXmlText().Value.Trim() = '' then
                    ChildXmlNode.Remove();
            end else
                RemoveWhitespaceNodes(ChildXmlNode);
        end;
    end;
}

