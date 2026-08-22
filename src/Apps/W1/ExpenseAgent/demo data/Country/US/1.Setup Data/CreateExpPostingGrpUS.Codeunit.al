// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8225 "Create Exp. Posting Grp US"
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
        ExpenseGLAccountNamesUS: Codeunit "Expense GL Account Names US";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.BusinessEntertainingDeductibleName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.MiscExternalExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherTravelExpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.RentalVehiclesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesUS.PayableInvoiceRoundingName()));
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
