// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Purchases.Vendor;

page 1621 "Office Vendor Details"
{
    Caption = 'Office Vendor Details';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("Balance (LCY)"; Rec."Balance (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year. It is calculated from amounts including VAT on all completed purchase invoices and credit memos.';
            }
            field("Balance Due (LCY)"; Rec."Balance Due (LCY)")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total value of your unpaid purchases from the vendor in the current fiscal year. It is calculated from amounts including VAT on all open purchase invoices and credit memos.';
            }
        }
    }

    actions
    {
    }
}

