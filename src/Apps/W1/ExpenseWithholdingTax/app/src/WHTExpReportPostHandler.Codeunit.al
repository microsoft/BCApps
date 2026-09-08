// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.WithholdingTax;
using Microsoft.WithholdingTax.Employee;

codeunit 7057 "WHT Exp. Report Post Handler"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnAfterProcessExpenseReportLine', '', false, false)]
    local procedure OnAfterProcessExpenseReportLine(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; PostedExpenseReportLine: Record "Posted Expense Report Line"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        AccumulateLineWHT(ExpenseReportHeader, ExpenseReportLine, PostedExpenseReportHeader."No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnBeforePostEmployeeEntry', '', false, false)]
    local procedure OnBeforePostEmployeeEntry(var GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
        TotalWHTAmountLCY: Decimal;
        FCYReduction: Decimal;
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        WHTExpReportBuffer.SetRange("Document No.", PostedExpenseReportHeader."No.");
        WHTExpReportBuffer.CalcSums("WHT Amount (LCY)");
        TotalWHTAmountLCY := WHTExpReportBuffer."WHT Amount (LCY)";

        if TotalWHTAmountLCY = 0 then
            exit;

        if GenJournalLine."Amount (LCY)" <> 0 then
            FCYReduction := Round(TotalWHTAmountLCY * (GenJournalLine.Amount / GenJournalLine."Amount (LCY)"))
        else
            FCYReduction := TotalWHTAmountLCY;

        GenJournalLine.Amount += FCYReduction;
        GenJournalLine."Amount (LCY)" += TotalWHTAmountLCY;
        GenJournalLine."Source Currency Amount" := GenJournalLine.Amount;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Expense Report-Post", 'OnAfterPostEmployeeEntry', '', false, false)]
    local procedure OnAfterPostEmployeeEntry(GenJournalLine: Record "Gen. Journal Line"; ExpenseReportHeader: Record "Expense Report Header"; PostedExpenseReportHeader: Record "Posted Expense Report Header")
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
    begin
        WHTExpReportBuffer.SetRange("Document No.", PostedExpenseReportHeader."No.");
        WHTExpReportBuffer.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterPostEmployee', '', false, false)]
    local procedure OnAfterPostEmployeeApplyExpenseWHT(GenJnlLine: Record "Gen. Journal Line"; EmployeeLedgerEntry: Record "Employee Ledger Entry"; TaxAmount: Decimal; TaxBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; sender: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
    begin
        if CheckWithholdingTaxDisabled() then
            exit;

        if GenJnlLine."Document No." = '' then
            exit;

        WHTExpReportBuffer.SetRange("Document No.", GenJnlLine."Document No.");
        if WHTExpReportBuffer.IsEmpty() then
            exit;

        PostBufferedWHT(GenJnlLine, NextTransactionNo, NextTaxEntryNo, sender);
    end;

    local procedure AccumulateLineWHT(ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; DocumentNo: Code[20])
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
        ExpenseCategory: Record "Expense Category";
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
        WHTAmount: Decimal;
        WHTBaseAmount: Decimal;
    begin
        if ExpenseReportLine."Reimbursable Amount (LCY)" = 0 then
            exit;

        if not ExpenseCategory.Get(ExpenseReportLine."Expense Category") then
            exit;

        if (ExpenseCategory."Wthldg. Tax Prod. Post. Group" = '') and (ExpenseCategory."Withholding Group Code" = '') then
            exit;

        if not ExpenseUser.Get(ExpenseReportHeader."Expense User No.") then
            exit;

        if not Employee.Get(ExpenseUser."Employee No.") then
            exit;

        if Employee."Withholding Tax Exempt" then
            exit;

        if Employee."Wthldg. Tax Bus. Post. Group" = '' then
            exit;

        BuildTempEmployeeLine(TempGenJnlLine, ExpenseReportHeader, ExpenseReportLine, Employee, ExpenseCategory, DocumentNo);

        if not WHTEmployeeCalc.IsEmployeeWHTApplicable(TempGenJnlLine) then
            exit;

        WHTEmployeeCalc.CalcEmployeeWHT(TempGenJnlLine, WHTAmount, WHTBaseAmount);
        if WHTBaseAmount = 0 then
            exit;

        WHTExpReportBuffer.Init();
        WHTExpReportBuffer."Document No." := DocumentNo;
        WHTExpReportBuffer."Line No." := NextBufferLineNo(DocumentNo);
        WHTExpReportBuffer."Wthldg. Tax Bus. Post. Group" := TempGenJnlLine."Wthldg. Tax Bus. Post. Group";
        WHTExpReportBuffer."Wthldg. Tax Prod. Post. Group" := TempGenJnlLine."Wthldg. Tax Prod. Post. Group";
        WHTExpReportBuffer."Expense Category" := ExpenseReportLine."Expense Category";
        WHTExpReportBuffer."WHT Base Amount (LCY)" := WHTBaseAmount;
        WHTExpReportBuffer."WHT Amount (LCY)" := WHTAmount;
        WHTExpReportBuffer.Insert();
    end;

    local procedure NextBufferLineNo(DocumentNo: Code[20]): Integer
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
    begin
        WHTExpReportBuffer.SetRange("Document No.", DocumentNo);
        if WHTExpReportBuffer.FindLast() then
            exit(WHTExpReportBuffer."Line No." + 10000);
        exit(10000);
    end;

    local procedure BuildTempEmployeeLine(var TempGenJnlLine: Record "Gen. Journal Line" temporary; ExpenseReportHeader: Record "Expense Report Header"; ExpenseReportLine: Record "Expense Report Line"; Employee: Record Employee; ExpenseCategory: Record "Expense Category"; DocumentNo: Code[20])
    begin
        TempGenJnlLine.Init();
        TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Employee;
        TempGenJnlLine."Account No." := Employee."No.";
        TempGenJnlLine."Posting Date" := ExpenseReportHeader."Posting Date";
        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Invoice;
        TempGenJnlLine."Document No." := DocumentNo;
        TempGenJnlLine."Expense Category" := ExpenseReportLine."Expense Category";
        TempGenJnlLine."Wthldg. Tax Bus. Post. Group" := Employee."Wthldg. Tax Bus. Post. Group";
        TempGenJnlLine."Wthldg. Tax Prod. Post. Group" := ExpenseCategory."Wthldg. Tax Prod. Post. Group";

        TempGenJnlLine."Currency Code" := '';
        TempGenJnlLine.Amount := -Abs(ExpenseReportLine."Reimbursable Amount (LCY)");
        TempGenJnlLine."Amount (LCY)" := TempGenJnlLine.Amount;
    end;

    local procedure PostBufferedWHT(EmployeeGenJnlLine: Record "Gen. Journal Line"; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTExpReportBuffer: Record "WHT Exp. Report Buffer";
        WorkGenJnlLine: Record "Gen. Journal Line";
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
        WHTGroupCode: Code[20];
    begin
        WHTExpReportBuffer.SetRange("Document No.", EmployeeGenJnlLine."Document No.");
        if WHTExpReportBuffer.FindSet() then
            repeat
                WorkGenJnlLine := EmployeeGenJnlLine;
                WorkGenJnlLine."Currency Code" := '';
                WorkGenJnlLine."Wthldg. Tax Bus. Post. Group" := WHTExpReportBuffer."Wthldg. Tax Bus. Post. Group";
                WorkGenJnlLine."Wthldg. Tax Prod. Post. Group" := WHTExpReportBuffer."Wthldg. Tax Prod. Post. Group";
                WorkGenJnlLine."Expense Category" := WHTExpReportBuffer."Expense Category";

                if WHTEmployeeCalc.ResolveWHTGroupComponents(WorkGenJnlLine, WHTGroupCode) then
                    PostWHTGroup(WorkGenJnlLine, WHTGroupCode, WHTExpReportBuffer."WHT Base Amount (LCY)", NextTransactionNo, NextTaxEntryNo, GenJnlPostLine)
                else
                    PostWHTSingle(WorkGenJnlLine, WHTExpReportBuffer."WHT Amount (LCY)", WHTExpReportBuffer."WHT Base Amount (LCY)", NextTransactionNo, NextTaxEntryNo, GenJnlPostLine);
            until WHTExpReportBuffer.Next() = 0;

        WHTExpReportBuffer.SetRange("Document No.", EmployeeGenJnlLine."Document No.");
        WHTExpReportBuffer.DeleteAll();
    end;

    local procedure PostWHTSingle(GenJnlLine: Record "Gen. Journal Line"; WHTAmount: Decimal; WHTBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        GLEntry: Record "G/L Entry";
        WHTEmployeeCalc: Codeunit "WHT Employee Calculation";
    begin
        if not WHTPostingSetup.Get(GenJnlLine."Wthldg. Tax Bus. Post. Group", GenJnlLine."Wthldg. Tax Prod. Post. Group") then begin
            if (WHTAmount = 0) and (WHTBaseAmount <> 0) then
                WHTEmployeeCalc.AccumulateBaseForPeriodThreshold(GenJnlLine, WHTBaseAmount);
            exit;
        end;

        if WHTAmount <> 0 then begin
            WHTPostingSetup.TestField("Payable Wthldg. Tax Acc. Code");
            GenJnlPostLine.InitGLEntry(
                GenJnlLine, GLEntry, WHTPostingSetup."Payable Wthldg. Tax Acc. Code", -WHTAmount, 0, false, true, 0);
            GenJnlPostLine.InsertGLEntry(GenJnlLine, GLEntry, true);
        end;

        WHTEmployeeCalc.InsertEmployeeWithholdingTaxEntry(GenJnlLine, WHTAmount, WHTBaseAmount, NextTransactionNo, NextTaxEntryNo);

        if (WHTAmount = 0) and (WHTBaseAmount <> 0) then
            WHTEmployeeCalc.AccumulateBaseForPeriodThreshold(GenJnlLine, WHTBaseAmount);
    end;

    local procedure PostWHTGroup(GenJnlLine: Record "Gen. Journal Line"; WHTGroupCode: Code[20]; WHTBaseAmount: Decimal; NextTransactionNo: Integer; var NextTaxEntryNo: Integer; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
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
                        GenJnlPostLine.InitGLEntry(
                            GenJnlLine, GLEntry, ComponentSetup."Payable Wthldg. Tax Acc. Code",
                            -ComponentWHT, 0, false, true, 0);
                        GenJnlPostLine.InsertGLEntry(GenJnlLine, GLEntry, true);
                    end;

                    WHTEmployeeCalc.InsertEmployeeWHTComponentEntry(
                        GenJnlLine, WHTGroupLine, ComponentWHT, WHTBaseAmount, NextTransactionNo, NextTaxEntryNo);
                end;

                if ParentSetup."Calculation Method" = ParentSetup."Calculation Method"::Compound then
                    CompoundBase := CompoundBase + ComponentWHT;
            until WHTGroupLine.Next() = 0;
    end;

    local procedure CheckWithholdingTaxDisabled(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then
            exit(true);

        exit(not GeneralLedgerSetup."Enable Withholding Tax");
    end;
}
