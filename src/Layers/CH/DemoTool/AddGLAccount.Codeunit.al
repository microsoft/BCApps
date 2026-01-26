codeunit 117559 "Add G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          '995796', XPrepaidHardwareContractslc, '0', '1', '1', '3', '', '2', DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), XVATHotel);
        InsertData(
          '995797', XPrepaidSoftwareContractslc, '0', '1', '1', '3', '', '2', DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), XVATHotel);
        InsertData(
          '996955', XServiceContractSalelc, '0', '0', '1', '2', '', '2', DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), XVATHotel);

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
        MakeAdjustments: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        XVATHotel: Label 'HOTEL';

    procedure InsertData(Fld1: Code[20]; Fld2: Text[50]; Fld4: Text[250]; Fld9: Text[250]; Fld14: Text[250]; Fld19: Text[250]; Fld34: Text[250]; Fld43: Text[250]; Fld44: Code[10]; Fld45: Code[10]; Fld57: Code[10]; Fld58: Code[10])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        Evaluate(GLAccount."No.", MakeAdjustments.Convert(Fld1));
        Evaluate(GLAccount.Name, Fld2);
        Evaluate(GLAccount."Account Type", Fld4);
        Evaluate(GLAccount."Income/Balance", Fld9);
        Evaluate(GLAccount."Direct Posting", Fld14);
        Evaluate(GLAccount.Indentation, Fld19);
        Evaluate(GLAccount.Totaling, Fld34);
        Evaluate(GLAccount."Gen. Posting Type", Fld43);
        Evaluate(GLAccount."Gen. Bus. Posting Group", Fld44);
        Evaluate(GLAccount."Gen. Prod. Posting Group", Fld45);
        Evaluate(GLAccount."VAT Bus. Posting Group", Fld57);
        Evaluate(GLAccount."VAT Prod. Posting Group", Fld58);
        GLAccount.Insert();
    end;
}

