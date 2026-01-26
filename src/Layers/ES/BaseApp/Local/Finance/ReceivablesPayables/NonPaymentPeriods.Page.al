// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 10701 "Non-Payment Periods"
{
    Caption = 'Non-Payment Periods';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Non-Payment Period";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("From Date"; Rec."From Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the non-payment period.';
                }
                field("To Date"; Rec."To Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the non-payment period.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the non-payment period.';
                }
            }
        }
    }

    actions
    {
    }
}

