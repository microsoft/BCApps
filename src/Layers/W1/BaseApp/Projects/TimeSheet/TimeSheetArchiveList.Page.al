// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Security.User;

page 960 "Time Sheet Archive List"
{
    ApplicationArea = Jobs;
    Caption = 'Time Sheet Archives';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Time Sheet Header Archive";
    SourceTableView = sorting("Resource No.", "Starting Date") order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Jobs;
                }
                field("Resource No."; Rec."Resource No.")
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&View Time Sheet")
            {
                ApplicationArea = Jobs;
                Caption = '&View Time Sheet';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open the time sheet.';

                trigger OnAction()
                begin
                    ViewTimeSheet();
                end;
            }
        }
        area(navigation)
        {
            group("&Time Sheet")
            {
                Caption = '&Time Sheet';
                Image = Timesheet;
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Time Sheet Arc. Comment Sheet";
                    RunPageLink = "No." = field("No."),
                                  "Time Sheet Line No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&View Time Sheet_Promoted"; "&View Time Sheet")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if UserSetup.Get(UserId) then
            CurrPage.Editable := UserSetup."Time Sheet Admin.";
        TimeSheetMgt.FilterTimeSheetsArchive(Rec, Rec.FieldNo("Owner User ID"));
        OnAfterOnOpenPage(Rec);
    end;

    var
        UserSetup: Record "User Setup";
        TimeSheetMgt: Codeunit "Time Sheet Management";

    local procedure ViewTimeSheet()
    begin
        Page.Run(Page::"Time Sheet Archive Card", Rec)
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage(var TimeSheetHeaderArchive: Record "Time Sheet Header Archive")
    begin
    end;
}

