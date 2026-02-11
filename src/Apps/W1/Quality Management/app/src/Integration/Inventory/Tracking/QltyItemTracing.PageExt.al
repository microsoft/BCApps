// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

pageextension 20428 "Qlty. Item Tracing" extends "Item Tracing"
{
    actions
    {
        addlast(Item)
        {
            action(Qlty_QualityInspections)
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Caption = 'Quality Inspections';
                Image = TaskQualityMeasure;
                ToolTip = 'View quality inspections filtered by the selected item, variant, location, and tracking details.';

                trigger OnAction()
                begin
                    ShowQualityInspections();
                end;
            }
        }
    }

    local procedure ShowQualityInspections()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        QltyInspectionHeader.SetFilter("Source Item No.", ItemNoFilter);
        if VariantFilter <> '' then
            QltyInspectionHeader.SetFilter("Source Variant Code", VariantFilter);
        if LotNoFilter <> '' then
            QltyInspectionHeader.SetFilter("Source Lot No.", LotNoFilter);
        if SerialNoFilter <> '' then
            QltyInspectionHeader.SetFilter("Source Serial No.", SerialNoFilter);
        if PackageNoFilter <> '' then
            QltyInspectionHeader.SetFilter("Source Package No.", PackageNoFilter);
        if Rec."Location Code" <> '' then
            QltyInspectionHeader.SetRange("Location Code", Rec."Location Code");
        Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
    end;
}
