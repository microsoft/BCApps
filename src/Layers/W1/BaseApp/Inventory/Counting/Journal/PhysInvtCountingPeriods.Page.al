// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

page 7381 "Phys. Invt. Counting Periods"
{
    AdditionalSearchTerms = 'physical count periods,inventory cycle periods';
    ApplicationArea = Basic, Suite, Warehouse;
    Caption = 'Physical Inventory Counting Periods';
    PageType = List;
    SourceTable = "Phys. Invt. Counting Period";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for physical inventory counting period.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the physical inventory counting period.';
                }
                field("Count Frequency per Year"; Rec."Count Frequency per Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of times you want the item or stockkeeping unit to be counted each year.';
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
}

