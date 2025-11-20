// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 578 "Change Global Dim. Log Entries"
{
    Caption = 'Log Entries';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Change Global Dim. Log Entry";
    SourceTableView = sorting(Progress)
                      where("Table ID" = filter(> 0));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    StyleExpr = Style;
                }
                field("Total Records"; Rec."Total Records")
                {
                    ApplicationArea = Suite;
                }
                field(Progress; Rec.Progress)
                {
                    ApplicationArea = Suite;
                }
                field("Remaining Duration"; Rec."Remaining Duration")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining duration of the job.';
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the earliest date and time when the job should be run.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Rerun)
            {
                AccessByPermission = TableData "Change Global Dim. Log Entry" = M;
                ApplicationArea = Suite;
                Caption = 'Rerun';
                Enabled = IsRerunEnabled;
                Image = RefreshLines;
                ToolTip = 'Restart incomplete jobs for global dimension change. Jobs may stop with the Incomplete status because of capacity issues. Such issues can typically be resolved by choosing the Rerun action.';

                trigger OnAction()
                var
                    ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
                begin
                    ChangeGlobalDimensions.Rerun(Rec);
                end;
            }
            action(ShowError)
            {
                ApplicationArea = Suite;
                Caption = 'Show Error';
                Enabled = IsRerunEnabled;
                Image = ErrorLog;
                ToolTip = 'View a message in the Job Queue Log Entries window about the error that stopped the global dimension change job.';

                trigger OnAction()
                begin
                    Rec.ShowError();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.Status in [Rec.Status::Incomplete, Rec.Status::Scheduled] then
            IsRerunEnabled := true
        else
            if Rec.Status = Rec.Status::" " then
                IsRerunEnabled := not AreAllLinesInBlankStatus()
            else
                IsRerunEnabled := false;
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Total Records" <> Rec."Completed Records" then
            Rec.UpdateStatus();
        SetStyle();
    end;

    var
        IsRerunEnabled: Boolean;
        Style: Text;

    local procedure AreAllLinesInBlankStatus(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', ChangeGlobalDimLogEntry.Status::" ");
        exit(ChangeGlobalDimLogEntry.IsEmpty);
    end;

    local procedure SetStyle()
    begin
        case Rec.Status of
            Rec.Status::" ":
                Style := 'Subordinate';
            Rec.Status::Completed:
                Style := 'Favorable';
            Rec.Status::Scheduled,
          Rec.Status::"In Progress":
                Style := 'Ambiguous';
            Rec.Status::Incomplete:
                Style := 'Unfavorable'
        end;
    end;
}

