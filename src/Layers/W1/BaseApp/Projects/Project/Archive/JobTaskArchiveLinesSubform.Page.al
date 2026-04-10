// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.Projects.Project.Job;

page 5181 "Job Task Archive Lines Subform"
{
    Caption = 'Project Task Archive Lines Subform';
    DataCaptionFields = "Job No.";
    PageType = ListPart;
    Editable = false;
    SourceTable = "Job Task Archive";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    Visible = false;
                }
                field("Job Task No."; Rec."Job Task No.")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                }
                field("Job Task Type"; Rec."Job Task Type")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Customer No.';
                    Visible = PerTaskBillingFieldsVisible;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Jobs;
                    Visible = PerTaskBillingFieldsVisible;
                }
                field("Job Posting Group"; Rec."Job Posting Group")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Jobs;
                    Visible = false;
                }
                field("WIP-Total"; Rec."WIP-Total")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("WIP Method"; Rec."WIP Method")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                }
                field("Schedule (Total Cost)"; Rec."Schedule (Total Cost)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    Caption = 'Budget (Total Cost)';
                    ToolTip = 'Specifies, in the local currency, the total budgeted cost for the project task during the time period in the Planning Date Filter field.';
                }
                field("Schedule (Total Price)"; Rec."Schedule (Total Price)")
                {
                    ApplicationArea = Suite;
                    Caption = 'Budget (Total Price)';
                    ToolTip = 'Specifies, in local currency, the total budgeted price for the project task during the time period in the Planning Date Filter field.';
                    Visible = false;
                }
                field("Usage (Total Cost)"; Rec."Usage (Total Cost)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in local currency, the total cost of the usage of items, resources and general ledger expenses posted on the project task during the time period in the Posting Date Filter field.';
                }
                field("Usage (Total Price)"; Rec."Usage (Total Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in the local currency, the total price of the usage of items, resources and general ledger expenses posted on the project task during the time period in the Posting Date Filter field.';
                    Visible = false;
                }
                field("Contract (Total Cost)"; Rec."Contract (Total Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in local currency, the total billable cost for the project task during the time period in the Planning Date Filter field.';
                    Visible = false;
                }
                field("Contract (Total Price)"; Rec."Contract (Total Price)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the project task during the time period in the Planning Date Filter field.';
                }
                field("Contract (Invoiced Cost)"; Rec."Contract (Invoiced Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies, in the local currency, the total billable cost for the project task that has been invoiced during the time period in the Posting Date Filter field.';
                    Visible = false;
                }
                field("Contract (Invoiced Price)"; Rec."Contract (Invoiced Price)")
                {
                    ApplicationArea = Basic, Suite, Jobs;
                    ToolTip = 'Specifies, in the local currency, the total billable price for the project task that has been invoiced during the time period in the Posting Date Filter field.';
                }
                field("Remaining (Total Cost)"; Rec."Remaining (Total Cost)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining total cost (LCY) as the sum of costs from project planning lines associated with the project task. The calculation occurs when you have specified that there is a usage link between the project ledger and the project planning lines.';
                    Visible = false;
                }
                field("Remaining (Total Price)"; Rec."Remaining (Total Price)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the remaining total price (LCY) as the sum of prices from project planning lines associated with the project task. The calculation occurs when you have specified that there is a usage link between the project ledger and the project planning lines.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Jobs;
                    Visible = PerTaskBillingFieldsVisible;
                    Tooltip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Your Reference"; Rec."Your Reference")
                {
                    ApplicationArea = Jobs;
                    Visible = PerTaskBillingFieldsVisible;
                    Tooltip = 'Specifies the customer''s reference. The content will be printed on sales documents.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Line)
            {
                Caption = 'Line';
                group("&Job")
                {
                    Caption = '&Project';
                    Image = Job;
                    action(JobPlanningLines)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project &Planning Lines';
                        Image = JobLines;
                        Scope = Repeater;
                        ToolTip = 'View all planning lines for the project. You use this window to plan what items, resources, and general ledger expenses that you expect to use on a project (budget) or you can specify what you actually agreed with your customer that he should pay for the project (billable).';

                        trigger OnAction()
                        var
                            JobPlanningLineArchive: Record "Job Planning Line Archive";
                            JobPlanningArchiveLines: Page "Job Planning Archive Lines";
                        begin
                            Rec.TestField("Job No.");
                            JobPlanningLineArchive.SetRange("Job No.", Rec."Job No.");
                            JobPlanningLineArchive.SetRange("Job Task No.", Rec."Job Task No.");
                            JobPlanningLineArchive.SetRange("Version No.", Rec."Version No.");
                            JobPlanningArchiveLines.SetTableView(JobPlanningLineArchive);
                            JobPlanningArchiveLines.Editable := true;
                            JobPlanningArchiveLines.Run();
                        end;
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := Rec.Indentation;
        StyleIsStrong := Rec."Job Task Type" <> "Job Task Type"::Posting;
    end;

    trigger OnOpenPage()
    var
        JobArchive: Record "Job Archive";
    begin
        if JobArchive.Get(Rec."Job No.") then
            PerTaskBillingFieldsVisible := JobArchive."Task Billing Method" = JobArchive."Task Billing Method"::"Multiple customers";
    end;

    trigger OnInit()
    begin
        PerTaskBillingFieldsVisible := false;
    end;

    var
        DescriptionIndent: Integer;
        StyleIsStrong: Boolean;
        PerTaskBillingFieldsVisible: Boolean;
}

