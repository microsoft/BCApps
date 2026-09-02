// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Sales;

using Microsoft.Sales.History;

page 18143 "Sales Cr Memo QR Code"
{
    PageType = CardPart;
    SourceTable = "Sales Cr.Memo Header";

    layout
    {
        area(Content)
        {
            field(UpdateTaxInfoLbl; UpdateTaxInfoLbl)
            {
                ApplicationArea = All;
                ShowCaption = false;
                Editable = false;
                StyleExpr = true;
                Style = Subordinate;
                trigger OnDrillDown()
                var
                    SalesCrMemoHeader: Record "Sales Cr.Memo Header";
                begin
                    SalesCrMemoHeader.get(Rec."No.");
                    Page.Run(Page::"Sales Cr Memo Dialog", SalesCrMemoHeader);
                end;
            }
#pragma warning disable AW0009 // Accepted: Migrating the underlying Blob field to Media or MediaSet requires a data-schema migration outside this low-risk ruleset change.
            field("QR Code"; Rec."QR Code")
#pragma warning restore AW0009
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the QR Code assigned by e-invoice portal for sales document.';
            }
        }
    }
    var
        UpdateTaxInfoLbl: Label 'Click here to update Information';
}
