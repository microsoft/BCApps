#if not CLEAN30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 11331 "Create Expense Posting Grp DE"
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
        CreateGLAccountDE: Codeunit "Create DE GL Acc.";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.BusinessEntertainingdeductibleName()), '', ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.BoardandlodgingName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.MiscexternalexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.RentalvehiclesName()), '', ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SalesInvoiceRoundingName()));
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