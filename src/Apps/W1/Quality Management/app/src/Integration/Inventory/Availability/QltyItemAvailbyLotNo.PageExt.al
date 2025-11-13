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
            field(QltyInspectionGradeDescription; MostRecentQltyGradeDescription)
            {
                AccessByPermission = tabledata "Qlty. Inspection Test Header" = R;
                ApplicationArea = QualityManagement;
                Caption = 'Quality Grade';
                ToolTip = 'Specifies the most recent grade for this lot number.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader.SetRange("Source Item No.", Rec."Item No.");
                    QltyInspectionTestHeader.SetFilter("Source Variant Code", Rec."Variant Code Filter");
                    QltyInspectionTestHeader.SetRange("Source Lot No.", Rec."Lot No.");
                    if Rec."Serial No." <> '' then
                        QltyInspectionTestHeader.SetRange("Source Serial No.", Rec."Serial No.");
                    if Rec."Package No." <> '' then
                        QltyInspectionTestHeader.SetRange("Source Package No.", Rec."Package No.");
                    if QltyInspectionTestHeader.FindFirst() then;
                    Page.Run(Page::"Qlty. Inspection Test List", QltyInspectionTestHeader);
                end;
            }
            field("Qlty. Insp. Test for Lot Count"; Rec."Qlty. Insp. Test for Lot Count")
            {
                AccessByPermission = tabledata "Qlty. Inspection Test Header" = R;
                ApplicationArea = QualityManagement;
                Editable = false;
            }
        }
    }

    var
        MostRecentQltyGradeDescription: Text;

    trigger OnAfterGetRecord()
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        DummyGradeCode: Code[20];
    begin
        QltyItemTracking.GetMostRecentGradeFor(Rec."Item No.", Rec."Variant Code Filter", Rec."Lot No.", Rec."Serial No.", Rec."Package No.", DummyGradeCode, MostRecentQltyGradeDescription);
    end;
}
