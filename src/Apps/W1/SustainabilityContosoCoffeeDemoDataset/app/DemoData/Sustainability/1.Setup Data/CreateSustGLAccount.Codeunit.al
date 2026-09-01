#pragma warning disable AA0247
codeunit 5362 "Create Sust. G/L Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        GLAccountIndent: Codeunit "G/L Account-Indent";
        CreatePostingGroup: Codeunit "Create Posting Groups";
    begin
        AddGLAccountsForLocalization();

        ContosoGLAccount.InsertGLAccount(UtilitiesExpensePowerPlantAccount(), UtilitiesExpensePowerPlantAccountName(), "G/L Account Income/Balance"::"Income Statement", Enum::"G/L Account Category"::Expense, '', Enum::"G/L Account Type"::Posting, CreatePostingGroup.DomesticPostingGroup(), CreatePostingGroup.RetailPostingGroup(), 0, '', Enum::"G/L Account Type"::Posting, '', '', true, false, false);
        GLAccountIndent.Indent();
    end;

    local procedure AddGLAccountsForLocalization()
    begin
        ContosoGLAccount.AddAccountForLocalization(UtilitiesExpensePowerPlantAccountName(), '60410');

        OnAfterAddGLAccountsForLocalization();
    end;

    var
        ContosoGLAccount: Codeunit "Contoso GL Account";
        UtilitiesExpensePowerPlantLbl: Label 'Utilities Expense - Power Plant', MaxLength = 100;

    procedure FindGLAccountByName(AccountName: Text[100]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Name", AccountName);
        if GLAccount.FindFirst() then
            exit(GLAccount."No.")
        else
            exit('');
    end;

    procedure UtilitiesExpensePowerPlantAccount(): Code[20]
    begin
        exit(ContosoGLAccount.GetAccountNo(UtilitiesExpensePowerPlantAccountName()));
    end;

    procedure UtilitiesExpensePowerPlantAccountName(): Text[100]
    begin
        exit(UtilitiesExpensePowerPlantLbl);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddGLAccountsForLocalization()
    begin
    end;
}