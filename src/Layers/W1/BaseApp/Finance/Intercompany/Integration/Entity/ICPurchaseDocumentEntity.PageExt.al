// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Entity;

pageextension 8550 "IC Purchase Document Entity" extends "Purchase Document Entity"
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
            field(buyFromIcPartnerCode; Rec."Buy-from IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Buy-from IC Partner Code', Locked = true;
            }
            field(payToIcPartnerCode; Rec."Pay-to IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Pay-to IC Partner Code', Locked = true;
            }
            field(icDirection; Rec."IC Direction")
            {
                ApplicationArea = All;
                Caption = 'IC Direction', Locked = true;
            }
        }
    }
}