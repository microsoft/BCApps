// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

page 1709 "Deferral Lines - Purchasing"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Lines - Purchasing';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Deferral Line";
    SourceTableView = where("Deferral Doc. Type" = const(Purchase));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                }
                field("Document No."; Rec."Document No.")
                {
                }
                field("Line No."; Rec."Line No.")
                {
                }
                field("Posting Date"; Rec."Posting Date")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Amount; Rec.Amount)
                {
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                }
                field("Currency Code"; Rec."Currency Code")
                {
                }
            }
        }
    }
}