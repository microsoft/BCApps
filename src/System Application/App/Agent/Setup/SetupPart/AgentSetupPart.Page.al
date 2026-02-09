// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

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
    InherentEntitlements = X;
    InherentPermissions = X;

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
                    ToolTip = 'The badge of the agent.';
                }
                field(Type; AgentPublisherText)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the publisher/type of the agent.';
                }
                field(Name; Rec."Display Name")
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the name of the agent.';
                }
                field(State; Rec.State)
                {
                    Caption = 'Active';
                    ToolTip = 'Specifies the state of the agent, such as active or inactive.';
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
                    ToolTip = 'Specifies the language and region settings for the agent.';

                    trigger OnDrillDown()
                    begin
                        if AgentSetup.OpenLanguageAndRegionPage(Rec) then begin
                            UpdateAgentSummaryDisplayText();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(UserAccessLink; ManageUserAccessLbl)
                {
                    Caption = 'Coworkers can use this agent.';
                    Editable = false;
                    ToolTip = 'Specifies the user access control settings for the agent.';

                    trigger OnDrillDown()
                    begin
                        if AgentSetup.UpdateUserAccessControl(Rec) then
                            CurrPage.Update(false);
                    end;
                }
            }
            field(Summary; AgentSummaryDisplayText)
            {
                Caption = 'Summary';
                MultiLine = true;
                Editable = false;
                ToolTip = 'Specifies a brief description of the agent.';
            }
            field(LanguageUsed; Rec."Language Used")
            {
                Caption = 'Language used';
                Editable = false;
                ToolTip = 'Specifies the language that the agent uses to communicate.';
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
        UpdateAgentSummaryDisplayText();
        UpdateAgentPublisherText();
    end;

    /// <summary>
    /// Returns the setup buffer from this page that can be used to save the agent configuration. See <see cref="SaveChanges"/> method in <see cref="Agent Setup"/> codeunit.
    /// </summary>
    /// <param name="AgentSetupBuffer">The setup buffer that is used for configuring the agent.</param>
    procedure GetAgentSetupBuffer(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetupImpl: Codeunit "Agent Setup Impl.";
    begin
        AgentSetupImpl.CopyAgentSetupBuffer(AgentSetupBuffer, Rec);
    end;

    /// <summary>
    /// Sets the agent setup buffer as the new record.
    /// You need to update the page manually after calling this method.
    /// </summary>
    /// <param name="AgentSetupBuffer">
    /// The setup buffer that is used for configuring the agent that will be set as a new record.
    /// </param>
    procedure SetAgentSetupBuffer(var AgentSetupBuffer: Record "Agent Setup Buffer")
    var
        AgentSetupImpl: Codeunit "Agent Setup Impl.";
    begin
        AgentSetupImpl.CopyAgentSetupBuffer(Rec, AgentSetupBuffer);
        AgentSummary := AgentSetupImpl.GetAgentSummary(AgentSetupBuffer);
        UpdateAgentSummaryDisplayText();
        UpdateAgentPublisherText();
    end;

    /// <summary>
    /// Sets the agent summary to the page.
    /// You need to update the page manually after calling this method.
    /// </summary>
    /// <param name="NewAgentSummary">
    /// The new summary information about the agent.
    /// </param>
    procedure SetAgentSummary(NewAgentSummary: Text)
    begin
        AgentSummary := NewAgentSummary;
        UpdateAgentSummaryDisplayText();
    end;

    /// <summary>
    /// Returns if the changes were made to the setup.
    /// </summary>
    /// <returns>>True if there are changes made, false otherwise.</returns>
    procedure GetChangesMade(): Boolean
    begin
        exit(AgentSetup.GetChangesMade(Rec));
    end;

    local procedure UpdateAgentSummaryDisplayText()
    var
        AgentSetupImpl: Codeunit "Agent Setup Impl.";
    begin
        AgentSummaryDisplayText := AgentSetupImpl.AppendAgentSummary(Rec, AgentSummary);
    end;

    local procedure UpdateAgentPublisherText()
    begin
        AgentPublisherText := GetAgentPublisherText();
    end;

    local procedure GetAgentPublisherText(): Text
    var
        AgentUtilities: Codeunit "Agent Utilities";
        AgentPublisherType: Enum "Agent Publisher Type";
        AgentPublisherName: Text[250];
    begin
        if not AgentUtilities.TryGetAgentPublisherInfo(Rec."Agent Metadata Provider", AgentPublisherName, AgentPublisherType) then
            exit('');

        if AgentPublisherType = AgentPublisherType::User then
            exit(UserCreatedAgentPublisherLbl);

        exit(StrSubstNo(AgentPublisherLbl, AgentPublisherName));
    end;

    var
        AgentSetup: Codeunit "Agent Setup";
        AgentSummaryDisplayText: Text;
        AgentSummary: Text;
        AgentPublisherText: Text;
        AgentPublisherLbl: Label 'By %1', Comment = '%1 is The agent publisher name';
        UserCreatedAgentPublisherLbl: Label 'Agent';
        ManageUserAccessLbl: Label 'Manage user access';
        LanguageAndRegionLbl: Label 'Language and region';
}