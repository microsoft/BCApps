// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 17238 "Create Exp. SubCategories AU"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
        CreateExpCategoriesAU: Codeunit "Create Expense Categories AU";
    begin
        // PER-DIEM subcategories
        ContosoExpenseAgent.InsertExpenseSubcategory(Country(), CreateExpCategoriesAU.PerDiem(), LocalCountryPerDiemLbl, LocalCountryPerDiemPostingLbl, false, true, false);
        ContosoExpenseAgent.InsertExpenseSubcategory(Intl(), CreateExpCategoriesAU.PerDiem(), InternationalPerDiemLbl, InternationalPerDiemPostingLbl, false, true, false);
    end;

    var
        CountryTok: Label 'COUNTRY', MaxLength = 20, Locked = true;
        IntlTok: Label 'INTL', MaxLength = 20, Locked = true;
        LocalCountryPerDiemLbl: Label 'Daily per-diem allowance based on domestic travel rates, paid instead of individual meal or incidental expense reimbursements.', MaxLength = 250;
        InternationalPerDiemLbl: Label 'Daily per-diem allowance for international business travel, based on applicable foreign travel rates.', MaxLength = 250;
        LocalCountryPerDiemPostingLbl: Label 'Local country per-diem', MaxLength = 100;
        InternationalPerDiemPostingLbl: Label 'International per-diem', MaxLength = 100;

    procedure Country(): Code[20]
    begin
        exit(CountryTok);
    end;

    procedure Intl(): Code[20]
    begin
        exit(IntlTok);
    end;
}