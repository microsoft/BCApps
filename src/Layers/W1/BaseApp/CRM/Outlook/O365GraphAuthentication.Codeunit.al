namespace microsoft.CRM.Outlook;
using System.Azure.Identity;

codeunit 7108 "O365 Graph Authentication"
{
    internal procedure GetAccessToken(var AccessToken: SecretText)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(GetURL(), AzureADMgt.GetO365ResourceName(), false);
    end;

    internal procedure GetURLForGraph(): Text
    begin
        exit(GetURL());
    end;

    local procedure GetURL(): Text
    begin
        exit('https://graph.microsoft.com');
    end;
}
