// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Integration;
using System.Threading;

page 681 "Report Inbox Part"
{
    Caption = 'Report Inbox';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Report Inbox";
    SourceTableView = sorting("User ID", "Created Date-Time")
                      order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the name of the report.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReport();
                        CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the description of the scheduled report that was processed from the job queue.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReport();
                        CurrPage.Update();
                    end;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the date and time that the scheduled report was processed from the job queue.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the object ID of the report.';
                    Visible = false;
                }
                field("Output Type"; Rec."Output Type")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Strong;
                    StyleExpr = not Rec.Read;
                    ToolTip = 'Specifies the output type of the scheduled report.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(OpenInOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open in OneDrive';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and open it in a new window so you can manage or share the file.', Comment = 'OneDrive should not be translated';
                Image = Cloud;
                Visible = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.OpenInOneDrive();
                end;
            }
            action(ShareWithOneDrive)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Share';
                ToolTip = 'Copy the file to your Business Central folder in OneDrive and share the file. You can also see who it''s already shared with.', Comment = 'OneDrive should not be translated';
                Image = Share;
                Visible = ShareOptionsEnabled;
                Scope = Repeater;
                trigger OnAction()
                begin
                    Rec.ShareWithOneDrive();
                end;
            }
            action(Show)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Download';
                Enabled = ActionsEnabled;
                Image = Download;
                ShortCutKey = 'Return';
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    Rec.ShowReport();
                    CurrPage.Update();
                end;
            }
            separator(Action11)
            {
            }
            action(Unread)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Unread Reports';
                Enabled = ShowAll;
                Image = FilterLines;
                ToolTip = 'Show only unread reports in your inbox.';

                trigger OnAction()
                begin
                    ShowAll := false;
                    UpdateVisibility();
                end;
            }
            action(All)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'All Reports';
                Enabled = not ShowAll;
                Image = AllLines;
                ToolTip = 'View all reports in your inbox.';

                trigger OnAction()
                begin
                    ShowAll := true;
                    UpdateVisibility();
                end;
            }
            separator(Action14)
            {
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Enabled = ActionsEnabled;
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                var
                    ReportInbox: Record "Report Inbox";
                begin
                    CurrPage.SetSelectionFilter(ReportInbox);
                    ReportInbox.DeleteAll();
                    UpdateVisibility();
                end;
            }
            separator(Action18)
            {
            }
            action(ShowQueue)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Queue';
                Image = List;
                ToolTip = 'Show scheduled reports.';

                trigger OnAction()
                var
                    JobQueueEntry: Record "Job Queue Entry";
                begin
                    JobQueueEntry.FilterGroup(2);
                    JobQueueEntry.SetRange("User ID", UserId);
                    JobQueueEntry.FilterGroup(0);
                    PAGE.Run(PAGE::"Job Queue Entries", JobQueueEntry);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        ShareOptionsEnabled := (not (Rec."Report Name" = '')) and (DocumentSharing.ShareEnabled());
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        ActionsEnabled := not Rec.IsEmpty();
        exit(Rec.Find(Which));
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId);
        Rec.SetAutoCalcFields();
        ShowAll := true;
        UpdateVisibility();
    end;

    var
        ShowAll: Boolean;
        ActionsEnabled: Boolean;
        ShareOptionsEnabled: Boolean;

    local procedure UpdateVisibility()
    begin
        if ShowAll then
            Rec.SetRange(Read)
        else
            Rec.SetRange(Read, false);
        ActionsEnabled := Rec.FindFirst();
        CurrPage.Update(false);
    end;
}

