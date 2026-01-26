// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

page 15000302 "Recurring Entries"
{
    Caption = 'Recurring Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Recurring Post";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Blanket Order No."; Rec."Blanket Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the blanket order number associated with the recurring document.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the recurring post.';
                }
                field(Time; Rec.Time)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time of the recurring post.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type associated with the recurring post.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number associated with the recurring document.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID associated with the recurring post.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the serial number associated with the recurring document.';
                }
            }
        }
    }

    actions
    {
    }
}

