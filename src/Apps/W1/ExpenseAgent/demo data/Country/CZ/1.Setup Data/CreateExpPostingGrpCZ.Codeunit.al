// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8469 "Create Exp. Posting Grp CZ"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiem(), ExpensePerDiemLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertRecord(var Rec: Record "Expense Posting Group")
    var
        CreateExpGLAccountCZ: Codeunit "Create Exp. GL Account CZ";
        ExpenseGLAccountNamesCZ: Codeunit "Expense GL Account Names CZ";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.RepresentationCostsName()), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccountCZ.MealsAndHospitalityExpenses(), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccountCZ.MileageAllowance(), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountCZ.PerDiemAllowance(), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccountCZ.CarRentalExpenses(), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.TravelExpensesName()), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCZ.OtherOperatingExpensesName()), CreateExpGLAccountCZ.NonRefundableEmployeeExpenses(), CreateExpGLAccountCZ.EmployeeExpenseAdvances(), CreateExpGLAccountCZ.ExpenseRoundingDifferences(), CreateExpGLAccountCZ.ExpenseRoundingDifferences());
        end;
    end;

    local procedure ValidateRecordFields(var ExpensePostingGroup: Record "Expense Posting Group"; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; ExpenseDebitRoundingAccount: Code[20]; ExpenseCreditRoundingAccount: Code[20])
    begin
        ExpensePostingGroup.Validate("Refundable Debit Account", RefundableDebitAccount);
        ExpensePostingGroup.Validate("Non-Refundable Debit Account", NonRefundableDebitAccount);
        ExpensePostingGroup.Validate("Prepayment Credit Account", PrepaymentCreditAccount);
        ExpensePostingGroup.Validate("Debit Rounding Account", ExpenseDebitRoundingAccount);
        ExpensePostingGroup.Validate("Credit Rounding Account", ExpenseCreditRoundingAccount);
    end;

    var
        ExpensePERDIEMTok: Label 'EXPENSE-PERDIEM', MaxLength = 20, Locked = true;
        ExpensePerDiemLbl: Label 'Expense - Per Diem', MaxLength = 100;

    procedure ExpensePerDiem(): Code[20]
    begin
        exit(ExpensePERDIEMTok);
    end;
}
