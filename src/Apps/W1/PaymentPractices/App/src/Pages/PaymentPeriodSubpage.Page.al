// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

page 692 "Payment Period Subpage"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payment Period Lines';
    DelayedInsert = true;
    PageType = ListPart;
    SourceTable = "Payment Period Line";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Days From"; Rec."Days From")
                {
                }
                field("Days To"; Rec."Days To")
                {
                }
                field(Description; Rec.Description)
                {
                }
            }
        }
    }
}
