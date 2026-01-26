// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;

tableextension 10012 "Service Cr.Memo Header NA" extends "Service Cr.Memo Header"
{
    fields
    {
        field(10018; "STE Transaction ID"; Text[20])
        {
            Caption = 'STE Transaction ID';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10019; "Electronic Document Sent"; Boolean)
        {
            Caption = 'Electronic Document Sent';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10020; "Original Document XML"; BLOB)
        {
            Caption = 'Original Document XML';
            DataClassification = CustomerContent;
        }
        field(10021; "No. of E-Documents Sent"; Integer)
        {
            Caption = 'No. of E-Documents Sent';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10022; "Original String"; BLOB)
        {
            Caption = 'Original String';
            DataClassification = CustomerContent;
        }
        field(10023; "Digital Stamp SAT"; BLOB)
        {
            Caption = 'Digital Stamp SAT';
            DataClassification = CustomerContent;
        }
        field(10024; "Certificate Serial No."; Text[250])
        {
            Caption = 'Certificate Serial No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10025; "Signed Document XML"; BLOB)
        {
            Caption = 'Signed Document XML';
            DataClassification = CustomerContent;
        }
        field(10026; "Digital Stamp PAC"; BLOB)
        {
            Caption = 'Digital Stamp PAC';
            DataClassification = CustomerContent;
        }
        field(10030; "Electronic Document Status"; Option)
        {
            Caption = 'Electronic Document Status';
            DataClassification = CustomerContent;
            Editable = false;
            OptionCaption = ' ,Stamp Received,Sent,Canceled,Stamp Request Error,Cancel Error,Cancel In Progress';
            OptionMembers = " ","Stamp Received",Sent,Canceled,"Stamp Request Error","Cancel Error","Cancel In Progress";
        }
        field(10031; "Date/Time Stamped"; Text[50])
        {
            Caption = 'Date/Time Stamped';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10032; "Date/Time Sent"; Text[50])
        {
            Caption = 'Date/Time Sent';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10033; "Date/Time Canceled"; Text[50])
        {
            Caption = 'Date/Time Canceled';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10035; "Error Code"; Code[10])
        {
            Caption = 'Error Code';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10036; "Error Description"; Text[250])
        {
            Caption = 'Error Description';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10037; "Date/Time Stamp Received"; DateTime)
        {
            Caption = 'Date/Time Stamp Received';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10038; "Date/Time Cancel Sent"; DateTime)
        {
            Caption = 'Date/Time Cancel Sent';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10040; "PAC Web Service Name"; Text[50])
        {
            Caption = 'PAC Web Service Name';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10041; "QR Code"; BLOB)
        {
            Caption = 'QR Code';
            DataClassification = CustomerContent;
        }
        field(10042; "Fiscal Invoice Number PAC"; Text[50])
        {
            Caption = 'Fiscal Invoice Number PAC';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10043; "Date/Time First Req. Sent"; Text[50])
        {
            Caption = 'Date/Time First Req. Sent';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(10050; "Foreign Trade"; Boolean)
        {
            Caption = 'Foreign Trade';
            DataClassification = CustomerContent;
        }
        field(10059; "SAT International Trade Term"; Code[10])
        {
            Caption = 'SAT International Trade Term';
            DataClassification = CustomerContent;
            TableRelation = "SAT International Trade Term";
        }
        field(10060; "Exchange Rate USD"; Decimal)
        {
            Caption = 'Exchange Rate USD';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 6;
        }
        field(27000; "CFDI Purpose"; Code[10])
        {
            Caption = 'CFDI Purpose';
            DataClassification = CustomerContent;
            TableRelation = "SAT Use Code";
        }
        field(27001; "CFDI Relation"; Code[10])
        {
            Caption = 'CFDI Relation';
            DataClassification = CustomerContent;
            TableRelation = "SAT Relationship Type";
        }
        field(27002; "CFDI Cancellation Reason Code"; Code[10])
        {
            Caption = 'CFDI Cancellation Reason';
            DataClassification = CustomerContent;
            TableRelation = "CFDI Cancellation Reason";
        }
        field(27003; "Substitution Document No."; Code[20])
        {
            Caption = 'Substitution Document No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Cr.Memo Header" where("Electronic Document Status" = filter("Stamp Received"));
        }
        field(27004; "CFDI Export Code"; Code[10])
        {
            Caption = 'CFDI Export Code';
            DataClassification = CustomerContent;
            TableRelation = "CFDI Export Code";
        }
        field(27005; "CFDI Period"; Option)
        {
            Caption = 'CFDI Period';
            DataClassification = CustomerContent;
            OptionCaption = 'Diario,Semanal,Quincenal,Mensual';
            OptionMembers = "Diario","Semanal","Quincenal","Mensual";
        }
        field(27007; "CFDI Cancellation ID"; Text[50])
        {
            Caption = 'CFDI Cancellation ID';
            DataClassification = CustomerContent;
        }
        field(27008; "Marked as Canceled"; Boolean)
        {
            Caption = 'Marked as Canceled';
            DataClassification = CustomerContent;
        }
        field(27009; "SAT Address ID"; Integer)
        {
            Caption = 'SAT Address ID';
            DataClassification = CustomerContent;
            TableRelation = "SAT Address";

            trigger OnLookup()
            var
                SATAddress: Record "SAT Address";
            begin
                if SATAddress.LookupSATAddress(SATAddress, Rec."Ship-to Country/Region Code", Rec."Bill-to Country/Region Code") then
                    Rec."SAT Address ID" := SATAddress.Id;
            end;
        }
        field(27012; "CFDI Certificate of Origin No."; Text[50])
        {
            Caption = 'CFDI Certificate of Origin No.';
            DataClassification = CustomerContent;
            Description = 'NumCertificadoOrigen';
        }
    }

    var
        Text10000: Label 'There is no electronic stamp for document no. %1.';

    procedure ExportEDocument()
    var
        TempBlob: Codeunit System.Utilities."Temp Blob";
        RBMgt: Codeunit System.IO."File Management";
    begin
        CalcFields("Signed Document XML");
        if "Signed Document XML".HasValue() then begin
            TempBlob.FromRecord(Rec, FieldNo("Signed Document XML"));
            RBMgt.BLOBExport(TempBlob, "No." + '.xml', true);
        end else
            Error(Text10000, "No.");
    end;

    procedure ExportEDocumentPDF()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        FileManagement: Codeunit System.IO."File Management";
        FilePath: Text;
    begin
        if "Electronic Document Status" in ["Electronic Document Status"::Sent, "Electronic Document Status"::"Stamp Received"] then begin
            ServiceCrMemoHeader := Rec;
            ServiceCrMemoHeader.SetRecFilter();
            FilePath := FileManagement.ServerTempFileName('pdf');
            REPORT.SaveAsPdf(REPORT::"Elec. Service Cr Memo MX", FilePath, ServiceCrMemoHeader);
            FileManagement.DownloadHandler(FilePath, '', '', '', "No." + '.pdf');
        end else
            Error(Text10000, "No.");
    end;

    procedure RequestStampEDocument()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        LoCRecRef: RecordRef;
    begin
        LoCRecRef.GetTable(Rec);
        EInvoiceMgt.RequestStampDocument(LoCRecRef, false);
    end;

    procedure CancelEDocument()
    var
        EInvoiceMgt: Codeunit "E-Invoice Mgt.";
        LoCRecRef: RecordRef;
    begin
        LoCRecRef.GetTable(Rec);
        EInvoiceMgt.CancelDocument(LoCRecRef);
    end;
}
