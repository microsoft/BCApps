// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 7000048 Installments
{
    AutoSplitKey = true;
    Caption = 'Installments';
    DataCaptionFields = "Payment Terms Code";
    PageType = List;
    SourceTable = Installment;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("% of Total"; Rec."% of Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the percentage of the total amount that will be applied to each one of the bills to be created.';
                }
                field("Gap between Installments"; Rec."Gap between Installments")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the time interval to be added to the due date of a bill, to obtain the due date of the next.';
                }
            }
        }
    }

    actions
    {
    }
}

