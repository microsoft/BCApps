// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Purchases.Payables;

pageextension 10048 "IRS 1099 Vendor Ledger Entries" extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("Exported to Payment File")
        {
            field("IRS 1099 Reporting Period"; Rec."IRS 1099 Reporting Period")
            {
                ApplicationArea = BasicCA, BasicUS;
                Tooltip = 'Specifies the period used for this entry''s IRS form and box setup. The reporting year for applied payments and refunds is determined by their posting dates, not this field.';
            }
            field("IRS 1099 Form No."; Rec."IRS 1099 Form No.")
            {
                ApplicationArea = BasicCA, BasicUS;
                Tooltip = 'Specifies the IRS form number for the vendor ledger entry.';
            }
            field("IRS 1099 Form Box No."; Rec."IRS 1099 Form Box No.")
            {
                ApplicationArea = BasicCA, BasicUS;
                Tooltip = 'Specifies the IRS form box number for the vendor ledger entry.';
            }
            field("IRS 1099 Reporting Amount"; Rec."IRS 1099 Reporting Amount")
            {
                ApplicationArea = BasicCA, BasicUS;
                Tooltip = 'Specifies the entry''s 1099-liable amount, not the amount paid in a particular year. The reporting calculation includes the proportion covered by applied payments and refunds.';
            }
        }
    }
}