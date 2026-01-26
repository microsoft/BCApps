// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Payables;

report 12195 "Datifattura Suggest Lines"
{
    Caption = 'Datifattura Suggest Lines';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(VATReportHeader; "VAT Report Header")
        {
            DataItemTableView = sorting("No.");

            trigger OnAfterGetRecord()
            var
                VATReportLine: Record "VAT Report Line";
            begin
                VATReportLine.SetRange("VAT Report No.", "No.");
                if not VATReportLine.IsEmpty() then
                    if not Confirm(DeleteReportLinesQst, false) then
                        Error('');
                VATReportLine.DeleteAll();
                if "VAT Report Type" = "VAT Report Type"::"Cancellation " then
                    CurrReport.Quit();
            end;
        }
        dataitem(VATInvoices; "VAT Entry")
        {
            DataItemTableView = sorting(Type, "Bill-to/Pay-to No.") order(ascending) where("Document Type" = filter(Invoice | "Credit Memo"));
            RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";

            trigger OnAfterGetRecord()
            begin
                if ("VAT Calculation Type" = "VAT Calculation Type"::"Reverse Charge VAT") and (Type = Type::Sale) then
                    CurrReport.Skip();
                if not IsForeignInvoiceLinkedWithCustoms(VATInvoices) then
                    CreateVATReportLine(VATInvoices);
            end;

            trigger OnPreDataItem()
            var
                VATReportLine: Record "VAT Report Line";
            begin
                VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
                if VATReportLine.FindLast() then;
                CurrentLineNo := VATReportLine."Line No.";

                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        DeleteReportLinesQst: Label 'All existing report lines will be deleted. Do you want to continue?';
        CurrentLineNo: Integer;

    local procedure CreateVATReportLine(var VATEntry: Record "VAT Entry")
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Entry No.", VATEntry."Entry No.");

        // check if the entry was reported before
        if not VATReportLine.IsEmpty() then
            exit;

        if not FindVATReportLine(VATReportLine, VATEntry) then
            InsertVATReportLine(VATReportLine, VATEntry);

        SetAmountsInVATReportLine(VATReportLine, VATEntry);
        VATReportLine.Modify();
    end;

    local procedure GetNextLineNo(): Integer
    begin
        CurrentLineNo += 1;
        exit(CurrentLineNo);
    end;

    local procedure GetVATTransactionNature(VATEntry: Record "VAT Entry"): Code[4]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if VATEntry."VAT Transaction Nature" <> '' then
            exit(VATEntry."VAT Transaction Nature");
        if VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group") then
            exit(VATPostingSetup."VAT Transaction Nature");
    end;

    local procedure GetVATReportLineDocumentNo(VATEntry: Record "VAT Entry"; DocNoLen: Integer): Code[20]
    begin
        if (VATEntry.Type = VATEntry.Type::Purchase) and
           (VATEntry."Document Type" in [VATEntry."Document Type"::"Credit Memo", VATEntry."Document Type"::Invoice])
        then
            exit(CopyStr(VATEntry."External Document No.", 1, DocNoLen));
        exit(VATEntry."Document No.");
    end;

    local procedure SetAmountsInVATReportLine(var VATReportLine: Record "VAT Report Line"; VATEntry: Record "VAT Entry")
    begin
        if (VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT") and
           (VATEntry.Type = VATEntry.Type::Sale)
        then
            exit;

        VATReportLine.Amount += VATEntry.Amount;
        VATReportLine.Base += VATEntry.Base;
        VATReportLine."Amount Incl. VAT" += VATEntry.Base + VATEntry.Amount;
        VATReportLine."Unrealized Amount" += VATEntry."Unrealized Amount";
        VATReportLine."Unrealized Base" += VATEntry."Unrealized Base";

        if VATEntry.Type = VATEntry.Type::Purchase then begin
            VATReportLine.Amount += VATEntry."Nondeductible Amount";
            VATReportLine.Base += VATEntry."Nondeductible Base";
            VATReportLine."Amount Incl. VAT" += VATEntry."Nondeductible Base" + VATEntry."Nondeductible Amount";
        end;
    end;

    local procedure FindVATReportLine(var FountVATReportLine: Record "VAT Report Line"; VATEntry: Record "VAT Entry"): Boolean
    var
        VATReportLine: Record "VAT Report Line";
        RecordFound: Boolean;
    begin
        Clear(FountVATReportLine);

        VATReportLine.Reset();
        VATReportLine.SetRange("Document Type", VATEntry."Document Type");
        VATReportLine.SetRange("Document No.", VATEntry."Document No.");
        VATReportLine.SetRange(Type, VATEntry.Type);
        VATReportLine.SetRange("VAT Group Identifier", VATEntry."VAT Identifier");

        RecordFound := VATReportLine.FindFirst();

        if RecordFound then
            FountVATReportLine := VATReportLine;

        exit(RecordFound);
    end;

    local procedure InsertVATReportLine(var VATReportLine: Record "VAT Report Line"; VATEntry: Record "VAT Entry")
    begin
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeader."No.";
        VATReportLine."Posting Date" := VATEntry."Posting Date";
        VATReportLine."Document No." := GetVATReportLineDocumentNo(VATEntry, MaxStrLen(VATReportLine."Document No."));
        VATReportLine."Line No." := GetNextLineNo();
        VATReportLine."Document Type" := VATEntry."Document Type";
        VATReportLine.Type := VATEntry.Type;
        VATReportLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
        VATReportLine."Source Code" := VATEntry."Source Code";
        VATReportLine."Reason Code" := VATEntry."Reason Code";
        VATReportLine."Country/Region Code" := VATEntry."Country/Region Code";
        VATReportLine."Internal Ref. No." := VATEntry."Internal Ref. No.";
        VATReportLine."External Document No." := VATEntry."External Document No.";
        VATReportLine."VAT Registration No." := VATEntry."VAT Registration No.";
        VATReportLine."Operation Occurred Date" := VATEntry."Operation Occurred Date";
        if VATEntry."Contract No." <> '' then
            VATReportLine."Contract Payment Type" := VATReportLine."Contract Payment Type"::Contract
        else
            VATReportLine."Contract Payment Type" := VATReportLine."Contract Payment Type"::"Without Contract";
        VATReportLine."VAT Entry No." := VATEntry."Entry No.";

        VATReportLine."VAT Bus. Posting Group" := VATEntry."VAT Bus. Posting Group";
        VATReportLine."VAT Prod. Posting Group" := VATEntry."VAT Prod. Posting Group";
        VATReportLine."VAT Group Identifier" := VATEntry."VAT Identifier";

        VATReportLine."VAT Transaction Nature" := GetVATTransactionNature(VATEntry);
        VATReportLine."Incl. in Report" := true;
        VATReportLine."Fattura Document Type" := VATEntry."Fattura Document Type";
        VATReportLine.Insert();
    end;

    local procedure IsForeignInvoiceLinkedWithCustoms(VATEntry: Record "VAT Entry"): Boolean
    var
        CustomsVATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VATEntry.Type <> VATEntry.Type::Purchase then
            exit(false);
        VendorLedgerEntry.SetCurrentKey("Document Type", "Document No.", "Document Occurrence", "Vendor No.");
        VendorLedgerEntry.SetRange("Document Type", VATEntry."Document Type");
        VendorLedgerEntry.SetRange("Document No.", VATEntry."Document No.");
        VendorLedgerEntry.SetRange("Vendor No.", VATEntry."Bill-to/Pay-to No.");
        VendorLedgerEntry.FindFirst(); // foreign Vendor Ledger Entry
        CustomsVATEntry.SetRange("Related Entry No.", VendorLedgerEntry."Entry No.");
        exit(not CustomsVATEntry.IsEmpty);
    end;
}

