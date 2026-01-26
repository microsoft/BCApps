// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System;
using System.Reflection;
using System.Utilities;
using System.Xml;

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
        XMLDOMMgt: Codeunit "XML DOM Management";
        TypeHelper: Codeunit "Type Helper";
        XMLDocument: DotNet XmlDocument;
        OutStream: OutStream;
        InStream: InStream;
    begin
        // Format input XML text: append indentations
        if XMLDOMMgt.LoadXMLDocumentFromText(InputXMLText, XMLDocument) then begin
            TempBlob.CreateOutStream(OutStream, TEXTENCODING::UTF8);
            XMLDocument.Save(OutStream);
            TempBlob.CreateInStream(InStream, TEXTENCODING::UTF8);
            exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.CRLFSeparator()));
        end;
        ClearLastError();
        exit(InputXMLText);
    end;
}

