// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8314 "Create Exp. Posting Grp DE"
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
        ExpenseGLAccountNamesDE: Codeunit "Expense GL Account Names DE";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.BusinessEntertainingdeductibleName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.BoardandlodgingName()), ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.MiscexternalexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.OthertravelexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.RentalvehiclesName()), '', ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNamesDE.SalesInvoiceRoundingName()));
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
