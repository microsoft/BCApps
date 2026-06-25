// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Reports;

pageextension 99000761 "Mfg. Purchasing Manager RC" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Certificates of Supply")
        {
#if not CLEAN28
            action("Subcontracting Worksheet")
            {
                ApplicationArea = LegacySubcontracting;
                Caption = 'Subcontracting Worksheets (Obsolete)';
#pragma warning disable AL0432
                RunObject = page Microsoft.Manufacturing.Journal."Subcontracting Worksheet";
#pragma warning restore AL0432
                ObsoleteReason = 'Will be replaced by the Subcontracting App.';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
#endif
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
#if not CLEAN28
        // IT Subcontracting
        addafter("Return Orders")
        {
            action("Subcontracting Orders")
            {
                ApplicationArea = LegacySubcontracting;
                Caption = 'Subcontracting Orders';
                RunObject = page "Subcontracting Order List";
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
            }
        }
        addafter("Transfer Orders")
        {
            action("Subcontracting Transfer Orders")
            {
                ApplicationArea = LegacySubcontracting;
                Caption = 'Subcontracting Transfer Orders';
                RunObject = page "Subcontracting Transfer List";
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
            }
        }
        addafter("Orders2")
        {
            action("Subcontracting Orders1")
            {
                ApplicationArea = LegacySubcontracting;
                Caption = 'Subcontracting Orders';
                RunObject = page "Subcontracting Order List";
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
            }
        }
        addafter("Transfer Orders1")
        {
            action("Subcontracting Transfer Orders1")
            {
                ApplicationArea = LegacySubcontracting;
                Caption = 'Subcontracting Transfer Orders';
                RunObject = page "Subcontracting Transfer List";
                ObsoleteReason = 'Preparation for replacement by Subcontracting app';
                ObsoleteState = Pending;
                ObsoleteTag = '27.0';
            }
        }
#endif
    }
}