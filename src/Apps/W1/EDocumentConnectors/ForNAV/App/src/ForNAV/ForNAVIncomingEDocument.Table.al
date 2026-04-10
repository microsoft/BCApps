// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;

// Used by Azure function - do not modify
table 6415 "ForNAV Incoming E-Document"
{
    DataClassification = CustomerContent;
    Access = Internal;
    Permissions = tabledata "E-Document" = RIMD;
    Caption = 'ForNAV Incoming Doc';
    fields
    {
        field(1; ID; Text[80]) // Needs to have same length as tableextension "ForNAV EDocument"."ForNAV ID"
        {
            DataClassification = SystemMetadata;
            Caption = 'ID';
        }
        field(6; DocNo; Text[20])
        {
            DataClassification = SystemMetadata;
            Caption = 'DocNo';
        }
        field(2; DocType; Option)
        {
            OptionMembers = Invoice,ApplicationResponse,CreditNote,Evidence;
            DataClassification = SystemMetadata;
            Caption = 'DocType';
        }
        field(3; DocCode; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'DocCode';
        }
        field(4; Doc; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Doc';
        }
        field(5; Status; Enum "ForNAV Incoming E-Doc Status")
        {
            DataClassification = SystemMetadata;
            Caption = 'Status';
        }
        field(11; EDocumentType; Enum "E-Document Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'EDocumentType';
        }
        field(7; Message; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Message';
        }
        field(8; SchemeID; Text[4])
        {
            DataClassification = CustomerContent;
            Caption = 'SchemeID';
        }
        field(9; EndpointID; Text[20]) // Size of VAT Reg#
        {
            DataClassification = CustomerContent;
            Caption = 'EndpointID';
        }
        field(10; "HTML Preview"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'HTML Preview';
        }
    }

    keys
    {
        key(PK; ID, DocType)
        {
            Clustered = true;
        }
        key(CreatedAt; SystemCreatedAt)
        {
        }
    }
    procedure GetDoc(): Text;
    var
        Document: BigText;
        InStr: InStream;
    begin
        Rec.CalcFields(Doc);
        Rec.Doc.CreateInStream(InStr, TextEncoding::UTF8);
        Document.Read(InStr);
        exit(Format(Document));
    end;

    procedure GetHtml(): Text;
    var
        Document: BigText;
        InStr: InStream;
    begin
        CalcFields("HTML Preview");
        "HTML Preview".CreateInStream(InStr, TextEncoding::UTF8);
        Document.Read(InStr);
        exit(Format(Document));
    end;

    procedure GetComment(): Text;
    var
        _Message: BigText;
        InStr: InStream;
    begin
        Rec.CalcFields(Message);
        Rec.Message.CreateInStream(InStr, TextEncoding::UTF8);
        _Message.Read(InStr);
        exit(Format(_Message));
    end;
}
