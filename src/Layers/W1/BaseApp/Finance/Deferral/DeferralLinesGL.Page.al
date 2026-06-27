// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

page 1710 "Deferral Lines - G/L"
{
    ApplicationArea = Suite;
    Caption = 'Deferral Lines - G/L';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Deferral Line";
    SourceTableView = where("Deferral Doc. Type" = const("G/L"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Gen. Jnl. Template Name"; Rec."Gen. Jnl. Template Name")
                {
                }
                field("Gen. Jnl. Batch Name"; Rec."Gen. Jnl. Batch Name")
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