// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;

tableextension 7000128 "SII Gen. Journal Line" extends "Gen. Journal Line"
{
    fields
    {
        field(10709; "Sales Invoice Type"; Enum "SII Sales Invoice Type")
        {
            Caption = 'Sales Invoice Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Invoice Type" <> "Sales Invoice Type"::"F1 Invoice" then begin
                    CheckAccAndBalAccTypeSII("Account Type"::Customer);
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(10710; "Sales Cr. Memo Type"; Enum "SII Sales Credit Memo Type")
        {
            Caption = 'Sales Cr. Memo Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Cr. Memo Type" <> "Sales Cr. Memo Type"::"R1 Corrected Invoice" then begin
                    CheckAccAndBalAccTypeSII("Account Type"::Customer);
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(10711; "Sales Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Sales Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Sales Special Scheme Code" <> "Sales Special Scheme Code"::"01 General" then
                    CheckAccAndBalAccTypeSII("Account Type"::Customer);
            end;
        }
        field(10712; "Purch. Invoice Type"; Enum "SII Purch. Invoice Type")
        {
            Caption = 'Purch. Invoice Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Invoice Type" <> "Purch. Invoice Type"::"F1 Invoice" then begin
                    CheckAccAndBalAccTypeSII("Account Type"::Vendor);
                    TestField("Document Type", "Document Type"::Invoice);
                end;
            end;
        }
        field(10713; "Purch. Cr. Memo Type"; Enum "SII Purch. Credit Memo Type")
        {
            Caption = 'Purch. Cr. Memo Type';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Cr. Memo Type" <> "Purch. Cr. Memo Type"::"R1 Corrected Invoice" then begin
                    CheckAccAndBalAccTypeSII("Account Type"::Vendor);
                    TestField("Document Type", "Document Type"::"Credit Memo");
                end;
            end;
        }
        field(10714; "Purch. Special Scheme Code"; Enum "SII Purch. Special Scheme Code")
        {
            Caption = 'Purch. Special Scheme Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Purch. Special Scheme Code" <> "Purch. Special Scheme Code"::"01 General" then
                    CheckAccAndBalAccTypeSII("Account Type"::Vendor);
            end;
        }
        field(10715; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;

            trigger OnValidate()
            begin
                if "Correction Type" <> 0 then
                    CheckDataForCorrectionSII();
            end;
        }
        field(10716; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;

            trigger OnLookup()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                InitGenJnlLineBufferWithCustVendSII(TempGenJournalLine);
                case true of
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                        if SalesInvoiceHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", SalesInvoiceHeader."No.");
                    TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                        if PurchInvHeader.LookupInvoice("Account No.") then
                            Validate("Corrected Invoice No.", PurchInvHeader."No.");
                end;
            end;

            trigger OnValidate()
            var
                SalesInvoiceHeader: Record "Sales Invoice Header";
                PurchInvHeader: Record "Purch. Inv. Header";
                TempGenJournalLine: Record "Gen. Journal Line" temporary;
            begin
                if "Corrected Invoice No." <> '' then begin
                    CheckDataForCorrectionSII();
                    InitGenJnlLineBufferWithCustVendSII(TempGenJournalLine);
                    case true of
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Customer:
                            SalesInvoiceHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                        TempGenJournalLine."Account Type" = TempGenJournalLine."Account Type"::Vendor:
                            PurchInvHeader.CheckCorrectedDocumentExist("Account No.", "Corrected Invoice No.");
                    end;
                end;
            end;
        }
        field(10720; "Succeeded Company Name"; Text[250])
        {
            Caption = 'Succeeded Company Name';
            DataClassification = CustomerContent;
        }
        field(10721; "Succeeded VAT Registration No."; Text[20])
        {
            Caption = 'Succeeded VAT Registration No.';
            DataClassification = CustomerContent;
        }
        field(10722; "ID Type"; Enum "SII ID Type")
        {
            Caption = 'ID Type';
            DataClassification = CustomerContent;
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
        Clear("SII First Summary Doc. No.");
        "SII First Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    procedure SetSIILastSummaryDocNo(SIISummaryDocNoText: Text)
    var
        OutStreamObj: OutStream;
    begin
        Clear("SII Last Summary Doc. No.");
        "SII Last Summary Doc. No.".CreateOutStream(OutStreamObj, TextEncoding::UTF8);
        OutStreamObj.WriteText(SIISummaryDocNoText);
    end;

    local procedure CheckAccAndBalAccTypeSII(AccType: Enum "Gen. Journal Account Type")
    begin
        if ("Account Type" <> AccType) and ("Bal. Account Type" <> AccType) then
            Error(
              IncorrectAccTypeErr,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"), Format(AccType));
    end;

    local procedure CheckDataForCorrectionSII()
    begin
        TestField("Document Type", "Document Type"::"Credit Memo");
        if not (("Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]) or
                ("Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]))
        then
            Error(IncorrectAccTypeErr,
              FieldCaption("Account Type"), FieldCaption("Bal. Account Type"),
              StrSubstNo(OneOrAnotherTxt, Format("Account Type"::Customer), Format("Account Type"::Vendor)));
    end;

    local procedure InitGenJnlLineBufferWithCustVendSII(var TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        TempGenJournalLine.Init();
        case true of
            "Account Type" in ["Account Type"::Customer, "Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Account Type";
                    TempGenJournalLine."Account No." := "Account No.";
                end;
            "Bal. Account Type" in ["Bal. Account Type"::Customer, "Bal. Account Type"::Vendor]:
                begin
                    TempGenJournalLine."Account Type" := "Bal. Account Type";
                    TempGenJournalLine."Account No." := "Bal. Account No.";
                end;
        end;
    end;

    procedure ClearInvCrMemoTypeFields()
    begin
        "Sales Invoice Type" := "Sales Invoice Type"::"F1 Invoice";
        "Sales Cr. Memo Type" := "Sales Cr. Memo Type"::"R1 Corrected Invoice";
        "Sales Special Scheme Code" := "Sales Special Scheme Code"::"01 General";
        "Purch. Invoice Type" := "Purch. Invoice Type"::"F1 Invoice";
        "Purch. Cr. Memo Type" := "Purch. Cr. Memo Type"::"R1 Corrected Invoice";
        "Purch. Special Scheme Code" := "Purch. Special Scheme Code"::"01 General";
        "Correction Type" := 0;
        "Corrected Invoice No." := '';
    end;

    var
        IncorrectAccTypeErr: Label '%1 or %2 must be a %3.', Comment = '%1=Account Type,%2=Balance Account Type,%3=Customer or Vendor';
        OneOrAnotherTxt: Label '%1 or %2', Comment = '%1 - Customer or Vendor, %2 - Customer or Vendor';
}
