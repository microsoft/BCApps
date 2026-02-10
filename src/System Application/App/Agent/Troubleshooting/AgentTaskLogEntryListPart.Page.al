// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents.Troubleshooting;

using System.Agents;
using System.Security.AccessControl;

page 4314 "Agent Task Log Entry ListPart"
{
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Agent Task Log Entry";
    CardPageId = "Agent Task Log Entry";
    Caption = 'Agent Task Log';
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Editable = false;
    SourceTableView = sorting("ID") order(descending);
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(LogEntries)
            {
                field(ID; Rec."ID")
                {
                    Caption = 'ID';
                    ToolTip = 'Specifies the unique identifier of the log entry.';
                }
                field(TaskID; Rec."Task ID")
                {
                    Visible = false;
                    Caption = 'Task ID';
                }
                field(Type; Rec.Type)
                {
                    Caption = 'Type';
                    StyleExpr = TypeStyle;
                }
                field(Level; Rec.Level)
                {
                    Caption = 'Level';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Description);
                    end;
                }
                field(Reason; Rec.Reason)
                {
                    Caption = 'Reason';
                    ToolTip = 'Specifies the reason, provided by the agent, for the log entry.';
                    Importance = Promoted;

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Reason);
                    end;
                }
                field(Details; DetailsTxt)
                {
                    Caption = 'Details';
                    ToolTip = 'Specifies the details.';

                    trigger OnDrillDown()
                    begin
                        Message(DetailsTxt);
                    end;
                }
                field(PageCaption; Rec."Page Caption")
                {
                    Caption = 'Page caption';
                }
                field(Username; UserName)
                {
                    Visible = false;
                    Caption = 'User';
                    ToolTip = 'Specifies the name of related user.';
                }
                field(CreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Timestamp';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
                }
            }
        }
    }

    procedure SetTaskId(NewTaskId: integer)
    begin
        Rec.SetRange(Rec."Task ID", NewTaskId);
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        User: Record User;
        AgentTaskImpl: Codeunit "Agent Task Impl.";
    begin
        DetailsTxt := AgentTaskImpl.GetDetailsForAgentTaskLogEntry(Rec);
        case Rec.Level of
            Rec.Level::Error:
                TypeStyle := Format(PageStyle::Unfavorable);
            Rec.Level::Warning:
                TypeStyle := Format(PageStyle::Ambiguous);
            else
                TypeStyle := Format(PageStyle::Standard);
        end;

        User.SetRange("User Security ID", Rec.SystemCreatedBy);
        if User.FindFirst() then
            UserName := User."User Name";
    end;

    internal procedure SetEntryFilter(CurrentEntryID: Integer)
    begin
        Rec.FilterGroup(10);
        Rec.SetFilter("Memory Entry ID", '=%1', CurrentEntryID);
        Rec.FilterGroup(0);
    end;

    var
        DetailsTxt: Text;
        TypeStyle: Text;
        UserName: Text;
}