// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;

pageextension 20429 "Qlty. Item Tracking Entries" extends "Item Tracking Entries"
{
    actions
    {
        addlast(navigation)
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
        QltyInspectionHeader.SetRange("Source Item No.", Rec."Item No.");
        if Rec."Variant Code" <> '' then
            QltyInspectionHeader.SetRange("Source Variant Code", Rec."Variant Code");
        if Rec."Lot No." <> '' then
            QltyInspectionHeader.SetRange("Source Lot No.", Rec."Lot No.");
        if Rec."Serial No." <> '' then
            QltyInspectionHeader.SetRange("Source Serial No.", Rec."Serial No.");
        if Rec."Package No." <> '' then
            QltyInspectionHeader.SetRange("Source Package No.", Rec."Package No.");
        if Rec."Location Code" <> '' then
            QltyInspectionHeader.SetRange("Location Code", Rec."Location Code");
        Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
    end;
}
