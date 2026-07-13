// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.WithholdingTax;

codeunit 7056 "WHT Expense Category Mgt."
{
    var
        NoPostingSetupErr: Label 'Withholding Tax Posting Setup does not exist for Business Posting Group %1, Product Posting Group %2.', Comment = '%1 = Bus. Post. Group, %2 = Prod. Post. Group';

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterValidateEvent, 'Expense Category', false, false)]
    local procedure OnAfterExpenseCategoryValidateEmployee(var Rec: Record "Gen. Journal Line")
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if ExpenseCategory.Get(Rec."Expense Category") then
            Rec."Wthldg. Tax Prod. Post. Group" := ExpenseCategory."Wthldg. Tax Prod. Post. Group"
        else
            Rec."Wthldg. Tax Prod. Post. Group" := '';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeCheckCalcEmployeeWHT, '', false, false)]
    local procedure OnBeforeCheckCalcEmployeeWHT(GenJnlLine: Record "Gen. Journal Line")
    var
        WithholdingTaxPostingSetup: Record "Withholding Tax Posting Setup";
    begin
        if not WithholdingTaxPostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") and IsExpenseCategorySingleTax(GenJnlLine) then
            Error(NoPostingSetupErr, GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeInsertThresholdAccumulator, '', false, false)]
    local procedure OnBeforeInsertThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; PostingSetup: Record "Withholding Tax Posting Setup")
    begin
        ThresholdAccumulator."Expense Category Code" := PostingSetup."Threshold Category Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeReverseThresholdAccumulator, '', false, false)]
    local procedure OnBeforeReverseThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; PostingSetup: Record "Withholding Tax Posting Setup")
    begin
        ThresholdAccumulator."Expense Category Code" := PostingSetup."Threshold Category Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeUpdateThresholdAccumulator, '', false, false)]
    local procedure OnBeforeUpdateThresholdAccumulator(var ThresholdAccumulator: Record "WHT Threshold Accumulator"; PostingSetup: Record "Withholding Tax Posting Setup")
    begin
        ThresholdAccumulator."Expense Category Code" := PostingSetup."Threshold Category Code";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WHT Employee Calculation", OnBeforeResolveWHTGroupComponents, '', false, false)]
    local procedure OnBeforeResolveWHTGroupComponents(GenJnlLine: Record "Gen. Journal Line"; var WHTGroupCode: Code[20]; var Result: Boolean)
    var
        WHTGroup: Record "Withholding Tax Group";
        ExpenseCategory: Record "Expense Category";
    begin
        if ExpenseCategory.Get(GenJnlLine."Expense Category") then
            if WHTGroup.Get(ExpenseCategory."Withholding Group Code") then begin
                WHTGroupCode := WHTGroup.Code;
                Result := true;
            end else
                Result := false;
    end;

    local procedure IsExpenseCategorySingleTax(GenJnlline: Record "Gen. Journal Line"): Boolean
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if GenJnlline."Expense Category" = '' then
            exit(true);

        if ExpenseCategory.Get(GenJnlline."Expense Category") then
            if (ExpenseCategory."Withholding Selection Mode" = ExpenseCategory."Withholding Selection Mode"::"Tax Group") and (ExpenseCategory."Withholding Group Code" <> '') then
                exit(false);

        exit(true);
    end;

    local procedure CheckWithholdingTaxDisabled(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Enable Withholding Tax" then
            exit(true);

        exit(false);
    end;
}
