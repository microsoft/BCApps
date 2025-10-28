// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;

pageextension 20413 "Qlty. Serial No. Info. List" extends "Serial No. Information List"
{
    layout
    {
        addafter(Blocked)
        {
            field(QltyInspectionGradeDescription; MostRecentQltyGradeDescription)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Quality Grade';
                ToolTip = 'Specifies the most recent grade for this serial number.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
                begin
                    QltyInspectionTestHeader.SetRange("Source Item No.", Rec."Item No.");
                    QltyInspectionTestHeader.SetRange("Source Variant Code", Rec."Variant Code");
                    QltyInspectionTestHeader.SetRange("Source Serial No.", Rec."Serial No.");
                    if QltyInspectionTestHeader.FindFirst() then;
                    Page.Run(Page::"Qlty. Inspection Test List", QltyInspectionTestHeader);
                end;
            }
            field("Qlty. Inspection Test Count"; Rec."Qlty. Inspection Test Count")
            {
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
        QltyItemTracking.GetMostRecentGradeFor(Rec."Item No.", Rec."Variant Code", '', Rec."Serial No.", '', DummyGradeCode, MostRecentQltyGradeDescription);
    end;
}
