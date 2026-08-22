// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8425 "Create Exp. Posting Grp IT"
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
        CreateExpGLAccountIT: Codeunit "Create Exp. GL Account IT";
        ExpenseGLAccountNamesIT: Codeunit "Expense GL Account Names IT";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.EntertainmentAndPRName()), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.EntertainmentAndPRName()), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.GasolineAndMotorOilName()), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.MiscellaneousName()), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountIT.PerDiemAllowance(), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.TravelName()), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccountIT.CarRentalExpenses(), CreateExpGLAccountIT.NonDeductibleEmployeeExpenses(), CreateExpGLAccountIT.EmployeeAdvancesPrepayments(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesIT.InvoiceRoundingName()));
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
