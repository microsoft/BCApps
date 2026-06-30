// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6842 "Spend Request Subform"
{
    Caption = 'Lines';
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "Spend Request Detail";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                }
                field(Amount; Rec.Amount)
                {
                }
                field("G/L Account No."; Rec."G/L Account No.")
                {
                }
            }
        }
    }
}
