// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.Foundation.Reporting;

page 5888 "Posted Phys. Invt. Rec. List"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Phys. Invt. Rec. List';
    CardPageID = "Posted Phys. Invt. Recording";
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Record Hdr";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Order No. of the table physical inventory recording header.';
                }
                field("Recording No."; Rec."Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Recording No. of the table physical inventory recording header.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Description of the table physical inventory recording header.';
                }
                field("Person Responsible"; Rec."Person Responsible")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Person Responsible of the table physical inventory recording header.';
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Date Recorded of the table physical inventory recording header.';
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Time Recorded of the table physical inventory recording header.';
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Person Recorded of the table physical inventory recording header.';
                }
            }
        }
    }

    actions
    {
        area(reporting)
        {
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                ToolTip = 'Print inventory count order recording.';

                trigger OnAction()
                var
                    DocumentPrint: Codeunit "Document-Print";
                begin
                    DocumentPrint.PrintPostedInvtRecording(Rec, true);
                end;
            }
        }
        area(Promoted)
        {
        }
    }
}

