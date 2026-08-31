#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 11192 "Create Expense Posting Grp AT"
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
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiemI(), ExpensePerDiemInCountryLbl);
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiemA(), ExpensePerDiemAbroadLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertRecord(var Rec: Record "Expense Posting Group")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        CreateATGLAccount: Codeunit "Create AT GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.HospitalityDomesticDeductibleAmountName()), '', ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.KilometerAllowanceName()), '', ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.OtherName()), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiemI():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.MealExpensesDomesticName()), '', ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            ExpensePerDiemA():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.MealExpensesAbroadName()), '', ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.TransportationThirdPartiesName()), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.TransportationThirdPartiesName()), '', ExpenseGLAccount.FindGLAccountByName(CreateATGLAccount.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.ApplicationRoundingName()));
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
        ExpensePERDIEMITok: Label 'EXPENSE-PERDIEM-I', MaxLength = 20, Locked = true;
        ExpensePerDiemInCountryLbl: Label 'Expense - Per Diem in country', MaxLength = 100;
        ExpensePERDIEMATok: Label 'EXPENSE-PERDIEM-A', MaxLength = 20, Locked = true;
        ExpensePerDiemAbroadLbl: Label 'Expense - Per Diem abroad', MaxLength = 100;

    procedure ExpensePerDiemI(): Code[20]
    begin
        exit(ExpensePERDIEMITok);
    end;

    procedure ExpensePerDiemA(): Code[20]
    begin
        exit(ExpensePERDIEMATok);
    end;
}
#endif