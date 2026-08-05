// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Employee;

codeunit 6919 "Expense Event Subscriber ES"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense GL Account", 'OnBeforeCreateGLAccount', '', false, false)]
    local procedure OnBeforeCreateGLAccount(var IsHandled: Boolean)
    begin
        CreateExpenseGLAccount.InsertGLAccount(ExpenseProfitLossAccountNo(), ExpenseProfitLossLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Equity, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseTravelRefundableDebitAccountNo(), ExpenseTravelRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePerDiemRefundableDebitAccountNo(), ExpensePerDiemRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMileageRefundableDebitAccountNo(), ExpenseMileageRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseEntertainRefundableDebitAccountNo(), ExpenseEntertainRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMealsRefundableDebitAccountNo(), ExpenseMealsRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseMealNonRefundableDebitAccountNo(), ExpenseMealNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseOtherNonRefundableDebitAccountNo(), ExpenseOtherNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePrepaymentDebitAccountNo(), ExpenseOtherPrepaymentLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseDebitRoundingAccountNo(), ExpenseOtherDebitRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseCreditRoundingAccountNo(), ExpenseOtherCreditRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPayableAccountNo(), ExpensePayableCashLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Liabilities, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPrepaymentAccountNo(), ExpensePrepaymentLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableCardPaidAccountNo(), ExpensePayableCardPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableBankPaidAccountNo(), ExpensePayableBankPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        UpdateIncomeStatementBalanceAccount();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeInsertPostingGroupSeed', '', false, false)]
    local procedure OnBeforeInsertPostingGroupSeed(var TempPostingGroup: Record "Expense Posting Group" temporary)
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        case TempPostingGroup.Code of
            CreateExpenseCategories.GetEXPENSETRAVELTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseTravelRefundableDebitAccountNo(), ExpenseOtherNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEPERDIEMTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpensePerDiemRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEOTHERTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMILEAGETxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMileageRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMEALSTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMealsRefundableDebitAccountNo(), ExpenseMealNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEENTERTAINTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseEntertainRefundableDebitAccountNo(), ExpenseOtherNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeUpdateEmployeePostingGroup', '', false, false)]
    local procedure OnBeforeUpdateEmployeePostingGroup(Code: Code[20]; var IsHandled: Boolean)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        IsHandled := true;
        if not EmployeePostingGroup.Get(Code) then
            exit;

        EmployeePostingGroup.Validate("Expense Report Payable Account", ExpenseReportPayableAccountNo());
        EmployeePostingGroup.Validate("Expense Payable Bank Paid Acc.", ExpensePayableBankPaidAccountNo());
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", ExpensePayableCardPaidAccountNo());
        EmployeePostingGroup.Validate("Exp. Report Prepayment Account", ExpenseReportPrepaymentAccountNo());
        EmployeePostingGroup.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeInsertRuleSeed', '', false, false)]
    local procedure OnBeforeInsertRuleSeed(var TempRuleHeader: Record "Expense Rule Header" temporary)
    begin
        if TempRuleHeader."Currency Code" = 'EUR' then
            TempRuleHeader."Currency Code" := 'USD';
    end;

    local procedure AddExpensePostingGroupAccount(var TempPostingGroup: Record "Expense Posting Group" temporary; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; DebitRoundingAccount: Code[20]; CreditRoundingAccount: Code[20])
    begin
        TempPostingGroup."Refundable Debit Account" := RefundableDebitAccount;
        TempPostingGroup."Non-Refundable Debit Account" := NonRefundableDebitAccount;
        TempPostingGroup."Prepayment Credit Account" := PrepaymentCreditAccount;
        TempPostingGroup."Debit Rounding Account" := DebitRoundingAccount;
        TempPostingGroup."Credit Rounding Account" := CreditRoundingAccount;
    end;

    local procedure ExpenseOtherRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherRefundableLbl, ExpenseOtherRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6290003');
    end;

    local procedure ExpenseTravelRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseTravelRefundableLbl, ExpenseTravelRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6291001');
    end;

    local procedure ExpensePerDiemRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemRefundableLbl, ExpensePerDiemRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6291002');
    end;

    local procedure ExpenseMileageRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMileageRefundableLbl, ExpenseMileageRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6291003');
    end;

    local procedure ExpenseMealsRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealsRefundableLbl, ExpenseMealsRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6292001');
    end;

    local procedure ExpenseEntertainRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseEntertainRefundableLbl, ExpenseEntertainRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6293001');
    end;

    local procedure ExpenseMealNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealNonRefundableLbl, ExpenseMealNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6292002');
    end;

    local procedure ExpenseOtherNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherNonRefundableLbl, ExpenseOtherNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6299001');
    end;

    local procedure ExpensePrepaymentDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherPrepaymentLbl, ExpenseOtherPrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('4800001');
    end;

    local procedure ExpenseDebitRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherDebitRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6298001');
    end;

    local procedure ExpenseCreditRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherCreditRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('6298001');
    end;

    local procedure ExpenseReportPayableAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Liabilities, ExpensePayableCashLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('4600001');
    end;

    local procedure ExpenseReportPrepaymentAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePrepaymentLbl, ExpensePrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('4800001');
    end;

    local procedure ExpensePayableBankPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableBankPaidLbl, ExpensePayableBankPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('5720001');
    end;

    local procedure ExpensePayableCardPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableCardPaidLbl, ExpensePayableCardPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('5721001');
    end;

    local procedure ExpenseProfitLossAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpenseProfitLossLbl, ExpenseProfitLossSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('1290001');
    end;

    local procedure UpdateIncomeStatementBalanceAccount()
    var
        ProfitLossAccountNo: Code[20];
    begin
        ProfitLossAccountNo := ExpenseProfitLossAccountNo();

        UpdateIncomeStmtBalAcc(ExpenseOtherRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseTravelRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePerDiemRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMileageRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseEntertainRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMealsRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseMealNonRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseOtherNonRefundableDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePrepaymentDebitAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseDebitRoundingAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseCreditRoundingAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseReportPayableAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpenseReportPrepaymentAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePayableCardPaidAccountNo(), ProfitLossAccountNo);
        UpdateIncomeStmtBalAcc(ExpensePayableBankPaidAccountNo(), ProfitLossAccountNo);
    end;

    local procedure UpdateIncomeStmtBalAcc(No: Code[20]; IncomeStmtBalAcc: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(No) then begin
            GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalAcc);
            GLAccount.Modify();
        end;
    end;

    var
        CreateExpenseGLAccount: Codeunit "Create Expense GL Account";
        ExpenseOtherRefundableLbl: Label 'Other Business Expenses', MaxLength = 100;
        ExpenseOtherRefundableSearchLbl: Label 'Other Business Expenses', MaxLength = 30;
        ExpenseMealNonRefundableLbl: Label 'Meal expenses, nondeductible', MaxLength = 100;
        ExpenseMealNonRefundableSearchLbl: Label 'Meal expenses, nondeductible', MaxLength = 30;
        ExpenseOtherNonRefundableLbl: Label 'Other nondeductible travel expenses', MaxLength = 100;
        ExpenseOtherNonRefundableSearchLbl: Label 'Other nondeductible travel', MaxLength = 30;
        ExpenseOtherPrepaymentLbl: Label 'Expenses Prepayments', MaxLength = 100;
        ExpenseOtherPrepaymentSearchLbl: Label 'Expenses Prepayments', MaxLength = 30;
        ExpenseOtherDebitRoundingLbl: Label 'Rounding Expenses Operating', MaxLength = 100;
        ExpenseOtherCreditRoundingLbl: Label 'Rounding Expenses Operating', MaxLength = 100;
        ExpenseRoundingSearchLbl: Label 'Rounding', MaxLength = 30;
        ExpenseTravelRefundableLbl: Label 'Travel expenses', MaxLength = 100;
        ExpenseTravelRefundableSearchLbl: Label 'Travel', MaxLength = 30;
        ExpensePerDiemRefundableLbl: Label 'Per-diem travel expenses', MaxLength = 100;
        ExpensePerDiemRefundableSearchLbl: Label 'Per-diem', MaxLength = 30;
        ExpenseMileageRefundableLbl: Label 'Mileage travel expenses', MaxLength = 100;
        ExpenseMileageRefundableSearchLbl: Label 'Mileage', MaxLength = 30;
        ExpenseMealsRefundableLbl: Label 'Meal expenses, deductible', MaxLength = 100;
        ExpenseMealsRefundableSearchLbl: Label 'Meals', MaxLength = 30;
        ExpenseEntertainRefundableLbl: Label 'Entertainment expenses', MaxLength = 100;
        ExpenseEntertainRefundableSearchLbl: Label 'Entertain', MaxLength = 30;
        ExpensePayableCashLbl: Label 'Remuneration Advances', MaxLength = 100;
        ExpensePrepaymentLbl: Label 'Expenses Prepayments', MaxLength = 100;
        ExpensePrepaymentSearchLbl: Label 'Expenses Prepayments', MaxLength = 30;
        ExpensePayableCardPaidLbl: Label 'Company credit card clearing account', MaxLength = 100;
        ExpensePayableCardPaidSearchLbl: Label 'credit card', MaxLength = 30;
        ExpensePayableBankPaidLbl: Label 'Banks Euro', MaxLength = 100;
        ExpensePayableBankPaidSearchLbl: Label 'Bank', MaxLength = 30;
        ExpenseProfitLossLbl: Label 'Profit or Loss', MaxLength = 100;
        ExpenseProfitLossSearchLbl: Label 'Profit or Loss', MaxLength = 30;
}