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
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = All;
                }
                field("Over-Receipt Tolerance %"; Rec."Over-Receipt Tolerance %")
                {
                    ApplicationArea = All;
                }
                field("Required Approval"; Rec."Required Approval")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
