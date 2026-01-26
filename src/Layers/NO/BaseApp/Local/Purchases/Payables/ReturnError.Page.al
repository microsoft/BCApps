// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

page 15000013 "Return Error"
{
    Caption = 'Return Error';
    Editable = false;
    PageType = List;
    SourceTable = "Return Error";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Waiting Journal Reference"; Rec."Waiting Journal Reference")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the waiting journal reference associated with the return error.';
                }
                field("Message Text"; Rec."Message Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the message text of the return error.';
                }
                field("Payment Order ID"; Rec."Payment Order ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the payment order associated with the return error.';
                    Visible = false;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the return error.';
                    Visible = false;
                }
                field(Time; Rec.Time)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time of the return error.';
                    Visible = false;
                }
                field("Transaction Name"; Rec."Transaction Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction name of the return error.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }
}

