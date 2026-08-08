// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8291 "DK Exp. Posting Grp"
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
        DKGLAccountNames: Codeunit "DK GL Account Names";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        DKExpGLAccount: Codeunit "DK Exp. GL Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.EntwinetobaccospiritsName()), '', ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.RestaurantdiningName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.MileagerateName()), '', ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, DKExpGLAccount.OtherExpenses(), DKExpGLAccount.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, DKExpGLAccount.TravelAllowancesPerDiem(), '', ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.TravelingtradefairsetcName()), DKExpGLAccount.NonDeductibleTravelExpenses(), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, DKExpGLAccount.RentalCarExpenses(), '', ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()), ExpenseGLAccount.FindGLAccountByName(DKGLAccountNames.CentdiscrepanciesName()));
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
