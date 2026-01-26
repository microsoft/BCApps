codeunit 101168 "Create Job G/L Accounts"
{

    trigger OnRun()
    var
        CreateGLAccount: Codeunit "Create G/L Account";
    begin
        DemoDataSetup.Get();
        InsertData(CreateGLAccount.JobCosts(), XJobCosts, 0, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.JobSales(), XJobSales, 0, 0, 2, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.JobCostsApplied(), XJobCostApplied, 0, 0, 2, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.JobSalesApplied(), XJobSalesApplied, 0, 0, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.WIPJobCosts(), XWIPJobCosts, 0, 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.WIPJobSales(), XWIPJobSales, 0, 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.WIPInvoicedSales(), XInvoicedJobSales, 0, 1, 1, 0, '', 0, '', '', '', '', true);
        InsertData(CreateGLAccount.WIPAccruedCosts(), XAccruedJobCosts, 0, 1, 1, 0, '', 0, '', '', '', '', true);
        GLAccIndent.Indent();
        AddCategoriesToGLAccounts();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GLAccIndent: Codeunit "G/L Account-Indent";
        XJobCosts: Label 'Job Costs';
        XJobSales: Label 'Job Sales';
        XJobCostApplied: Label 'Job Costs Applied';
        XJobSalesApplied: Label 'Job Sales Applied';
        XWIPJobCosts: Label 'WIP Job Costs';
        XWIPJobSales: Label 'WIP Job Sales';
        XInvoicedJobSales: Label 'Invoiced Job Sales';
        XAccruedJobCosts: Label 'Accrued Job Costs';

    procedure InsertData(AccountNo: Code[20]; AccountName: Text[50]; AccountType: Option; IncomeBalance: Option; DebitCredit: Option; NoOfBlankLines: Integer; Totaling: Text[250]; GenPostingType: Option; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]; VATGenPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectPosting: Boolean)
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNo) then
            exit;

        GLAccount.Init();
        GLAccount.Validate("No.", AccountNo);
        GLAccount.Validate(Name, AccountName);
        GLAccount.Validate("Account Type", AccountType);
        if GLAccount."Account Type" = GLAccount."Account Type"::Posting then
            GLAccount.Validate("Direct Posting", DirectPosting);
        GLAccount.Validate("Income/Balance", "G/L Account Report Type".FromInteger(IncomeBalance));
        GLAccount.Validate("Debit/Credit", DebitCredit);
        GLAccount.Validate("No. of Blank Lines", NoOfBlankLines);
        if Totaling <> '' then
            GLAccount.Validate(Totaling, Totaling);
        if GenPostingType > 0 then
            GLAccount.Validate("Gen. Posting Type", GenPostingType);
        if GenBusPostingGroup <> '' then
            GLAccount.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        if GenProdPostingGroup <> '' then
            GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if VATGenPostingGroup <> '' then
            GLAccount.Validate("VAT Bus. Posting Group", VATGenPostingGroup);
        if VATProdPostingGroup <> '' then
            GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Insert();
    end;

    procedure AddCategoriesToGLAccounts()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if GLAccountCategory.IsEmpty() then
            exit;

        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignCategoryToChartOfAccounts(GLAccountCategory);
                AssignCategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;

        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        if GLAccountCategory.FindSet() then
            repeat
                AssignSubcategoryToChartOfAccounts(GLAccountCategory);
                AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory);
            until GLAccountCategory.Next() = 0;
    end;

    procedure AssignCategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
    begin
        case GLAccountCategory."Account Category" of
            GLAccountCategory."Account Category"::Assets:
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.WIPJobSales(), CreateGLAccount.WIPJobCosts());
            GLAccountCategory."Account Category"::Income:
                begin
                    UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobSales(), '10251');
                    UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobSalesApplied(), '10451');
                end;
            GLAccountCategory."Account Category"::"Cost of Goods Sold":
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobCosts(), '20301');
            GLAccountCategory."Account Category"::Expense:
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobCostsApplied(), '20400');
        end;
    end;

    procedure AssignSubcategoryToChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        case GLAccountCategory.Description of
            GLAccountCategoryMgt.GetJobsCost():
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobCosts(), '20301');
            GLAccountCategoryMgt.GetIncomeJobs():
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobSales(), '10251');
            GLAccountCategoryMgt.GetOtherIncomeExpense():
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobCostsApplied(), '20400');
            GLAccountCategoryMgt.GetJobSalesContra():
                UpdateGLAccounts(GLAccountCategory, CreateGLAccount.JobSalesApplied(), '10451');
        end;
    end;

    local procedure UpdateGLAccounts(GLAccountCategory: Record "G/L Account Category"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if not TryGetGLAccountNoRange(GLAccount, FromGLAccountNo, ToGLAccountNo) then
            exit;

        GLAccount.ModifyAll("Account Category", GLAccountCategory."Account Category", false);
        GLAccount.ModifyAll("Account Subcategory Entry No.", GLAccountCategory."Entry No.", false);
    end;

    [TryFunction]
    local procedure TryGetGLAccountNoRange(var GLAccount: Record "G/L Account"; FromGLAccountNo: Code[20]; ToGLAccountNo: Code[20])
    var
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        GLAccount.SetRange("No.", MakeAdjustments.Convert(FromGLAccountNo), MakeAdjustments.Convert(ToGLAccountNo));
    end;

    local procedure AssignCategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;

    local procedure AssignSubcategoryToLocalChartOfAccounts(GLAccountCategory: Record "G/L Account Category")
    begin
        GLAccountCategory.Find();
        // Reserved for local chart of accounts
    end;
}

