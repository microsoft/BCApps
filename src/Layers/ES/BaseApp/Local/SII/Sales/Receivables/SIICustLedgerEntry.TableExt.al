// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Receivables;

tableextension 7000125 "SII Cust. Ledger Entry" extends "Cust. Ledger Entry"
{
    fields
    {
        field(10700; "Invoice Type"; Enum "SII Sales Invoice Type")
        {
            Caption = 'Invoice Type';
            DataClassification = CustomerContent;
        }
        field(10701; "Cr. Memo Type"; Enum "SII Sales Credit Memo Type")
        {
            Caption = 'Cr. Memo Type';
            DataClassification = CustomerContent;
        }
        field(10702; "Special Scheme Code"; Enum "SII Sales Special Scheme Code")
        {
            Caption = 'Special Scheme Code';
            DataClassification = CustomerContent;
        }
        field(10703; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
        field(10704; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
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
}
