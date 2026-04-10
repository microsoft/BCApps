namespace System.Security.User;

using Microsoft.EServices.EDocument;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Security.AccessControl;

pageextension 9204 "User Settings" extends "User Settings"
{
    layout
    {
        addbefore("Teaching Tips")
        {
            field(MyNotificationsLbl; MyNotificationsLbl)
            {
                ApplicationArea = All;
                Caption = 'Notifications';
                Editable = false;
                ToolTip = 'Specifies the notifications that can be enabled by the user.';
                Visible = IsMyNotificationsVisible;

                trigger OnDrillDown()
                begin
                    Page.RunModal(Page::"My Notifications");
                end;
            }
        }
        addafter("User Settings")
        {
            group(Files)
            {
                Visible = OneDriveLinkVisible;
                Caption = 'Files';

                field(OpenOneDriveBCFolder; OneDriveLinkText)
                {
                    ApplicationArea = All;
                    Caption = 'Cloud Storage';
                    Editable = false;
                    ToolTip = 'Specifies a link to explore your Business Central folder in OneDrive. Select the link to open the folder in a new window.';
                    AccessByPermission = tabledata "Document Service" = r;

                    trigger OnDrillDown()
                    var
                        DocumentServiceManagement: Codeunit "Document Service Management";
                    begin
                        Hyperlink(DocumentServiceManagement.GetMyBusinessCentralFilesLink());
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        IsNotOnMobile: Boolean;
    begin
        IsNotOnMobile := ClientTypeManagement.GetCurrentClientType() <> ClientType::Phone;
        IsMyNotificationsVisible := IsNotOnMobile and (Rec."User Security ID" = UserSecurityId());
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetOneDriveLinkVisibilityAndText();
    end;

    local procedure SetOneDriveLinkVisibilityAndText()
    var
        User: Record User;
        DummyDocumentService: Record "Document Service";
        DummyDocumentServiceScenario: Record "Document Service Scenario";
        DocumentServiceManagement: Codeunit "Document Service Management";
        EnvironmentInformation: Codeunit "Environment Information";
        DocumentSharing: Codeunit "Document Sharing";
    begin
        OneDriveLinkVisible := false;

        if Rec."User Security ID" = UserSecurityId() then
            if DummyDocumentService.ReadPermission() and DummyDocumentServiceScenario.ReadPermission() then
                if DocumentSharing.ShareEnabled() or EnvironmentInformation.IsSaaSInfrastructure() then begin
                    OneDriveLinkVisible := true;

                    if User.Get(UserSecurityId()) and (User."Full Name" <> '') then
                        OneDriveLinkText := StrSubstNo(OneDriveLinkTextTemplateTxt, User."Full Name")
                    else
                        OneDriveLinkText := StrSubstNo(OneDriveLinkTextTemplateTxt, UserId());
                end;

        Session.LogMessage('0000FPY', StrSubstNo(OneDriveLinkVisibilityTelemetryMsg, OneDriveLinkVisible), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', DocumentServiceManagement.GetTelemetryCategory());
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        OneDriveLinkVisible: Boolean;
        OneDriveLinkText: Text;
        IsMyNotificationsVisible: Boolean;
        MyNotificationsLbl: Label 'Change when I receive notifications.';
        OneDriveLinkTextTemplateTxt: Label '%1''s files on OneDrive', Comment = '%1 = A full user name, for example "John Doe"';
        OneDriveLinkVisibilityTelemetryMsg: Label 'OneDrive link visibility set to %1.', Locked = true;
}