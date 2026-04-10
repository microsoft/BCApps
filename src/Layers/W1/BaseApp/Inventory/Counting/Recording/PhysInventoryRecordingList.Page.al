// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Foundation.Reporting;

page 5880 "Phys. Inventory Recording List"
{
    ApplicationArea = Warehouse;
    Caption = 'Phys. Inventory Recording List';
    CardPageID = "Phys. Inventory Recording";
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Record Header";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Recording No."; Rec."Recording No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("Physical Inventory Recording")
            {
                ApplicationArea = Warehouse;
                Caption = 'Physical Inventory Recording';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Prepare to count inventory by creating a recording document to capture the quantities.';

                trigger OnAction()
                var
                    DocumentPrint: Codeunit "Document-Print";
                begin
                    DocumentPrint.PrintInvtRecording(Rec, true);
                end;
            }
        }
        area(Promoted)
        {
        }
    }
}

