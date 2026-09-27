// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GST.Services;

using Microsoft.Service.History;

page 18165 "Service Cr Memo QR Code"
{
    PageType = CardPart;
    SourceTable = "Service Cr.Memo Header";

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
                    ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                begin
                    ServiceCrMemoHeader.get(Rec."No.");
                    Page.Run(Page::"Service Cr Memo Dialog", ServiceCrMemoHeader);
                end;
            }
#pragma warning disable AW0009 // Accepted: The field remains Blob/Bitmap; migrating existing data to Media or MediaSet requires a breaking schema and data upgrade. Tracked by AB#640773.
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
