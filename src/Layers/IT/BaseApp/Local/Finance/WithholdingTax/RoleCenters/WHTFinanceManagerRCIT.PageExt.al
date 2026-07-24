// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.Payment;
using Microsoft.Finance.RoleCenters;

pageextension 12109 "WHT Finance Manager RC IT" extends "Finance Manager Role Center"
{
    actions
    {
        addafter("Vendor Sheet - Print")
        {
            action("Withholding Taxes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withholding Taxes';
                RunObject = report "Withholding Taxes";
            }
            action("Contribution")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Contribution';
                RunObject = report "Contribution";
            }
            action("Summary Withholding Payment")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Summary Withholding Payment';
                RunObject = report "Summary Withholding Payment";
            }
            action("Compensation Details")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Compensation Details';
                RunObject = report "Compensation Details";
            }
            action(Certifications)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Certifications';
                RunObject = report Certifications;
            }
        }

        addafter("Purchases & Payables Setup")
        {
            action("Withhold Tax Code")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Withhold Tax Code';
                RunObject = page "Withhold Codes";
            }
        }
    }
}
