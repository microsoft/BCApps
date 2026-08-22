// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;


codeunit 8278 "Create Exp. Posting Grp ES"
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
        CreateExpGLAccountES: Codeunit "Create Exp. GL Account ES";
        ExpenseGLAccountNamesES: Codeunit "Expense GL Account Names ES";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccountES.EntertainmentExpensesAccount(), '', CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesES.OtherBusinessExpensesName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, CreateExpGLAccountES.TravelExpenses(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccountES.RentalCarExpenses(), '', CreateExpGLAccountES.ExpensesPrepayments(), CreateExpGLAccountES.RoundingExpensesOperatingAccount(), CreateExpGLAccountES.RoundingExpensesOperatingAccount());
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
