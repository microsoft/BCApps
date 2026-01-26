// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Service.History;

tableextension 10790 "Service Header ES" extends "Service Header"
{
    fields
    {
        modify("Due Date")
        {
            trigger OnAfterValidate()
            var
                PaymentTerms: Record "Payment Terms";
            begin
                if PaymentTerms.Get("Payment Terms Code") then
                    PaymentTerms.VerifyMaxNoDaysTillDueDate("Due Date", "Document Date", CopyStr(FieldCaption("Due Date"), 1, 50));
            end;
        }

        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                ServiceInvoiceHeader: Record "Service Invoice Header";
                PostedServiceInvoices: Page "Posted Service Invoices";
            begin
                ServiceInvoiceHeader.SetCurrentKey("No.");
                ServiceInvoiceHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");

                PostedServiceInvoices.SetTableView(ServiceInvoiceHeader);
                PostedServiceInvoices.SetRecord(ServiceInvoiceHeader);
                PostedServiceInvoices.LookupMode(true);
                if PostedServiceInvoices.RunModal() = ACTION::LookupOK then begin
                    PostedServiceInvoices.GetRecord(ServiceInvoiceHeader);
                    Validate("Corrected Invoice No.", ServiceInvoiceHeader."No.");
                end;
                Clear(PostedServiceInvoices);
            end;

            trigger OnValidate()
            var
                ServiceInvoiceHeader: Record "Service Invoice Header";
                SIIManagement: Codeunit "SII Management";
                DoesNotExistErr: Label 'The %1 does not exist. \Identification fields and values:\%1 = %2', Comment = '%1 - field caption, %2 - field value';
            begin
                if "Corrected Invoice No." <> '' then begin
                    ServiceInvoiceHeader.SetCurrentKey("No.");
                    ServiceInvoiceHeader.SetRange("Bill-to Customer No.", "Bill-to Customer No.");
                    ServiceInvoiceHeader.SetRange("No.", "Corrected Invoice No.");
                    if ServiceInvoiceHeader.IsEmpty() then
                        Error(DoesNotExistErr, FieldCaption("Corrected Invoice No."), "Corrected Invoice No.");
                end;
                Validate("ID Type", SIIManagement.GetSalesIDType("Bill-to Customer No.", "Correction Type", "Corrected Invoice No."));
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

            trigger OnValidate()
            begin
                SetSIIFirstSummaryDocNo('');
                SetSIILastSummaryDocNo('');
            end;
        }
        field(10709; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                ServSIIManagement: Codeunit "Serv. SII Management";
            begin
                ServSIIManagement.UpdateServiceSpecialSchemeCodeInSalesHeader(Rec, xRec);
            end;
        }
        field(10710; "Operation Description"; Text[250])
        {
            Caption = 'Operation Description';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;

            trigger OnValidate()
            var
                SIIManagement: Codeunit "SII Management";
            begin
                Validate("ID Type", SIIManagement.GetSalesIDType("Bill-to Customer No.", "Correction Type", "Corrected Invoice No."));
            end;
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
        field(10722; "ID Type"; Option)
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,02-VAT Registration No.,03-Passport,04-ID Document,05-Certificate Of Residence,06-Other Probative Document,07-Not On The Census';
            OptionMembers = " ","02-VAT Registration No.","03-Passport","04-ID Document","05-Certificate Of Residence","06-Other Probative Document","07-Not On The Census";
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
            TableRelation = Microsoft.Sales.Receivables."Customer Pmt. Address".Code where("Customer No." = field("Bill-to Customer No."));
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
            if "Document Type" in ["Document Type"::Invoice, "Document Type"::Order] then
                TestField("Invoice Type", "Invoice Type"::"F4 Invoice summary entry")
            else
                TestField("Cr. Memo Type", "Cr. Memo Type"::"F4 Invoice summary entry");

        Clear("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    procedure SetSIILastSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        if SIISummaryDocNoText <> '' then
            if "Document Type" in ["Document Type"::Invoice, "Document Type"::Order] then
                TestField("Invoice Type", "Invoice Type"::"F4 Invoice summary entry")
            else
                TestField("Cr. Memo Type", "Cr. Memo Type"::"F4 Invoice summary entry");

        Clear("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

}