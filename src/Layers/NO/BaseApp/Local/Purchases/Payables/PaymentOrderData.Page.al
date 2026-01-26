// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

page 15000003 "Payment Order Data"
{
    Caption = 'Payment Order Data';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Payment Order Data";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Line No"; Rec."Line No")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number.';
                }
                field(Data; Rec.Data)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data that the payment order submits.';
                }
            }
        }
    }

    actions
    {
    }
}

