// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.RoleCenters;

pageextension 8016 "Acc. Payable Activities" extends "Acc. Payable Activities"
{
    layout
    {
        addafter("Purch. Invoices Due Next Week")
        {
            field("Vendor Contracts"; VendorContracts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Contracts';
                Editable = false;
                Tooltip = 'Specifies the number of vendor contracts.';

                trigger OnDrillDown()
                begin
                    Page.Run(Page::"Vendor Contracts");
                end;
            }
        }
    }

    var
        VendorContracts: Integer;

    trigger OnOpenPage()
    var
        VendorContract: Record "Vendor Subscription Contract";
    begin
        VendorContracts := VendorContract.Count();
    end;
}