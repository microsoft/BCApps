// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer.Document;

using Microsoft.Inventory.Transfer;
using Microsoft.QualityManagement.Document;

tableextension 20409 "Qlty. Transfer Header" extends "Transfer Header"
{
    fields
    {
        field(20400; "Qlty. Inspection No."; Code[20])
        {
            Caption = 'Quality Inspection No.';
            ToolTip = 'Specifies the related quality inspection.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Header"."No.";
        }
        field(20401; "Qlty. Inspection Reinspection No."; Integer)
        {
            Caption = 'Quality Inspection Reinspection No.';
            ToolTip = 'Specifies the related quality inspection.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Header"."Reinspection No." where("No." = field("Qlty. Inspection No."));
            BlankZero = true;
        }
    }

    keys
    {
        key(Key20400; "Qlty. Inspection No.", "Qlty. Inspection Reinspection No.")
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
        if QltyInspectionHeader.Get(Rec."Qlty. Inspection No.", Rec."Qlty. Inspection Reinspection No.") then begin
            QltyInspection.SetRecord(QltyInspectionHeader);
            QltyInspection.Run();
        end;
    end;
}
