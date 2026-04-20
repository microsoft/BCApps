// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;

page 4322 "Agent Task Log Entry Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Editable = false;
    SourceTable = "Agent Task Log Entry";
    Caption = 'Agent Task Log Entry';
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(DescriptionGroup)
            {
                Caption = 'Description';
                Visible = Rec.Description <> '';

                field(Description; Rec.Description)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the description of the log entry.';
                    Style = Subordinate;
                    MultiLine = true;
                }
            }
            group(ReasonGroup)
            {
                Caption = 'Reason';
                Visible = Rec.Reason <> '';

                field(Reason; Rec.Reason)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the reason, provided by the agent, for the log entry.';
                    Style = Subordinate;
                    MultiLine = true;
                }
            }
            group(DetailsGroup)
            {
                Caption = 'Details';
                Visible = LogEntryDetailsTxt <> '';

                field(Details; LogEntryDetailsTxt)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies the details of the log entry.';
                    Style = Subordinate;
                    MultiLine = true;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        LogEntryDetailsTxt := AgentTaskImpl.GetDetailsForAgentTaskLogEntry(Rec);
    end;

    var
        LogEntryDetailsTxt: Text;
}