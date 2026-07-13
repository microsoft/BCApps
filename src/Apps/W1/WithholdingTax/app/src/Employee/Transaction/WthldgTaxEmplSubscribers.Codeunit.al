// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;

codeunit 6791 "Wthldg Tax Empl. Subscribers"
{
    var
        GeneralLedgerSetup: Record "General Ledger Setup";


    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnAfterAccountNoOnValidateGetEmployeeAccount, '', false, false)]
    local procedure OnAfterAccountNoValidateEmployee(var GenJournalLine: Record "Gen. Journal Line"; var Employee: Record Employee)
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if Employee."Withholding Tax Exempt" then
            exit;

        GenJournalLine."Wthldg. Tax Bus. Post. Group" := Employee."Wthldg. Tax Bus. Post. Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnPostEmployeeOnAfterInitEmployeeLedgerEntry, '', false, false)]
    local procedure OnPostEmployeeOnAfterInitEmployeeLedgerEntry(var GenJnlLine: Record "Gen. Journal Line"; var EmployeeLedgerEntry: Record "Employee Ledger Entry"; var TaxAmount: Decimal; var TaxBaseAmount: Decimal)
    var
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if not WHTEmployeeCalc.IsEmployeeWHTApplicable(GenJnlLine) then
            exit;

        WHTEmployeeCalc.CalcEmployeeWHT(GenJnlLine, TaxAmount, TaxBaseAmount);

        EmployeeLedgerEntry."WHT Amount" := -TaxAmount;
        EmployeeLedgerEntry."WHT Base Amount" := TaxBaseAmount;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterPostEmployee, '', false, false)]
    local procedure OnAfterPostEmployee(GenJnlLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry"; TaxAmount: Decimal; TaxBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if not WHTEmployeeCalc.IsEmployeeWHTApplicable(GenJnlLine) then
            exit;

        PostEmployeeWithholdingTax(GenJnlLine, TaxAmount, TaxBaseAmount, NextTransactionNo, NextTaxEntryNo, sender);

        if (TaxAmount = 0) and (TaxBaseAmount <> 0) then
            WHTEmployeeCalc.AccumulateBaseForPeriodThreshold(GenJnlLine, TaxBaseAmount);
    end;

    local procedure PostEmployeeWithholdingTax(GenJnlLine: Record "Gen. Journal Line"; TaxAmount: Decimal; TaxBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GLEntry: Record "G/L Entry";
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
        WHTGroupCode: Code[20];
    begin
        if WHTEmployeeCalc.ResolveWHTGroupComponents(GenJnlLine, WHTGroupCode) then begin
            PostEmployeeWHTGroupEntries(GenJnlLine, WHTGroupCode, TaxBaseAmount, NextTransactionNo, NextTaxEntryNo, sender);
            exit;
        end;

        if not WHTPostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then
            exit;

        if TaxAmount <> 0 then begin
            WHTPostingSetup.TestField("Payable Wthldg. Tax Acc. Code");
            sender.InitGLEntry(
                GenJnlLine, GLEntry,
                WHTPostingSetup."Payable Wthldg. Tax Acc. Code",
                TaxAmount, 0, false, true, 0);
            sender.InsertGLEntry(GenJnlLine, GLEntry, true);
        end;

        WHTEmployeeCalc.InsertEmployeeWithholdingTaxEntry(
            GenJnlLine, TaxAmount, TaxBaseAmount, NextTransactionNo, NextTaxEntryNo);
    end;

    local procedure PostEmployeeWHTGroupEntries(GenJnlLine: Record "Gen. Journal Line"; WHTGroupCode: Code[20]; WHTBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTGroupLine: Record "Withholding Tax Group Line";
        ComponentSetup: Record "Withholding Tax Posting Setup";
        ParentSetup: Record "Withholding Tax Posting Setup";
        GLEntry: Record "G/L Entry";
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
        CompoundBase: Decimal;
        ComponentWHT: Decimal;
    begin
        CompoundBase := WHTBaseAmount;

        WHTGroupLine.SetCurrentKey("Group Code", "Component Order");
        WHTGroupLine.SetRange("Group Code", WHTGroupCode);
        if WHTGroupLine.FindSet() then
            repeat
                ParentSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group");
                ComponentWHT := Round(WHTEmployeeCalc.CalcComponentWHT(WHTGroupLine, CompoundBase, GenJnlLine));
                if ComponentWHT <> 0 then begin
                    if (WHTGroupLine."Wthldg. Tax Prod. Post. Group" <> '') and
                       ComponentSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", WHTGroupLine."Wthldg. Tax Prod. Post. Group")
                    then begin
                        sender.InitGLEntry(
                            GenJnlLine, GLEntry,
                            ComponentSetup."Payable Wthldg. Tax Acc. Code",
                            ComponentWHT, 0, false, true, 0);
                        sender.InsertGLEntry(GenJnlLine, GLEntry, true);
                    end;

                    WHTEmployeeCalc.InsertEmployeeWHTComponentEntry(
                        GenJnlLine, WHTGroupLine, ComponentWHT, WHTBaseAmount, NextTransactionNo, NextTaxEntryNo);
                end;

                if ParentSetup."Calculation Method" = ParentSetup."Calculation Method"::Compound then
                    CompoundBase := CompoundBase + ComponentWHT;
            until WHTGroupLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeInitGLEntryForGLAcc, '', false, false)]
    local procedure OnBeforeInitGLEntryForGLAcc(GenJnlLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var TaxAmount: Decimal; var TaxAmountLCY: Decimal; var IsHandled: Boolean; var sender: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if not WHTEmployeeCalc.IsEmployeeWHTApplicable(GenJnlLine) then
            exit;

        if WHTEmployeeCalc.IsNetCalculationBase(GenJnlLine) then
            exit;

        WHTEmployeeCalc.IsThresholdIncludeded(true);
        WHTEmployeeCalc.CalcEmployeeWHT(GenJnlLine, TaxAmount, TaxAmountLCY);
        WHTEmployeeCalc.IsThresholdIncludeded(false);

        if (GenJnlLine.Amount > 0) then begin
            TaxAmount := -TaxAmount;
            TaxAmountLCY := -TaxAmountLCY;
        end;

        sender.InitGLEntry(
                GenJnlLine, GLEntry, GenJnlLine."Account No.", GenJnlLine."Amount (LCY)" + TaxAmount,
                GenJnlLine."Source Currency Amount" + TaxAmount, true, GenJnlLine."System-Created Entry",
                CalcSourceCurrVATBaseAmount(GenJnlLine, TaxAmount, sender));
        IsHandled := true;
    end;


    local procedure CalcSourceCurrVATBaseAmount(var GenJnlLine: Record "Gen. Journal Line"; WithholdingAmountLCY: Decimal; var sender: Codeunit "Gen. Jnl.-Post Line"): Decimal
    var
        SourceCurrVATBaseAmount: Decimal;
    begin
        if (GenJnlLine."Source Currency Code" <> '') and ((not GenJnlLine."System-Created Entry") or GenJnlLine."Financial Void") then begin
            if GenJnlLine."Source Curr. VAT Base Amount" <> 0 then
                SourceCurrVATBaseAmount := GenJnlLine."Source Curr. VAT Base Amount" + sender.CalcAmountSourceCurrency(GenJnlLine, WithholdingAmountLCY)
            else
                SourceCurrVATBaseAmount := GenJnlLine."Source Currency Amount" + sender.CalcAmountSourceCurrency(GenJnlLine, WithholdingAmountLCY);
        end else
            SourceCurrVATBaseAmount := sender.CalcAmountSourceCurrency(GenJnlLine, GenJnlLine."VAT Base Amount (LCY)" + WithholdingAmountLCY);

        exit(SourceCurrVATBaseAmount);
    end;

    local procedure CheckWithholdingTaxDisabled(): Boolean
    begin
        GeneralLedgerSetup.Get();
        if not GeneralLedgerSetup."Enable Withholding Tax" then
            exit(true);

        exit(false);
    end;
}
