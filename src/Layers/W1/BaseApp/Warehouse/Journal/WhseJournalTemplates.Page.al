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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                }
                field("Registering No. Series"; Rec."Registering No. Series")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Increment Batch Name"; Rec."Increment Batch Name")
                {
                    ApplicationArea = Warehouse;
                }
                field("Page ID"; Rec."Page ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Page Caption"; Rec."Page Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    Visible = false;
                }
                field("Test Report ID"; Rec."Test Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Test Report Caption"; Rec."Test Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    Visible = false;
                }
                field("Registering Report ID"; Rec."Registering Report ID")
                {
                    ApplicationArea = Warehouse;
                    LookupPageID = Objects;
                    Visible = false;
                }
                field("Registering Report Caption"; Rec."Registering Report Caption")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    Visible = false;
                }
                field("Force Registering Report"; Rec."Force Registering Report")
                {
                    ApplicationArea = Warehouse;
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

