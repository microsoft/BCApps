// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;

#pragma warning disable AS0088
tableextension 7000028 "SII Gen. Journal Line" extends "Gen. Journal Line"
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

    var
        IncorrectAccTypeErr: Label '%1 or %2 must be a %3.', Comment = '%1=Account Type,%2=Balance Account Type,%3=Customer or Vendor';
}
