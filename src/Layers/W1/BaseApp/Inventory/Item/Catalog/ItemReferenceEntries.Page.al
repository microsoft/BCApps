// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Inventory.Reports;

page 5737 "Item Reference Entries"
{
    Caption = 'Item Reference Entries';
    DataCaptionFields = "Item No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Reference";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Reference Type"; Rec."Reference Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reference Type No."; Rec."Reference Type No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item linked to this reference. It will override the standard description when entered on an order.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an additional description of the item linked to this reference.';
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
        area(Processing)
        {
            action(PrintLabel)
            {
                ApplicationArea = Basic, Suite;
                Image = Print;
                Caption = 'Print Label';
                ToolTip = 'Print Label';

                trigger OnAction()
                var
                    ItemReference: Record "Item Reference";
                    ReferenceNoLabel: Report "Reference No Label";
                begin
                    ItemReference := Rec;
                    CurrPage.SetSelectionFilter(ItemReference);
                    ReferenceNoLabel.SetTableView(ItemReference);
                    ReferenceNoLabel.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Report';

                actionref("Print Label"; PrintLabel)
                {

                }
            }
        }
    }
}

