// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Integration;

page 680 "Report Inbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Inbox';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Report Inbox";
    SourceTableView = sorting("User ID", "Created Date-Time")
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the report.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReport();
                        CurrPage.Update(false);
                    end;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the report.';
                }
                field("Created Date-Time"; Rec."Created Date-Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that the scheduled report was processed from the job queue.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
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
                Enabled = DownloadEnabled;
                Scope = Repeater;
                Image = Download;
                ShortCutKey = 'Return';
                ToolTip = 'Download the file to your device. Depending on the file, you will need an app to view or edit the file.';

                trigger OnAction()
                begin
                    Rec.ShowReport();
                    CurrPage.Update();
                end;
            }

        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenInOneDrive_Promoted; OpenInOneDrive)
                {
                }
                actionref(ShareWithOneDrive_Promoted; ShareWithOneDrive)
                {
                }
                actionref(Show_Promoted; Show)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        DocumentSharing: Codeunit "Document Sharing";
    begin
        ShareOptionsEnabled := (not (Rec."Report Name" = '')) and (DocumentSharing.ShareEnabled());
        DownloadEnabled := (not (Rec."Report Name" = ''));
    end;

    var
        ShareOptionsEnabled: Boolean;
        DownloadEnabled: Boolean;
}

