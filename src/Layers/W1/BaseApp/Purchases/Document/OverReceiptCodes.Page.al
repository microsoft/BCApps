// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

page 8510 "Over-Receipt Codes"
{
    Caption = 'Over-Receipt Codes';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Over-Receipt Code";

    layout
    {
        area(Content)
        {
            repeater(OverReceiptCodeRepeater)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a code for the over-receive policy.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the over-receive policy.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the over-receipt code will be used by default.';
                }
                field("Over-Receipt Tolerance %"; Rec."Over-Receipt Tolerance %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage by which the ordered quantity is allowed to be exceeded.';
                }
                field("Required Approval"; Rec."Required Approval")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if over-receiving items with this over-receipt-code code must first be approved.';
                }
            }
        }
    }
}
