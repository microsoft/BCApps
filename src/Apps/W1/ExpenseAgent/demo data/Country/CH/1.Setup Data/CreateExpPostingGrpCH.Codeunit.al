// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8436 "Create Exp. Posting Grp CH"
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
        CreateExpGLAccountCH: Codeunit "Create Exp. GL Account CH";
        ExpenseGLAccountNamesCH: Codeunit "Expense GL Account Names CH";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccountCH.EntertainmentExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccountCH.MealsAndHospitalityExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccountCH.MileageAllowance(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.MiscCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountCH.PerDiemAllowance(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.TravelCostsCustomerServiceName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.TravelCostsCustomerServiceName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.OtherPersonnelCostsName()), CreateExpGLAccountCH.EmployeeExpenseAdvances(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesCH.RoundingDifferencesPurchaseName()));
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
