codeunit 119032 "Create WIP Accounts"
{

    trigger OnRun()
    begin
        exit; // RU
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccountCategory: Record "G/L Account Category";
        Adjust: Codeunit "Make Adjustments";
        XDirectCostAppliedRetail: Label 'Direct Cost Applied, Retail';
        XOverheadAppliedRetail: Label 'Overhead Applied, Retail';
        XPurchaseVarianceRetail: Label 'Purchase Variance, Retail';
        XDirectCostAppliedRawmat: Label 'Direct Cost Applied, Rawmat.';
        XOverheadAppliedRawmat: Label 'Overhead Applied, Rawmat.';
        XPurchaseVarianceRawmat: Label 'Purchase Variance, Rawmat.';
        XDirectCostAppliedCap: Label 'Direct Cost Applied, Cap.';
        XOverheadAppliedCap: Label 'Overhead Applied, Cap.';
        XPurchaseVarianceCap: Label 'Purchase Variance, Cap.';
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
        InsertData('9990162', XDirectCostAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('9990163', XOverheadAppliedRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('9990164', XPurchaseVarianceRetail, 0, 0, 0, '', 0, '', '', false);
        InsertData('9990165', XDirectCostAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('9990166', XOverheadAppliedRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('9990167', XPurchaseVarianceRawmat, 0, 0, 0, '', 0, '', '', false);
        InsertData('9925250', XDirectCostAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('9925260', XOverheadAppliedCap, 0, 0, 0, '', 0, '', '', false);
        InsertData('9925270', XPurchaseVarianceCap, 0, 0, 0, '', 0, '', '', false);

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
                            GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('9990165'));
                            GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('9990166'));
                            GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('9990167'));
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
                            GenPostingSetup.Validate("Direct Cost Applied Account", Adjust.Convert('9990165'));
                            GenPostingSetup.Validate("Overhead Applied Account", Adjust.Convert('9990166'));
                            GenPostingSetup.Validate("Purchase Variance Account", Adjust.Convert('9990167'));
                            GenPostingSetup.Modify();
                        end;
                end;
            until GenPostingSetup.Next() = 0;
    end;
}

