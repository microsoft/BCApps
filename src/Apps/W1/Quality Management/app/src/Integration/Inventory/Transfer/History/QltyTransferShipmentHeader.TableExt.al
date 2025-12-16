// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer.History;

using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Document;

tableextension 20411 "Qlty. Transfer Shipment Header" extends "Transfer Shipment Header"
{
    fields
    {
        field(20400; "Qlty. Inspection No."; Code[20])
        {
            Caption = 'Quality Inspection No.';
            ToolTip = 'Specifies the related quality inspection.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Header"."No.";
            Description = 'Only used to link to the inspection that created the original Transfer document that generated this.';
        }
        field(20401; "Qlty. Reinspection No."; Integer)
        {
            Caption = 'Quality Reinspection No.';
            ToolTip = 'Specifies the related quality reinspection.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Header"."Reinspection No." where("No." = field("Qlty. Inspection No."));
            Description = 'Only used to link to the inspection that created the original Transfer document that generated this.';
            BlankZero = true;
        }
    }

    keys
    {
        key(Key20400; "Qlty. Inspection No.", "Qlty. Reinspection No.")
        {
        }
    }

    /// <summary>
    /// Runs associated Quality Inspection page
    /// </summary>
    procedure QltyShowRelatedInspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspection: Page "Qlty. Inspection";
    begin
        if QltyInspectionHeader.Get(Rec."Qlty. Inspection No.", Rec."Qlty. Reinspection No.") then begin
            QltyInspection.SetRecord(QltyInspectionHeader);
            QltyInspection.Run();
        end;
    end;
}
