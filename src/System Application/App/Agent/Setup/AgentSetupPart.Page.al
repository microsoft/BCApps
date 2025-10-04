// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

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
                        Rec.SetConfigUpdated(true);
                    end;
                }
                field(LanguageAndRegion; LanguageAndRegionLbl)
                {
                    ShowCaption = false;
                    Editable = false;
                    ToolTip = 'Specifies the language and region settings for the sales order agent.';

                    ApplicationArea = All;
                    trigger OnDrillDown()
                    begin
                        Rec.SetupLanguageAndRegion();
                    end;

                }
                field(UserSettingsLink; ManageUserAccessLbl)
                {
                    Caption = 'Coworkers can use this agent.';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the user access control settings for the sales order agent.';

                    trigger OnDrillDown()
                    begin
                        Rec.UpdateUserAccessControl();
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

                ApplicationArea = All;
            }
        }
    }

    procedure InitializePart(UserSecurityID: Guid; AgentMetadataProvider: Enum "Agent Metadata Provider"; DefaultUserName: Code[50]; DefaultDisplayName: Text[80]; NewAgentSummary: Text)
    begin
        Rec.Initialize(UserSecurityID, AgentMetadataProvider, DefaultUserName, DefaultDisplayName, NewAgentSummary);
        AgentSummary := NewAgentSummary;
    end;

    procedure GetChangesMade(): Boolean
    begin
        exit(Rec.GetChangesMade());
    end;

    var
        AgentSummary: Text;
        ManageUserAccessLbl: Label 'Manage user access';
        LanguageAndRegionLbl: Label 'Language and region';
}