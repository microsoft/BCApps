// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

page 12174 "Stop Payment Periods"
{
    Caption = 'Stop Payment Periods';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Deferring Due Dates";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("From-Date"; Rec."From-Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date of the time period in which payments are not allowed.';
                }
                field("To-Date"; Rec."To-Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the end date of the time period in which payments are not allowed.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the deferring due dates.';
                }
                field("Due Date Calculation"; Rec."Due Date Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the formula that is used to calculate the time period in which payments are not allowed.';
                }
            }
        }
    }

    actions
    {
    }
}

