namespace System.Azure.Identity;

using Microsoft.Utilities;
using System.Security.Authentication;
using System.Environment;

page 6302 "Azure AD Access Dialog"
{
    Caption = 'Microsoft Entra service permissions';
    PageType = NavigatePage;

    layout
    {
        area(content)
        {
            label(Para0)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'The functionality you have selected to use requires services from Microsoft Entra to access your system.';
            }
            label(Para1)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Before you can begin using this functionality, you must first grant access to these services.  To grant access, choose the ''Authorize Azure Services''  link.';
            }
            usercontrol(OAuthIntegration; OAuthIntegration)
            {
                ApplicationArea = Basic, Suite;

                trigger ControlAddInReady()
                begin
                    CurrPage.OAuthIntegration.Authorize(AzureAdMgt.GetAuthCodeUrl(ResourceUrl), LinkNameTxt, LinkTooltipTxt);
                end;

                trigger AuthorizationCodeRetrieved(authorizationCode: Text)
                begin
                    AuthCode := authorizationCode;
                    CurrPage.Close();
                    if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows then
                        Message(CloseWindowMsg);
                end;

                trigger AuthorizationErrorOccurred(error: Text; description: Text)
                var
                    ActivityLog: Record "Activity Log";
                    AzureAdAppSetup: Record "Azure AD App Setup";
                begin
                    // OnOAuthAccessDenied event is raised if Auth fails because access is denied
                    // Subcribe to this event if you want to respond to it
                    // description contains AADSTS65004 error code if user denied the request and AADSTS65005 if the client
                    // has not set up required permissions for the resource being requested
                    if error = 'access_denied' then
                        OnOAuthAccessDenied(description, ResourceFriendlyName)
                    else begin
                        if not AzureAdAppSetup.IsEmpty() then begin
                            AzureAdAppSetup.FindFirst();
                            ActivityLog.LogActivityForUser(
                              AzureAdAppSetup.RecordId, ActivityLog.Status::Failed, 'Azure Authorization', description, error, UserId);
                        end;
                        ThrowError();
                    end;
                end;
            }
            label(Para2)
            {
                ApplicationArea = Basic, Suite;
                Caption = '';
                ShowCaption = false;
            }
            label(Para3)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Microsoft Entra Services:';
                Style = Strong;
                StyleExpr = true;
            }
            field(Para4; ResourceFriendlyName)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                Visible = ResourceFriendlyName <> '';
            }
        }
    }

    actions
    {
    }

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        ClientTypeManagement: Codeunit "Client Type Management";
        AuthCode: SecretText;
        ResourceUrl: Text;
        AuthorizationTxt: Label 'Error occurred while trying to authorize with Microsoft Entra ID. Please try again or contact your system administrator if error persist.';
        ResourceFriendlyName: Text;
        CloseWindowMsg: Label 'Authorization sucessful. Close the window to proceed.';
        LinkNameTxt: Label 'Authorize Azure Services';
        LinkTooltipTxt: Label 'You will be redirected to the authorization provider in a different browser instance.';
#if not CLEAN25

    [NonDebuggable]
    [Obsolete('Replaced by GetAuthorizationCodeAsSecretText', '25.0')]
    procedure GetAuthorizationCode(Resource: Text; ResourceName: Text): Text
    begin
        exit(GetAuthorizationCodeAsSecretText(Resource, ResourceName).Unwrap());
    end;
#endif

    procedure GetAuthorizationCodeAsSecretText(Resource: Text; ResourceName: Text): SecretText
    var
        BlankSecretText: SecretText;
    begin
        ResourceUrl := Resource;
        ResourceFriendlyName := ResourceName;
        CurrPage.Update();
        if not AzureAdMgt.IsAzureADAppSetupDone() then begin
            PAGE.RunModal(PAGE::"Azure AD App Setup Wizard");
            if not AzureAdMgt.IsAzureADAppSetupDone() then
                exit(BlankSecretText);
        end;

        CurrPage.RunModal();
        exit(AuthCode);
    end;

    local procedure ThrowError()
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Windows then
            Message(AuthorizationTxt)
        else
            Error(AuthorizationTxt)
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnOAuthAccessDenied(description: Text; resourceFriendlyName: Text)
    begin
    end;
}

