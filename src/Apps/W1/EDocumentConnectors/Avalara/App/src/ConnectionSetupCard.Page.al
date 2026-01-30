// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.Telemetry;

/// <summary>
/// Connection setup card.
/// allows input of credentials and testing
/// allows Selection of company
/// of connection
/// </summary>

page 6372 "Connection Setup Card"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Avalara Connection Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    Permissions = tabledata "Connection Setup" = rm;
    SourceTable = "Connection Setup";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(ClientID; ClientID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client ID';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the client ID.';

                    trigger OnValidate()
                    begin
                        AvalaraAuth.SetClientId(Rec."Client Id - Key", ClientID);
                    end;
                }
                field(ClientSecret; ClientSecret)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Client Secret';
                    ExtendedDatatype = Masked;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the client secret.';

                    trigger OnValidate()
                    begin
                        AvalaraAuth.SetClientSecret(Rec."Client Secret - Key", ClientSecret);
                    end;
                }
                field("Authentication URL"; Rec."Authentication URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL to connect to Avalara.';
                }
                field("API URL"; Rec."API URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL to connect to Avalara''s api.';
                }
                field("Sandbox Authentication URL"; Rec."Sandbox Authentication URL")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the URL to connect to Avalara sandbox.';
                }
                field("Sandbox API URL"; Rec."Sandbox API URL")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sandbox API URL';
                    ToolTip = 'Specifies the URL to connect to Avalara sandbox api.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the company name.';
                }
                field("Company Id"; Rec."Company Id")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the company ID.';
                }
                field("Token Expiry"; Rec."Token Expiry")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Token Expiry';
                }
                field("Avalara Send Mode"; Rec."Avalara Send Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the send mode.';
                }
#if not CLEAN27
                field("Send Mode"; Rec."Send Mode")
                {
                    ApplicationArea = Basic, Suite;
                    ObsoleteReason = 'Use "Avalara Send Mode" instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the send mode.';
                    Visible = false;
                }
#endif
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectCompanyId)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Avalara Company Id';
                Image = SelectEntries;
                ToolTip = 'Select Avalara company for service.';

                trigger OnAction()
                begin
                    AvalaraProcessing.UpdateCompanyId(Rec);
                    CurrPage.Update();
                end;
            }

            /// <summary>
            /// Set country mandate and gets input fields associated with the mandate.
            /// </summary>

            action(SelectMandate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Avalara Mandate';
                Image = SelectEntries;
                ToolTip = 'Select Avalara company for service.';

                trigger OnAction()
                var
                    tempMandate: Record Mandate;
                    MandateSelected: Text;
                begin
                    MandateSelected := '';

                    AvalaraProcessing.UpdateMandate(MandateSelected);
                    if MandateSelected <> '' then
                        AvalaraProcessing.GetSingleMandate(tempMandate, MandateSelected);
                end;
            }

            /// <summary>
            /// Checks credentials by requesting the orl/registations.
            /// the response is not processed it proves the credentials
            /// </summary>

            action(CheckCredentials)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Check Credentials';
                Image = SelectEntries;
                ToolTip = 'Request a new authorisation token to confirm current settings ';

                trigger OnAction()
                var
                    Result: Text;
                begin
                    Result := AvalaraProcessing.GetRegistrationList();
                    if StrLen(Result) > 3 then
                        Message('Credentials are valid for the selected sending mode environment.');
                end;
            }
        }
        area(Promoted)
        {
            actionref(SelectCompanyIdRef; SelectCompanyId) { }
            actionref(SelectMandateRef; SelectMandate) { }
            actionref(CheckCredentialsRef; CheckCredentials) { }
        }
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000NHL', AvalaraProcessing.GetAvalaraTok(), Enum::"Feature Uptake Status"::Discovered);
        AvalaraAuth.CreateConnectionSetupRecord();
        AvalaraAuth.IsClientCredsSet(ClientID, ClientSecret);
    end;

    trigger OnClosePage()
    begin
        Rec.TestField("Company Id");
    end;

    var

        AvalaraAuth: Codeunit Authenticator;
        AvalaraProcessing: Codeunit Processing;
        [NonDebuggable]
        ClientID, ClientSecret : Text;
}
