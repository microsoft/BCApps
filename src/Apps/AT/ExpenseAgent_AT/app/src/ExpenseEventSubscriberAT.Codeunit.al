// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.HumanResources.Employee;

codeunit 6914 "Expense Event Subscriber AT"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense GL Account", 'OnBeforeCreateGLAccount', '', false, false)]
    local procedure OnBeforeCreateGLAccount(var IsHandled: Boolean)
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
    begin
        CreateExpenseGLAccount.InsertGLAccount(ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseTravelRefundableDebitAccountNo(), ExpenseTravelRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePerDiemARefundableDebitAccountNo(), ExpensePerDiemARefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePerDiemIRefundableDebitAccountNo(), ExpensePerDiemIRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMileageRefundableDebitAccountNo(), ExpenseMileageRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseEntertainRefundableDebitAccountNo(), ExpenseEntertainRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseMealsRefundableDebitAccountNo(), ExpenseMealsRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseMealNonRefundableDebitAccountNo(), ExpenseMealNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseOtherNonRefundableDebitAccountNo(), ExpenseOtherNonRefundableLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePrepaymentDebitAccountNo(), ExpenseOtherPrepaymentLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseDebitRoundingAccountNo(), ExpenseOtherDebitRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseCreditRoundingAccountNo(), ExpenseOtherCreditRoundingLbl, "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPayableAccountNo(), ExpensePayableCashLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Liabilities, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpenseReportPrepaymentAccountNo(), ExpensePrepaymentLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableCardPaidAccountNo(), ExpensePayableCardPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        CreateExpenseGLAccount.InsertGLAccount(ExpensePayableBankPaidAccountNo(), ExpensePayableBankPaidLbl, "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, '', Enum::"G/L Account Type"::Posting, '', '', '', 1, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);

        GLAccountIndent.Indent();
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeAddPostingGroupSeed', '', false, false)]
    local procedure OnBeforeAddPostingGroupSeed(Code: Code[20]; var IsHandled: Boolean)
    begin
        if Code = CreateExpenseCategories.GetEXPENSEPERDIEMTxt() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnAfterBuildPostingGroupSeeds', '', false, false)]
    local procedure OnAfterBuildPostingGroupSeeds(var TempPostingGroup: Record "Expense Posting Group" temporary)
    begin
        CreateExpenseCategories.AddPostingGroupSeed(TempPostingGroup, ExpensePerDiemI(), ExpensePerDiemInCountryLbl, ExpensePerDiemIRefundableDebitAccountNo());
        CreateExpenseCategories.AddPostingGroupSeed(TempPostingGroup, ExpensePerDiemA(), ExpensePerDiemAbroadLbl, ExpensePerDiemARefundableDebitAccountNo());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnAfterBuildCategorySeeds', '', false, false)]
    local procedure OnAfterBuildCategorySeeds(var TempCategory: Record "Expense Category" temporary)
    begin
        CreateExpenseCategories.AddCategorySeed(TempCategory, PerDiemI(), PerDiemByAssignedPolicyLbl, PerDiemIByAssignedPolicyPostingLbl, CreateExpenseCategories.GetTRAVELTxt(), ExpensePerDiemI(), CreateExpenseCategories.GetCASHTxt(), true, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::"Per Diem");
        CreateExpenseCategories.AddCategorySeed(TempCategory, PerDiemA(), PerDiemByAssignedPolicyLbl, PerDiemAByAssignedPolicyPostingLbl, CreateExpenseCategories.GetTRAVELTxt(), ExpensePerDiemA(), CreateExpenseCategories.GetCASHTxt(), true, false, "Expense Attachment Enforcement"::" ", "Expense Detail Needed"::"Per Diem");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnAfterBuildSubcategorySeeds', '', false, false)]
    local procedure OnAfterBuildSubcategorySeeds(var TempSubcategory: Record "Expense Subcategory" temporary)
    begin
        CreateExpenseCategories.AddSubcategorySeed(TempSubcategory, Country(), PerDiemA(), LocalCountryPerDiemLbl, LocalCountryPerDiemPostingLbl, true, false);
        CreateExpenseCategories.AddSubcategorySeed(TempSubcategory, Intl(), PerDiemI(), InternationalPerDiemLbl, InternationalPerDiemPostingLbl, true, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnAfterBuildRuleSeeds', '', false, false)]
    local procedure OnAfterBuildRuleSeeds(var TempRuleHeader: Record "Expense Rule Header" temporary)
    begin
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetCANADAALLTxt(), 'CAD', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetDENMARKALLTxt(), 'USD', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemA(), CreateExpenseCategories.GetDOMESTICTxt(), 'USD', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetFRANCEALLTxt(), 'USD', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetGERMANYALLTxt(), 'USD', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetUKOTHERTxt(), 'GBP', "Expense Justification"::" ");
        CreateExpenseCategories.AddRuleSeed(TempRuleHeader, PerDiemI(), CreateExpenseCategories.GetUSAOTHERTxt(), 'USD', "Expense Justification"::" ");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnAfterBuildRuleConditionSeeds', '', false, false)]
    local procedure OnAfterBuildRuleConditionSeeds(var TempRuleCondition: Record "Expense Rule Condition" temporary)
    begin
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetCANADAALLTxt(), "Expense Rule Condition Type"::"Daily Rate", 125);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetDENMARKALLTxt(), "Expense Rule Condition Type"::"Daily Rate", 450);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemA(), CreateExpenseCategories.GetDOMESTICTxt(), "Expense Rule Condition Type"::"Daily Rate", 50);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetFRANCEALLTxt(), "Expense Rule Condition Type"::"Daily Rate", 110);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetGERMANYALLTxt(), "Expense Rule Condition Type"::"Daily Rate", 105);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetUKOTHERTxt(), "Expense Rule Condition Type"::"Daily Rate", 115);
        CreateExpenseCategories.AddRuleConditionSeed(TempRuleCondition, PerDiemI(), CreateExpenseCategories.GetUSAOTHERTxt(), "Expense Rule Condition Type"::"Daily Rate", 120);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeAddCategorySeed', '', false, false)]
    local procedure OnBeforeAddCategorySeed(Code: Code[20]; var IsHandled: Boolean)
    begin
        if Code = CreateExpenseCategories.GetPERDIEMTxt() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeAddSubcategorySeed', '', false, false)]
    local procedure OnBeforeAddSubcategorySeed(CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
        if CategoryCode = CreateExpenseCategories.GetPERDIEMTxt() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeAddRuleSeed', '', false, false)]
    local procedure OnBeforeAddRuleSeed(CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
        if CategoryCode = CreateExpenseCategories.GetPERDIEMTxt() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeAddRuleConditionSeed', '', false, false)]
    local procedure OnBeforeAddRuleConditionSeed(CategoryCode: Code[20]; var IsHandled: Boolean)
    begin
        if CategoryCode = CreateExpenseCategories.GetPERDIEMTxt() then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeInsertPostingGroupSeed', '', false, false)]
    local procedure OnBeforeInsertPostingGroupSeed(var TempPostingGroup: Record "Expense Posting Group" temporary)
    begin
        case TempPostingGroup.Code of
            CreateExpenseCategories.GetEXPENSETRAVELTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseTravelRefundableDebitAccountNo(), ExpenseOtherNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEOTHERTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseOtherRefundableDebitAccountNo(), ExpenseOtherNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            ExpensePerDiemI():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpensePerDiemIRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            ExpensePerDiemA():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpensePerDiemARefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMILEAGETxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMileageRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEMEALSTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseMealsRefundableDebitAccountNo(), ExpenseMealNonRefundableDebitAccountNo(), ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
            CreateExpenseCategories.GetEXPENSEENTERTAINTxt():
                AddExpensePostingGroupAccount(TempPostingGroup, ExpenseEntertainRefundableDebitAccountNo(), '', ExpensePrepaymentDebitAccountNo(), ExpenseDebitRoundingAccountNo(), ExpenseCreditRoundingAccountNo());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense Categories", 'OnBeforeUpdateEmployeePostingGroup', '', false, false)]
    local procedure OnBeforeUpdateEmployeePostingGroup(Code: Code[20]; var IsHandled: Boolean)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        IsHandled := true;
        if not EmployeePostingGroup.Get(Code) then
            exit;

        EmployeePostingGroup.Validate("Expense Report Payable Account", ExpenseReportPayableAccountNo());
        EmployeePostingGroup.Validate("Expense Payable Bank Paid Acc.", ExpensePayableBankPaidAccountNo());
        EmployeePostingGroup.Validate("Expense Payable Card Paid Acc.", ExpensePayableCardPaidAccountNo());
        EmployeePostingGroup.Validate("Exp. Report Prepayment Account", ExpenseReportPrepaymentAccountNo());
        EmployeePostingGroup.Modify(true);
    end;

    local procedure AddExpensePostingGroupAccount(var TempPostingGroup: Record "Expense Posting Group" temporary; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; DebitRoundingAccount: Code[20]; CreditRoundingAccount: Code[20])
    begin
        TempPostingGroup."Refundable Debit Account" := RefundableDebitAccount;
        TempPostingGroup."Non-Refundable Debit Account" := NonRefundableDebitAccount;
        TempPostingGroup."Prepayment Credit Account" := PrepaymentCreditAccount;
        TempPostingGroup."Debit Rounding Account" := DebitRoundingAccount;
        TempPostingGroup."Credit Rounding Account" := CreditRoundingAccount;
    end;

    local procedure ExpenseOtherRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherRefundableLbl, ExpenseOtherRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7740');
    end;

    local procedure ExpenseTravelRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseTravelRefundableLbl, ExpenseTravelRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7310');
    end;

    local procedure ExpensePerDiemARefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemARefundableLbl, ExpensePerDiemARefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7360');
    end;

    local procedure ExpensePerDiemIRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpensePerDiemIRefundableLbl, ExpensePerDiemIRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7350');
    end;

    local procedure ExpenseMileageRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMileageRefundableLbl, ExpenseMileageRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7340');
    end;

    local procedure ExpenseMealsRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealsRefundableLbl, ExpenseMealsRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7691');
    end;

    local procedure ExpenseEntertainRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseEntertainRefundableLbl, ExpenseEntertainRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7680');
    end;

    local procedure ExpenseMealNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseMealNonRefundableLbl, ExpenseMealNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7692');
    end;

    local procedure ExpenseOtherNonRefundableDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherNonRefundableLbl, ExpenseOtherNonRefundableSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('7745');
    end;

    local procedure ExpensePrepaymentDebitAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherPrepaymentLbl, ExpenseOtherPrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('2770');
    end;

    local procedure ExpenseDebitRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherDebitRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('8070');
    end;

    local procedure ExpenseCreditRoundingAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Expense, ExpenseOtherCreditRoundingLbl, ExpenseRoundingSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('8070');
    end;

    local procedure ExpenseReportPayableAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Liabilities, ExpensePayableCashLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('3680');
    end;

    local procedure ExpenseReportPrepaymentAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePrepaymentLbl, ExpensePrepaymentSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('2770');
    end;

    local procedure ExpensePayableBankPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableBankPaidLbl, ExpensePayableBankPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('2800');
    end;

    local procedure ExpensePayableCardPaidAccountNo(): Code[20]
    var
        ExistingAccNo: Code[20];
    begin
        ExistingAccNo := CreateExpenseGLAccount.FindExistingExpenseAccount("G/L Account Category"::Assets, ExpensePayableCardPaidLbl, ExpensePayableCardPaidSearchLbl);
        if ExistingAccNo <> '' then
            exit(ExistingAccNo);

        exit('2830');
    end;

    local procedure ExpensePerDiemI(): Code[20]
    begin
        exit(ExpensePERDIEMITok);
    end;

    local procedure ExpensePerDiemA(): Code[20]
    begin
        exit(ExpensePERDIEMATok);
    end;

    local procedure PerDiemI(): Code[20]
    begin
        exit(PerDiemITok);
    end;

    local procedure PerDiemA(): Code[20]
    begin
        exit(PerDiemATok);
    end;

    local procedure Country(): Code[20]
    begin
        exit(CountryTok);
    end;

    local procedure Intl(): Code[20]
    begin
        exit(IntlTok);
    end;

    var
        CreateExpenseGLAccount: Codeunit "Create Expense GL Account";
        CreateExpenseCategories: Codeunit "Create Expense Categories";
        ExpenseOtherRefundableLbl: Label 'Other', MaxLength = 100;
        ExpenseOtherRefundableSearchLbl: Label 'Other', MaxLength = 30;
        ExpenseMealNonRefundableLbl: Label 'Meal expenses, nondeductible', MaxLength = 100;
        ExpenseMealNonRefundableSearchLbl: Label 'Meal expenses, nondeductible', MaxLength = 30;
        ExpenseOtherNonRefundableLbl: Label 'Misc. external expenses, nondeductible', MaxLength = 100;
        ExpenseOtherNonRefundableSearchLbl: Label 'external expenses', MaxLength = 30;
        ExpenseOtherPrepaymentLbl: Label 'Settlement account cash bank', MaxLength = 100;
        ExpenseOtherPrepaymentSearchLbl: Label 'Settlement account cash', MaxLength = 30;
        ExpenseOtherDebitRoundingLbl: Label 'Application Rounding', MaxLength = 100;
        ExpenseOtherCreditRoundingLbl: Label 'Application Rounding', MaxLength = 100;
        ExpenseRoundingSearchLbl: Label 'Rounding', MaxLength = 30;
        ExpenseTravelRefundableLbl: Label 'Transportation third parties', MaxLength = 100;
        ExpenseTravelRefundableSearchLbl: Label 'Transportation third', MaxLength = 30;
        ExpensePerDiemARefundableLbl: Label 'Meal expenses abroad', MaxLength = 100;
        ExpensePerDiemARefundableSearchLbl: Label 'Meal expenses abroad', MaxLength = 30;
        ExpensePerDiemIRefundableLbl: Label 'Meal expenses domestic', MaxLength = 100;
        ExpensePerDiemIRefundableSearchLbl: Label 'Meal expenses domestic', MaxLength = 30;
        ExpenseMileageRefundableLbl: Label 'Kilometer allowance', MaxLength = 100;
        ExpenseMileageRefundableSearchLbl: Label 'Kilometer', MaxLength = 30;
        ExpenseMealsRefundableLbl: Label 'Meal expenses, deductible', MaxLength = 100;
        ExpenseMealsRefundableSearchLbl: Label 'Meals', MaxLength = 30;
        ExpenseEntertainRefundableLbl: Label 'Hospitality domestic deductible amount', MaxLength = 100;
        ExpenseEntertainRefundableSearchLbl: Label 'Hospitality domestic', MaxLength = 30;
        ExpensePayableCashLbl: Label 'Employees Payable', MaxLength = 100;
        ExpensePrepaymentLbl: Label 'Settlement account cash bank', MaxLength = 100;
        ExpensePrepaymentSearchLbl: Label 'Settlement account cash', MaxLength = 30;
        ExpensePayableCardPaidLbl: Label 'Company credit card clearing account', MaxLength = 100;
        ExpensePayableCardPaidSearchLbl: Label 'credit card', MaxLength = 30;
        ExpensePayableBankPaidLbl: Label 'Bank, LCY', MaxLength = 100;
        ExpensePayableBankPaidSearchLbl: Label 'Bank', MaxLength = 30;
        ExpensePERDIEMITok: Label 'EXPENSE-PERDIEM-I', MaxLength = 20, Locked = true;
        ExpensePerDiemInCountryLbl: Label 'Expense - Per Diem in country', MaxLength = 100;
        ExpensePERDIEMATok: Label 'EXPENSE-PERDIEM-A', MaxLength = 20, Locked = true;
        ExpensePerDiemAbroadLbl: Label 'Expense - Per Diem abroad', MaxLength = 100;
        PerDiemITok: Label 'PER-DIEM-I', MaxLength = 20, Locked = true;
        PerDiemATok: Label 'PER-DIEM-A', MaxLength = 20, Locked = true;
        PerDiemByAssignedPolicyLbl: Label 'Expenses for per-diem or daily allowance paid for business trips, typically based on travel itinerary or other proof of travel (e.g., booking or agenda), rather than individual expense receipts.', MaxLength = 250;
        PerDiemIByAssignedPolicyPostingLbl: Label 'Per-diem (international) by assigned policy', MaxLength = 100;
        PerDiemAByAssignedPolicyPostingLbl: Label 'Per-diem (local) by assigned policy', MaxLength = 100;
        CountryTok: Label 'COUNTRY', MaxLength = 20, Locked = true;
        IntlTok: Label 'INTL', MaxLength = 20, Locked = true;
        LocalCountryPerDiemLbl: Label 'Daily per-diem allowance based on domestic travel rates, paid instead of individual meal or incidental expense reimbursements.', MaxLength = 250;
        InternationalPerDiemLbl: Label 'Daily per-diem allowance for international business travel, based on applicable foreign travel rates.', MaxLength = 250;
        LocalCountryPerDiemPostingLbl: Label 'Local country per-diem', MaxLength = 100;
        InternationalPerDiemPostingLbl: Label 'International per-diem', MaxLength = 100;
}