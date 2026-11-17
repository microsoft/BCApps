#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 10921 "Create Expense Posting Grp ES"
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
        CreateESGLAccounts: Codeunit "Create ES GL Accounts";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ExpenseGLAccountES: Codeunit "Create Expense G/L Account ES";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccountES.EntertainmentExpensesAccount(), '', ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateESGLAccounts.OtherBusinessExpensesName()), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccountES.TravelExpenses(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccountES.RentalCarExpenses(), '', ExpenseGLAccountES.ExpensesPrepayments(), ExpenseGLAccountES.RoundingExpensesOperatingAccount(), ExpenseGLAccountES.RoundingExpensesOperatingAccount());
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