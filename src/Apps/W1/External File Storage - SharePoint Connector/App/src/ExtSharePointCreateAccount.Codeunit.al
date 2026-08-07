namespace System.ExternalFileStorage;

codeunit 4581 "Ext. SharePoint Create Account"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SharePoint Account" = r;
    TableNo = "Ext. SharePoint Account";

    trigger OnRun()
    var
        ExtSharePointAccount: Record "Ext. SharePoint Account";
        TempFileAccount: Record "File Account" temporary;
        SharePointConnectorImpl: Codeunit "Ext. SharePoint Connector Impl";
        SecretToPass: SecretText;
        CertificatePassword: SecretText;
        SetAsDefaultTxt: Text;
    begin
        if not IsolatedStorage.Get(GetSecretKeyToken(Rec.Id), DataScope::Module, SecretToPass) then
            exit;

        ExtSharePointAccount.SetRange(Name, Rec.Name);
        if ExtSharePointAccount.FindFirst() then
            SharePointConnectorImpl.DeleteAccount(ExtSharePointAccount.Id);

        if IsolatedStorage.Get(GetCertPwdKeyToken(Rec.Id), DataScope::Module, CertificatePassword) then;

        SharePointConnectorImpl.CreateAccount(Rec, SecretToPass, CertificatePassword, TempFileAccount);
        if IsolatedStorage.Get(GetSetAsDefaultKeyToken(Rec.Id), DataScope::Module, SetAsDefaultTxt) then
            if SetAsDefaultTxt = '1' then
                MakeDefault(TempFileAccount);
    end;

    internal procedure MakeDefault(TempFileAccount: Record "File Account" temporary)
    var
        FileScenarioCU: Codeunit "File Scenario";
    begin
        // Cannot call codeunit "File Account Impl.", procedure IsUserFileAdmin due to it's protection level
        FileScenarioCU.SetDefaultFileAccount(TempFileAccount);
    end;

    internal procedure GetSecretKeyToken(AccountId: Guid): Text
    var
        SecretKeyTokLbl: Label 'EFS_Secret_%1', Locked = true;
    begin
        exit(StrSubstNo(SecretKeyTokLbl, AccountId));
    end;

    internal procedure GetCertPwdKeyToken(AccountId: Guid): Text
    var
        CertPwdKeyTokLbl: Label 'EFS_CertPwd_%1', Locked = true;
    begin
        exit(StrSubstNo(CertPwdKeyTokLbl, AccountId));
    end;

    internal procedure GetSetAsDefaultKeyToken(AccountId: Guid): Text
    var
        SetAsDefaultKeyTokLbl: Label 'EFS_SetAsDefault_%1', Locked = true;
    begin
        exit(StrSubstNo(SetAsDefaultKeyTokLbl, AccountId));
    end;
}
