// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8403 "Create Exp. Posting Grp NL"
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
        CreateExpGLAccountNL: Codeunit "Create Exp. GL Account NL";
        ExpenseGLAccountNamesNL: Codeunit "Expense GL Account Names NL";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccountNL.BusinessMealsAndEntertainment(), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.BoardAndLodgingName()), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccountNL.MileageReimbursement(), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccountNL.OtherEmployeeExpenses(), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountNL.PerDiemAllowance(), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.OtherTravelExpensesName()), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.RentalVehiclesName()), CreateExpGLAccountNL.NonDeductibleEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.CurrentReceivableFromEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesNL.PayableInvoiceRoundingName()));
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
