// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Availability;

using Microsoft.Inventory.Availability;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;

pageextension 20410 "Qlty. Item Avail. by Lot No." extends "Item Avail. by Lot No. Lines"
{
    layout
    {
        addafter(QtyAvailable)
        {
            field(QltyInspectionResultDescription; MostRecentQltyResultDescription)
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Caption = 'Quality Result';
                ToolTip = 'Specifies the most recent result for this lot number.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader.SetRange("Source Item No.", Rec."Item No.");
                    QltyInspectionHeader.SetFilter("Source Variant Code", Rec."Variant Code Filter");
                    QltyInspectionHeader.SetRange("Source Lot No.", Rec."Lot No.");
                    if Rec."Serial No." <> '' then
                        QltyInspectionHeader.SetRange("Source Serial No.", Rec."Serial No.");
                    if Rec."Package No." <> '' then
                        QltyInspectionHeader.SetRange("Source Package No.", Rec."Package No.");
                    if QltyInspectionHeader.FindFirst() then;
                    Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
                end;
            }
            field("Qlty. Inspection for Lot Count"; Rec."Qlty. Inspection for Lot Count")
            {
                ApplicationArea = QualityManagement;
                AccessByPermission = tabledata "Qlty. Inspection Header" = R;
                Editable = false;
            }
        }
    }

    var
        MostRecentQltyResultDescription: Text;

    trigger OnAfterGetRecord()
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        DummyResultCode: Code[20];
    begin
        QltyItemTracking.GetMostRecentResultFor(Rec."Item No.", Rec."Variant Code Filter", Rec."Lot No.", Rec."Serial No.", Rec."Package No.", DummyResultCode, MostRecentQltyResultDescription);
    end;
}
