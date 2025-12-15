// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;

pageextension 20414 "Qlty. Serial No. Info. Card" extends "Serial No. Information Card"
{
    layout
    {
        addafter(General)
        {
            group(Qlty_Management)
            {
                Caption = 'Quality Management';

                field(QltyInspectionGradeDescription; MostRecentQltyGradeDescription)
                {
                    ApplicationArea = QualityManagement;
                    Caption = 'Quality Grade';
                    ToolTip = 'Specifies the most recent grade for this serial number.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        QltyInspectionHeader: Record "Qlty. Inspection Header";
                    begin
                        QltyInspectionHeader.SetRange("Source Item No.", Rec."Item No.");
                        QltyInspectionHeader.SetRange("Source Variant Code", Rec."Variant Code");
                        QltyInspectionHeader.SetRange("Source Serial No.", Rec."Serial No.");
                        if QltyInspectionHeader.FindFirst() then;
                        Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
                    end;
                }
                field("Qlty. Inspection Count"; Rec."Qlty. Inspection Count")
                {
                    ApplicationArea = QualityManagement;
                    Editable = false;
                }
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
