codeunit 119032 "Create WIP Accounts"
{

    trigger OnRun()
    var
        InvtPostingSetup: Record "Inventory Posting Setup";
    begin
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
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
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

