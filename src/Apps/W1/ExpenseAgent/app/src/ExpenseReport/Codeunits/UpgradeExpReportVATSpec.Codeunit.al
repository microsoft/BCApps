// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Upgrade;

codeunit 7105 "Upgrade Exp. Report VAT Spec"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Currency = r,
                  tabledata "Currency Exchange Rate" = r,
                  tabledata "Expense Report Header" = r,
                  tabledata "Expense Report Line" = r,
                  tabledata "Expense Report Line VAT Spec." = rm,
                  tabledata "General Ledger Setup" = r,
                  tabledata "Posted Expense Report Header" = r,
                  tabledata "Posted Exp. Rep. Line VAT Spec" = rm;

    var
        BackfillCompletedTelemetryMsg: Label 'Expense VAT specification reimbursement amount backfill completed.', Locked = true;

    trigger OnUpgradePerCompany()
    begin
        BackfillReimbursementAmounts();
    end;

    local procedure BackfillExpenseReportLineVATSpecCurrencyMetadata()
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        CachedDocumentNo: Code[20];
        CachedDocumentLineNo: Integer;
        HasCachedDocumentLine: Boolean;
        ParentLineFound: Boolean;
    begin
        ExpenseReportLine.SetLoadFields("Expense Currency Code", "Expense Currency Factor");
        ExpenseReportLineVATSpec.SetCurrentKey("Document No.", "Document Line No.", "Line No.");
        ExpenseReportLineVATSpec.SetLoadFields("Document No.", "Document Line No.", "Currency Code", "Currency Factor");
        CachedDocumentNo := '';
        CachedDocumentLineNo := 0;
        if ExpenseReportLineVATSpec.FindSet(true) then
            repeat
                if (not HasCachedDocumentLine) or
                   (CachedDocumentNo <> ExpenseReportLineVATSpec."Document No.") or
                   (CachedDocumentLineNo <> ExpenseReportLineVATSpec."Document Line No.")
                then begin
                    CachedDocumentNo := ExpenseReportLineVATSpec."Document No.";
                    CachedDocumentLineNo := ExpenseReportLineVATSpec."Document Line No.";
                    HasCachedDocumentLine := true;
                    ParentLineFound := ExpenseReportLine.Get(CachedDocumentNo, CachedDocumentLineNo);
                end;

                if ParentLineFound then
                    if (ExpenseReportLineVATSpec."Currency Code" <> ExpenseReportLine."Expense Currency Code") or
                       (ExpenseReportLineVATSpec."Currency Factor" <> ExpenseReportLine."Expense Currency Factor")
                    then begin
                        ExpenseReportLineVATSpec."Currency Code" := ExpenseReportLine."Expense Currency Code";
                        ExpenseReportLineVATSpec."Currency Factor" := ExpenseReportLine."Expense Currency Factor";
                        ExpenseReportLineVATSpec.Modify(false);
                    end;
            until ExpenseReportLineVATSpec.Next() = 0;
    end;

    local procedure BackfillReimbursementAmounts()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetBackfillReimbursementAmountsUpgradeTag()) then
            exit;

        BackfillExpenseReportLineVATSpecCurrencyMetadata();
        CopyReimbursementAmountsFromLCY();
        BackfillExpenseReportLineVATSpecs();
        BackfillPostedExpenseReportLineVATSpecs();

        LogBackfillCompleted();
        SetBackfillReimbursementAmountsUpgradeTag();
    end;

    local procedure LogBackfillCompleted()
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('Category', ExpenseAuditSubscribers.TelemetryCategory());
        TelemetryDimensions.Add('ExpenseReportVATSpecificationCount', Format(ExpenseReportLineVATSpec.Count()));
        TelemetryDimensions.Add('PostedExpenseReportVATSpecificationCount', Format(PostedExpenseReportLineVATSpec.Count()));
        Session.LogMessage(
            '0000V16', BackfillCompletedTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
            TelemetryDimensions);
    end;

    internal procedure SetBackfillReimbursementAmountsUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetBackfillReimbursementAmountsUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(GetBackfillReimbursementAmountsUpgradeTag());
    end;

    local procedure CopyReimbursementAmountsFromLCY()
    var
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        ExpenseReportLineVATSpecDataTransfer: DataTransfer;
        PostedExpenseReportLineVATSpecDataTransfer: DataTransfer;
    begin
        ExpenseReportLineVATSpecDataTransfer.SetTables(Database::"Expense Report Line VAT Spec.", Database::"Expense Report Line VAT Spec.");
        ExpenseReportLineVATSpecDataTransfer.AddFieldValue(ExpenseReportLineVATSpec.FieldNo("VAT Base Amount (LCY)"), ExpenseReportLineVATSpec.FieldNo("VAT Base Amount (RCY)"));
        ExpenseReportLineVATSpecDataTransfer.AddFieldValue(ExpenseReportLineVATSpec.FieldNo("VAT Amount (LCY)"), ExpenseReportLineVATSpec.FieldNo("VAT Amount (RCY)"));
        ExpenseReportLineVATSpecDataTransfer.AddFieldValue(ExpenseReportLineVATSpec.FieldNo("Amount (LCY)"), ExpenseReportLineVATSpec.FieldNo("Amount (RCY)"));
        ExpenseReportLineVATSpecDataTransfer.CopyFields();

        PostedExpenseReportLineVATSpecDataTransfer.SetTables(Database::"Posted Exp. Rep. Line VAT Spec", Database::"Posted Exp. Rep. Line VAT Spec");
        PostedExpenseReportLineVATSpecDataTransfer.AddFieldValue(PostedExpenseReportLineVATSpec.FieldNo("VAT Base Amount (LCY)"), PostedExpenseReportLineVATSpec.FieldNo("VAT Base Amount (RCY)"));
        PostedExpenseReportLineVATSpecDataTransfer.AddFieldValue(PostedExpenseReportLineVATSpec.FieldNo("VAT Amount (LCY)"), PostedExpenseReportLineVATSpec.FieldNo("VAT Amount (RCY)"));
        PostedExpenseReportLineVATSpecDataTransfer.AddFieldValue(PostedExpenseReportLineVATSpec.FieldNo("Amount (LCY)"), PostedExpenseReportLineVATSpec.FieldNo("Amount (RCY)"));
        PostedExpenseReportLineVATSpecDataTransfer.CopyFields();
    end;

    local procedure BackfillExpenseReportLineVATSpecs()
    var
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.";
        CachedDocumentNo: Code[20];
        HasCachedDocumentNo: Boolean;
        HeaderFound: Boolean;
    begin
        ExpenseReportLineVATSpec.SetCurrentKey("Document No.", "Document Line No.", "Line No.");
        ExpenseReportLineVATSpec.SetLoadFields(
            "Document No.", "Currency Code", "VAT Base Amount (LCY)", "VAT Amount", "VAT Amount (LCY)", "Reclaim %",
            "VAT Base Amount (RCY)", "VAT Amount (RCY)", "Amount (RCY)", "Reclaim VAT Amount",
            "Reclaim VAT Amount (LCY)", "Reclaim VAT Amount (RCY)");
        if not ExpenseReportLineVATSpec.FindSet(true) then
            exit;

        CachedDocumentNo := '';
        repeat
            if (not HasCachedDocumentNo) or (CachedDocumentNo <> ExpenseReportLineVATSpec."Document No.") then begin
                CachedDocumentNo := ExpenseReportLineVATSpec."Document No.";
                HasCachedDocumentNo := true;
                ExpenseReportHeader.SetLoadFields("Reimbursement Currency Code", "Posting Date", "Reimbursement Currency Factor");
                HeaderFound := ExpenseReportHeader.Get(CachedDocumentNo);
            end;

            if HeaderFound then
                if ExpenseReportHeader."Reimbursement Currency Code" <> '' then begin
                    ExpenseReportLineVATSpec.UpdateReimbursementAmounts(ExpenseReportHeader);
                    ExpenseReportLineVATSpec.Modify(false);
                end else
                    if ExpenseReportLineVATSpec."Reclaim %" <> 0 then begin
                        UpdateExpenseReportLineReclaimAmount(ExpenseReportLineVATSpec);
                        ExpenseReportLineVATSpec.Modify(false);
                    end;
        until ExpenseReportLineVATSpec.Next() = 0;
    end;

    local procedure UpdateExpenseReportLineReclaimAmount(var ExpenseReportLineVATSpec: Record "Expense Report Line VAT Spec.")
    var
        ReimbursementCurrency: Record Currency;
    begin
        ReimbursementCurrency.Initialize('');
        ExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)" :=
            Round(
                ExpenseReportLineVATSpec."VAT Amount (RCY)" * ExpenseReportLineVATSpec."Reclaim %" / 100,
                ReimbursementCurrency."Amount Rounding Precision");
    end;

    local procedure BackfillPostedExpenseReportLineVATSpecs()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
        PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec";
        CachedExpenseReportNo: Code[20];
        HasCachedExpenseReportNo: Boolean;
        HeaderFound: Boolean;
    begin
        PostedExpenseReportLineVATSpec.SetCurrentKey("Expense Report No.", "Expense Report Line No.", "Line No.");
        PostedExpenseReportLineVATSpec.SetLoadFields(
            "Expense Report No.", "VAT Base Amount (LCY)", "VAT Amount (LCY)", "Reclaim %",
            "VAT Base Amount (RCY)", "VAT Amount (RCY)", "Amount (RCY)", "Reclaim VAT Amount (RCY)");
        if not PostedExpenseReportLineVATSpec.FindSet(true) then
            exit;

        CachedExpenseReportNo := '';
        repeat
            if (not HasCachedExpenseReportNo) or (CachedExpenseReportNo <> PostedExpenseReportLineVATSpec."Expense Report No.") then begin
                CachedExpenseReportNo := PostedExpenseReportLineVATSpec."Expense Report No.";
                HasCachedExpenseReportNo := true;
                PostedExpenseReportHeader.SetLoadFields("Reimbursement Currency Code", "Posting Date", "Reimbursement Currency Factor");
                HeaderFound := PostedExpenseReportHeader.Get(CachedExpenseReportNo);
            end;

            if HeaderFound then
                if PostedExpenseReportHeader."Reimbursement Currency Code" <> '' then begin
                    UpdatePostedReimbursementAmounts(PostedExpenseReportLineVATSpec, PostedExpenseReportHeader);
                    PostedExpenseReportLineVATSpec.Modify(false);
                end else
                    if PostedExpenseReportLineVATSpec."Reclaim %" <> 0 then begin
                        UpdatePostedReclaimAmount(PostedExpenseReportLineVATSpec);
                        PostedExpenseReportLineVATSpec.Modify(false);
                    end;
        until PostedExpenseReportLineVATSpec.Next() = 0;
    end;

    local procedure UpdatePostedReclaimAmount(var PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec")
    var
        ReimbursementCurrency: Record Currency;
    begin
        ReimbursementCurrency.Initialize('');
        PostedExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)" :=
            Round(
                PostedExpenseReportLineVATSpec."VAT Amount (RCY)" * PostedExpenseReportLineVATSpec."Reclaim %" / 100,
                ReimbursementCurrency."Amount Rounding Precision");
    end;

    local procedure UpdatePostedReimbursementAmounts(var PostedExpenseReportLineVATSpec: Record "Posted Exp. Rep. Line VAT Spec"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ReimbursementCurrency: Record Currency;
    begin
        ReimbursementCurrency.Initialize(PostedExpenseReportHeader."Reimbursement Currency Code");

        PostedExpenseReportLineVATSpec."VAT Base Amount (RCY)" :=
            Round(
                CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    PostedExpenseReportHeader."Posting Date", PostedExpenseReportHeader."Reimbursement Currency Code",
                    PostedExpenseReportLineVATSpec."VAT Base Amount (LCY)", PostedExpenseReportHeader."Reimbursement Currency Factor"),
                ReimbursementCurrency."Amount Rounding Precision");
        PostedExpenseReportLineVATSpec."VAT Amount (RCY)" :=
            Round(
                CurrencyExchangeRate.ExchangeAmtLCYToFCY(
                    PostedExpenseReportHeader."Posting Date", PostedExpenseReportHeader."Reimbursement Currency Code",
                    PostedExpenseReportLineVATSpec."VAT Amount (LCY)", PostedExpenseReportHeader."Reimbursement Currency Factor"),
                ReimbursementCurrency."Amount Rounding Precision");
        PostedExpenseReportLineVATSpec."Amount (RCY)" :=
            PostedExpenseReportLineVATSpec."VAT Base Amount (RCY)" + PostedExpenseReportLineVATSpec."VAT Amount (RCY)";

        PostedExpenseReportLineVATSpec."Reclaim VAT Amount (RCY)" :=
            Round(
                PostedExpenseReportLineVATSpec."VAT Amount (RCY)" * PostedExpenseReportLineVATSpec."Reclaim %" / 100,
                ReimbursementCurrency."Amount Rounding Precision");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetBackfillReimbursementAmountsUpgradeTag());
    end;

    local procedure GetBackfillReimbursementAmountsUpgradeTag(): Code[250]
    begin
        exit('MS-ExpenseAgent-BackfillVATSpecReimbursementAmounts-20260818');
    end;
}
