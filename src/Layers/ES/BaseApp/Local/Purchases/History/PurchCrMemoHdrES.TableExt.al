// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Foundation.Reporting;
#if not CLEANSCHEMA25
using Microsoft.Purchases.Reports;
#endif
using Microsoft.Purchases.Vendor;

#pragma warning disable AS0088
tableextension 10719 "Purch. Cr. Memo Hdr. ES" extends "Purch. Cr. Memo Hdr."
{
    fields
    {
        field(10700; "Autocredit Memo No."; Code[20])
        {
            Caption = 'Autocredit Memo No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(7000001; "Vendor Bank Acc. Code"; Code[20])
        {
            Caption = 'Vendor Bank Acc. Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Bank Account".Code where("Vendor No." = field("Pay-to Vendor No."));
        }
#if not CLEANSCHEMA25
        field(7000003; "Pay-at Code"; Code[10])
        {
            Caption = 'Pay-at Code';
            DataClassification = CustomerContent;
            TableRelation = "Vendor Pmt. Address".Code where("Vendor No." = field("Pay-to Vendor No."));
            ObsoleteReason = 'Address is taken from the fields Pay-to Address, Pay-to City, etc.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(10705; "Corrected Invoice No."; Code[20])
        {
            Caption = 'Corrected Invoice No.';
            DataClassification = CustomerContent;
            TableRelation = "Purch. Inv. Header";

            trigger OnLookup()
            var
                PurchaseInvoiceHeader: Record "Purch. Inv. Header";
            begin
                if PurchaseInvoiceHeader.LookupInvoice("Pay-to Vendor No.") then
                    Validate("Corrected Invoice No.", PurchaseInvoiceHeader."No.");
            end;
        }
        field(10711; "Correction Type"; Option)
        {
            Caption = 'Correction Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Replacement,Difference,Removal';
            OptionMembers = " ",Replacement,Difference,Removal;
        }
    }

    [Scope('OnPrem')]
    procedure PrintRecordsAutoCrMemo(ShowRequestForm: Boolean)
    var
        PurchCrMemoHeader: Record "Purch. Cr. Memo Hdr.";
        ReportSelection: Record "Report Selections";
    begin
        PurchCrMemoHeader.Copy(Rec);
        ReportSelection.SetRange(Usage, ReportSelection.Usage::"P.AutoCr.Memo");
        ReportSelection.SetFilter("Report ID", '<>0');
        ReportSelection.Find('-');
        repeat
            REPORT.RunModal(ReportSelection."Report ID", ShowRequestForm, false, PurchCrMemoHeader);
        until ReportSelection.Next() = 0;
    end;
}
