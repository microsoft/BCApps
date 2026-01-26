// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

page 15000027 "Payment Type Codes Abroad"
{
    Caption = 'Payment Type Codes Abroad';
    PageType = List;
    SourceTable = "Payment Type Code Abroad";

    layout
    {
        area(content)
        {
            repeater(Control1080000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the payment type codes that have been set up.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the payment type code.';
                }
            }
        }
    }

    actions
    {
    }
}

