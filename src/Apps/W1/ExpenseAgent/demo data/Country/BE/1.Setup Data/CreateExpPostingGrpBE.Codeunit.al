// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8414 "Create Exp. Posting Grp BE"
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
        CreateExpGLAccountBE: Codeunit "Create Exp. GL Account BE";
        ExpenseGLAccountNamesBE: Codeunit "Expense GL Account Names BE";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesBE.EntertainmentAndPRName()), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccountBE.BusinessMeals(), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccountBE.MileageAllowance(), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccountBE.OtherEmployeeExpenses(), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountBE.PerDiemAllowance(), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesBE.TravelName()), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesBE.TravelName()), CreateExpGLAccountBE.NonRefundableEmployeeExpenses(), CreateExpGLAccountBE.EmployeeTravelAdvances(), CreateExpGLAccountBE.ExpenseRoundingDifferences(), CreateExpGLAccountBE.ExpenseRoundingDifferences());
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
