// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Foundation.Reporting;
using Microsoft.Projects.Project.Posting;

page 276 "Job Journal Batches"
{
    Caption = 'Project Journal Batches';
    DataCaptionExpression = DataCaption();
    Editable = true;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Job Journal Batch";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Jobs;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Jobs;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Jobs;
                }
                field("Posting No. Series"; Rec."Posting No. Series")
                {
                    ApplicationArea = Jobs;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Jobs;
                    Visible = true;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of lines in this journal batch.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Edit Journal")
            {
                ApplicationArea = Jobs;
                Caption = 'Edit Journal';
                Image = OpenJournal;
                ShortCutKey = 'Return';
                ToolTip = 'Open a journal based on the journal batch.';

                trigger OnAction()
                begin
                    JobJnlMgt.TemplateSelectionFromBatch(Rec);
                end;
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Test Report';
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintJobJnlBatch(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Jobs;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    RunObject = Codeunit "Job Jnl.-B.Post";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action("Post and &Print")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    RunObject = Codeunit "Job Jnl.-B.Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Journal_Promoted"; "Edit Journal")
                {
                }
                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("P&ost_Promoted"; "P&ost")
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Journal Template Name");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetupNewBatch();
    end;

    trigger OnOpenPage()
    begin
        JobJnlMgt.OpenJnlBatch(Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        JobJnlMgt: Codeunit JobJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        JobJnlTemplate: Record "Job Journal Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Journal Template Name") <> '' then
                if Rec.GetRangeMin("Journal Template Name") = Rec.GetRangeMax("Journal Template Name") then
                    if JobJnlTemplate.Get(Rec.GetRangeMin("Journal Template Name")) then
                        exit(JobJnlTemplate.Name + ' ' + JobJnlTemplate.Description);
    end;
}

