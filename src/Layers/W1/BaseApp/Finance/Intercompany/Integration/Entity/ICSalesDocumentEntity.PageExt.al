// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

pageextension 8552 "IC Sales Document Entity" extends "Sales Document Entity"
{
    layout
    {
        addafter(invoiceDiscountValue)
        {
            field(sendIcDocument; Rec."Send IC Document")
            {
                ApplicationArea = All;
                Caption = 'Send IC Document', Locked = true;
            }
            field(icStatus; Rec."IC Status")
            {
                ApplicationArea = All;
                Caption = 'IC Status', Locked = true;
            }
            field(sellToIcPartnerCode; Rec."Sell-to IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Sell-to IC Partner Code', Locked = true;
            }
            field(billToIcPartnerCode; Rec."Bill-to IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Bill-to IC Partner Code', Locked = true;
            }
            field(icDirection; Rec."IC Direction")
            {
                ApplicationArea = All;
                Caption = 'IC Direction', Locked = true;
            }
        }
    }
}