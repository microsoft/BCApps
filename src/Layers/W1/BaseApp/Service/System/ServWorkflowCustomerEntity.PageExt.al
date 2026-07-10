// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

pageextension 6491 "Serv. Workflow Customer Entity" extends "Workflow - Customer Entity"
{
    layout
    {
        addafter(shippingAgentServiceCode)
        {
            field(serviceZoneCode; Rec."Service Zone Code")
            {
                ApplicationArea = All;
                Caption = 'Service Zone Code', Locked = true;
            }
            field(contractGainLossAmount; Rec."Contract Gain/Loss Amount")
            {
                ApplicationArea = All;
                Caption = 'Contract Gain/Loss Amount', Locked = true;
            }
            field(shipToFilter; Rec."Ship-to Filter")
            {
                ApplicationArea = All;
                Caption = 'Ship-to Filter', Locked = true;
            }
            field(outstandingServOrdersLcy; Rec."Outstanding Serv. Orders (LCY)")
            {
                ApplicationArea = All;
                Caption = 'Outstanding Serv. Orders (LCY)', Locked = true;
            }
            field(servShippedNotInvoicedLcy; Rec."Serv Shipped Not Invoiced(LCY)")
            {
                ApplicationArea = All;
                Caption = 'Serv Shipped Not Invoiced(LCY)', Locked = true;
            }
            field(outstandingServInvoicesLcy; Rec."Outstanding Serv.Invoices(LCY)")
            {
                ApplicationArea = All;
                Caption = 'Outstanding Serv.Invoices(LCY)', Locked = true;
            }
        }
    }
}
