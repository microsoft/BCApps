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
                ToolTip = 'Specifies whether the document is sent to the intercompany partner.';
            }
            field(icStatus; Rec."IC Status")
            {
                ApplicationArea = All;
                Caption = 'IC Status', Locked = true;
                ToolTip = 'Specifies the intercompany status of the document.';
            }
            field(buyFromIcPartnerCode; Rec."Buy-from IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Buy-from IC Partner Code', Locked = true;
                ToolTip = 'Specifies the code of the intercompany partner that the vendor is linked to.';
            }
            field(payToIcPartnerCode; Rec."Pay-to IC Partner Code")
            {
                ApplicationArea = All;
                Caption = 'Pay-to IC Partner Code', Locked = true;
                ToolTip = 'Specifies the code of the intercompany partner that the pay-to vendor is linked to.';
            }
            field(icDirection; Rec."IC Direction")
            {
                ApplicationArea = All;
                Caption = 'IC Direction', Locked = true;
                ToolTip = 'Specifies the direction of the intercompany document.';
            }
        }
    }
}
