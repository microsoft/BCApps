// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 779 "Analysis Report Chart List"
{
    Caption = 'Analysis Report Chart List';
    CardPageID = "Analysis Report Chart Setup";
    PageType = List;
    SourceTable = "Analysis Report Chart Setup";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Suite;
                }
                field("Analysis Area"; Rec."Analysis Area")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Analysis Report Name"; Rec."Analysis Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Base X-Axis on"; Rec."Base X-Axis on")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Suite;
                }
                field("End Date"; Rec."End Date")
                {
                    ApplicationArea = Suite;
                }
                field("Period Length"; Rec."Period Length")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No. of Periods"; Rec."No. of Periods")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Start Date" := WorkDate();
    end;
}

