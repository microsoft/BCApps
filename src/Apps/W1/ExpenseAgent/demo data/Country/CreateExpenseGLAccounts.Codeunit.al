// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

codeunit 8224 "Create Expense G/L Accounts"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Expense G/L Account", 'OnAfterAddGLAccountsForLocalization', '', false, false)]
    local procedure ModifyGLAccount()
    begin
        case CountryCode of
            'AT':
                ModifyGLAccountAT();
            'AU':
                ModifyGLAccountAU();
            'BE':
                ModifyGLAccountBE();
            'CA':
                ModifyGLAccountCA();
            'CH':
                ModifyGLAccountCH();
            'CZ':
                ModifyGLAccountCZ();
            'DE':
                ModifyGLAccountDE();
            'DK':
                ModifyGLAccountDK();
            'ES':
                ModifyGLAccountES();
            'FI':
                ModifyGLAccountFI();
            'FR':
                ModifyGLAccountFR();
            'GB':
                ModifyGLAccountGB();
            'IT':
                ModifyGLAccountIT();
            'NL':
                ModifyGLAccountNL();
            'NO':
                ModifyGLAccountNO();
            'NZ':
                ModifyGLAccountNZ();
            'US':
                ModifyGLAccountUS();
        end;
    end;

    local procedure ModifyGLAccountAT()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsAT();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsClearingAccountAT(), CompanyCreditCardsClearingAccountNameAT(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsAT()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsClearingAccountNameAT(), '2830');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '7691');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '7692');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '7745');
    end;


    procedure CompanyCreditCardsClearingAccountAT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsClearingAccountNameAT()));
    end;

    procedure CompanyCreditCardsClearingAccountNameAT(): Text[100]
    begin
        exit(CompanyCreditCardsClearingAccountATTok);
    end;

    local procedure ModifyGLAccountAU()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsAU();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.RentalVehiclesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.BusinessEntertainingNondeductibleAccount(), ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsAU()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '1025');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), '1512');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '6246');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '6247');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '6248');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '6237');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '6416');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '6415');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.RentalVehiclesAccountName(), '6250');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), '6236');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherTravelExpensesAccountName(), '6249');
    end;

    local procedure ModifyGLAccountBE()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsBE();

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeTravelAdvancesBE(), EmployeeTravelAdvancesNameBE(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearingBE(), CompanyPaidExpenseClearingNameBE(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CorporateCardExpenseClearingBE(), CorporateCardExpenseClearingNameBE(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(BusinessMealsBE(), BusinessMealsNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MileageAllowanceBE(), MileageAllowanceNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceBE(), PerDiemAllowanceNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpensesBE(), OtherEmployeeExpensesNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpensesBE(), NonRefundableEmployeeExpensesNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferencesBE(), ExpenseRoundingDifferencesNameBE(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsBE()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeTravelAdvancesNameBE(), '416000');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingNameBE(), '457100');
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpenseClearingNameBE(), '457200');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealsNameBE(), '613910');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceNameBE(), '613940');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameBE(), '613950');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesNameBE(), '623100');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesNameBE(), '643100');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesNameBE(), '655100');
    end;


    procedure EmployeeTravelAdvancesBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeTravelAdvancesNameBE()));
    end;

    procedure EmployeeTravelAdvancesNameBE(): Text[100]
    begin
        exit(EmployeeTravelAdvancesBETok);
    end;

    procedure CompanyPaidExpenseClearingBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingNameBE()));
    end;

    procedure CompanyPaidExpenseClearingNameBE(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingBETok);
    end;

    procedure CorporateCardExpenseClearingBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpenseClearingNameBE()));
    end;

    procedure CorporateCardExpenseClearingNameBE(): Text[100]
    begin
        exit(CorporateCardExpenseClearingBETok);
    end;

    procedure BusinessMealsBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealsNameBE()));
    end;

    procedure BusinessMealsNameBE(): Text[100]
    begin
        exit(BusinessMealsBETok);
    end;

    procedure MileageAllowanceBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageAllowanceNameBE()));
    end;

    procedure MileageAllowanceNameBE(): Text[100]
    begin
        exit(MileageAllowanceBETok);
    end;

    procedure PerDiemAllowanceBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameBE()));
    end;

    procedure PerDiemAllowanceNameBE(): Text[100]
    begin
        exit(PerDiemAllowanceBETok);
    end;

    procedure OtherEmployeeExpensesBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherEmployeeExpensesNameBE()));
    end;

    procedure OtherEmployeeExpensesNameBE(): Text[100]
    begin
        exit(OtherEmployeeExpensesBETok);
    end;

    procedure NonRefundableEmployeeExpensesBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonRefundableEmployeeExpensesNameBE()));
    end;

    procedure NonRefundableEmployeeExpensesNameBE(): Text[100]
    begin
        exit(NonRefundableEmployeeExpensesBETok);
    end;

    procedure ExpenseRoundingDifferencesBE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpenseRoundingDifferencesNameBE()));
    end;

    procedure ExpenseRoundingDifferencesNameBE(): Text[100]
    begin
        exit(ExpenseRoundingDifferencesBETok);
    end;

    local procedure ModifyGLAccountCA()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsCA();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsAccount(), ExpenseGLAccount.EmployeePrepaymentsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"Begin-Total", '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', false, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"End-Total", '', '', '', 0, ExpenseGLAccount.EmployeePrepaymentsAccount() + '..' + ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), Enum::"General Posting Type"::" ", '', '', false, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.RentalVehiclesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.BusinessEntertainingNondeductibleAccount(), ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsCA()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '11160');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsAccountName(), '13600');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), '13610');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), '13690');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '61310');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '61320');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '61330');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '67410');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '67420');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '67430');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.RentalVehiclesAccountName(), '63110');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.BusinessEntertainingNondeductibleAccountName(), '61120');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherTravelExpensesAccountName(), '61340');
    end;

    local procedure ModifyGLAccountCH()
    var
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsCH();

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseAdvancesCH(), EmployeeExpenseAdvancesNameCH(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseReimbursementsPayableCH(), EmployeeExpenseReimbursementsPayableNameCH(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyCardExpensesPayableCH(), CompanyCardExpensesPayableNameCH(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearingCH(), CompanyPaidExpenseClearingNameCH(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(MileageAllowanceCH(), MileageAllowanceNameCH(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceCH(), PerDiemAllowanceNameCH(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(EntertainmentExpensesCH(), EntertainmentExpensesNameCH(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MealsAndHospitalityExpensesCH(), MealsAndHospitalityExpensesNameCH(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsCH()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseAdvancesNameCH(), '1305');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseReimbursementsPayableNameCH(), '2270');
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpensesPayableNameCH(), '2271');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingNameCH(), '2272');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceNameCH(), '5821');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameCH(), '5822');
        ContosoGLAccount.AddAccountForLocalization(MealsAndHospitalityExpensesNameCH(), '5841');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesNameCH(), '5840');
    end;


    procedure EmployeeExpenseAdvancesCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseAdvancesNameCH()));
    end;

    procedure EmployeeExpenseAdvancesNameCH(): Text[100]
    begin
        exit(EmployeeExpenseAdvancesCHTok);
    end;

    procedure EmployeeExpenseReimbursementsPayableCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseReimbursementsPayableNameCH()));
    end;

    procedure EmployeeExpenseReimbursementsPayableNameCH(): Text[100]
    begin
        exit(EmployeeExpenseReimbursementsPayableCHTok);
    end;

    procedure CompanyCardExpensesPayableCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpensesPayableNameCH()));
    end;

    procedure CompanyCardExpensesPayableNameCH(): Text[100]
    begin
        exit(CompanyCardExpensesPayableCHTok);
    end;

    procedure CompanyPaidExpenseClearingCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingNameCH()));
    end;

    procedure CompanyPaidExpenseClearingNameCH(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingCHTok);
    end;

    procedure MileageAllowanceCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageAllowanceNameCH()));
    end;

    procedure MileageAllowanceNameCH(): Text[100]
    begin
        exit(MileageAllowanceCHTok);
    end;

    procedure PerDiemAllowanceCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameCH()));
    end;

    procedure PerDiemAllowanceNameCH(): Text[100]
    begin
        exit(PerDiemAllowanceCHTok);
    end;

    procedure EntertainmentExpensesCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesNameCH()));
    end;

    procedure EntertainmentExpensesNameCH(): Text[100]
    begin
        exit(EntertainmentExpensesCHTok);
    end;

    procedure MealsAndHospitalityExpensesCH(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealsAndHospitalityExpensesNameCH()));
    end;

    procedure MealsAndHospitalityExpensesNameCH(): Text[100]
    begin
        exit(MealsAndHospitalityExpensesCHTok);
    end;

    local procedure ModifyGLAccountCZ()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsCZ();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCardExpensesPayableCZ(), CompanyCardExpensesPayableNameCZ(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseAdvancesCZ(), EmployeeExpenseAdvancesNameCZ(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense);
        ContosoGLAccount.InsertGLAccount(MileageAllowanceCZ(), MileageAllowanceNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceCZ(), PerDiemAllowanceNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpensesCZ(), CarRentalExpensesNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MealsAndHospitalityExpensesCZ(), MealsAndHospitalityExpensesNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := '';
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpensesCZ(), NonRefundableEmployeeExpensesNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferencesCZ(), ExpenseRoundingDifferencesNameCZ(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsCZ()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpensesPayableNameCZ(), '325200');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseAdvancesNameCZ(), '335100');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceNameCZ(), '512200');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameCZ(), '512300');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesNameCZ(), '512400');
        ContosoGLAccount.AddAccountForLocalization(MealsAndHospitalityExpensesNameCZ(), '513200');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesNameCZ(), '548200');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesNameCZ(), '548900');
    end;


    procedure CompanyCardExpensesPayableCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpensesPayableNameCZ()));
    end;

    procedure CompanyCardExpensesPayableNameCZ(): Text[100]
    begin
        exit(CompanyCardExpensesPayableCZTok);
    end;

    procedure EmployeeExpenseAdvancesCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseAdvancesNameCZ()));
    end;

    procedure EmployeeExpenseAdvancesNameCZ(): Text[100]
    begin
        exit(EmployeeExpenseAdvancesCZTok);
    end;

    procedure MileageAllowanceCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageAllowanceNameCZ()));
    end;

    procedure MileageAllowanceNameCZ(): Text[100]
    begin
        exit(MileageAllowanceCZTok);
    end;

    procedure PerDiemAllowanceCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameCZ()));
    end;

    procedure PerDiemAllowanceNameCZ(): Text[100]
    begin
        exit(PerDiemAllowanceCZTok);
    end;

    procedure CarRentalExpensesCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CarRentalExpensesNameCZ()));
    end;

    procedure CarRentalExpensesNameCZ(): Text[100]
    begin
        exit(CarRentalExpensesCZTok);
    end;

    procedure MealsAndHospitalityExpensesCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MealsAndHospitalityExpensesNameCZ()));
    end;

    procedure MealsAndHospitalityExpensesNameCZ(): Text[100]
    begin
        exit(MealsAndHospitalityExpensesCZTok);
    end;

    procedure NonRefundableEmployeeExpensesCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonRefundableEmployeeExpensesNameCZ()));
    end;

    procedure NonRefundableEmployeeExpensesNameCZ(): Text[100]
    begin
        exit(NonRefundableEmployeeExpensesCZTok);
    end;

    procedure ExpenseRoundingDifferencesCZ(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpenseRoundingDifferencesNameCZ()));
    end;

    procedure ExpenseRoundingDifferencesNameCZ(): Text[100]
    begin
        exit(ExpenseRoundingDifferencesCZTok);
    end;

    local procedure ModifyGLAccountDE()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsDE();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsClearingAccountDE(), CompanyCreditCardsClearingAccountNameDE(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsDE()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsClearingAccountNameDE(), '3510');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '6664');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '6658');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '6662');
    end;


    procedure CompanyCreditCardsClearingAccountDE(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsClearingAccountNameDE()));
    end;

    procedure CompanyCreditCardsClearingAccountNameDE(): Text[100]
    begin
        exit(CompanyCreditCardsClearingAccountDETok);
    end;

    local procedure ModifyGLAccountDK()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsDK();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsDK(), CompanyCreditCardsNameDK(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(TravelAllowancesPerDiemDK(), TravelAllowancesPerDiemNameDK(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(NonDeductibleTravelExpensesDK(), NonDeductibleTravelExpensesNameDK(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RentalCarExpensesDK(), RentalCarExpensesNameDK(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherExpensesDK(), OtherExpensesNameDK(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsDK()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsNameDK(), '18300');
        ContosoGLAccount.AddAccountForLocalization(TravelAllowancesPerDiemNameDK(), '03652');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '03661');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleTravelExpensesNameDK(), '03655');
        ContosoGLAccount.AddAccountForLocalization(RentalCarExpensesNameDK(), '03654');
        ContosoGLAccount.AddAccountForLocalization(OtherExpensesNameDK(), '05699');
    end;


    procedure CompanyCreditCardsDK(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsNameDK()));
    end;

    procedure CompanyCreditCardsNameDK(): Text[100]
    begin
        exit(CompanyCreditCardsDKTok);
    end;

    procedure TravelAllowancesPerDiemDK(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(TravelAllowancesPerDiemNameDK()));
    end;

    procedure TravelAllowancesPerDiemNameDK(): Text[100]
    begin
        exit(TravelAllowancesPerDiemDKTok);
    end;

    procedure RentalCarExpensesDK(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalCarExpensesNameDK()));
    end;

    procedure RentalCarExpensesNameDK(): Text[100]
    begin
        exit(RentalCarExpensesDKTok);
    end;

    procedure NonDeductibleTravelExpensesDK(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonDeductibleTravelExpensesNameDK()));
    end;

    procedure NonDeductibleTravelExpensesNameDK(): Text[100]
    begin
        exit(NonDeductibleTravelExpensesDKTok);
    end;

    procedure OtherExpensesDK(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherExpensesNameDK()));
    end;

    procedure OtherExpensesNameDK(): Text[100]
    begin
        exit(OtherExpensesDKTok);
    end;

    local procedure ModifyGLAccountES()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsES();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsClearingAccountES(), CompanyCreditCardsClearingAccountNameES(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpensesPrepaymentsES(), ExpensesPrepaymentsNameES(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RentalCarExpensesES(), RentalCarExpensesNameES(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(TravelExpensesES(), TravelExpensesNameES(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EntertainmentExpensesAccountES(), EntertainmentExpensesAccountNameES(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RoundingExpensesOperatingAccountES(), RoundingExpensesOperatingAccountNameES(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        UpdateIncomeStatementBalanceAccountES();
    end;

    local procedure AddGLAccountsES()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsClearingAccountNameES(), '5721001');
        ContosoGLAccount.AddAccountForLocalization(ExpensesPrepaymentsNameES(), '4800001');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '6291002');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '6291003');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '6292001');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '6292002');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '6299001');
        ContosoGLAccount.AddAccountForLocalization(RentalCarExpensesNameES(), '6291004');
        ContosoGLAccount.AddAccountForLocalization(TravelExpensesNameES(), '6291001');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesAccountNameES(), '6293001');
        ContosoGLAccount.AddAccountForLocalization(RoundingExpensesOperatingAccountNameES(), '6298001');
    end;

    local procedure UpdateIncomeStatementBalanceAccountES()
    begin
        UpdateIncomeStmtBalAccES(CompanyCreditCardsClearingAccountES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpensesPrepaymentsES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(RentalCarExpensesES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(TravelExpensesES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(EntertainmentExpensesAccountES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
        UpdateIncomeStmtBalAccES(RoundingExpensesOperatingAccountES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.ProfitOrLossName()));
    end;

    local procedure UpdateIncomeStmtBalAccES(No: Code[20]; IncomeStmtBalAcc: Code[20])
    var
        GLAccount: Record "G/L Account";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        i: Integer;
    begin
        // "Income Stmt. Bal. Acc." is added by the ES localization to table G/L Account.
        // Look it up dynamically via FieldRef so this demo data works without an ES-loc
        // compile-time dependency; silently skip when the field is not present.
        if not GLAccount.Get(No) then
            exit;

        RecRef.GetTable(GLAccount);
        for i := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(i);
            if FieldRef.Name = 'Income Stmt. Bal. Acc.' then begin
                FieldRef.Validate(IncomeStmtBalAcc);
                RecRef.Modify();
                exit;
            end;
        end;
    end;


    procedure CompanyCreditCardsClearingAccountES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsClearingAccountNameES()));
    end;

    procedure CompanyCreditCardsClearingAccountNameES(): Text[100]
    begin
        exit(CompanyCreditCardsClearingAccountESTok);
    end;

    procedure TravelExpensesES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(TravelExpensesNameES()));
    end;

    procedure TravelExpensesNameES(): Text[100]
    begin
        exit(TravelExpensesESTok);
    end;

    procedure ExpensesPrepaymentsES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpensesPrepaymentsNameES()));
    end;

    procedure ExpensesPrepaymentsNameES(): Text[100]
    begin
        exit(ExpensesPrepaymentsESTok);
    end;

    procedure RentalCarExpensesES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalCarExpensesNameES()));
    end;

    procedure RentalCarExpensesNameES(): Text[100]
    begin
        exit(RentalCarExpensesESTok);
    end;

    procedure EntertainmentExpensesAccountES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesAccountNameES()));
    end;

    procedure EntertainmentExpensesAccountNameES(): Text[100]
    begin
        exit(EntertainmentExpensesESTok);
    end;

    procedure RoundingExpensesOperatingAccountES(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RoundingExpensesOperatingAccountNameES()));
    end;

    procedure RoundingExpensesOperatingAccountNameES(): Text[100]
    begin
        exit(RoundingExpensesOperatingESTok);
    end;

    local procedure ModifyGLAccountFI()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsFI();

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(CompanyCardExpenseClearingFI(), CompanyCardExpenseClearingNameFI(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearingFI(), CompanyPaidExpenseClearingNameFI(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(BusinessMealExpensesFI(), BusinessMealExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(MileageAllowanceFI(), MileageAllowanceNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceFI(), PerDiemAllowanceNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpensesFI(), CarRentalExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherTravelExpensesFI(), OtherTravelExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        ContosoGLAccount.InsertGLAccount(EntertainmentExpensesFI(), EntertainmentExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpensesFI(), OtherEmployeeExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpensesFI(), NonRefundableEmployeeExpensesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferencesFI(), ExpenseRoundingDifferencesNameFI(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsFI()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCardExpenseClearingNameFI(), '2916');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingNameFI(), '2917');
        ContosoGLAccount.AddAccountForLocalization(EntertainmentExpensesNameFI(), '6160');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealExpensesNameFI(), '6161');
        ContosoGLAccount.AddAccountForLocalization(MileageAllowanceNameFI(), '6162');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameFI(), '6163');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesNameFI(), '6164');
        ContosoGLAccount.AddAccountForLocalization(OtherTravelExpensesNameFI(), '6165');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesNameFI(), '6166');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesNameFI(), '6167');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesNameFI(), '6168');
    end;


    procedure CompanyCardExpenseClearingFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCardExpenseClearingNameFI()));
    end;

    procedure CompanyCardExpenseClearingNameFI(): Text[100]
    begin
        exit(CompanyCardExpenseClearingFITok);
    end;

    procedure CompanyPaidExpenseClearingFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingNameFI()));
    end;

    procedure CompanyPaidExpenseClearingNameFI(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingFITok);
    end;

    procedure EntertainmentExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EntertainmentExpensesNameFI()));
    end;

    procedure EntertainmentExpensesNameFI(): Text[100]
    begin
        exit(EntertainmentExpensesFITok);
    end;

    procedure BusinessMealExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealExpensesNameFI()));
    end;

    procedure BusinessMealExpensesNameFI(): Text[100]
    begin
        exit(BusinessMealExpensesFITok);
    end;

    procedure MileageAllowanceFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageAllowanceNameFI()));
    end;

    procedure MileageAllowanceNameFI(): Text[100]
    begin
        exit(MileageAllowanceFITok);
    end;

    procedure PerDiemAllowanceFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameFI()));
    end;

    procedure PerDiemAllowanceNameFI(): Text[100]
    begin
        exit(PerDiemAllowanceFITok);
    end;

    procedure CarRentalExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CarRentalExpensesNameFI()));
    end;

    procedure CarRentalExpensesNameFI(): Text[100]
    begin
        exit(CarRentalExpensesFITok);
    end;

    procedure OtherTravelExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherTravelExpensesNameFI()));
    end;

    procedure OtherTravelExpensesNameFI(): Text[100]
    begin
        exit(OtherTravelExpensesFITok);
    end;

    procedure OtherEmployeeExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherEmployeeExpensesNameFI()));
    end;

    procedure OtherEmployeeExpensesNameFI(): Text[100]
    begin
        exit(OtherEmployeeExpensesFITok);
    end;

    procedure NonRefundableEmployeeExpensesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonRefundableEmployeeExpensesNameFI()));
    end;

    procedure NonRefundableEmployeeExpensesNameFI(): Text[100]
    begin
        exit(NonRefundableEmployeeExpensesFITok);
    end;

    procedure ExpenseRoundingDifferencesFI(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpenseRoundingDifferencesNameFI()));
    end;

    procedure ExpenseRoundingDifferencesNameFI(): Text[100]
    begin
        exit(ExpenseRoundingDifferencesFITok);
    end;

    local procedure ModifyGLAccountFR()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsFR();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(CompanyCreditCardsFR(), CompanyCreditCardsNameFR(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpensePrepaymentAccountFR(), ExpensePrepaymentAccountNameFR(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(RentalCarExpensesFR(), RentalCarExpensesNameFR(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherTravelExpensesAccount(), ExpenseGLAccount.OtherTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsFR()
    begin
        ContosoGLAccount.AddAccountForLocalization(CompanyCreditCardsNameFR(), '512900');
        ContosoGLAccount.AddAccountForLocalization(ExpensePrepaymentAccountNameFR(), '486200');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '625110');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '625120');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '625200');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '625210');
        ContosoGLAccount.AddAccountForLocalization(RentalCarExpensesNameFR(), '625130');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherTravelExpensesAccountName(), '625180');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '625290');
    end;


    procedure CompanyCreditCardsFR(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyCreditCardsNameFR()));
    end;

    procedure CompanyCreditCardsNameFR(): Text[100]
    begin
        exit(CompanyCreditCardsFRTok);
    end;

    procedure ExpensePrepaymentAccountFR(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpensePrepaymentAccountNameFR()));
    end;

    procedure ExpensePrepaymentAccountNameFR(): Text[100]
    begin
        exit(ExpensePrepaymentAccountFRTok);
    end;

    procedure RentalCarExpensesFR(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(RentalCarExpensesNameFR()));
    end;

    procedure RentalCarExpensesNameFR(): Text[100]
    begin
        exit(RentalCarExpensesFRTok);
    end;

    local procedure ModifyGLAccountGB()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsGB();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsGB()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '78410');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '30550');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '30560');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '30535');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '30840');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '30850');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '31545');
    end;

    local procedure ModifyGLAccountIT()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsIT();

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeAdvancesPrepaymentsIT(), EmployeeAdvancesPrepaymentsNameIT(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpenseReimbursementPayableIT(), EmployeeExpenseReimbursementPayableNameIT(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CorporateCardExpenseClearingIT(), CorporateCardExpenseClearingNameIT(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CompanyPaidExpenseClearingIT(), CompanyPaidExpenseClearingNameIT(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceIT(), PerDiemAllowanceNameIT(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(CarRentalExpensesIT(), CarRentalExpensesNameIT(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonDeductibleEmployeeExpensesIT(), NonDeductibleEmployeeExpensesNameIT(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsIT()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeAdvancesPrepaymentsNameIT(), '2341');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpenseReimbursementPayableNameIT(), '5851');
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpenseClearingNameIT(), '5852');
        ContosoGLAccount.AddAccountForLocalization(CompanyPaidExpenseClearingNameIT(), '5853');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameIT(), '8431');
        ContosoGLAccount.AddAccountForLocalization(CarRentalExpensesNameIT(), '8432');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleEmployeeExpensesNameIT(), '8911');
    end;


    procedure EmployeeAdvancesPrepaymentsIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeAdvancesPrepaymentsNameIT()));
    end;

    procedure EmployeeAdvancesPrepaymentsNameIT(): Text[100]
    begin
        exit(EmployeeAdvancesPrepaymentsITTok);
    end;

    procedure EmployeeExpenseReimbursementPayableIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpenseReimbursementPayableNameIT()));
    end;

    procedure EmployeeExpenseReimbursementPayableNameIT(): Text[100]
    begin
        exit(EmployeeExpenseReimbursementPayableITTok);
    end;

    procedure CorporateCardExpenseClearingIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpenseClearingNameIT()));
    end;

    procedure CorporateCardExpenseClearingNameIT(): Text[100]
    begin
        exit(CorporateCardExpenseClearingITTok);
    end;

    procedure CompanyPaidExpenseClearingIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CompanyPaidExpenseClearingNameIT()));
    end;

    procedure CompanyPaidExpenseClearingNameIT(): Text[100]
    begin
        exit(CompanyPaidExpenseClearingITTok);
    end;

    procedure PerDiemAllowanceIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameIT()));
    end;

    procedure PerDiemAllowanceNameIT(): Text[100]
    begin
        exit(PerDiemAllowanceITTok);
    end;

    procedure CarRentalExpensesIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CarRentalExpensesNameIT()));
    end;

    procedure CarRentalExpensesNameIT(): Text[100]
    begin
        exit(CarRentalExpensesITTok);
    end;

    procedure NonDeductibleEmployeeExpensesIT(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonDeductibleEmployeeExpensesNameIT()));
    end;

    procedure NonDeductibleEmployeeExpensesNameIT(): Text[100]
    begin
        exit(NonDeductibleEmployeeExpensesITTok);
    end;

    local procedure ModifyGLAccountNL()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsNL();

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(CorporateCardExpensePayableNL(), CorporateCardExpensePayableNameNL(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(BankPaidExpenseClearingNL(), BankPaidExpenseClearingNameNL(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetTravelExpense(), 80);
        ContosoGLAccount.InsertGLAccount(MileageReimbursementNL(), MileageReimbursementNameNL(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(PerDiemAllowanceNL(), PerDiemAllowanceNameNL(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(BusinessMealsAndEntertainmentNL(), BusinessMealsAndEntertainmentNameNL(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(OtherEmployeeExpensesNL(), OtherEmployeeExpensesNameNL(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonDeductibleEmployeeExpensesNL(), NonDeductibleEmployeeExpensesNameNL(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsNL()
    begin
        ContosoGLAccount.AddAccountForLocalization(CorporateCardExpensePayableNameNL(), '1521');
        ContosoGLAccount.AddAccountForLocalization(BankPaidExpenseClearingNameNL(), '1522');
        ContosoGLAccount.AddAccountForLocalization(MileageReimbursementNameNL(), '3465');
        ContosoGLAccount.AddAccountForLocalization(PerDiemAllowanceNameNL(), '3466');
        ContosoGLAccount.AddAccountForLocalization(BusinessMealsAndEntertainmentNameNL(), '3564');
        ContosoGLAccount.AddAccountForLocalization(OtherEmployeeExpensesNameNL(), '4291');
        ContosoGLAccount.AddAccountForLocalization(NonDeductibleEmployeeExpensesNameNL(), '4292');
    end;


    procedure CorporateCardExpensePayableNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(CorporateCardExpensePayableNameNL()));
    end;

    procedure CorporateCardExpensePayableNameNL(): Text[100]
    begin
        exit(CorporateCardExpensePayableNLTok);
    end;

    procedure BankPaidExpenseClearingNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BankPaidExpenseClearingNameNL()));
    end;

    procedure BankPaidExpenseClearingNameNL(): Text[100]
    begin
        exit(BankPaidExpenseClearingNLTok);
    end;

    procedure MileageReimbursementNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(MileageReimbursementNameNL()));
    end;

    procedure MileageReimbursementNameNL(): Text[100]
    begin
        exit(MileageReimbursementNLTok);
    end;

    procedure PerDiemAllowanceNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(PerDiemAllowanceNameNL()));
    end;

    procedure PerDiemAllowanceNameNL(): Text[100]
    begin
        exit(PerDiemAllowanceNLTok);
    end;

    procedure BusinessMealsAndEntertainmentNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(BusinessMealsAndEntertainmentNameNL()));
    end;

    procedure BusinessMealsAndEntertainmentNameNL(): Text[100]
    begin
        exit(BusinessMealsAndEntertainmentNLTok);
    end;

    procedure OtherEmployeeExpensesNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(OtherEmployeeExpensesNameNL()));
    end;

    procedure OtherEmployeeExpensesNameNL(): Text[100]
    begin
        exit(OtherEmployeeExpensesNLTok);
    end;

    procedure NonDeductibleEmployeeExpensesNL(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonDeductibleEmployeeExpensesNameNL()));
    end;

    procedure NonDeductibleEmployeeExpensesNameNL(): Text[100]
    begin
        exit(NonDeductibleEmployeeExpensesNLTok);
    end;

    local procedure ModifyGLAccountNO()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        SubCategory: Text[80];
    begin
        AddGLAccountsNO();

        SubCategory := Format(GLAccountCategoryMgt.GetCash(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCashNO(), EmployeeExpensePayableCashNameNO(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCardNO(), EmployeeExpensePayableCardNameNO(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePayableCompanyPaidNO(), EmployeeExpensePayableCompanyPaidNameNO(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategoryMgt.GetPrepaidExpenses(), 80);
        ContosoGLAccount.InsertGLAccount(EmployeeExpensePrepaymentsNO(), EmployeeExpensePrepaymentsNameNO(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Income, 80);
        ContosoGLAccount.InsertGLAccount(NonRefundableEmployeeExpensesNO(), NonRefundableEmployeeExpensesNameNO(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseRoundingDifferencesNO(), ExpenseRoundingDifferencesNameNO(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Income, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
    end;

    local procedure AddGLAccountsNO()
    begin
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCashNameNO(), '5960');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCardNameNO(), '5961');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePayableCompanyPaidNameNO(), '5962');
        ContosoGLAccount.AddAccountForLocalization(EmployeeExpensePrepaymentsNameNO(), '5963');
        ContosoGLAccount.AddAccountForLocalization(NonRefundableEmployeeExpensesNameNO(), '5964');
        ContosoGLAccount.AddAccountForLocalization(ExpenseRoundingDifferencesNameNO(), '5965');
    end;


    procedure EmployeeExpensePayableCashNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCashNameNO()));
    end;

    procedure EmployeeExpensePayableCashNameNO(): Text[100]
    begin
        exit(EmployeeExpensePayableCashNOTok);
    end;

    procedure EmployeeExpensePayableCardNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCardNameNO()));
    end;

    procedure EmployeeExpensePayableCardNameNO(): Text[100]
    begin
        exit(EmployeeExpensePayableCardNOTok);
    end;

    procedure EmployeeExpensePayableCompanyPaidNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePayableCompanyPaidNameNO()));
    end;

    procedure EmployeeExpensePayableCompanyPaidNameNO(): Text[100]
    begin
        exit(EmployeeExpensePayableCompanyPaidNOTok);
    end;

    procedure EmployeeExpensePrepaymentsNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(EmployeeExpensePrepaymentsNameNO()));
    end;

    procedure EmployeeExpensePrepaymentsNameNO(): Text[100]
    begin
        exit(EmployeeExpensePrepaymentsNOTok);
    end;

    procedure NonRefundableEmployeeExpensesNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(NonRefundableEmployeeExpensesNameNO()));
    end;

    procedure NonRefundableEmployeeExpensesNameNO(): Text[100]
    begin
        exit(NonRefundableEmployeeExpensesNOTok);
    end;

    procedure ExpenseRoundingDifferencesNO(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(ExpenseRoundingDifferencesNameNO()));
    end;

    procedure ExpenseRoundingDifferencesNameNO(): Text[100]
    begin
        exit(ExpenseRoundingDifferencesNOTok);
    end;

    local procedure ModifyGLAccountNZ()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsNZ();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsAccount(), ExpenseGLAccount.EmployeePrepaymentsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"Begin-Total", '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', false, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::"End-Total", '', '', '', 0, ExpenseGLAccount.EmployeePrepaymentsAccount() + '..' + ExpenseGLAccount.EmployeePrepaymentsTotalAccount(), Enum::"General Posting Type"::" ", '', '', false, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.RentalVehiclesAccount(), ExpenseGLAccount.RentalVehiclesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsNZ()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '2950');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsAccountName(), '2500');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsExpensesAccountName(), '2510');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.EmployeePrepaymentsTotalAccountName(), '2590');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '8431');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '8432');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '8433');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '8421');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '8650');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '8660');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.RentalVehiclesAccountName(), '8435');
    end;

    local procedure ModifyGLAccountUS()
    var
        GLAccountCategory: Record "G/L Account Category";
        SubCategory: Text[80];
    begin
        AddGLAccountsUS();

        SubCategory := Format(GLAccountCategory."Account Category"::Assets, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.CompanyCreditCardsAccount(), ExpenseGLAccount.CompanyCreditCardsAccountName(), "G/L Account Income/Balance"::"Balance Sheet", Enum::"G/L Account Category"::Assets, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::" ", '', '', true, false, false);

        SubCategory := Format(GLAccountCategory."Account Category"::Expense, 80);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.PerDiemTravelExpensesAccount(), ExpenseGLAccount.PerDiemTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MileageTravelExpensesAccount(), ExpenseGLAccount.MileageTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.MealExpensesDeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MealExpensesNondeductibleAccount(), ExpenseGLAccount.MealExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccount(), ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
        ContosoGLAccount.InsertGLAccount(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccount(), ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, SubCategory, Enum::"G/L Account Type"::Posting, '', '', '', 0, '', Enum::"General Posting Type"::Purchase, '', '', true, false, false);
    end;

    local procedure AddGLAccountsUS()
    begin
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.CompanyCreditCardsAccountName(), '18600');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.PerDiemTravelExpensesAccountName(), '62350');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MileageTravelExpensesAccountName(), '62360');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesDeductibleAccountName(), '62370');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MealExpensesNondeductibleAccountName(), '62380');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.OtherNondeductibleTravelExpensesAccountName(), '62390');
        ContosoGLAccount.AddAccountForLocalization(ExpenseGLAccount.MiscExternalExpensesNondeductibleAccountName(), '68285');
    end;

    procedure SetCountryCode(NewCountryCode: Code[10])
    begin
        CountryCode := NewCountryCode;
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        CountryCode: Code[10];
        CompanyCreditCardsClearingAccountATTok: Label 'Company credit card clearing account', MaxLength = 100;
        EmployeeTravelAdvancesBETok: Label 'Employee Travel Advances', MaxLength = 100;
        CompanyPaidExpenseClearingBETok: Label 'Company Paid Expense Clearing', MaxLength = 100;
        CorporateCardExpenseClearingBETok: Label 'Corporate Card Expense Clearing', MaxLength = 100;
        BusinessMealsBETok: Label 'Business Meals', MaxLength = 100;
        MileageAllowanceBETok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceBETok: Label 'Per-Diem Allowance', MaxLength = 100;
        OtherEmployeeExpensesBETok: Label 'Other Employee Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesBETok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesBETok: Label 'Expense Rounding Differences', MaxLength = 100;
        EmployeeExpenseAdvancesCHTok: Label 'Employee Expense Advances', MaxLength = 100;
        EmployeeExpenseReimbursementsPayableCHTok: Label 'Employee Expense Reimbursements Payable', MaxLength = 100;
        CompanyCardExpensesPayableCHTok: Label 'Company Card Expenses Payable', MaxLength = 100;
        CompanyPaidExpenseClearingCHTok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        MileageAllowanceCHTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceCHTok: Label 'Per Diem Allowance', MaxLength = 100;
        EntertainmentExpensesCHTok: Label 'Entertainment Expenses', MaxLength = 100;
        MealsAndHospitalityExpensesCHTok: Label 'Meals and Hospitality Expenses', MaxLength = 100;
        CompanyCardExpensesPayableCZTok: Label 'Company Card Expenses Payable', MaxLength = 100;
        EmployeeExpenseAdvancesCZTok: Label 'Employee Expense Advances', MaxLength = 100;
        MileageAllowanceCZTok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceCZTok: Label 'Per Diem Allowance', MaxLength = 100;
        CarRentalExpensesCZTok: Label 'Car Rental Expenses', MaxLength = 100;
        MealsAndHospitalityExpensesCZTok: Label 'Meals and Hospitality Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesCZTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesCZTok: Label 'Expense Rounding Differences', MaxLength = 100;
        CompanyCreditCardsClearingAccountDETok: Label 'Company credit card clearing account', MaxLength = 100;
        CompanyCreditCardsDKTok: Label 'Company credit cards', MaxLength = 100;
        TravelAllowancesPerDiemDKTok: Label 'Travel allowances (per diem)', MaxLength = 100;
        RentalCarExpensesDKTok: Label 'Rental car expenses', MaxLength = 100;
        NonDeductibleTravelExpensesDKTok: Label 'Non-deductible travel expenses', MaxLength = 100;
        OtherExpensesDKTok: Label 'Other expenses', MaxLength = 100;
        CompanyCreditCardsClearingAccountESTok: Label 'Company credit card clearing account', MaxLength = 100;
        TravelExpensesESTok: Label 'Travel expenses', MaxLength = 100;
        ExpensesPrepaymentsESTok: Label 'Expenses Prepayments', MaxLength = 100;
        RentalCarExpensesESTok: Label 'Rental Car Expenses', MaxLength = 100;
        EntertainmentExpensesESTok: Label 'Entertainment expenses', MaxLength = 100;
        RoundingExpensesOperatingESTok: Label 'Rounding Expenses (Operating)', MaxLength = 100;
        CompanyCardExpenseClearingFITok: Label 'Company Card Expense Clearing', MaxLength = 100;
        CompanyPaidExpenseClearingFITok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        EntertainmentExpensesFITok: Label 'Entertainment Expenses', MaxLength = 100;
        BusinessMealExpensesFITok: Label 'Business Meal Expenses', MaxLength = 100;
        MileageAllowanceFITok: Label 'Mileage Allowance', MaxLength = 100;
        PerDiemAllowanceFITok: Label 'Per-Diem Allowance', MaxLength = 100;
        CarRentalExpensesFITok: Label 'Car Rental Expenses', MaxLength = 100;
        OtherTravelExpensesFITok: Label 'Other Travel Expenses', MaxLength = 100;
        OtherEmployeeExpensesFITok: Label 'Other Employee Expenses', MaxLength = 100;
        NonRefundableEmployeeExpensesFITok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesFITok: Label 'Expense Rounding Differences', MaxLength = 100;
        CompanyCreditCardsFRTok: Label 'Company credit cards', MaxLength = 100;
        ExpensePrepaymentAccountFRTok: Label 'Expense prepayment account', MaxLength = 100;
        RentalCarExpensesFRTok: Label 'Rental car expenses', MaxLength = 100;
        EmployeeAdvancesPrepaymentsITTok: Label 'Employee Advances and Expense Prepayments', MaxLength = 100;
        EmployeeExpenseReimbursementPayableITTok: Label 'Employee Expense Reimbursement Payable', MaxLength = 100;
        CorporateCardExpenseClearingITTok: Label 'Corporate Card Expense Clearing', MaxLength = 100;
        CompanyPaidExpenseClearingITTok: Label 'Company-Paid Expense Clearing', MaxLength = 100;
        PerDiemAllowanceITTok: Label 'Per Diem Allowance', MaxLength = 100;
        CarRentalExpensesITTok: Label 'Car Rental Expenses', MaxLength = 100;
        NonDeductibleEmployeeExpensesITTok: Label 'Non-Deductible Employee Expenses', MaxLength = 100;
        CorporateCardExpensePayableNLTok: Label 'Corporate Card Expense Payable', MaxLength = 100;
        BankPaidExpenseClearingNLTok: Label 'Bank-Paid Expense Clearing Account', MaxLength = 100;
        MileageReimbursementNLTok: Label 'Mileage Reimbursement', MaxLength = 100;
        PerDiemAllowanceNLTok: Label 'Per Diem Allowance', MaxLength = 100;
        BusinessMealsAndEntertainmentNLTok: Label 'Business Meals and Entertainment', MaxLength = 100;
        OtherEmployeeExpensesNLTok: Label 'Other Employee Expenses', MaxLength = 100;
        NonDeductibleEmployeeExpensesNLTok: Label 'Non-Deductible Employee Expenses', MaxLength = 100;
        EmployeeExpensePayableCashNOTok: Label 'Employee Expense Payable - Cash Reimbursement', MaxLength = 100;
        EmployeeExpensePayableCardNOTok: Label 'Employee Expense Payable - Company Card', MaxLength = 100;
        EmployeeExpensePayableCompanyPaidNOTok: Label 'Employee Expense Payable - Company Paid', MaxLength = 100;
        EmployeeExpensePrepaymentsNOTok: Label 'Employee Expense Prepayments', MaxLength = 100;
        NonRefundableEmployeeExpensesNOTok: Label 'Non-Refundable Employee Expenses', MaxLength = 100;
        ExpenseRoundingDifferencesNOTok: Label 'Expense Rounding Differences', MaxLength = 100;
}