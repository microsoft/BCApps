// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Reports;

page 1027 "Job WIP Cockpit"
{
    AdditionalSearchTerms = 'Job WIP Cockpit';
    ApplicationArea = Jobs;
    Caption = 'Project WIP Cockpit';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = Job;
    SourceTableView = where(Status = filter(Open | Completed),
                            "WIP Completion Posted" = const(false));
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            repeater(Jobs)
            {
                FreezeColumn = Description;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number for the project. You can use one of the following methods to fill in the number:';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies a short description of the project.';
                }
                field("WIP Warnings"; Rec."WIP Warnings")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies whether or not there are WIP warnings associated with a project.';
                }
                field("Recog. Costs Amount"; Rec."Recog. Costs Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the Recognized Cost amount that was last calculated for the project. The Recognized Cost Amount for the project is the sum of the Recognized Cost Project WIP Entries.';
                }
                field("Recog. Costs G/L Amount"; Rec."Recog. Costs G/L Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total Recognized Cost amount that was last posted to the general ledger for the project. The Recognized Cost G/L amount for the project is the sum of the Recognized Cost Project WIP G/L Entries.';
                }
                field("Recog. Sales Amount"; Rec."Recog. Sales Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the recognized sales amount that was last calculated for the project, which is the sum of the Recognized Sales Project WIP Entries.';
                }
                field("Recog. Sales G/L Amount"; Rec."Recog. Sales G/L Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total Recognized Sales amount that was last posted to the general ledger for the project. The Recognized Sales G/L amount for the project is the sum of the Recognized Sales Project WIP G/L Entries.';
                }
                field("Recog. Costs Amount Difference"; Rec."Recog. Costs Amount" - Rec."Recog. Costs G/L Amount")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recog. Costs Amount Difference';
                    ToolTip = 'Specifies the difference in recognized costs for the project.';
                }
                field("Recog. Sales Amount Difference"; Rec."Recog. Sales Amount" - Rec."Recog. Sales G/L Amount")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recog. Sales Amount Difference';
                    ToolTip = 'Specifies the difference in recognized sales for the project.';
                }
                field("Recog. Profit Amount"; Rec.CalcRecognizedProfitAmount())
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recog. Profit Amount';
                    ToolTip = 'Specifies the recognized profit amount for the project.';
                }
                field("Recog. Profit G/L Amount"; Rec.CalcRecognizedProfitGLAmount())
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recog. Profit G/L Amount';
                    ToolTip = 'Specifies the total recognized profit G/L amount for this project.';
                }
                field("Recog. Profit Amount Difference"; Rec.CalcRecognizedProfitAmount() - Rec.CalcRecognizedProfitGLAmount())
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recog. Profit Amount Difference';
                    ToolTip = 'Specifies the difference in recognized profit for the project.';
                }
                field("WIP Posting Date"; Rec."WIP Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date that was entered when the Project Calculate WIP batch job was last run.';
                }
                field("WIP G/L Posting Date"; Rec."WIP G/L Posting Date")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the posting date that was entered when the Project Post WIP to general ledger batch job was last run.';
                }
                field("Total WIP Cost Amount"; Rec."Total WIP Cost Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total WIP cost amount that was last calculated for the project. The WIP Cost Amount for the project is the value WIP Cost Project WIP Entries less the value of the Recognized Cost Project WIP Entries. For projects with WIP Methods of Sales Value or Percentage of Completion, the WIP Cost Amount is normally 0.';
                }
                field("Total WIP Cost G/L Amount"; Rec."Total WIP Cost G/L Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total WIP Cost amount that was last posted to the G/L for the project. The WIP Cost Amount for the project is the value WIP Cost Project WIP G/L Entries less the value of the Recognized Cost Project WIP G/L Entries. For projects with WIP Methods of Sales Value or Percentage of Completion, the WIP Cost Amount is normally 0.';
                }
                field("Total WIP Cost Difference"; Rec."Total WIP Cost Amount" - Rec."Total WIP Cost G/L Amount")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total WIP Cost Difference';
                    ToolTip = 'Specifies the difference in total WIP costs.';
                }
                field("Total WIP Sales Amount"; Rec."Total WIP Sales Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total WIP sales amount that was last calculated for the project. It is calculated as the value in the WIP Sales field minus the value in the Recognized Sales field in the Project WIP Entries window. For projects that use the Cost Value or Cost of Sales WIP methods, the WIP sales amount is normally 0. ';
                }
                field("Total WIP Sales G/L Amount"; Rec."Total WIP Sales G/L Amount")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the total WIP sales amount that was last calculated for the project. It is calculated as the value in the WIP Sales field minus the value in the Recognized Sales field in the Project G/L WIP Entries window. For projects that use the Cost Value or Cost of Sales WIP methods, the WIP sales amount is normally 0. ';
                }
                field("Total WIP Sales Difference"; Rec."Total WIP Sales Amount" - Rec."Total WIP Sales G/L Amount")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Total WIP Sales Difference';
                    ToolTip = 'Specifies the difference in total WIP sales.';
                }
            }
            group(JobWIPTotalsGroup)
            {
                ShowCaption = false;
                part(Control28; "Job WIP Totals")
                {
                    ApplicationArea = Jobs;
                    SubPageLink = "Job No." = field("No."),
                                "Posted to G/L" = const(false);
                }
            }
        }
        area(factboxes)
        {
            part(Control34; "Job WIP/Recognition FactBox")
            {
                ApplicationArea = Jobs;
                SubPageLink = "No." = field("No."),
                              "Planning Date Filter" = field("Planning Date Filter"),
                              "Resource Filter" = field("Resource Filter"),
                              "Posting Date Filter" = field("Posting Date Filter"),
                              "Resource Gr. Filter" = field("Resource Gr. Filter");
                Visible = true;
            }
            systempart(Control6; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control5; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("<Action34>")
            {
                Caption = 'Project';
                Image = Job;
                action(Job)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project';
                    Image = JobLedger;
                    RunObject = Page "Job Card";
                    RunPageOnRec = true;
                    ToolTip = 'View or edit detailed information about the project.';
                }
                action("Job Task Lines")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project Task Lines';
                    Image = TaskList;
                    RunObject = Page "Job Task Lines";
                    RunPageLink = "Job No." = field("No.");
                    ToolTip = 'Plan how you want to set up your planning information. In this window you can specify the tasks involved in a project. To start planning a project or to post usage for a project, you must set up at least one project task.';
                }
                action("<Action31>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ledger E&ntries';
                    Image = JobLedger;
                    RunObject = Page "Job Ledger Entries";
                    RunPageLink = "Job No." = field("No.");
                    RunPageView = sorting("Job No.", "Job Task No.", "Entry Type", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("<Action30>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Job Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
            group("W&IP")
            {
                Caption = 'W&IP';
                Image = WIP;
                action("Show Warnings")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Show Warnings';
                    Image = Find;
                    ToolTip = 'View the warning message for lines where the WIP Warnings check box is selected.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobWIPWarning: Record "Job WIP Warning";
                        TempJobWIPWarning: Record "Job WIP Warning" temporary;
                    begin
                        Job.Copy(Rec);
                        CurrPage.SetSelectionFilter(Job);
                        if Job.FindSet() then
                            repeat
                                JobWIPWarning.SetRange("Job No.", Job."No.");
                                if JobWIPWarning.FindSet() then
                                    repeat
                                        TempJobWIPWarning := JobWIPWarning;
                                        TempJobWIPWarning.Insert();
                                    until JobWIPWarning.Next() = 0;
                            until Job.Next() = 0;
                        PAGE.RunModal(PAGE::"Job WIP Warnings", TempJobWIPWarning);
                    end;
                }
                action("WIP Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP Entries';
                    Image = WIPEntries;
                    RunObject = Page "Job WIP Entries";
                    RunPageLink = "Job No." = field("No.");
                    RunPageView = sorting("Job No.", "Job Posting Group", "WIP Posting Date");
                    ToolTip = 'View the project''s WIP entries.';
                }
                action("WIP G/L Entries")
                {
                    ApplicationArea = Jobs;
                    Caption = 'WIP G/L Entries';
                    Image = WIPLedger;
                    RunObject = Page "Job WIP G/L Entries";
                    RunPageLink = "Job No." = field("No."),
                                  Reversed = const(false);
                    RunPageView = sorting("Job No.");
                    ToolTip = 'View the project''s WIP G/L entries.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate WIP")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Calculate WIP';
                    Ellipsis = true;
                    Image = CalculateWIP;
                    ToolTip = 'Use a batch job to help you calculate the value of work in process (WIP) on your projects.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                    begin
                        Rec.TestField("No.");
                        Job.Copy(Rec);
                        Job.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"Job Calculate WIP", true, false, Job);
                    end;
                }
                action("Post WIP to G/L")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Post WIP to G/L';
                    Ellipsis = true;
                    Image = PostOrder;
                    ToolTip = 'Post the project WIP totals to the general ledger.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                    begin
                        Rec.TestField("No.");
                        Job.Copy(Rec);
                        Job.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"Job Post WIP to G/L", true, false, Job);
                    end;
                }
                action("<Action37>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Delete WIP Entries';
                    Image = Delete;
                    ToolTip = 'Delete all WIP entries for the selected projects.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobCalculateWIP: Codeunit "Job Calculate WIP";
                    begin
                        if Confirm(Text001) then begin
                            Job.Copy(Rec);
                            CurrPage.SetSelectionFilter(Job);
                            if Job.FindSet() then
                                repeat
                                    JobCalculateWIP.DeleteWIP(Job);
                                until Job.Next() = 0;

                            Message(Text002);
                        end;
                    end;
                }
                action("<Action38>")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Recalculate WIP';
                    Image = CalculateWIP;
                    ToolTip = 'Calculate the work in process again. Every time WIP is calculated, an entry is created in the Project WIP Entries window.';

                    trigger OnAction()
                    var
                        Job: Record Job;
                        JobWIPEntry: Record "Job WIP Entry";
                        JobCalculateWIP: Codeunit "Job Calculate WIP";
                        FailedJobs: Text[1024];
                    begin
                        if Confirm(Text003) then begin
                            Job.Copy(Rec);
                            CurrPage.SetSelectionFilter(Job);
                            if Job.FindSet() then
                                repeat
                                    JobWIPEntry.SetRange("Job No.", Job."No.");
                                    if not JobWIPEntry.FindFirst() then
                                        FailedJobs := FailedJobs + Job."No." + ', '
                                    else
                                        JobCalculateWIP.JobCalcWIP(Job, Job."WIP Posting Date", JobWIPEntry."Document No.");
                                until Job.Next() = 0;

                            if FailedJobs = '' then
                                Message(Text004)
                            else
                                Message(Text005, DelStr(FailedJobs, StrLen(FailedJobs) - 1, StrLen(FailedJobs)));
                        end;
                    end;
                }
            }
        }
        area(reporting)
        {
            action("<Action32>")
            {
                ApplicationArea = Jobs;
                Caption = 'Project WIP To G/L';
                Image = "Report";
                ToolTip = 'View the value of work in process on the projects that you select compared to the amount that has been posted in the general ledger.';

                trigger OnAction()
                var
                    Job: Record Job;
                begin
                    Rec.TestField("No.");
                    Job.Copy(Rec);
                    Job.SetRange("No.", Rec."No.");
                    REPORT.RunModal(REPORT::"Job WIP To G/L", true, false, Job);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Calculate WIP_Promoted"; "Calculate WIP")
                {
                }
                actionref("Post WIP to G/L_Promoted"; "Post WIP to G/L")
                {
                }
                actionref("<Action37>_Promoted"; "<Action37>")
                {
                }
                actionref("<Action38>_Promoted"; "<Action38>")
                {
                }
                actionref("Show Warnings_Promoted"; "Show Warnings")
                {
                }
                actionref("<Action30>_Promoted"; "<Action30>")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Define', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Job_Promoted; Job)
                {
                }
                actionref("Job Task Lines_Promoted"; "Job Task Lines")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Analyze', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("WIP Entries_Promoted"; "WIP Entries")
                {
                }
                actionref("WIP G/L Entries_Promoted"; "WIP G/L Entries")
                {
                }
                actionref("<Action31>_Promoted"; "<Action31>")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("<Action32>_Promoted"; "<Action32>")
                {
                }
            }
        }
    }

    var
#pragma warning disable AA0074
        Text001: Label 'Are you sure that you want to delete the WIP entries for all selected projects?';
        Text002: Label 'WIP Entries were deleted successfully.';
        Text003: Label 'Are you sure that you want to recalculate the WIP entries for all selected projects?';
        Text004: Label 'WIP Entries were recalculated successfully.';
#pragma warning disable AA0470
        Text005: Label 'The recalculation for the following projects failed because no WIP entries were found: %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

