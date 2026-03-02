// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;
using System.AI;

/// <summary>
/// ConfigurationDialog page for setting up and configuring the Shopify Tax Matching Agent.
/// Follows the Agent Framework pattern with SourceTable = Agent (temporary).
/// </summary>
page 30470 "Shpfy Tax Agent Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Configure Shopify Tax Matching Agent';
    SourceTable = Agent;
    SourceTableTemporary = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(AgentInfo)
            {
                Caption = 'Agent';

                field(Badge; BadgeTxt)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'The badge of the Shopify Tax Agent.';
                }
                field(Name; Rec."Display Name")
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'The display name of the agent.';
                }
                field(State; Rec.State)
                {
                    Caption = 'Active';
                    ToolTip = 'Specifies whether the agent is active.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                        CurrPage.Update();
                    end;
                }
                field(UserSettingsLink; ManageUserAccessLbl)
                {
                    Caption = 'Coworkers can use this agent.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies which users can interact with this agent.';

                    trigger OnDrillDown()
                    begin
                        if Page.RunModal(Page::"Select Agent Access Control", TempAgentAccessControl) = Action::LookupOK then
                            SetupChanged := true;
                    end;
                }
            }
            group(AgentConfig)
            {
                Caption = 'Configuration';
                InstructionalText = 'Select which Shopify shop this agent should process tax matching for and configure tax matching behavior.';

                field(ShopCode; ShopCode)
                {
                    Caption = 'Shop Code';
                    ToolTip = 'Specifies the Shopify shop this agent instance is configured for. Each shop can only be assigned to one agent.';
                    TableRelation = "Shpfy Shop";

                    trigger OnValidate()
                    var
                        ExistingSetup: Record "Shpfy Tax Agent Setup";
                    begin
                        if (ShopCode <> '') and ExistingSetup.Get(ShopCode) then
                            if ExistingSetup."User Security ID" <> Rec."User Security ID" then
                                Error(ShopAlreadyAssignedErr, ShopCode);
                        SetupChanged := true;
                    end;
                }
                field(AutoCreateJurisdictions; AutoCreateTaxJurisdictions)
                {
                    Caption = 'Auto Create Tax Jurisdictions';
                    ToolTip = 'Specifies whether the tax matching agent can automatically create new Tax Jurisdictions when no match is found in the existing list.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
                }
                field(AutoCreateAreas; AutoCreateTaxAreas)
                {
                    Caption = 'Auto Create Tax Areas';
                    ToolTip = 'Specifies whether the tax matching agent can automatically create new Tax Areas when no matching combination of Tax Jurisdictions exists.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
                }
                field(NamingPattern; TaxAreaNamingPattern)
                {
                    Caption = 'Tax Area Naming Pattern';
                    ToolTip = 'Specifies the prefix pattern used when auto-creating Tax Area codes (e.g., "SHPFY-AUTO-"). A sequential number will be appended.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
                }
            }
            group(AgentSummary)
            {
                Caption = 'About';
                field(Summary; AgentSummaryLbl)
                {
                    Caption = 'Summary';
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Specifies a summary of what this agent does.';
                }
            }
        }
    }

    actions
    {
        area(SystemActions)
        {
            systemaction(OK)
            {
                Caption = 'Update';
                Enabled = SetupChanged;
                ToolTip = 'Apply the changes to the agent setup.';
            }
            systemaction(Cancel)
            {
                Caption = 'Cancel';
                ToolTip = 'Discard the changes to the agent setup.';
            }
        }
    }

    trigger OnOpenPage()
    var
        TaxAgentSetup: Record "Shpfy Tax Agent Setup";
        AzureOpenAI: Codeunit "Azure OpenAI";
        ShpfyTaxAgent: Codeunit "Shpfy Tax Agent";
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::"Shpfy Tax Agent") then
            Error(EnableCapabilityFirstErr);

        BadgeTxt := ShpfyTaxAgent.GetDefaultInitials();

        // Load existing setup if editing an existing agent
        if not IsNullGuid(Rec."User Security ID") then begin
            TaxAgentSetup.SetRange("User Security ID", Rec."User Security ID");
            if TaxAgentSetup.FindFirst() then begin
                ShopCode := TaxAgentSetup."Shop Code";
                AutoCreateTaxJurisdictions := TaxAgentSetup."Auto Create Tax Jurisdictions";
                AutoCreateTaxAreas := TaxAgentSetup."Auto Create Tax Areas";
                TaxAreaNamingPattern := TaxAgentSetup."Tax Area Naming Pattern";
            end;
        end;

        if Rec.Insert() then;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TaxAgentSetup: Record "Shpfy Tax Agent Setup";
        ShpfyTaxAgent: Codeunit "Shpfy Tax Agent";
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        if IsNullGuid(Rec."User Security ID") or (ShopCode = '') then
            exit(true);

        // Set instructions from resource file
        ShpfyTaxAgent.SetAgentInstructions(Rec."User Security ID");

        // Save setup keyed by Shop Code
        if TaxAgentSetup.Get(ShopCode) then begin
            TaxAgentSetup."User Security ID" := Rec."User Security ID";
            TaxAgentSetup."Auto Create Tax Jurisdictions" := AutoCreateTaxJurisdictions;
            TaxAgentSetup."Auto Create Tax Areas" := AutoCreateTaxAreas;
            TaxAgentSetup."Tax Area Naming Pattern" := TaxAreaNamingPattern;
            TaxAgentSetup.Modify();
        end else begin
            // Delete any previous setup for this agent (shop code may have changed)
            TaxAgentSetup.SetRange("User Security ID", Rec."User Security ID");
            TaxAgentSetup.DeleteAll();

            TaxAgentSetup.Init();
            TaxAgentSetup."Shop Code" := ShopCode;
            TaxAgentSetup."User Security ID" := Rec."User Security ID";
            TaxAgentSetup."Auto Create Tax Jurisdictions" := AutoCreateTaxJurisdictions;
            TaxAgentSetup."Auto Create Tax Areas" := AutoCreateTaxAreas;
            TaxAgentSetup."Tax Area Naming Pattern" := TaxAreaNamingPattern;
            TaxAgentSetup.Insert();
        end;

        exit(true);
    end;

    var
        TempAgentAccessControl: Record "Agent Access Control" temporary;
        ShopCode: Code[20];
        BadgeTxt: Text[4];
        AutoCreateTaxJurisdictions: Boolean;
        AutoCreateTaxAreas: Boolean;
        TaxAreaNamingPattern: Text[50];
        SetupChanged: Boolean;
        AgentSummaryLbl: Label 'Matches Shopify tax line descriptions to Business Central Tax Jurisdictions and assigns Tax Areas to orders. Processes orders that are on hold awaiting tax matching.';
        EnableCapabilityFirstErr: Label 'The Shopify Tax Agent capability is not configured. Please activate it on the Copilot & AI Capabilities page.';
        ShopAlreadyAssignedErr: Label 'Shop %1 is already assigned to another Shopify Tax Agent. Each shop can only have one tax matching agent.', Comment = '%1 is the shop code';
        ManageUserAccessLbl: Label 'Manage user access';
}
