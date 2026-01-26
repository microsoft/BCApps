codeunit 117559 "Add G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        // NAVCZ
        CreateGLAccount.InsertData(
          '602220', XPrepaidHardwareContractslc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATItemCode(), true);
        CreateGLAccount.InsertData(
          '602230', XPrepaidSoftwareContractslc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATItemCode(), true);
        CreateGLAccount.InsertData(
          '602320', XServiceContractSalelc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.FirstReducedVATItemCode(), true);
        // NAVCZ
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Liabilities, GLAccountCategoryMgt.GetCurrentLiabilities());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Income, GLAccountCategoryMgt.GetIncomeService());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccIndent.Indent();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccountCategory: Record "G/L Account Category";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XPrepaidHardwareContractslc: Label 'Prepaid Hardware Contracts';
        XPrepaidSoftwareContractslc: Label 'Prepaid Software Contracts';
        XServiceContractSalelc: Label 'Service Contract Sale';
        CreateGLAccount: Codeunit "Create G/L Account";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
}

