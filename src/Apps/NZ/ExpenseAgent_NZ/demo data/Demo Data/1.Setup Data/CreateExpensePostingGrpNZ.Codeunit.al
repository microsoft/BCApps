#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 17221 "Create Expense Posting Grp NZ"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiem(), ExpensePerDiemLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertRecord(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.TravelName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.FinanceChargestoVendorsName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.InvoiceRoundingName()));
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
#endif