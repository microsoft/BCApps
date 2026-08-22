// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8447 "Create Exp. Posting Grp NO"
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
        CreateExpGLAccountNO: Codeunit "Create Exp. GL Account NO";
        ExpenseGLAccountNamesNO: Codeunit "Expense GL Account Names NO";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.EntertainmentDeductibleName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.EntertainmentDeductibleName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.CarAllowanceName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.AdministrativeExpensesName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.SubsistenceName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.TravelName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNO.TravelName()), CreateExpGLAccountNO.NonRefundableEmployeeExpenses(), CreateExpGLAccountNO.EmployeeExpensePrepayments(), CreateExpGLAccountNO.ExpenseRoundingDifferences(), CreateExpGLAccountNO.ExpenseRoundingDifferences());
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
