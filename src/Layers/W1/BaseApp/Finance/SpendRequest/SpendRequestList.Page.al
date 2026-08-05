// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

page 6840 "Spend Request List"
{
    Caption = 'Spend Requests';
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Documents;
    SourceTable = "Spend Request";
    CardPageId = "Spend Request Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("No."; Rec."No.")
                {
                }
                field(Type; Rec.Type)
                {
                }
                field("Requested By"; Rec."Requested By")
                {
                }
                field(Purpose; Rec.Purpose)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("Total Expected Amount (LCY)"; Rec."Total Expected Amount (LCY)")
                {
                }
                field("Total Spent Amount (LCY)"; Rec."Total Spent Amount (LCY)")
                {
                }
                field(RemainingAmountLCY; Rec.GetRemainingAmountLCY())
                {
                    Caption = 'Remaining Amount (LCY)';
                    ToolTip = 'Specifies the difference between estimated amount and actually spent amount.';
                    Importance = Additional;
                }
                field("Expected Start Date"; Rec."Expected Start Date")
                {
                }
                field("Expected End Date"; Rec."Expected End Date")
                {
                }
                field("Approved by User Name"; Rec."Approved/Rejected by User Name")
                {
                }
                field(ClosedAt; Rec."Closed At")
                {
                }
                field(ClosedByDoc; Rec."Closed By Document No.")
                {
                }
            }
        }
    }
}
