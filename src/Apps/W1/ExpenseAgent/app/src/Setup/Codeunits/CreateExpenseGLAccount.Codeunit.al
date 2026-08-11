// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 6971 "Create Expense GL Account"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        CreateGLAccount();
    end;

    var
        ExpenseOtherRefundableLbl: Label 'Misc. external expenses', MaxLength = 100;
        ExpenseOtherRefundableSearchLbl: Label 'Misc. external', MaxLength = 30;
        ExpenseOtherNonRefundableLbl: Label 'Other Incidental Revenue', MaxLength = 100;
        ExpenseOtherNonRefundableSearchLbl: Label 'Incidental revenue', MaxLength = 30;
        ExpenseOtherPrepaymentLbl: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        ExpenseOtherPrepaymentSearchLbl: Label 'prepaid expenses', MaxLength = 30;
        ExpenseOtherDebitRoundingLbl: Label 'Payable Invoice Rounding', MaxLength = 100;
        ExpenseOtherCreditRoundingLbl: Label 'Payable Invoice Rounding', MaxLength = 100;
        ExpenseRoundingSearchLbl: Label 'Rounding', MaxLength = 30;
        ExpenseTravelRefundableLbl: Label 'Other travel expenses', MaxLength = 100;
        ExpenseTravelRefundableSearchLbl: Label 'travel expense', MaxLength = 30;
        ExpensePerDiemRefundableLbl: Label 'Per-diem travel expenses', MaxLength = 100;
        ExpensePerDiemRefundableSearchLbl: Label 'Per-diem', MaxLength = 30;
        ExpenseMileageRefundableLbl: Label 'Mileage travel expenses', MaxLength = 100;
        ExpenseMileageRefundableSearchLbl: Label 'Mileage', MaxLength = 30;
        ExpenseMealsRefundableLbl: Label 'Meal expenses, deductible', MaxLength = 100;
        ExpenseMealsRefundableSearchLbl: Label 'Meals', MaxLength = 30;
        ExpenseEntertainRefundableLbl: Label 'Business Entertaining, deductible', MaxLength = 100;
        ExpenseEntertainRefundableSearchLbl: Label 'Entertain', MaxLength = 30;
        ExpensePayableCashLbl: Label 'Employees Payable', MaxLength = 100;
        ExpensePrepaymentLbl: Label 'Other prepaid expenses and accrued income', MaxLength = 100;
        ExpensePrepaymentSearchLbl: Label 'prepaid expenses', MaxLength = 30;
        ExpensePayableCardPaidLbl: Label 'Company credit cards account', MaxLength = 100;
        ExpensePayableCardPaidSearchLbl: Label 'credit card', MaxLength = 30;
        ExpensePayableBankPaidLbl: Label 'Other bank accounts', MaxLength = 100;
        ExpensePayableBankPaidSearchLbl: Label 'bank', MaxLength = 30;


    local procedure CreateGLAccount()
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
        IsHandled: Boolean;
    begin
        OnBeforeCreateGLAccount(IsHandled);
        if IsHandled then
            exit;

        InsertGLAccount(ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseTravelRefundableDebitAccountNo(), ExpenseTravelRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePerDiemRefundableDebitAccountNo(), ExpensePerDiemRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseMileageRefundableDebitAccountNo(), ExpenseMileageRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseEntertainRefundableDebitAccountNo(), ExpenseEntertainRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseMealsRefundableDebitAccountNo(), ExpenseMealsRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        InsertGLAccount(ExpenseNonRefundableDebitAccountNo(), ExpenseOtherNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePrepaymentDebitAccountNo(), ExpenseOtherPrepaymentLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseDebitRoundingAccountNo(), ExpenseOtherDebitRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseCreditRoundingAccountNo(), ExpenseOtherCreditRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        InsertGLAccount(ExpenseReportPayableAccountNo(), ExpensePayableCashLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Liabilities, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpenseReportPrepaymentAccountNo(), ExpensePrepaymentLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePayableCardPaidAccountNo(), ExpensePayableCardPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        InsertGLAccount(ExpensePayableBankPaidAccountNo(), ExpensePayableBankPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        GLAccountIndent.Indent();
    end;

    internal procedure InsertGLAccount(AccountNo: Code[20]; Name: Text[100]; IncomeOrBalance: Enum "G/L Account Income/Balance"; AccountCategory: Enum "G/L Account Category"; AccountSubCategory: Text[80]; AccountType: Enum "G/L Account Type"; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; TaxGroup: Code[20]; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Enum "General Posting Type"; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean; ReconciliationAccount: Boolean; NewPage: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit;

        GLAccount.Validate("No.", AccountNo);
        GLAccount.Validate(Name, Name);

        case IncomeOrBalance of
            IncomeOrBalance::"Income Statement":
                GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Income Statement");
            IncomeOrBalance::"Balance Sheet":
                GLAccount.Validate("Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");
        end;

        ValidateAccountCategory(GLAccount, AccountCategory, AccountSubCategory);

        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);

        GLAccount.Validate("No. of Blank Lines", NoOfBlankLines);

        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        if GenPostingType <> GenPostingType::" " then
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
        if (VATGenPostingGroup <> '') then
            GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
        if (VATProdPostingGroup <> '') then
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);

        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("Reconciliation Account", ReconciliationAccount);
        GLAccount.Validate("New Page", NewPage);

        if GenProdPostingGroup <> '' then
            GLAccount.Validate("Tax Group Code", TaxGroup);

        GLAccount.Insert(true);
    end;

    local procedure ValidateAccountCategory(var GLAccount: Record "G/L Account"; Category: Enum "G/L Account Category"; SubCategory: Text[80])
    begin
        if Category <> Enum::"G/L Account Category"::" " then begin
            GLAccount.Validate("Account Category", Category);

            if SubCategory = '' then
                GLAccount.Validate("Account Subcategory Entry No.", 0)
            else
                GLAccount.ValidateAccountSubCategory(SubCategory);
        end else
            GLAccount.Validate("Account Category", Enum::"G/L Account Category"::" ");
    end;

    internal procedure ExpenseOtherRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherRefundableLbl, ExpenseOtherRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('31540');
    end;

    internal procedure ExpenseTravelRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseTravelRefundableLbl, ExpenseTravelRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('30540');
    end;

    internal procedure ExpensePerDiemRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemRefundableLbl, ExpensePerDiemRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('30550');
    end;

    internal procedure ExpenseMileageRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMileageRefundableLbl, ExpenseMileageRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('30560');
    end;

    internal procedure ExpenseMealsRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealsRefundableLbl, ExpenseMealsRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('30535');
    end;

    internal procedure ExpenseEntertainRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseEntertainRefundableLbl, ExpenseEntertainRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('30820');
    end;

    internal procedure ExpenseNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherNonRefundableLbl, ExpenseOtherNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('10390');
    end;

    internal procedure ExpensePrepaymentDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherPrepaymentLbl, ExpenseOtherPrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('76600');
    end;

    internal procedure ExpenseDebitRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherDebitRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('31330');
    end;

    internal procedure ExpenseCreditRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherCreditRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('31330');
    end;

    internal procedure ExpenseReportPayableAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Liabilities, ExpensePayableCashLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('5850');
    end;

    internal procedure ExpenseReportPrepaymentAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePrepaymentLbl, ExpensePrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('76600');
    end;

    internal procedure ExpensePayableBankPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableBankPaidLbl, ExpensePayableBankPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('78400');
    end;

    internal procedure ExpensePayableCardPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableCardPaidLbl, ExpensePayableCardPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('78600');
    end;

    internal procedure FindExistingExpenseAccount(AccountCategory: Enum "G/L Account Category"; FullDescription: Text; PartialDescription: Text) AccNo: Code[20]
    begin
        AccNo := FindExistingExpenseAccount(AccountCategory, FullDescription);
        if AccNo <> '' then
            exit;
        AccNo := FindExistingExpenseAccount(AccountCategory, PartialDescription);
    end;

    internal procedure FindExistingExpenseAccount(AccountCategory: Enum "G/L Account Category"; SearchDescription: Text): Code[20]
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
    begin
        if SearchDescription = '' then
            exit('');
        SearchDescription := ConvertStr(SearchDescription, ' ', '*');
        SearchDescription := '@*' + SearchDescription + '*'; // ignore case, any position in text

        GLAccount.SetRange("Account Category", AccountCategory);
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);

        GLAccount.SetFilter(Name, SearchDescription);
        if GLAccount.FindFirst() then
            exit(GLAccount."No.");

        GLAccount.SetRange(Name);
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, SearchDescription);
        if GLAccountCategory.FindSet() then
            repeat
                GLAccount.SetRange("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
                if GLAccount.FindFirst() then
                    exit(GLAccount."No.");
            until GLAccountCategory.Next() = 0;

        exit('');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGLAccount(var IsHandled: Boolean)
    begin
    end;
}