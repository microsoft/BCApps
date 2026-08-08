// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;


codeunit 8278 "ES Exp. Posting Grp"
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
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ESExpGLAccount: Codeunit "ES Exp. GL Account";
        ESGLAccountNames: Codeunit "ES GL Account Names";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ESExpGLAccount.EntertainmentExpensesAccount(), '', ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ESGLAccountNames.OtherBusinessExpensesName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ESExpGLAccount.TravelExpenses(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ESExpGLAccount.RentalCarExpenses(), '', ESExpGLAccount.ExpensesPrepayments(), ESExpGLAccount.RoundingExpensesOperatingAccount(), ESExpGLAccount.RoundingExpensesOperatingAccount());
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
