// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Tracking;

using Microsoft.Inventory.Tracking;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Inventory;

pageextension 20411 "Qlty. Lot No. Info. List" extends "Lot No. Information List"
{
    layout
    {
        addafter("Expired Inventory")
        {
            field(QltyInspectionResultDescription; MostRecentQltyResultDescription)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Quality Result';
                ToolTip = 'Specifies the most recent result for this lot number.';
                Editable = false;

                trigger OnDrillDown()
                var
                    QltyInspectionHeader: Record "Qlty. Inspection Header";
                begin
                    QltyInspectionHeader.SetRange("Source Item No.", Rec."Item No.");
                    QltyInspectionHeader.SetRange("Source Variant Code", Rec."Variant Code");
                    QltyInspectionHeader.SetRange("Source Lot No.", Rec."Lot No.");
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

    var
        MostRecentQltyResultDescription: Text;

    trigger OnAfterGetRecord()
    var
        QltyItemTracking: Codeunit "Qlty. Item Tracking";
        DummyResultCode: Code[20];
    begin
        QltyItemTracking.GetMostRecentResultFor(Rec."Item No.", Rec."Variant Code", Rec."Lot No.", '', '', DummyResultCode, MostRecentQltyResultDescription);
    end;
}
