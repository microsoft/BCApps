#pragma warning disable AA0247
codeunit 10770 "Create Sust. ES G/L Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Sust. G/L Account", 'OnAfterAddGLAccountsForLocalization', '', false, false)]
    local procedure ModifyCommonGLAccounts()
    begin
        ContosoGLAccount.AddAccountForLocalization(CreateSustGLAccount.UtilitiesExpensePowerPlantAccountName(), '6004100');

        CreateGLAccountForLocalization();
    end;

    local procedure CreateGLAccountForLocalization()
    var
        CreatePostingGroup: Codeunit "Create Posting Groups";
    begin
        ContosoGLAccount.SetOverwriteData(true);
        ContosoGLAccount.InsertGLAccount(CreateSustGLAccount.UtilitiesExpensePowerPlantAccount(), CreateSustGLAccount.UtilitiesExpensePowerPlantAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, CreatePostingGroup.DomesticPostingGroup(), CreatePostingGroup.RetailPostingGroup(), 0, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        ContosoGLAccount.SetOverwriteData(false);

        UpdateIncomeStatementBalanceAccount();
    end;

    local procedure UpdateIncomeStatementBalanceAccount()
    begin
        UpdateIncomeStmtBalAcc(CreateSustGLAccount.UtilitiesExpensePowerPlantAccount(), CreateSustGLAccount.FindGLAccountByName(CreateESGLAccounts.ProfitOrLossName()));
    end;

    local procedure UpdateIncomeStmtBalAcc(No: Code[20]; IncomeStmtBalAcc: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(No) then begin
            GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalAcc);
            GLAccount.Modify();
        end;
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        CreateSustGLAccount: Codeunit "Create Sust. G/L Account";
        CreateESGLAccounts: Codeunit "Create ES GL Accounts";
}