// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8291 "Create Exp. Posting Grp DK"
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
        ExpenseGLAccountNamesDK: Codeunit "Expense GL Account Names DK";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpGLAccountDK: Codeunit "Create Exp. GL Account DK";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.EntwinetobaccospiritsName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.RestaurantdiningName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.MileagerateName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccountDK.OtherExpenses(), CreateExpGLAccountDK.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountDK.TravelAllowancesPerDiem(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.TravelingtradefairsetcName()), CreateExpGLAccountDK.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccountDK.RentalCarExpenses(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDK.CentdiscrepanciesName()));
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
