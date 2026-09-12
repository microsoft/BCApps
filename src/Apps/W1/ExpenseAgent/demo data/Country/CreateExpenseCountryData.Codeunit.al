// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.HumanResources;
using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;
using Microsoft.HumanResources.Employee;

codeunit 8222 "Create Expense Country Data"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Expense Per Diem" = rim;

    procedure CreateSetupData()
    var
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode();
        BindSetupSubscribers(CountryCode);

        Codeunit.Run(Codeunit::"Create Expense Payment Method");
        Codeunit.Run(Codeunit::"Create Expense No. Series DM");
        Codeunit.Run(Codeunit::"Create Expense Group");
        Codeunit.Run(Codeunit::"Create Expense G/L Account");
        Codeunit.Run(Codeunit::"Create Expense Posting Group");
        Codeunit.Run(Codeunit::"Create Expense Team");
        Codeunit.Run(Codeunit::"Create Exp. Agent Setup");

        UpdateEmployeePostingGroup(CountryCode);
        InsertExpensePostingGroups(CountryCode);

        UnbindSetupSubscribers();
    end;

    local procedure UpdateEmployeePostingGroup(CountryCode: Code[10])
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        HRGLAccount: Codeunit "Create HR GL Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        ExpenseGLAccountNames: Codeunit "Expense GL Account Names";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateEmployeePostingGroup: Codeunit "Create Employee Posting Group";
    begin
        ContosoExpenseAgent.SetOverwriteData(true);
        case CountryCode of
            'AT':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.SettlementAccountCashBankName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), CreateExpenseGLAccounts.CompanyCreditCardsClearingAccountAT());
            'AU':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EmployeesPayableName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), ExpenseGLAccount.CompanyCreditCardsAccount());
            'BE':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EmployeesPayableName()), CreateExpenseGLAccounts.EmployeeTravelAdvancesBE(), CreateExpenseGLAccounts.CompanyPaidExpenseClearingBE(), CreateExpenseGLAccounts.CorporateCardExpenseClearingBE());
            'CA':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.VacationCompensationPayableName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(BankCheckingLbl), ExpenseGLAccount.CompanyCreditCardsAccount());
            'CH':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpenseGLAccounts.EmployeeExpenseReimbursementsPayableCH(), CreateExpenseGLAccounts.EmployeeExpenseAdvancesCH(), CreateExpenseGLAccounts.CompanyPaidExpenseClearingCH(), CreateExpenseGLAccounts.CompanyCardExpensesPayableCH());
            'CZ':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayablesToEmployeesName()), CreateExpenseGLAccounts.EmployeeExpenseAdvancesCZ(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BankAccountKBName()), CreateExpenseGLAccounts.CompanyCardExpensesPayableCZ());
            'DE':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(HRGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AssetsintheformofprepaidexpensesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BusinessaccountOperatingDomesticName()), CreateExpenseGLAccounts.CompanyCreditCardsClearingAccountDE());
            'DK':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AccountsPayablePostingName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PrepaymentsAccruedCostsName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BankName()), CreateExpenseGLAccounts.CompanyCreditCardsDK());
            'ES':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.RemunerationAdvancesName()), CreateExpenseGLAccounts.ExpensesPrepaymentsES(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.BanksEuroName()), CreateExpenseGLAccounts.CompanyCreditCardsClearingAccountES());
            'FI':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.Otherreceivables1Name()), CreateExpenseGLAccounts.CompanyPaidExpenseClearingFI(), CreateExpenseGLAccounts.CompanyCardExpenseClearingFI());
            'FR':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EmployeesPayableName()), CreateExpenseGLAccounts.ExpensePrepaymentAccountFR(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLcyName()), CreateExpenseGLAccounts.CompanyCreditCardsFR());
            'GB':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EmployeesPayableName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.CashName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherBankAccountsName()), ExpenseGLAccount.CompanyCreditCardsAccount());
            'IT':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpenseGLAccounts.EmployeeExpenseReimbursementPayableIT(), CreateExpenseGLAccounts.EmployeeAdvancesPrepaymentsIT(), CreateExpenseGLAccounts.CompanyPaidExpenseClearingIT(), CreateExpenseGLAccounts.CorporateCardExpenseClearingIT());
            'NL':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentLiabilitiesToEmployeesName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.CurrentReceivableFromEmployeesName()), CreateExpenseGLAccounts.BankPaidExpenseClearingNL(), CreateExpenseGLAccounts.CorporateCardExpensePayableNL());
            'NO':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), CreateExpenseGLAccounts.EmployeeExpensePayableCashNO(), CreateExpenseGLAccounts.EmployeeExpensePrepaymentsNO(), CreateExpenseGLAccounts.EmployeeExpensePayableCompanyPaidNO(), CreateExpenseGLAccounts.EmployeeExpensePayableCardNO());
            'NZ':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.EmployeesPayableName()), ExpenseGLAccount.EmployeePrepaymentsExpensesAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.BankLCYName()), ExpenseGLAccount.CompanyCreditCardsAccount());
            'US':
                ContosoExpenseAgent.UpdateEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.AccountsPayableDomesticName()), ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.CashName()), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.OtherBankAccountsName()), ExpenseGLAccount.CompanyCreditCardsAccount());
        end;
        ContosoExpenseAgent.SetOverwriteData(false);

        if CountryCode = 'CZ' then
            UpdatePayablesAccountInEmployeePostingGroup(CreateEmployeePostingGroup.EmployeeExpenses(), ExpenseGLAccount.FindGLAccountByName(ExpenseGLAccountNames.PayablesToEmployeesName()));
    end;

    local procedure UpdatePayablesAccountInEmployeePostingGroup(EmployeePostingGroupCode: Code[20]; PayablesAccount: Code[20])
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        if not EmployeePostingGroup.Get(EmployeePostingGroupCode) then
            exit;
        if EmployeePostingGroup."Payables Account" <> '' then
            exit;

        EmployeePostingGroup.Validate("Payables Account", PayablesAccount);
        EmployeePostingGroup.Modify(true);
    end;

    local procedure InsertExpensePostingGroups(CountryCode: Code[10])
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        if CountryCode = 'AT' then begin
            ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiemI(), ExpensePerDiemInCountryLbl);
            ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiemA(), ExpensePerDiemAbroadLbl);
            exit;
        end;

        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiem(), ExpensePerDiemLbl);
    end;

    procedure CreateMasterData()
    var
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode();

        if CountryCode = 'ES' then
            Codeunit.Run(Codeunit::"Update Employee ES");

        Codeunit.Run(Codeunit::"Create Expense Location");
        Codeunit.Run(Codeunit::"Create Expense Categories DM");
        Codeunit.Run(Codeunit::"Create Expense Subcategories");
        Codeunit.Run(Codeunit::"Create Expense Rule Header");
        Codeunit.Run(Codeunit::"Create Expense Rule Condition");
        Codeunit.Run(Codeunit::"Create Expense User");

        case CountryCode of
            'AT', 'AU', 'BE', 'CA', 'CH', 'CZ', 'DE', 'DK', 'ES', 'FI', 'FR', 'GB', 'IT', 'NL', 'NO', 'NZ', 'US':
                CreateCountryMasterData(CountryCode);
        end;
    end;

    local procedure CreateCountryMasterData(CountryCode: Code[10])
    begin
        CreateExpenseCategories(CountryCode);
        CreateExpenseSubcategories(CountryCode);
        CreateExpenseRuleHeaders(CountryCode);
        CreateExpenseRuleConditions(CountryCode);
    end;

    local procedure CreateExpenseCategories(CountryCode: Code[10])
    var
        CreateExpenseGroup: Codeunit "Create Expense Group";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        if CountryCode = 'AT' then begin
            ContosoExpenseAgent.InsertExpenseCategory(PerDiemI(), PerDiemByAssignedPolicyLbl, PerDiemIByAssignedPolicyPostingLbl, ExpensePerDiemI(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
            ContosoExpenseAgent.InsertExpenseCategory(PerDiemA(), PerDiemByAssignedPolicyLbl, PerDiemAByAssignedPolicyPostingLbl, ExpensePerDiemA(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
            exit;
        end;

        ContosoExpenseAgent.InsertExpenseCategory(PerDiem(), PerDiemByAssignedPolicyLbl, PerDiemByAssignedPolicyPostingLbl, GetExpensePerDiemPostingGroup(), Enum::"Expense Attachment Enforcement"::" ", CreateExpensePaymentMethod.Cash(), false, false, CreateExpenseGroup.Travel(), true, Enum::"Expense Reimbursement Type"::"Employee Paid", Enum::"Expense Detail Needed"::"Per Diem");
    end;

    local procedure CreateExpenseSubcategories(CountryCode: Code[10])
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseSubcategory(Country(), GetPerDiemCategory(CountryCode, true), LocalCountryPerDiemLbl, LocalCountryPerDiemPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Intl(), GetPerDiemCategory(CountryCode, false), InternationalPerDiemLbl, InternationalPerDiemPostingLbl, false, true, false);
    end;

    local procedure CreateExpenseRuleHeaders(CountryCode: Code[10])
    var
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.CanadaAll(), 0D, Enum::"Expense Justification"::" ", false, '', GetCanadaCurrency(CountryCode), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.DenmarkAll(), 0D, Enum::"Expense Justification"::" ", false, '', GetEuropeanCurrency(CountryCode), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, true), CreateExpenseLocation.Domestic(), 0D, Enum::"Expense Justification"::" ", false, '', '', '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.FranceAll(), 0D, Enum::"Expense Justification"::" ", false, '', GetEuropeanCurrency(CountryCode), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.GermanyAll(), 0D, Enum::"Expense Justification"::" ", false, '', GetEuropeanCurrency(CountryCode), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.UKOther(), 0D, Enum::"Expense Justification"::" ", false, '', GetUKCurrency(CountryCode), '');
        ContosoExpenseAgent.InsertExpenseRuleHeader(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.USAOther(), 0D, Enum::"Expense Justification"::" ", false, '', GetUSCurrency(CountryCode), '');
    end;

    local procedure CreateExpenseRuleConditions(CountryCode: Code[10])
    var
        CreateExpenseLocation: Codeunit "Create Expense Location";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.CanadaAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 125);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.DenmarkAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 450);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, true), CreateExpenseLocation.Domestic(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 50);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.FranceAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 110);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.GermanyAll(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 105);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.UKOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 115);
        ContosoExpenseAgent.InsertExpenseRuleCondition(GetPerDiemCategory(CountryCode, false), CreateExpenseLocation.USAOther(), 0D, 10000, Enum::"Expense Rule Condition Type"::"Daily Rate", 120);
    end;

    local procedure GetExpensePerDiemPostingGroup(): Code[20]
    begin
        exit(ExpensePerDiem());
    end;

    local procedure ExpensePerDiem(): Code[20]
    begin
        exit(ExpensePERDIEMTok);
    end;

    local procedure ExpensePerDiemI(): Code[20]
    begin
        exit(ExpensePERDIEMITok);
    end;

    local procedure ExpensePerDiemA(): Code[20]
    begin
        exit(ExpensePERDIEMATok);
    end;

    local procedure GetPerDiemCategory(CountryCode: Code[10]; Local: Boolean): Code[20]
    begin
        if CountryCode <> 'AT' then
            exit(PerDiem());
        if Local then
            exit(PerDiemA());
        exit(PerDiemI());
    end;

    local procedure GetCanadaCurrency(CountryCode: Code[10]): Code[10]
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        if CountryCode <> 'CA' then
            exit(CreateCurrency.CAD());
    end;

    local procedure GetEuropeanCurrency(CountryCode: Code[10]): Code[10]
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        case CountryCode of
            'AT', 'BE', 'DE', 'ES', 'FI', 'FR', 'IT', 'NL':
                exit(CreateCurrency.USD());
            else
                exit(CreateCurrency.EUR());
        end;
    end;

    local procedure GetUKCurrency(CountryCode: Code[10]): Code[10]
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        if CountryCode <> 'GB' then
            exit(CreateCurrency.GBP());
    end;

    local procedure GetUSCurrency(CountryCode: Code[10]): Code[10]
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        if CountryCode = 'AT' then
            exit(CreateCurrency.USD());
    end;

    procedure PerDiem(): Code[20]
    begin
        exit(PerDiemTok);
    end;

    procedure PerDiemI(): Code[20]
    begin
        exit(PerDiemITok);
    end;

    procedure PerDiemA(): Code[20]
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

    procedure CreateTransactionalData()
    var
        CreateExpenseLocation: Codeunit "Create Expense Location";
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode();
        BindExpenseSubscriber(CountryCode);

        Codeunit.Run(Codeunit::"Create Expense");
        Codeunit.Run(Codeunit::"Create Exp. Report");

        case CountryCode of
            'AT', 'DE', 'FR':
                CreateCountryExpense(CountryCode, CreateExpenseLocation.FranceAll());
            'AU', 'CA', 'DK', 'ES', 'GB', 'NZ', 'US':
                CreateCountryExpense(CountryCode, CreateExpenseLocation.DenmarkAll());
            'BE', 'CH', 'CZ', 'FI', 'IT', 'NL', 'NO':
                CreateCountryExpense(CountryCode, CreateExpenseLocation.GermanyAll());
        end;

        UnbindExpenseSubscriber();
    end;

    local procedure CreateCountryExpense(CountryCode: Code[10]; LocationCode: Code[20])
    var
        Expense: Record Expense;
        ContosoUtility: Codeunit "Contoso Utilities";
        CreateExpenseUser: Codeunit "Create Expense User";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpensePaymentMethod: Codeunit "Create Expense Payment Method";
    begin
        Expense := ContosoExpenseAgent.InsertExpense(CreateExpenseUser.EH(), GetPerDiemCategory(CountryCode, false), LocationCode, PerDiemByAssignedPolicyShortLbl, '', ContosoUtility.AdjustDate(19030203D), '', 0, '', CreateExpensePaymentMethod.Cash(), true, false, '', CreateDateTime(ContosoUtility.AdjustDate(19030115D), 144000T), CreateDateTime(ContosoUtility.AdjustDate(19030121D), 000500T), 0, 0, '', '', '', '', '');
        UpdateExpensePerDiem(Expense."No.", 10000, false, false, true);
        UpdateExpensePerDiem(Expense."No.", 30000, false, true, false);
        UpdateExpensePerDiem(Expense."No.", 40000, false, false, true);
        UpdateExpensePerDiem(Expense."No.", 60000, false, true, true);
    end;

    local procedure UpdateExpensePerDiem(ExpenseNo: Code[20]; LineNo: Integer; Breakfast: Boolean; Lunch: Boolean; Dinner: Boolean)
    var
        ExpensePerDiemToUpdate: Record "Expense Per Diem";
    begin
        ExpensePerDiemToUpdate.Get(ExpenseNo, LineNo);

        ExpensePerDiemToUpdate.Validate(Breakfast, Breakfast);
        ExpensePerDiemToUpdate.Validate(Lunch, Lunch);
        ExpensePerDiemToUpdate.Validate(Dinner, Dinner);
        ExpensePerDiemToUpdate.Modify();
    end;

    procedure CreateHistoricalData()
    var
        CountryCode: Code[10];
    begin
        CountryCode := GetCountryCode();
        BindExpenseSubscriber(CountryCode);
        BindPostedExpenseReportSubscriber(CountryCode);

        Codeunit.Run(Codeunit::"Create Posted Expense Report");
        Codeunit.Run(Codeunit::"Create Posted Expense Reports");

        UnbindPostedExpenseReportSubscriber();
        UnbindExpenseSubscriber();
    end;

    local procedure GetCountryCode(): Code[10]
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
    begin
        if ContosoCoffeeDemoDataSetup.Get() then
            exit(ContosoCoffeeDemoDataSetup."Country/Region Code");
    end;

    local procedure BindSetupSubscribers(CountryCode: Code[10])
    begin
        CreateExpensePostingGroups.SetCountryCode(CountryCode);

        CreateExpenseGLAccounts.SetCountryCode(CountryCode);
        BindSubscription(CreateExpenseGLAccounts);
        BindSubscription(CreateExpensePostingGroups);
    end;

    local procedure UnbindSetupSubscribers()
    begin
        UnbindSubscription(CreateExpensePostingGroups);
        UnbindSubscription(CreateExpenseGLAccounts);
    end;

    local procedure BindExpenseSubscriber(CountryCode: Code[10])
    begin
        ExpenseDemoDataSubscriber.SetCountryCode(CountryCode);
        BindSubscription(ExpenseDemoDataSubscriber);
    end;

    local procedure UnbindExpenseSubscriber()
    begin
        UnbindSubscription(ExpenseDemoDataSubscriber);
    end;

    local procedure BindPostedExpenseReportSubscriber(CountryCode: Code[10])
    begin
        CreatePostedExpenseReports.SetCountryCode(CountryCode);
        BindSubscription(CreatePostedExpenseReports);
    end;

    local procedure UnbindPostedExpenseReportSubscriber()
    begin
        UnbindSubscription(CreatePostedExpenseReports);
    end;

    var
        CreateExpenseGLAccounts: Codeunit "Create Expense G/L Accounts";
        CreateExpensePostingGroups: Codeunit "Create Expense Posting Groups";
        ExpenseDemoDataSubscriber: Codeunit "Expense Demo Data Subscriber";
        CreatePostedExpenseReports: Codeunit "Create Posted Expense Reports";
        BankCheckingLbl: Label 'Bank, Checking', MaxLength = 100;
        ExpensePERDIEMTok: Label 'EXPENSE-PERDIEM', MaxLength = 20, Locked = true;
        ExpensePerDiemLbl: Label 'Expense - Per Diem', MaxLength = 100;
        ExpensePERDIEMITok: Label 'EXPENSE-PERDIEM-I', MaxLength = 20, Locked = true;
        ExpensePerDiemInCountryLbl: Label 'Expense - Per Diem in country', MaxLength = 100;
        ExpensePERDIEMATok: Label 'EXPENSE-PERDIEM-A', MaxLength = 20, Locked = true;
        ExpensePerDiemAbroadLbl: Label 'Expense - Per Diem abroad', MaxLength = 100;
        PerDiemTok: Label 'PER-DIEM', MaxLength = 20, Locked = true;
        PerDiemITok: Label 'PER-DIEM-I', MaxLength = 20, Locked = true;
        PerDiemATok: Label 'PER-DIEM-A', MaxLength = 20, Locked = true;
        CountryTok: Label 'COUNTRY', MaxLength = 20, Locked = true;
        IntlTok: Label 'INTL', MaxLength = 20, Locked = true;
        PerDiemByAssignedPolicyLbl: Label 'Expenses for per-diem or daily allowance paid for business trips, typically based on travel itinerary or other proof of travel (e.g., booking or agenda), rather than individual expense receipts.', MaxLength = 250;
        PerDiemByAssignedPolicyPostingLbl: Label 'Per-diem by assigned policy', MaxLength = 100;
        PerDiemIByAssignedPolicyPostingLbl: Label 'Per-diem (international) by assigned policy', MaxLength = 100;
        PerDiemAByAssignedPolicyPostingLbl: Label 'Per-diem (local) by assigned policy', MaxLength = 100;
        PerDiemByAssignedPolicyShortLbl: Label 'Per-diem by assigned policy', MaxLength = 100;
        LocalCountryPerDiemLbl: Label 'Daily per-diem allowance based on domestic travel rates, paid instead of individual meal or incidental expense reimbursements.', MaxLength = 250;
        InternationalPerDiemLbl: Label 'Daily per-diem allowance for international business travel, based on applicable foreign travel rates.', MaxLength = 250;
        LocalCountryPerDiemPostingLbl: Label 'Local country per-diem', MaxLength = 100;
        InternationalPerDiemPostingLbl: Label 'International per-diem', MaxLength = 100;
}
