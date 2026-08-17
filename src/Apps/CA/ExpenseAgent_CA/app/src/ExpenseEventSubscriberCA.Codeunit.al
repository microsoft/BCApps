// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Employee;

codeunit 6916 "Expense Event Subscriber CA"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense GL Account", 'OnBeforeCreateGLAccount', '', false, false)]
    local procedure OnBeforeCreateGLAccount(var IsHandled: Boolean)
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountIndent: Codeunit "G/L Account-Indent";
        SubCategory: Text[80];
    begin
        CreateExpenseGLAccount.InsertGLAccount(ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseTravelRefundableDebitAccountNo(), ExpenseTravelRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePerDiemRefundableDebitAccountNo(), ExpensePerDiemRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMileageRefundableDebitAccountNo(), ExpenseMileageRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseEntertainRefundableDebitAccountNo(), ExpenseEntertainRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMealsRefundableDebitAccountNo(), ExpenseMealsRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseNonRefundableDebitAccountNo(), ExpenseOtherNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        CreateExpenseGLAccount.InsertGLAccount(EmployeePrepaymentsAccountNo(), ExpensePrepaymentBeginLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::"Begin-Total", '', '', '', 0, '', Enum::"G/L Account Type"::"Begin-Total", '', '', false, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePrepaymentDebitAccountNo(), ExpenseOtherPrepaymentLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(EmployeePrepaymentsTotalAccountNo(), ExpensePrepaymentTotalLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::"End-Total", '', '', '', 0, EmployeePrepaymentsAccountNo() + '..' + EmployeePrepaymentsTotalAccountNo(), Enum::"G/L Account Type"::"End-Total", '', '', false, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseDebitRoundingAccountNo(), ExpenseOtherDebitRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseCreditRoundingAccountNo(), ExpenseOtherCreditRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPayableAccountNo(), ExpensePayableCashLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Liabilities, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPrepaymentAccountNo(), ExpensePrepaymentLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableCardPaidAccountNo(), ExpensePayableCardPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableBankPaidAccountNo(), ExpensePayableBankPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        GLAccountIndent.Indent();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeInsertPostingGroupSeed', '', false, false)]
    local procedure OnBeforeInsertPostingGroupSeed(var TempPostingGroup: Record "Expense Posting Group" temporary)
    var
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        case TempPostingGroup.Code of
            CreateExpenseCategories.GetEXPENSETRAVELTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseTravelRefundableDebitAccountNo(), ExpenseNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEPERDIEMTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpensePerDiemRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEOTHERTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseOtherRefundableDebitAccountNo(), ExpenseNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMILEAGETxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMileageRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMEALSTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMealsRefundableDebitAccountNo(), ExpenseNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEENTERTAINTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseEntertainRefundableDebitAccountNo(), ExpenseNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
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
        if TempRuleHeader."Currency Code" = 'CAD' then
            TempRuleHeader."Currency Code" := '';
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

        exit('67430');
    end;

    local procedure ExpenseTravelRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseTravelRefundableLbl, ExpenseTravelRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('61340');
    end;

    local procedure ExpensePerDiemRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemRefundableLbl, ExpensePerDiemRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('61310');
    end;

    local procedure ExpenseMileageRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMileageRefundableLbl, ExpenseMileageRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('61320');
    end;

    local procedure ExpenseMealsRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealsRefundableLbl, ExpenseMealsRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('61330');
    end;

    local procedure ExpenseEntertainRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseEntertainRefundableLbl, ExpenseEntertainRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('61200');
    end;

    local procedure ExpenseNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherNonRefundableLbl, ExpenseOtherNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('71900');
    end;

    local procedure EmployeePrepaymentsAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePrepaymentBeginLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('13600');
    end;

    local procedure ExpensePrepaymentDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherPrepaymentLbl, ExpenseOtherPrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('13610');
    end;

    local procedure EmployeePrepaymentsTotalAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePrepaymentTotalLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('13690');
    end;

    local procedure ExpenseDebitRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherDebitRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('47400');
    end;

    local procedure ExpenseCreditRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherCreditRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('47400');
    end;

    local procedure ExpenseReportPayableAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Liabilities, ExpensePayableCashLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('23850');
    end;

    local procedure ExpenseReportPrepaymentAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePrepaymentLbl, ExpensePrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('13610');
    end;

    local procedure ExpensePayableBankPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableBankPaidLbl, ExpensePayableBankPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('11120');
    end;

    local procedure ExpensePayableCardPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableCardPaidLbl, ExpensePayableCardPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('11160');
    end;

    var
        CreateExpenseGLAccount: Codeunit "Create Expense GL Account";
        ExpenseOtherRefundableLbl: Label 'Misc. external expenses, nondeductible', MaxLength = 100;
        ExpenseOtherRefundableSearchLbl: Label 'Misc. external', MaxLength = 30;
        ExpenseOtherNonRefundableLbl: Label 'Finance Charges to Vendors', MaxLength = 100;
        ExpenseOtherNonRefundableSearchLbl: Label 'Finance Charges to Vendors', MaxLength = 30;
        ExpensePrepaymentBeginLbl: Label 'Employee prepayments', MaxLength = 100;
        ExpenseOtherPrepaymentLbl: Label 'Employee Prepayments, Expenses', MaxLength = 100;
        ExpensePrepaymentTotalLbl: Label 'Employee Prepayments, Total', MaxLength = 100;
        ExpenseOtherPrepaymentSearchLbl: Label 'Employee Prepayments, Expenses', MaxLength = 30;
        ExpenseOtherDebitRoundingLbl: Label 'Invoice Rounding', MaxLength = 100;
        ExpenseOtherCreditRoundingLbl: Label 'Invoice Rounding', MaxLength = 100;
        ExpenseRoundingSearchLbl: Label 'Rounding', MaxLength = 30;
        ExpenseTravelRefundableLbl: Label 'Other travel expenses', MaxLength = 100;
        ExpenseTravelRefundableSearchLbl: Label 'Travel', MaxLength = 30;
        ExpensePerDiemRefundableLbl: Label 'Per-diem travel expenses', MaxLength = 100;
        ExpensePerDiemRefundableSearchLbl: Label 'Per-diem', MaxLength = 30;
        ExpenseMileageRefundableLbl: Label 'Mileage travel expenses', MaxLength = 100;
        ExpenseMileageRefundableSearchLbl: Label 'Mileage', MaxLength = 30;
        ExpenseMealsRefundableLbl: Label 'Meal expenses, deductible', MaxLength = 100;
        ExpenseMealsRefundableSearchLbl: Label 'Meals', MaxLength = 30;
        ExpenseEntertainRefundableLbl: Label 'Entertainment and PR', MaxLength = 100;
        ExpenseEntertainRefundableSearchLbl: Label 'Entertain', MaxLength = 30;
        ExpensePayableCashLbl: Label 'Vacation Compensation Payable', MaxLength = 100;
        ExpensePrepaymentLbl: Label 'Employee Prepayments, Expenses', MaxLength = 100;
        ExpensePrepaymentSearchLbl: Label 'Employee Prepayments', MaxLength = 30;
        ExpensePayableCardPaidLbl: Label 'Company credit cards account', MaxLength = 100;
        ExpensePayableCardPaidSearchLbl: Label 'credit card', MaxLength = 30;
        ExpensePayableBankPaidLbl: Label 'Bank, Checking', MaxLength = 100;
        ExpensePayableBankPaidSearchLbl: Label 'bank', MaxLength = 30;
}