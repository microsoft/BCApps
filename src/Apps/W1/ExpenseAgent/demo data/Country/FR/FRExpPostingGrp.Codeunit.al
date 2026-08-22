// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 8302 "FR Exp. Posting Grp"
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
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        FRExpGLAccount: Codeunit "FR Exp. GL Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EntertainmentandPRName()), '', FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.TravelName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, FRExpGLAccount.RentalCarExpenses(), '', FRExpGLAccount.ExpensePrepaymentAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
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
