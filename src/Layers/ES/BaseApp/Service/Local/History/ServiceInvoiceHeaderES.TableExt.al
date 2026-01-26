// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;


tableextension 10792 "Service Invoice Header ES" extends "Service Invoice Header"
{
    fields
    {
        field(10706; "SII Status"; Enum "SII Document Status")
        {
            CalcFormula = lookup("SII Doc. Upload State".Status where("Document Source" = const("Customer Ledger"),
                                                                       "Document Type" = const(Invoice),
                                                                       "Document No." = field("No.")));
            Caption = 'SII Status';
            FieldClass = FlowField;

            trigger OnLookup()
            var
                SIIDocUploadState: Record "SII Doc. Upload State";
                SIIHistory: Record "SII History";
            begin
                SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
                SIIDocUploadState.SetRange("Document Type", SIIDocUploadState."Document Type"::Invoice);
                SIIDocUploadState.SetRange("Document No.", "No.");
                if SIIDocUploadState.FindFirst() then begin
                    SIIHistory.SetRange("Document State Id", SIIDocUploadState.Id);
                    PAGE.Run(PAGE::"SII History", SIIHistory);
                end;
            end;
        }
        field(10707; "Invoice Type"; Enum "SII Sales Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                SetSIIFirstSummaryDocNo('');
                SetSIILastSummaryDocNo('');
            end;
        }
        field(10708; "Cr. Memo Type"; Enum "SII Sales Credit Memo Type")
        {
            Caption = 'Cr. Memo Type';
            DataClassification = CustomerContent;
        }
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
        field(10710; "Operation Description"; Text[250])
        {
            Caption = 'Operation Description';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10712; "Operation Description 2"; Text[250])
        {
            Caption = 'Operation Description 2';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10722; "ID Type"; Enum "SII ID Type")
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
        }
        field(10723; "Sent to SII"; Boolean)
        {
            CalcFormula = exist("SII Doc. Upload State" where("Document Source" = const("Customer Ledger"),
                                                               "Document Type" = const(Invoice),
                                                               "Document No." = field("No.")));
            Editable = false;
            FieldClass = FlowField;
        }
        field(10724; "Do Not Send To SII"; Boolean)
        {
            Caption = 'Do Not Send To SII';
            DataClassification = CustomerContent;
        }
        field(10725; "Issued By Third Party"; Boolean)
        {
            Caption = 'Issued By Third Party';
            DataClassification = CustomerContent;
        }
        field(10726; "SII First Summary Doc. No."; Blob)
        {
            Caption = 'First Summary Doc. No.';
            DataClassification = CustomerContent;
        }
        field(10727; "SII Last Summary Doc. No."; Blob)
        {
            Caption = 'Last Summary Doc. No.';
            DataClassification = CustomerContent;
        }
        field(7000000; "Applies-to Bill No."; Code[20])
        {
            Caption = 'Applies-to Bill No.';
            DataClassification = CustomerContent;
        }
        field(7000001; "Cust. Bank Acc. Code"; Code[20])
        {
            Caption = 'Cust. Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            TableRelation = "Customer Pmt. Address".Code where("Customer No." = field("Bill-to Customer No."));
            ObsoleteReason = 'Address is taken from the fields Bill-to Address, Bill-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
    }

    procedure GetSIIFirstSummaryDocNo(): Text
    var
        InStreamObj: InStream;
        SIISummaryDocNoText: Text;
    begin
        CalcFields("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateInStream(InStreamObj, TextEncoding::UTF8);
        InStreamObj.ReadText(SIISummaryDocNoText);
        exit(SIISummaryDocNoText);
    end;

    procedure GetSIILastSummaryDocNo(): Text
    var
        InStreamObj: InStream;
        SIISummaryDocNoText: Text;
    begin
        CalcFields("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateInStream(InStreamObj, TextEncoding::UTF8);
        InStreamObj.ReadText(SIISummaryDocNoText);
        exit(SIISummaryDocNoText);
    end;

    procedure SetSIIFirstSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        if SIISummaryDocNoText <> '' then
            TestField("Invoice Type", "Invoice Type"::"F4 Invoice summary entry");

        Clear("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    procedure SetSIILastSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        if SIISummaryDocNoText <> '' then
            TestField("Invoice Type", "Invoice Type"::"F4 Invoice summary entry");

        Clear("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;
}