// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

pageextension 681 "Paym. Prac. Vend. Ledg. Entr." extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("Invoice Received Date")
        {
            field("SCF Payment Date"; Rec."SCF Payment Date")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
        addafter("Vendor No.")
        {
            field(SmallBusiness; IsSmallBusiness)
            {
                ApplicationArea = All;
                Caption = 'Small Business';
                ToolTip = 'Specifies whether the vendor is classified as a small business.';
                Editable = false;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Vendor: Record Vendor;
        CompanySize: Record "Company Size";
    begin
        IsSmallBusiness := false;
        if Vendor.Get(Rec."Vendor No.") then
            if CompanySize.Get(Vendor."Company Size Code") then
                IsSmallBusiness := CompanySize."Small Business";
    end;

    var
        IsSmallBusiness: Boolean;
}