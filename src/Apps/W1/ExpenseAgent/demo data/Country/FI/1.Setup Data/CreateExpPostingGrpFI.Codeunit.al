// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8458 "Create Exp. Posting Grp FI"
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
        CreateExpGLAccountFI: Codeunit "Create Exp. GL Account FI";
        ExpenseGLAccountNamesFI: Codeunit "Expense GL Account Names FI";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.EntertainmentExpenses(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.BusinessMealExpenses(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.MileageAllowance(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.OtherEmployeeExpenses(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            ExpensePerDiem():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.PerDiemAllowance(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.OtherTravelExpenses(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, CreateExpGLAccountFI.CarRentalExpenses(), CreateExpGLAccountFI.NonRefundableEmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesFI.Otherreceivables1Name()), CreateExpGLAccountFI.ExpenseRoundingDifferences(), CreateExpGLAccountFI.ExpenseRoundingDifferences());
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
