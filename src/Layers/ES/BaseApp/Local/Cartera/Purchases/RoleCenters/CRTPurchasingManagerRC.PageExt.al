// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Purchases.Reports;

pageextension 7000077 "CRT Purchasing Manager RC" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Purchasing Deferral Summary")
        {
            action("Long Term Purchase Invoices")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Long Term Purchase Invoices';
                RunObject = report "Long Term Purchase Invoices";
            }
        }
    }
}
