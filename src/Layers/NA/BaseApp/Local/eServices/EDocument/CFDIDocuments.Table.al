// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.IO;
using System.Utilities;

table 27005 "CFDI Documents"
{
    Caption = 'CFDI Documents';
    DataCaptionFields = "No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(5; "Document Table ID"; Integer)
        {
            Caption = 'Document Table ID';
        }
        field(10; Prepayment; Boolean)
        {
            Caption = 'Prepayment';
        }
        field(15; Reversal; Boolean)
        {
            Caption = 'Reversal';
        }
        field(10019; "Electronic Document Sent"; Boolean)
        {
            Caption = 'Electronic Document Sent';
            Editable = false;
        }
        field(10020; "Original Document XML"; BLOB)
        {
            Caption = 'Original Document XML';
        }
        field(10021; "No. of E-Documents Sent"; Integer)
        {
            Caption = 'No. of E-Documents Sent';
            Editable = false;
        }
        field(10022; "Original String"; BLOB)
        {
            Caption = 'Original String';
        }
        field(10023; "Digital Stamp SAT"; BLOB)
        {
            Caption = 'Digital Stamp SAT';
        }
        field(10024; "Certificate Serial No."; Text[250])
        {
            Caption = 'Certificate Serial No.';
            Editable = false;
        }
        field(10025; "Signed Document XML"; BLOB)
        {
            Caption = 'Signed Document XML';
        }
        field(10026; "Digital Stamp PAC"; BLOB)
        {
            Caption = 'Digital Stamp PAC';
        }
        field(10030; "Electronic Document Status"; Option)
        {
            Caption = 'Electronic Document Status';
            Editable = false;
            OptionCaption = ' ,Stamp Received,Sent,Canceled,Stamp Request Error,Cancel Error';
            OptionMembers = " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error";
        }
        field(10031; "Date/Time Stamped"; Text[50])
        {
            Caption = 'Date/Time Stamped';
            Editable = false;
        }
        field(10032; "Date/Time Sent"; Text[50])
        {
            Caption = 'Date/Time Sent';
            Editable = false;
        }
        field(10033; "Date/Time Canceled"; Text[50])
        {
            Caption = 'Date/Time Canceled';
            Editable = false;
        }
        field(10035; "Error Code"; Code[10])
        {
            Caption = 'Error Code';
            Editable = false;
        }
        field(10036; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            Editable = false;
        }
        field(10037; "Date/Time Stamp Received"; DateTime)
        {
            Caption = 'Date/Time Stamp Received';
            Editable = false;
        }
        field(10038; "Date/Time Cancel Sent"; DateTime)
        {
            Caption = 'Date/Time Cancel Sent';
            Editable = false;
        }
        field(10040; "PAC Web Service Name"; Text[50])
        {
            Caption = 'PAC Web Service Name';
            Editable = false;
        }
        field(10041; "QR Code"; BLOB)
        {
            Caption = 'QR Code';
        }
        field(10042; "Fiscal Invoice Number PAC"; Text[50])
        {
            Caption = 'Fiscal Invoice Number PAC';
            Editable = false;
        }
        field(10043; "Date/Time First Req. Sent"; Text[50])
        {
            Caption = 'Date/Time First Req. Sent';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.", "Document Table ID", Prepayment, Reversal)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NoStampErr: Label 'There is no electronic stamp for document no. %1.', Comment = '%1=The document number.';

    procedure ExportEDocument()
    var
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        CalcFields("Signed Document XML");
        if "Signed Document XML".HasValue() then begin
            TempBlob.FromRecord(Rec, FieldNo("Signed Document XML"));
            FileManagement.BLOBExport(TempBlob, "No." + '.xml', true);
        end else
            Error(NoStampErr, "No.");
    end;

    procedure SendEDocument()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        LoCRecRef: RecordRef;
        EDocAction: Option "Request Stamp",Send,Cancel;
    begin
        LoCRecRef.GetTable(Rec);
        EInvoiceMgt.EDocActionValidation(EDocAction::Send, "Electronic Document Status");
        EInvoiceMgt.Send(LoCRecRef, true);
    end;
}

