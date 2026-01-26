// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 35481 "Issued Cust. Bill Information"
{
    Caption = 'Issued Cust. Bill Information';
    PageType = CardPart;
    SourceTable = "Issued Customer Bill Header";

    layout
    {
        area(content)
        {
            field("Total Amount"; Rec."Total Amount")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the total amount due of the issued customer bills that have been sent to the bank.';
            }
        }
    }

    actions
    {
    }
}

