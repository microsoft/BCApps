// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 10700 "Payment Days"
{
    Caption = 'Payment Days';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Payment Day";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Day of the month"; Rec."Day of the month")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment day established for the client, vendor, or the company.';
                }
            }
        }
    }

    actions
    {
    }
}

