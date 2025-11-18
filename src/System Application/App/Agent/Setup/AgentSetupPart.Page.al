// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.Environment.Configuration;

/// <summary>
/// Setup part that is representing the first page of the configuration dialog
/// </summary>
page 4310 "Agent Setup Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Extensible = false;
    Caption = 'Configure Agent';
    InstructionalText = 'Choose how the agent helps with inquiries, quotes, and orders.';
    SourceTable = "Agent Setup Buffer";
    RefreshOnActivate = true;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                field(Badge; Rec.Initials)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'The badge of the sales order agent.';
                }
                field(Type; Rec."Agent Metadata Provider")
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the type of the sales order agent.';
                }
                field(Name; Rec."Display Name")
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the sales order agent.';
                }
                field(State; Rec.State)
                {
                    Caption = 'Active';
                    ToolTip = 'Specifies the state of the sales order agent, such as active or inactive.';
                    trigger OnValidate()
                    begin
                        Rec."State Updated" := true;
                        Rec.Modify();
                        CurrPage.Update(false);
                    end;
                }
                field(LanguageAndRegion; LanguageAndRegionLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the language and region settings for the sales order agent.';

                    trigger OnDrillDown()
                    begin
                        if AgentSetup.SetupLanguageAndRegion(Rec) then
                            CurrPage.Update(false);
                    end;
                }
                field(UserAccessLink; ManageUserAccessLbl)
                {
                    Caption = 'Coworkers can use this agent.';
                    Editable = false;
                    ToolTip = 'Specifies the user access control settings for the sales order agent.';

                    trigger OnDrillDown()
                    begin
                        if AgentSetup.UpdateUserAccessControl(Rec) then
                            CurrPage.Update(false);
                    end;
                }
            }

            field(Summary; AgentSummary)
            {
                Caption = 'Summary';
                MultiLine = true;
                Editable = false;
                ToolTip = 'Specifies a brief description of the sales order agent.';
            }
            field(LanguageUsed; Rec."Language Used")
            {
                Caption = 'Language used';
                Editable = false;
                ToolTip = 'Specifies the language that the sales order agent uses to communicate.';
            }
        }
    }

    /// <summary>
    /// Initializes the setup page.
    /// </summary>
    /// <param name="UserSecurityID">Represents the User Security ID of the agent being configured. It should be a null guid if it is a new agent</param>
    /// <param name="AgentMetadataProvider">The metadata provider for the agent being configured.</param>
    /// <param name="DefaultUserName">Default user name to use if creating a new agent.</param>
    /// <param name="DefaultDisplayName">Default display name to use if creating a new agent.</param>
    /// <param name="NewAgentSummary">Summary information about the agent showing the agent capabilities.</param>
    procedure Initialize(UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; NewAgentSummary: Text)
    begin
        AgentSetup.GetSetupRecord(Rec, UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName, NewAgentSummary);
        AgentSummary := NewAgentSummary;
    end;

    /// <summary>
    /// Returns the setup buffer from this page that can be used to save the agent configuration. See <see cref="SaveChanges"/> method in <see cref="Agent Setup"/> codeunit.
    /// </summary>
    /// <param name="AgentSetupBuffer">The setup buffer that is used for configuring the agent.</param>
    procedure GetAgentSetupBuffer(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        TempUserSettings: Record "User Settings" temporary;
        TempAccessControl: Record "Agent Access Control" temporary;
    begin
        AgentSetupBuffer.Copy(Rec, true);
        TempUserSettings := Rec.GetUserSettings();
        AgentSetupBuffer.SetUserSettings(TempUserSettings);
        Rec.GetTempAgentAccessControl(TempAccessControl);
        AgentSetupBuffer.SetTempAgentAccessControl(TempAccessControl);
    end;

    var
        AgentSetup: Codeunit "Agent Setup";
        AgentSummary: Text;
        ManageUserAccessLbl: Label 'Manage user access';
        LanguageAndRegionLbl: Label 'Language and region';
}