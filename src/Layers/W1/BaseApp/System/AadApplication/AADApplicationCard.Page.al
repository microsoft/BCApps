namespace System.Environment.Configuration;

using Microsoft.Integration.Graph;
using System.Security.AccessControl;
using System.Security.Authentication;
using System.Security.User;

page 9861 "AAD Application Card"
{
    Caption = 'Microsoft Entra Application Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "AAD Application";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Client Id"; Rec."Client Id")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    Editable = EditableByNotEnabled;
                    Caption = 'Client ID';
                    ToolTip = 'Specifies the client ID for the app.';
                }
                field(Description; Rec.Description)
                {
                    ShowMandatory = true;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the app. The description will be automatically added in the User Name field of the card the first time the app is enabled.';
                    Editable = EditableByNotEnabled;
                    trigger OnValidate()
                    begin
                        UpdateControl();
                    end;
                }
                field(State; Rec.State)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Standard;
                    Caption = 'State';
                    ToolTip = 'Specifies if the app is enabled or disabled.';
                    trigger OnValidate()
                    begin
                        UpdateControl();
                    end;
                }
                field("Contact Information"; Rec."Contact Information")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = EditableByNotEnabled;
                    Caption = 'Contact Information';
                    ToolTip = 'Specifies the contact information of the app.';
                }
                group(Extension)
                {
                    field("App ID"; Rec."App ID")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = EditableByNotEnabled;
                        Caption = 'App ID';
                        ToolTip = 'Specifies the app ID of the extension.';
                    }
                    field("App Name"; Rec."App Name")
                    {
                        Editable = EditableByNotEnabled;
                        ApplicationArea = Basic, Suite;
                        Caption = 'App Name';
                        ToolTip = 'Specifies the app name of the extension.';
                    }
                }
                group("User information")
                {
                    field("User ID"; Rec."User id")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'User ID';
                        ToolTip = 'Specifies the unique ID (GUID) assigned to the application. This field is automatically filled in once the app is enabled. The user ID. like the user name, is used to indicate sessions and operations that are run by the app.';
                    }
                    field("User name"; Username)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'User Name';
                        ToolTip = 'Specifies the user name assigned to the app. This field is automatically filled in with the value of the Description field once the app is enabled. The user name, like the user ID, is used to indicate sessions and operations that are run by the app..';
                    }
                    field("User Telemetry Id"; TelemetryUserId)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'User Telemetry ID';
                        ToolTip = 'Specifies a telemetry ID assigned to the app which can be used for troubleshooting purposes.';
                    }
                }
                field(ShowEnableWarning; ShowEnableWarning)
                {
                    ApplicationArea = Basic, Suite;
                    ShowCaption = false;
                    AssistEdit = false;
                    Editable = false;
                    Enabled = not EditableByNotEnabled;
                    trigger OnDrillDown()
                    begin
                        DrilldownCode();
                    end;
                }
            }
            part(Permissions; "User Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Permission Sets';
                Enabled = SetUserPermissionEnabled;
                SubPageLink = "User Security ID" = field("User Id");
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Consent)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Grant Consent';
                Image = Setup;
                Enabled = not IsVEApp;
                Scope = Repeater;
                ToolTip = 'Grant consent for this application to access data from Business Central.';


                trigger OnAction()

                begin
                    GrantConsent();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Consent_Promoted; Consent)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        AADApplicationSetup: Codeunit "AAD Application Setup";
    begin
        IsVEApp := LowerCase(GraphMgtGeneralTools.StripBrackets(Format(Rec."Client Id"))) = AADApplicationSetup.GetD365BCForVEAppId();
        UpdateControl();
    end;

    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
        CommonOAuthAuthorityUrlLbl: Label 'https://login.microsoftonline.com/common/adminconsent', Locked = true;
        ConsentFailedErr: Label 'Failed to give consent.';
        ConsentSuccessTxt: Label 'Consent was given successfully.';
        EnabledWarningTok: Label 'You must set the State field to Disabled before you can make changes to this app.';
        DisableEnableQst: Label 'Do you want to disable this app?';
        UserName: Text;
        TelemetryUserId: Guid;
        ShowEnableWarning: Text;
        IsVEApp: Boolean;
        SetUserPermissionEnabled: Boolean;
        EditableByNotEnabled: Boolean;

    [Scope('OnPrem')]
    local procedure GrantConsent();
    var
        OAuth2: Codeunit OAuth2;
        Success: Boolean;
        ErrorMsgTxt: Text;
    begin
        OAuth2.RequestClientCredentialsAdminPermissions(GraphMgtGeneralTools.StripBrackets(Format(Rec."Client Id")), CommonOAuthAuthorityUrlLbl, '', Success, ErrorMsgTxt);
        if not Success then
            if ErrorMsgTxt <> '' then
                Error(ErrorMsgTxt)
            else
                Error(ConsentFailedErr);
        Message(ConsentSuccessTxt);
        Rec."Permission Granted" := true;
        Rec.Modify();
    end;

    local procedure UpdateControl()
    var
        User: Record User;
        UserProperty: Record "User Property";
    begin
        SetUserPermissionEnabled := true;
        if IsNullGuid(Rec."User ID") then
            SetUserPermissionEnabled := false;
        EditableByNotEnabled := Rec.State = Rec.State::Disabled;
        ShowEnableWarning := '';
        if CurrPage.Editable and (Rec.State = Rec.State::Enabled) then
            ShowEnableWarning := EnabledWarningTok;
        Clear(UserName);
        Clear(TelemetryUserId);
        if User.Get(Rec."User Id") then begin
            UserName := User."User Name";
            if UserProperty.Get(User."User Security ID") then
                TelemetryUserId := UserProperty."Telemetry User ID"
        end;
    end;

    local procedure DrilldownCode()
    begin
        if Confirm(DisableEnableQst, true) then begin
            Rec.Validate(Rec.State, Rec.State::Disabled);
            UpdateControl();
            CurrPage.Update();
        end;
    end;
}