// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Automated line generation process for VAT reports based on posted VAT entries.
/// Analyzes VAT ledger entries within specified periods and creates corresponding VAT report lines.
/// </summary>
report 741 "VAT Report Suggest Lines"
{
    Caption = 'VAT Report Suggest Lines';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(VATReportHeader; "VAT Report Header")
        {

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
        dataitem(FEInvoicesIssued; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = filter(Resident), Type = filter(Sale), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(FEInvoicesIssued, FEInvoicesIssuedTxt, "Document Type"::Invoice);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
        dataitem(FRInvoicesReceived; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = filter(Resident), Type = filter(Purchase), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(FRInvoicesReceived, FRInvoicesReceivedTxt, "Document Type"::Invoice);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
        dataitem(NECreditMemosIssued; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = const(Resident), Type = filter(Sale), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(NECreditMemosIssued, NECreditMemosIssuedTxt, "Document Type"::"Credit Memo");
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
        dataitem(NRCreditMemosReceived; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = const(Resident), Type = filter(Purchase), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(NRCreditMemosReceived, NRCreditMemosReceivedTxt, "Document Type"::"Credit Memo");
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
        dataitem(FNNonResidentsSales; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = const("Non-Resident"), Type = filter(Sale), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(FNNonResidentsSales, FNNonResidentsSalesTxt, "Document Type"::Invoice);
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Posting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
            end;
        }
        dataitem(SENonResidentsPurchases; "VAT Entry")
        {
            DataItemTableView = sorting("Posting Date", Type, "Document Type", "Document No.") order(ascending) where("Include in VAT Transac. Rep." = const(true), Resident = const("Non-Resident"), Type = filter(Purchase), "Unrealized VAT Entry No." = const(0));

            trigger OnAfterGetRecord()
            begin
                ProcessTransaction(SENonResidentsPurchases, SENonResidentsPurchasesTxt, "Document Type"::Invoice);
            end;

            trigger OnPreDataItem()
            begin
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

    trigger OnPostReport()
    begin
        ApplyThresholdOnInvoiceLines(VATReportHeader."No.");
    end;

    var
        DeleteReportLinesQst: Label 'All existing report lines will be deleted. Do you want to continue?';
        TotalBase: Decimal;
        TotalAmount: Decimal;
        FEInvoicesIssuedTxt: Label 'FE', Locked = true;
        FRInvoicesReceivedTxt: Label 'FR', Locked = true;
        NECreditMemosIssuedTxt: Label 'NE', Locked = true;
        NRCreditMemosReceivedTxt: Label 'NR', Locked = true;
        FNNonResidentsSalesTxt: Label 'FN', Locked = true;
        SENonResidentsPurchasesTxt: Label 'SE', Locked = true;

    local procedure CreateVATReportLine(VATEntry: Record "VAT Entry"; RecordIdentifier: Code[30])
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeader."No.";
        VATReportLine."Posting Date" := VATEntry."Posting Date";
        VATReportLine."Document No." := VATEntry."Document No.";
        VATReportLine."Line No." := GetNextLineNo();
        VATReportLine."Document Type" := VATEntry."Document Type";
        VATReportLine.Type := VATEntry.Type;
        VATReportLine.Base := TotalBase;
        UpdateVatReportLineAmount(VATReportLine, VATEntry."Document No.");
        VATReportLine.Amount := TotalAmount;
        VATReportLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
        VATReportLine."Source Code" := VATEntry."Source Code";
        VATReportLine."Reason Code" := VATEntry."Reason Code";
        VATReportLine."Country/Region Code" := VATEntry."Country/Region Code";
        VATReportLine."Internal Ref. No." := VATEntry."Internal Ref. No.";
        VATReportLine."External Document No." := VATEntry."External Document No.";
        VATReportLine."VAT Registration No." := VATEntry."VAT Registration No.";
        VATReportLine."Record Identifier" := RecordIdentifier;
        VATReportLine."Operation Occurred Date" := VATEntry."Operation Occurred Date";
        if VATEntry."Contract No." <> '' then
            VATReportLine."Contract Payment Type" := VATReportLine."Contract Payment Type"::Contract
        else
            VATReportLine."Contract Payment Type" := VATReportLine."Contract Payment Type"::"Without Contract";
        VATReportLine."Amount Incl. VAT" := VATReportLine.Base + VATReportLine.Amount;
        VATReportLine."VAT Entry No." := VATEntry."Entry No.";

        VATReportLine."VAT Group Identifier" := VATEntry."VAT Registration No.";
        if VATReportLine."VAT Group Identifier" = '' then
            VATReportLine."VAT Group Identifier" := VATEntry."Fiscal Code";

        VATReportLine."Incl. in Report" := true;
        VATReportLine.Insert();
    end;

    local procedure CheckNewGroup(var VATEntry: Record "VAT Entry"): Boolean
    var
        VATEntryLoc: Record "VAT Entry";
    begin
        VATEntryLoc.Copy(VATEntry);
        if VATEntryLoc.Next() = 0 then
            exit(true);
        exit((VATEntryLoc."Posting Date" <> VATEntry."Posting Date") or
          (VATEntryLoc.Type <> VATEntry.Type) or
          (VATEntryLoc."Document Type" <> VATEntry."Document Type") or
          (VATEntryLoc."Document No." <> VATEntry."Document No."));
    end;

    local procedure UpdateTotals(VATEntry: Record "VAT Entry")
    begin
        TotalBase += TotalVATEntryBase(VATEntry);
        TotalAmount += TotalVATEntryAmount(VATEntry);
    end;

    local procedure ClearGlobals()
    begin
        Clear(TotalBase);
        Clear(TotalAmount);
    end;

    local procedure ProcessTransaction(var VATEntry: Record "VAT Entry"; RecordIdentifier: Code[10]; GroupType: Enum "Gen. Journal Document Type")
    begin
        UpdateTotals(VATEntry);
        if CheckNewGroup(VATEntry) then begin
            if DetermineGroupType(VATEntry) = GroupType then
                CreateVATReportLine(VATEntry, RecordIdentifier);
            ClearGlobals();
        end;
    end;

    local procedure GetNextLineNo(): Integer
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.FindLast() then;
        exit(VATReportLine."Line No." + 1);
    end;

    local procedure ApplyThresholdOnInvoiceLines(VatReportHeaderNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
        VATTransactionReportAmount: Record "VAT Transaction Report Amount";
    begin
        VATReportLine.SetRange("VAT Report No.", VatReportHeaderNo);
        VATReportLine.SetFilter(
          "Record Identifier", '%1|%2|%3|%4|%5|%6', FEInvoicesIssuedTxt, FRInvoicesReceivedTxt, NECreditMemosIssuedTxt,
          NRCreditMemosReceivedTxt, FNNonResidentsSalesTxt, SENonResidentsPurchasesTxt);

        if VATReportLine.FindSet() then
            repeat
                if not VATTransactionReportAmount.IncludeInVATTransacRep(
                     VATReportLine."Posting Date", true, Abs(VATReportLine."Amount Incl. VAT"))
                then
                    VATReportLine.Delete();
            until VATReportLine.Next() = 0;
    end;

    local procedure IsInvoice(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              ((VATEntry.Type = VATEntry.Type::Sale) and (TotalBase < 0)) or
              ((VATEntry.Type = VATEntry.Type::Purchase) and (TotalBase > 0)) or
              (VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT"));
    end;

    local procedure IsCreditMemo(VATEntry: Record "VAT Entry"): Boolean
    begin
        exit(
              ((VATEntry.Type = VATEntry.Type::Sale) and (TotalBase > 0)) or
              ((VATEntry.Type = VATEntry.Type::Purchase) and (TotalBase < 0)) or
              (VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Full VAT"));
    end;

    local procedure DetermineGroupType(var VATEntry: Record "VAT Entry"): Enum "Gen. Journal Document Type"
    begin
        if IsInvoice(VATEntry) then
            exit(VATEntry."Document Type"::Invoice);
        if IsCreditMemo(VATEntry) then
            exit(VATEntry."Document Type"::"Credit Memo");
    end;

    local procedure TotalVATEntryBase(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Base + VATEntry."Nondeductible Base" + VATEntry."Unrealized Base");
    end;

    local procedure TotalVATEntryAmount(VATEntry: Record "VAT Entry"): Decimal
    begin
        exit(VATEntry.Amount + VATEntry."Nondeductible Amount" + VATEntry."Unrealized Amount");
    end;

    local procedure UpdateVatReportLineAmount(var VATReportLine: Record "VAT Report Line"; DocumentNo: Code[20])
    var
        TempVATEntry: Record "VAT Entry";
    begin
        TempVATEntry.SetRange("Document No.", DocumentNo);
        TempVATEntry.SetFilter("Deductible %", '<100');
        if TempVATEntry.FindFirst() then
            VATReportLine.Amount := 0
        else
            VATReportLine.Amount := TotalAmount;
    end;
}

