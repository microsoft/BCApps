codeunit 119032 "Create WIP Accounts"
{

    trigger OnRun()
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        InsertData('997191', XDirectCostAppliedRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), false);
        InsertData('997192', XOverheadAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997193', XPurchaseVarianceRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997293', XPurchaseVarianceRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997792', XOverheadAppliedCap, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), false);
        InsertData('997793', XPurchaseVarianceCap, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), false);
        InsertData('997891', XCapacityVariance, 0, 0, 0, '', 0, '', '', false);
        InsertData('997892', XSubcontractedVariance, 0, 0, 0, '', 0, '', '', false);

        GLAccIndent.Indent();

        UpdateManufactAccounts();

        // Assets
        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Assets);
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgtCZL.GetCI1Material());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgtCZL.GetCI32Goods());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        // Expense
        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Expense);
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Expense, GLAccountCategoryMgtCZL.GetA2MaterialAndEnergyConsumption());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Expense, GLAccountCategoryMgtCZL.GetA3Services());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        if InvtPostingSetup.Find('-') then
            repeat
                InvtPostingSetup.Validate("WIP Account", Adjust.Convert('992140'));
                InvtPostingSetup.Validate("Material Variance Account", Adjust.Convert('997890'));
                InvtPostingSetup.Validate("Capacity Variance Account", Adjust.Convert('997891'));
                InvtPostingSetup.Validate("Subcontracted Variance Account", Adjust.Convert('997892'));
                InvtPostingSetup.Validate("Cap. Overhead Variance Account", Adjust.Convert('997893'));
                InvtPostingSetup.Validate("Mfg. Overhead Variance Account", Adjust.Convert('997894'));
                InvtPostingSetup.Modify();
            until InvtPostingSetup.Next() = 0;
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccountCategory: Record "G/L Account Category";
        Adjust: Codeunit "Make Adjustments";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XDirectCostAppliedRetail: Label 'Direct Cost Applied, Retail';
        XOverheadAppliedRetail: Label 'Overhead Applied, Retail';
        XPurchaseVarianceRetail: Label 'Purchase Variance, Retail';
        XPurchaseVarianceRawmat: Label 'Purchase Variance, Rawmat.';
        XOverheadAppliedCap: Label 'Overhead Applied, Cap.';
        XPurchaseVarianceCap: Label 'Purchase Variance, Cap.';
        XCapacityVariance: Label 'Capacity Variance';
        XSubcontractedVariance: Label 'Subcontracted Variance';
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        GLAccountCategoryMgtCZL: Codeunit "G/L Account Category Mgt. CZL";
        CreateGLAccount: Codeunit "Create G/L Account";

    procedure InsertData("No.": Code[20]; Name: Text[30]; "Account Type": Option; "Income/Balance": Option; "No. of Blank Lines": Integer; Totaling: Text[30]; "Gen. Posting Type": Option; "Gen. Bus. Posting Group": Code[20]; "Gen. Prod. Posting Group": Code[20]; "Direct Posting": Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Init();
        GLAccount.Validate("No.", Adjust.Convert("No."));
        GLAccount.Validate(Name, Name);
        GLAccount.Validate("Account Type", "Account Type");
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", "Direct Posting");
        if CopyStr(GLAccount."No.", 1, 1) in ['0' .. '4'] then // NAVCZ
            "Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet".AsInteger()
        else
            "Income/Balance" := GLAccount."Income/Balance"::"Income Statement".AsInteger();
        GLAccount."Income/Balance" := "G/L Account Report Type".FromInteger("Income/Balance");
        GLAccount.Validate("No. of Blank Lines", "No. of Blank Lines");
        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        GLAccount.Validate("Gen. Posting Type", "Gen. Posting Type");
        GLAccount.Validate("Gen. Bus. Posting Group", "Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        GLAccount.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        InsertData('997191', XDirectCostAppliedRetail, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.RetailCode(), false);
        InsertData('997192', XOverheadAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997193', XPurchaseVarianceRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997293', XPurchaseVarianceRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997792', XOverheadAppliedCap, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), false);
        InsertData('997793', XPurchaseVarianceCap, 0, 0, 0, '', 1, DemoDataSetup.DomesticCode(), DemoDataSetup.MiscCode(), false);

        UpdateManufactAccounts();

        // Assets
        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Assets);
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgtCZL.GetCI1Material());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgtCZL.GetCI32Goods());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        // Expense
        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::Expense);
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Expense, GLAccountCategoryMgtCZL.GetA2MaterialAndEnergyConsumption());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Expense, GLAccountCategoryMgtCZL.GetA3Services());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
    end;

    local procedure UpdateManufactAccounts()
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        DemoDataSetup.Get();
        if GenPostingSetup.FindSet() then
            repeat
                // NAVCZ
                if GenPostingSetup."Gen. Bus. Posting Group" in [
                    DemoDataSetup.DomesticCode(), DemoDataSetup.EUCode(), DemoDataSetup.ExportCode(), '']
                then
                    // NAVCZ
                    case GenPostingSetup."Gen. Prod. Posting Group" of
                        DemoDataSetup.RawMatCode():
                            begin
                                GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997291'));
                                GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997292'));
                                GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('997293'));
                                GenPostingSetup.Modify();
                            end;
                        DemoDataSetup.MiscCode(),
                        DemoDataSetup.NoVATCode(),
                        DemoDataSetup.RetailCode():
                            begin
                                GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997110')); // NAVCZ
                                GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997192'));
                                GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('997193'));
                                GenPostingSetup.Modify();
                            end;
                        DemoDataSetup.ServicesCode(),
                        DemoDataSetup.ManufactCode():
                            begin
                                GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997150')); // NAVCZ
                                GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997792'));
                                GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('997793'));
                                GenPostingSetup.Modify();
                            end;
                    end;

                // NAVCZ
                if (GenPostingSetup."Gen. Bus. Posting Group" = DemoDataSetup.IManufactureCode()) and
                   (GenPostingSetup."Gen. Prod. Posting Group" = DemoDataSetup.ManufactCode())
                then begin
                    GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997180'));
                    GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997180'));
                    GenPostingSetup.Modify();
                end;
            // NAVCZ
            until GenPostingSetup.Next() = 0;
    end;
}

