// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.History;

pageextension 20580 "Subc. Summary Receipt Lines" extends "Purch. Receipt Lines"
{
    trigger OnOpenPage()
    begin
        if not SummaryDetail then
            exit;

        // The native item-charge lookup excludes corrections, zero quantities and non-item lines.
        // A summary drilldown must instead retain every row contributing to the signed total.
        Rec.FilterGroup(2);
        Rec.SetRange(Type);
        Rec.SetRange(Quantity);
        Rec.SetRange(Correction);
        Rec.FilterGroup(0);
    end;

    internal procedure SetSummaryDetail()
    begin
        SummaryDetail := true;
    end;

    var
        SummaryDetail: Boolean;
}
