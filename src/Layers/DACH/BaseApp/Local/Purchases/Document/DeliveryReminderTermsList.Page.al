// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

page 5005280 "Delivery Reminder Terms List"
{
    Caption = 'Delivery Reminder Terms List';
    Editable = false;
    PageType = List;
    SourceTable = "Delivery Reminder Term";

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code to identify this set of delivery reminder terms.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the delivery reminder terms.';
                }
                field("Max. No. of Delivery Reminders"; Rec."Max. No. of Delivery Reminders")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum number of delivery reminders that can be created for an order.';
                }
            }
        }
    }

    actions
    {
    }
}

