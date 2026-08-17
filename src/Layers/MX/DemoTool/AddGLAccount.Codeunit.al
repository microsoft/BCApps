codeunit 117559 "Add G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        CreateGLAccount.InsertData('995795', XPrepaidServiceContractslc, 3, 1, 0, '', 0, '', '', '', '', false);
        CreateGLAccount.InsertData(
          '995796', XPrepaidHardwareContractslc, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), true);
        CreateGLAccount.InsertData(
          '995797', XPrepaidSoftwareContractslc, 0, 1, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), true);
        CreateGLAccount.InsertData('995799', XTotalPrepaidServiceContractlc, 4, 1, 0,
          MakeAdjustments.Convert('995795') + '..' + MakeAdjustments.Convert('995799'), 0, '', '', '', '', false);

        CreateGLAccount.InsertData('996950', XSalesofServiceContractslc, 3, 0, 0, '', 0, '', '', '', '', false);
        CreateGLAccount.InsertData(
          '996955', XServiceContractSalelc, 0, 0, 0, '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode(), true);
        CreateGLAccount.InsertData('996959', XTotalSaleofServContractslc, 4, 0, 0,
          MakeAdjustments.Convert('996950') + '..' + MakeAdjustments.Convert('996959'), 0, '', '', '', '', false);

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
        XPrepaidServiceContractslc: Label 'Prepaid Service Contracts';
        XPrepaidHardwareContractslc: Label 'Prepaid Hardware Contracts';
        XPrepaidSoftwareContractslc: Label 'Prepaid Software Contracts';
        XTotalPrepaidServiceContractlc: Label 'Total Prepaid Service Contract';
        XSalesofServiceContractslc: Label 'Sales of Service Contracts';
        XServiceContractSalelc: Label 'Service Contract Sale';
        XTotalSaleofServContractslc: Label 'Total Sale of Serv. Contracts';
        CreateGLAccount: Codeunit "Create G/L Account";
        MakeAdjustments: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
}

