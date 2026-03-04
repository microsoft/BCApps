// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Agents;
using System.AI;
using System.Security.AccessControl;

/// <summary>
/// ConfigurationDialog page for setting up and configuring the Shopify Tax Matching Agent.
/// Source table is Shpfy Tax Agent Setup (temporary). The agent framework passes the agent's
/// User Security ID as a filter on the source table before opening this page.
/// </summary>
page 30470 "Shpfy Tax Agent Setup"
{
    PageType = ConfigurationDialog;
    Extensible = false;
    ApplicationArea = All;
    Caption = 'Configure Shopify Tax Matching Agent';
    SourceTable = "Shpfy Tax Agent Setup";
    SourceTableTemporary = true;
    RefreshOnActivate = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            part(AgentSetupPart; "Agent Setup Part")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
            }
            group(AgentConfig)
            {
                Caption = 'Configuration';
                InstructionalText = 'Select which Shopify shop this agent should process tax matching for and configure tax matching behavior.';

                field(ShopCode; Rec."Shop Code")
                {
                    Caption = 'Shop Code';
                    ShowMandatory = true;
                    Editable = false;
                    ToolTip = 'Specifies the Shopify shop this agent instance is configured for. Each shop can only be assigned to one agent.';

                    trigger OnAssistEdit()
                    var
                        ExistingSetup: Record "Shpfy Tax Agent Setup";
                        Shop: Record "Shpfy Shop";
                        ShopSelection: Page "Shpfy Shop Selection";
                    begin
                        Shop.SetRange(Enabled, true);
                        ShopSelection.SetTableView(Shop);
                        ShopSelection.LookupMode := true;
                        if ShopSelection.RunModal() <> Action::LookupOK then
                            exit;

                        ShopSelection.GetRecord(Shop);
                        if Shop.Code = Rec."Shop Code" then
                            exit;

                        if ExistingSetup.Get(Shop.Code) then
                            if ExistingSetup."User Security ID" <> Rec."User Security ID" then
                                Error(ShopAlreadyAssignedErr, Shop.Code);

                        Rec.Rename(Shop.Code);
                        SetupChanged := true;
                        CurrPage.Update();
                    end;
                }
                field(AutoCreateJurisdictions; Rec."Auto Create Tax Jurisdictions")
                {
                    Caption = 'Auto Create Tax Jurisdictions';
                    ToolTip = 'Specifies whether the tax matching agent can automatically create new Tax Jurisdictions when no match is found in the existing list.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
                }
                field(AutoCreateAreas; Rec."Auto Create Tax Areas")
                {
                    Caption = 'Auto Create Tax Areas';
                    ToolTip = 'Specifies whether the tax matching agent can automatically create new Tax Areas when no matching combination of Tax Jurisdictions exists.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
                }
                field(NamingPattern; Rec."Tax Area Naming Pattern")
                {
                    Caption = 'Tax Area Naming Pattern';
                    ToolTip = 'Specifies the prefix pattern used when auto-creating Tax Area codes (e.g., "SHPFY-AUTO-"). A sequential number will be appended.';

                    trigger OnValidate()
                    begin
                        SetupChanged := true;
                    end;
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
        ShpfyTaxAgentCU: Codeunit "Shpfy Tax Agent";
        AgentUserSecurityId: Guid;
    begin
        if not AzureOpenAI.IsEnabled("Copilot Capability"::"Shpfy Tax Agent") then
            Error(EnableCapabilityFirstErr);

        // The agent framework filters the source table by "User Security ID" before opening.
        // Read it to identify which agent we are configuring (null guid = new agent).
        if Rec.GetFilter("User Security ID") <> '' then
            Evaluate(AgentUserSecurityId, Rec.GetFilter("User Security ID"));

        // Load the existing setup for this agent if one exists
        TaxAgentSetup.SetRange("User Security ID", AgentUserSecurityId);
        if TaxAgentSetup.FindFirst() then
            Rec := TaxAgentSetup;
        Rec."User Security ID" := AgentUserSecurityId;
        Rec.Insert();

        // Initialize the Agent Setup Part (badge, name, state, user access controls)
        CurrPage.AgentSetupPart.Page.Initialize(
            AgentUserSecurityId,
            "Agent Metadata Provider"::"Shpfy Tax Agent",
            ShpfyTaxAgentCU.AgentUserName(),
            ShpfyTaxAgentCU.AgentDisplayName(),
            AgentSummaryLbl);
        CurrPage.AgentSetupPart.Page.Update();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        SetupChanged := true;
        exit(true);
    end;

    trigger OnAfterGetCurrRecord()
    var
        AgentSetupBuffer: Record "Agent Setup Buffer";
    begin
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);
        SetupChanged := SetupChanged or AgentSetup.GetChangesMade(AgentSetupBuffer);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TaxAgentSetup: Record "Shpfy Tax Agent Setup";
        AgentSetupBuffer: Record "Agent Setup Buffer";
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        ShpfyTaxAgentCU: Codeunit "Shpfy Tax Agent";
        AgentCU: Codeunit Agent;
        AgentUserSecurityId: Guid;
    begin
        if CloseAction = CloseAction::Cancel then
            exit(true);

        if Rec."Shop Code" = '' then
            exit(true);

        // Save the agent framework configuration (state, access controls, display name, etc.)
        CurrPage.AgentSetupPart.Page.GetAgentSetupBuffer(AgentSetupBuffer);

        // For new agents stamp the shop code into the name so multiple agents are distinguishable
        if IsNullGuid(AgentSetupBuffer."User Security ID") then begin
            AgentSetupBuffer."User Name" := CopyStr('Shpfy Tax Agent (' + Rec."Shop Code" + ') - ' + CompanyName(), 1, MaxStrLen(AgentSetupBuffer."User Name"));
            AgentSetupBuffer."Display Name" := CopyStr('Shopify Tax Matching Agent (' + Rec."Shop Code" + ')', 1, MaxStrLen(AgentSetupBuffer."Display Name"));
            AgentSetupBuffer."Values Updated" := true;
            AgentSetupBuffer.Modify();
        end;

        AgentUserSecurityId := AgentSetup.SaveChanges(AgentSetupBuffer);

        // Assign permission sets to the agent user (not done automatically by the framework)
        ShpfyTaxAgentCU.GetDefaultAccessControls(TempAccessControlBuffer);
        AgentCU.UpdateAccessControl(AgentUserSecurityId, TempAccessControlBuffer);

        // Set instructions from resource file
        ShpfyTaxAgentCU.SetAgentInstructions(AgentUserSecurityId);

        // Save our specific setup keyed by Shop Code
        if TaxAgentSetup.Get(Rec."Shop Code") then begin
            TaxAgentSetup."User Security ID" := AgentUserSecurityId;
            TaxAgentSetup."Auto Create Tax Jurisdictions" := Rec."Auto Create Tax Jurisdictions";
            TaxAgentSetup."Auto Create Tax Areas" := Rec."Auto Create Tax Areas";
            TaxAgentSetup."Tax Area Naming Pattern" := Rec."Tax Area Naming Pattern";
            TaxAgentSetup.Modify();
        end else begin
            // Delete any previous setup for this agent (shop code may have changed)
            TaxAgentSetup.SetRange("User Security ID", AgentUserSecurityId);
            TaxAgentSetup.DeleteAll();

            TaxAgentSetup.Init();
            TaxAgentSetup."Shop Code" := Rec."Shop Code";
            TaxAgentSetup."User Security ID" := AgentUserSecurityId;
            TaxAgentSetup."Auto Create Tax Jurisdictions" := Rec."Auto Create Tax Jurisdictions";
            TaxAgentSetup."Auto Create Tax Areas" := Rec."Auto Create Tax Areas";
            TaxAgentSetup."Tax Area Naming Pattern" := Rec."Tax Area Naming Pattern";
            TaxAgentSetup.Insert();
        end;

        exit(true);
    end;

    var
        AgentSetup: Codeunit "Agent Setup";
        SetupChanged: Boolean;
        AgentSummaryLbl: Label 'Matches Shopify tax line descriptions to Business Central Tax Jurisdictions and assigns Tax Areas to orders. Processes orders that are on hold awaiting tax matching.';
        EnableCapabilityFirstErr: Label 'The Shopify Tax Agent capability is not configured. Please activate it on the Copilot & AI Capabilities page.';
        ShopAlreadyAssignedErr: Label 'Shop %1 is already assigned to another Shopify Tax Agent. Each shop can only have one tax matching agent.', Comment = '%1 is the shop code';
}
