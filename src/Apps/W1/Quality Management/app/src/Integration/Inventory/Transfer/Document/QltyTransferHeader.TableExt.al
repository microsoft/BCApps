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
        field(20400; "Qlty. Inspection Test No."; Code[20])
        {
            Caption = 'Quality Inspection Test No.';
            ToolTip = 'Specifies the related quality inspection test.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Test Header"."No.";
        }
        field(20401; "Qlty. Inspection Retest No."; Integer)
        {
            Caption = 'Quality Inspection Retest No.';
            ToolTip = 'Specifies the related quality inspection test.';
            DataClassification = CustomerContent;
            TableRelation = "Qlty. Inspection Test Header"."Retest No." where("No." = field("Qlty. Inspection Test No."));
        }
    }

    keys
    {
        key(Key20400; "Qlty. Inspection Test No.", "Qlty. Inspection Retest No.")
        {
        }
    }

    /// <summary>
    /// Runs associated Quality Inspection Test page
    /// </summary>
    procedure QltyShowRelatedInspectionTest()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTest: Page "Qlty. Inspection Test";
    begin
        if QltyInspectionTestHeader.Get(Rec."Qlty. Inspection Test No.", Rec."Qlty. Inspection Retest No.") then begin
            QltyInspectionTest.SetRecord(QltyInspectionTestHeader);
            QltyInspectionTest.Run();
        end;
    end;
}
