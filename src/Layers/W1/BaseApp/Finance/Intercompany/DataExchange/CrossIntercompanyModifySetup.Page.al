// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

using Microsoft.Intercompany.Partner;

page 565 "CrossIntercompany Modify Setup"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany External Setup';
    PageType = StandardDialog;
    SourceTable = "IC Partner";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(DataExchangeInformation)
            {
                ShowCaption = false;

                field("Code"; Rec.Code)
                {
                    Caption = 'IC Partner Code';
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code.';
                    Enabled = false;
                    Editable = false;
                }
                field(ConnectionUrl; ConnectionUrl)
                {
                    Caption = 'IC Partner''s Connection URL';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the connection URL for the intercompany partner''s environment.';
                }
                field(CompanyId; CompanyId)
                {
                    Caption = 'IC Partner''s Company ID';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the intercompany partner''s company ID in their environment.';
                }
                field(ClientId; ClientId)
                {
                    Caption = 'Client ID';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the client ID of the Microsoft Entra authentication application.';
                }
                field(ClientSecret; NewClientSecret)
                {
                    Caption = 'Client Secret';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ExtendedDatatype = Masked;
                    ToolTip = 'Specifies the client secret of the Microsoft Entra authentication application.';
                    trigger OnValidate()
                    begin
                        if NewClientSecret <> ClientSecretTok then
                            ClientSecretModified := true;
                    end;
                }
                field(TokenEndpoint; TokenEndpoint)
                {
                    Caption = 'Token Endpoint';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the OAuth 2.0 token endpoint of the Microsoft Entra authentication application.';
                }
                field(RedirectUrl; RedirectUrl)
                {
                    Caption = 'Redirect URL';
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                    ToolTip = 'Specifies the OAuth 2.0 redirect URL of the Microsoft Entra authentication application.';
                }
            }
        }
    }

#if not CLEAN25
    actions
    {
        area(Processing)
        {
            action(TestConnection)
            {
                ApplicationArea = Intercompany;
                Caption = 'Test Connection';
                ToolTip = 'Test the connection to the partner''s company to check whether authentication is correctly set up.';
                Image = InteractionTemplateSetup;
                Visible = false;
                ObsoleteState = Pending;
                ObsoleteReason = 'Moved logic to OnClosePage.';
                ObsoleteTag = '25.0';

                trigger OnAction()
                var
                    CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
                begin
                    if CrossIntercompanyConnector.TestICPartnerSetup(Rec) then
                        Message(SuccesfullConnectionMsg)
                    else
                        Message(FailedConnectionErr);
                end;
            }
        }
    }
#endif

    trigger OnOpenPage()
    begin
        PopulatePartnerSensibleDetails();
        ClientSecretModified := false;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempICPartner: Record "IC Partner" temporary;
    begin
        if CloseAction <> CloseAction::OK then
            exit(true);

        SaveConfigurationToTemporaryPartner(TempICPartner);
        if not AreNewConnectionDetailsValid(TempICPartner) then begin
            Message(GetLastErrorText());
            exit(false);
        end;

        Rec."Connection Url Key" := TempICPartner."Connection Url Key";
        Rec."Company Id Key" := TempICPartner."Company Id Key";
        Rec."Client Id Key" := TempICPartner."Client Id Key";
        Rec."Client Secret Key" := TempICPartner."Client Secret Key";
        Rec."Token Endpoint Key" := TempICPartner."Token Endpoint Key";
        Rec."Redirect Url Key" := TempICPartner."Redirect Url Key";
        Rec.Modify(true);
        exit(true);
    end;

    [TryFunction]
    local procedure AreNewConnectionDetailsValid(var TempICPartner: Record "IC Partner" temporary)
    var
        CrossIntercompanyConnector: Codeunit "CrossIntercompany Connector";
    begin
        CrossIntercompanyConnector.TestICPartnerSetup(TempICPartner);
        CrossIntercompanyConnector.FinishICPartnerSetup(TempICPartner);
    end;

    var
        [NonDebuggable]
        NewClientSecret: Text;
        ClientSecretModified: Boolean;
        ConnectionUrl, TokenEndpoint, RedirectUrl : Text;
        CompanyId, ClientId : Guid;
#if not CLEAN25
        SuccesfullConnectionMsg: Label 'Connection to the partner''s company was successful.';
        FailedConnectionErr: Label 'Connection to the partner''s company failed.';
#endif
        ClientSecretTok: Label '*********', Locked = true;

    [NonDebuggable]
    local procedure PopulatePartnerSensibleDetails()
    var
        ICPartnerChangeMonitor: Codeunit "IC Partner Change Monitor";
    begin
        ICPartnerChangeMonitor.CheckHasPermissionsToChangeSensitiveFields();

        ConnectionUrl := Rec.GetSecret(Rec."Connection Url Key").Unwrap();
        if not Rec.GetSecret(Rec."Company Id Key").IsEmpty() then
            CompanyId := Rec.GetSecret(Rec."Company Id Key").Unwrap();
        if not Rec.GetSecret(Rec."Client Id Key").IsEmpty() then
            ClientId := Rec.GetSecret(Rec."Client Id Key").Unwrap();
        NewClientSecret := ClientSecretTok;
        TokenEndpoint := Rec.GetSecret(Rec."Token Endpoint Key").Unwrap();
        RedirectUrl := Rec.GetSecret(Rec."Redirect Url Key").Unwrap();
    end;

    local procedure SaveConfigurationToTemporaryPartner(var TempICPartner: Record "IC Partner" temporary)
    var
        ICPartnerChangeMonitor: Codeunit "IC Partner Change Monitor";
        CompanyIdentification, Auth2ClientId : SecretText;
    begin
        ICPartnerChangeMonitor.CheckHasPermissionsToChangeSensitiveFields();
        TempICPartner.Reset();

        CompanyIdentification := Format(CompanyId);
        Auth2ClientId := Format(ClientId);

        TempICPartner.Code := Rec.Code;
        TempICPartner.Name := Rec.Name;
        TempICPartner."Inbox Details" := Rec."Inbox Details";
        TempICPartner."Connection Url Key" := TempICPartner.SetSecret(TempICPartner."Connection Url Key", ConnectionUrl);
        TempICPartner."Company Id Key" := TempICPartner.SetSecret(TempICPartner."Company Id Key", CompanyIdentification);
        TempICPartner."Client Id Key" := TempICPartner.SetSecret(TempICPartner."Client Id Key", Auth2ClientId);
        TempICPartner."Token Endpoint Key" := TempICPartner.SetSecret(TempICPartner."Token Endpoint Key", TokenEndpoint);
        TempICPartner."Redirect Url Key" := TempICPartner.SetSecret(TempICPartner."Redirect Url Key", RedirectUrl);
        TempICPartner."Token Expiration Time" := CurrentDateTime;

        if ClientSecretModified then
            TempICPartner."Client Secret Key" := TempICPartner.SetSecret(TempICPartner."Client Secret Key", NewClientSecret)
        else
            TempICPartner."Client Secret Key" := Rec."Client Secret Key";

        TempICPartner."Inbox Type" := Enum::Microsoft.Intercompany.Partner."IC Partner Inbox Type"::Database;
        TempICPartner."Data Exchange Type" := Enum::"IC Data Exchange Type"::API;

        TempICPartner.Insert();
    end;
}
