codeunit 119032 "Create WIP Accounts"
{

    trigger OnRun()
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
        InsertData('997191', XDirectCostAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997192', XOverheadAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997193', XPurchaseVarianceRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997291', XDirectCostAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997292', XOverheadAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997293', XPurchaseVarianceRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997705', XCostofCapacities, 3, 0, 0, '', 0, '', '', false);
        InsertData('997710', XCostofCapacities, 0, 0, 0, '', 0, '', '', false);
        InsertData('997791', XDirectCostAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('997792', XOverheadAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('997793', XPurchaseVarianceCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('997795', XTotalCostofCapacities, 4, 0, 0, '', 0, '', '', false);
        InsertData('997805', XVariance, 3, 0, 0, '', 0, '', '', false);
        InsertData('997891', XMaterialVariance, 0, 0, 0, '', 0, '', '', false);
        InsertData('997892', XCapacityVariance, 0, 0, 0, '', 0, '', '', false);
        InsertData('997893', XMaterialOverheadVariance, 0, 0, 0, '', 0, '', '', false);
        InsertData('997894', XCapOverheadVariance, 0, 0, 0, '', 0, '', '', false);
        InsertData('997895', XTotalVariance, 4, 0, 0, '', 0, '', '', false);

        InsertData('992140', XWIPAccountFinishedgoods, 0, 1, 0, '', 0, '', '', false);
        GLAccIndent.SetHidePrintDialog(true);
        GLAccIndent.Indent();

        UpdateManufactAccounts();

        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::"Cost of Goods Sold");
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::"Cost of Goods Sold", GLAccountCategoryMgt.GetCOGSMaterials());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::Assets, GLAccountCategoryMgt.GetCurrentAssets());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);

        if InvtPostingSetup.Find('-') then
            repeat
                InvtPostingSetup.Validate("WIP Account", Adjust.Convert('992140'));
                InvtPostingSetup.Validate("Material Variance Account", Adjust.Convert('997891'));
                InvtPostingSetup.Validate("Capacity Variance Account", Adjust.Convert('997892'));
                InvtPostingSetup.Validate("Mfg. Overhead Variance Account", Adjust.Convert('997893'));
                InvtPostingSetup.Validate("Cap. Overhead Variance Account", Adjust.Convert('997894'));
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
        XDirectCostAppliedRawmat: Label 'Direct Cost Applied, Rawmat.';
        XOverheadAppliedRawmat: Label 'Overhead Applied, Rawmat.';
        XPurchaseVarianceRawmat: Label 'Purchase Variance, Rawmat.';
        XCostofCapacities: Label 'Cost of Capacities';
        XDirectCostAppliedCap: Label 'Direct Cost Applied, Cap.';
        XOverheadAppliedCap: Label 'Overhead Applied, Cap.';
        XPurchaseVarianceCap: Label 'Purchase Variance, Cap.';
        XTotalCostofCapacities: Label 'Total Cost of Capacities';
        XVariance: Label 'Variance';
        XMaterialVariance: Label 'Material Variance';
        XCapacityVariance: Label 'Capacity Variance';
        XCapOverheadVariance: Label 'Cap. Overhead Variance';
        XTotalVariance: Label 'Total Variance';
        XWIPAccountFinishedgoods: Label 'WIP Account, Finished goods';
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
        CreateGLAccount: Codeunit "Create G/L Account";
        XMaterialOverheadVariance: Label 'Material Overhead Variance';

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
                GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger("Income/Balance"));
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
        InsertData('997191', XDirectCostAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997192', XOverheadAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997193', XPurchaseVarianceRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('997291', XDirectCostAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997292', XOverheadAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997293', XPurchaseVarianceRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('997791', XDirectCostAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('997792', XOverheadAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('997793', XPurchaseVarianceCap, 0, 0, 0, '', 0, '', '', false);

        UpdateManufactAccounts();

        GLAccountCategoryMgt.GetAccountCategory(GLAccountCategory, GLAccountCategory."Account Category"::"Cost of Goods Sold");
        CreateGLAccount.AssignCategoryToChartOfAccounts(GLAccountCategory);
        GLAccountCategoryMgt.GetAccountSubcategory(GLAccountCategory,
          GLAccountCategory."Account Category"::"Cost of Goods Sold", GLAccountCategoryMgt.GetCOGSMaterials());
        CreateGLAccount.AssignSubcategoryToChartOfAccounts(GLAccountCategory);
    end;

    local procedure UpdateManufactAccounts()
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        DemoDataSetup.Get();
        if GenPostingSetup.FindSet() then
            repeat
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
                            GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997191'));
                            GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997192'));
                            GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('997193'));
                            GenPostingSetup.Modify();
                        end;
                    DemoDataSetup.ServicesCode(),
                    DemoDataSetup.ManufactCode():
                        begin
                            GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('997791'));
                            GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('997792'));
                            GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('997793'));
                            GenPostingSetup.Modify();
                        end;
                end;
            until GenPostingSetup.Next() = 0;
    end;
}

