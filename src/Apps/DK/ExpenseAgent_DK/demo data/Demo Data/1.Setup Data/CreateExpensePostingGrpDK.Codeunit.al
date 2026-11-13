#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 13676 "Create Expense Posting Grp DK"
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
        CreateDKGLAccounts: Codeunit "Create GL Acc. DK";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ExpenseGLAccountDK: Codeunit "Create Expense G/L Account DK";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.EntwinetobaccospiritsName()), '', ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.RestaurantdiningName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.MileagerateName()), '', ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccountDK.OtherExpenses(), ExpenseGLAccountDK.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccountDK.TravelAllowancesPerDiem(), '', ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.TravelingtradefairsetcName()), ExpenseGLAccountDK.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccountDK.RentalCarExpenses(), '', ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.CentdiscrepanciesName()));
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