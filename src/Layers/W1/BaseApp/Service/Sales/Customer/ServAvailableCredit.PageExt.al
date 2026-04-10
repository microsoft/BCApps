// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

pageextension 6488 "Serv. Available Credit" extends "Available Credit"
{
    layout
    {
        addafter("Outstanding Invoices (LCY)")
        {
            field("Outstanding Serv. Orders (LCY)"; Rec."Outstanding Serv. Orders (LCY)")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies your expected service income from the customer in LCY based on ongoing service orders.';
            }
            field("Serv Shipped Not Invoiced(LCY)"; Rec."Serv Shipped Not Invoiced(LCY)")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies your expected service income from the customer in LCY based on service orders that are shipped but not invoiced.';
            }
            field("Outstanding Serv.Invoices(LCY)"; Rec."Outstanding Serv.Invoices(LCY)")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies your expected service income from the customer in LCY based on unpaid service invoices.';
            }
        }
    }

}
