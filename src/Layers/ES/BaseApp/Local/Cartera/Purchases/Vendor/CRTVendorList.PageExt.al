// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;

pageextension 7000074 "CRT Vendor List" extends "Vendor List"
{
    layout
    {
        addafter(VendorHistPayToFactBox)
        {
            part(Control1903433907; "Cartera Payables Statistics FB")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "No." = field("No.");
                Visible = true;
            }
        }

        actions
        {
            addafter("Vendor - Trial Balance")
            {
                action("Vendor - Due Payments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor - Due Payments';
                    Image = "Report";
                    RunObject = Report "Vendor - Due Payments";
                    ToolTip = 'View a list of payments to be made to a particular vendor sorted by due date.';
                }
            }
            addfirst(Category_Report)
            {
                actionref("Vendor - Due Payments_Promoted"; "Vendor - Due Payments")
                {
                }
            }
        }
    }
}
