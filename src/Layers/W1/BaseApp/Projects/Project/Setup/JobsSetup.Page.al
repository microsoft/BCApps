// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Setup;

using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Job;

page 463 "Jobs Setup"
{
    AccessByPermission = TableData Job = R;
    AdditionalSearchTerms = 'project setup, Jobs Setup';
    ApplicationArea = Jobs;
    Caption = 'Projects Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Jobs Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Automatic Update Job Item Cost"; Rec."Automatic Update Job Item Cost")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies in the Projects Setup window that cost changes are automatically adjusted each time the Adjust Cost - Item Entries batch job is run. The adjustment process and its results are the same as when you run the Update Project Item Cost batch job.';
                }
                field("Apply Usage Link by Default"; Rec."Apply Usage Link by Default")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether project ledger entries are linked to project planning lines by default. Select this check box if you want to apply this setting to all new projects that you create.';
                }
                field("Allow Sched/Contract Lines Def"; Rec."Allow Sched/Contract Lines Def")
                {
                    ApplicationArea = Jobs;
                    Caption = 'Allow Budget/Billable Lines Def';
                    ToolTip = 'Specifies whether project lines can be of type Both Budget and Billable by default. Select this check box if you want to apply this setting to all new projects that you create.';
                }
                field("Default WIP Method"; Rec."Default WIP Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the default method to be used for calculating work in process (WIP). It is applied whenever you create a new project, but you can modify the value on the project card.';
                }
                field("Default WIP Posting Method"; Rec."Default WIP Posting Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies how the default WIP method is to be applied when posting Work in Process (WIP) to the general ledger. By default, it is applied per project.';
                }
                field("Default Job Posting Group"; Rec."Default Job Posting Group")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the default posting group to be applied when you create a new project. This group is used whenever you create a project, but you can modify the value on the project card.';
                }
                field("Default Task Billing Method"; Rec."Default Task Billing Method")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specify whether to use the customer specified for the project for all tasks or allow people to specify different customers. One customer lets you invoice only the customer specified for the project. Multiple customers lets you invoice customers specified on each task, which can be different customers.';
                }
                field("Logo Position on Documents"; Rec."Logo Position on Documents")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                    ToolTip = 'Specifies the position of your company logo on business letters and documents.';
                }
                field("Document No. Is Job No."; Rec."Document No. Is Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies that the project number is also the document number in the ledger entries posted for the project.';
                }
            }
            group(Prices)
            {
                Caption = 'Prices';
                Visible = ExtendedPriceEnabled;
                field("Default Sales Price List Code"; Rec."Default Sales Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing sales price list that stores all new price lines created in the price worksheet page.';
                }
                field("Default Purch Price List Code"; Rec."Default Purch Price List Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the existing purchase price list that stores all new price lines created in the price worksheet page.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("Job Nos."; Rec."Job Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to projects. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
                }
                field("Job WIP Nos."; Rec."Job WIP Nos.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to project WIP documents. To see the number series that have been set up in the No. Series table, click the drop-down arrow in the field.';
                }
                field("Price List Nos."; Rec."Price List Nos.")
                {
                    ApplicationArea = Jobs;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to project price lists.';
                }
            }
            group(Archiving)
            {
                Caption = 'Archiving';

                field("Archive Orders"; Rec."Archive Jobs")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies if you want to automatically archive projects when: deleted, status changed, when project or project task quote sent to customer or related sales invoice posted.';
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
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;
}

