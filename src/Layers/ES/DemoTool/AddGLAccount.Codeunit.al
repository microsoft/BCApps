codeunit 117559 "Add G/L Account"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('995795', XPrepaidServiceContractslc, 0, '1', '0',
          '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode());
        InsertData('995796', XPrepaidHardwareContractslc, 0, '1', '1',
          '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode());
        InsertData('995797', XPrepaidSoftwareContractslc, 0, '1', '1',
          '', 2, DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesCode(), DemoDataSetup.DomesticCode(), DemoDataSetup.ServicesVATCode());
        InsertData('995799', XTotalPrepaidServiceContractlc, 1, '0', '1',
          MakeAdjustments.Convert('995795') + '..' + MakeAdjustments.Convert('995799'), 0, '', '', '', '');

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Liabilities, GLAccountCategoryMgt.GetCurrentLiabilities());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Income, GLAccountCategoryMgt.GetIncomeService());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccIndent.SetHidePrintDialog(true);
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
        CreateGLAccount: Codeunit "Create G/L Account";
        MakeAdjustments: Codeunit "Make Adjustments";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[50]; AccountType: Option; Fld9: Text[250]; Fld14: Text[250]; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", MakeAdjustments.Convert(AccountNo));
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then begin
            Evaluate(GLAccount."Direct Posting", Fld14);
            GLAccount.Validate("Income Stmt. Bal. Acc.", '1290001');
        end;
        Evaluate(GLAccount."Income/Balance", Fld9);
        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Insert();
    end;
}

