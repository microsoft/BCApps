// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using System.Reflection;

page 7321 "Whse. Journal Templates"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Journal Templates';
    PageType = List;
    SourceTable = "Warehouse Journal Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the name of the warehouse journal template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a description of the warehouse journal template.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the type of transaction the warehouse journal template is being used for.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Registering No. Series"; Rec."Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number series code used to assign document numbers to the warehouse entries that are registered from this journal.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if batch names using this template are automatically incremented. Example: The posting following BATCH001 is automatically named BATCH002.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the page that is used to show the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the displayed name of the journal or worksheet that uses the template.';
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the test report that is printed when you click Registering, Test Report.';
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the test report that is printed when you click Registering, Test Report.';
                    Visible = false;
                }
                field("Registering Report ID"; Rec."Registering Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the registering report that is printed when you click Registering, Register and Print.';
                    Visible = false;
                }
                field("Registering Report Caption"; Rec."Registering Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the report that is printed when you click Registering, Register and Print.';
                    Visible = false;
                }
                field("Force Registering Report"; Rec."Force Registering Report")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that a registering report is printed automatically when you register entries from the journal.';
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
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Whse. Journal Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                    ToolTip = 'View or edit multiple journals for a specific template. You can use batches when you need multiple journals of a certain type.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Batches_Promoted"; Batches)
            {

            }
        }
    }
}

