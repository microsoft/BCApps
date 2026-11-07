// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.ExtendedText;

pageextension 5005273 DRExtendedText extends "Extended Text"
{
    layout
    {
        addafter("Prepmt. Purchase Credit Memo")
        {
            field("Delivery Reminder"; Rec."Delivery Reminder")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies whether the extended text will be available on delivery reminders.';
            }
        }
    }
}
