// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Reports;

pageextension 99000761 "Mfg. Purchasing Manager RC" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Certificates of Supply")
        {
            action("Subcontracting Worksheet")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Worksheets';
                RunObject = page "Subcontracting Worksheet";
            }
        }
        addafter("Vendors1")
        {
            action("Production Forecasts")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Production Forecasts';
                RunObject = page "Demand Forecast Names";
            }
        }
        addafter("Jobs")
        {
            action("Planned Prod. Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Planned Production Orders';
                RunObject = page "Planned Production Orders";
            }
            action("Firm Planned Prod. Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Firm Planned Prod. Orders';
                RunObject = page "Firm Planned Prod. Orders";
            }
        }
        addafter("Item/Vendor Catalog1")
        {
            action("Prod. Order - Shortage List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - Shortage List';
                RunObject = report "Prod. Order - Shortage List";
            }
            action("Prod. Order - Mat. Requisition")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - Mat. Requisition';
                RunObject = report "Prod. Order - Mat. Requisition";
            }
        }
    }
}
