// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

xmlport 5875 "Export Phys. Invt. Recording"
{
    Caption = 'Export Phys. Invt. Recording';
    Direction = Export;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Phys. Invt. Record Line"; "Phys. Invt. Record Line")
            {
                XmlName = 'PhysInvtRecordLine';
                fieldelement(OrderNo; "Phys. Invt. Record Line"."Order No.")
                {
                }
                fieldelement(RecordingNo; "Phys. Invt. Record Line"."Recording No.")
                {
                }
                fieldelement(LineNo; "Phys. Invt. Record Line"."Line No.")
                {
                }
                fieldelement(ItemNo; "Phys. Invt. Record Line"."Item No.")
                {
                }
                fieldelement(VariantCode; "Phys. Invt. Record Line"."Variant Code")
                {
                }
                fieldelement(LocationCode; "Phys. Invt. Record Line"."Location Code")
                {
                }
                fieldelement(BinCode; "Phys. Invt. Record Line"."Bin Code")
                {
                }
                fieldelement(Description; "Phys. Invt. Record Line".Description)
                {
                }
                fieldelement(Description2; "Phys. Invt. Record Line"."Description 2")
                {
                }
                fieldelement(UnitOfMeasureCode; "Phys. Invt. Record Line"."Unit of Measure Code")
                {
                }
                fieldelement(ShelfNo; "Phys. Invt. Record Line"."Shelf No.")
                {
                }
                fieldelement(Quantity; "Phys. Invt. Record Line".Quantity)
                {
                }
                fieldelement(PersonRecorded; "Phys. Invt. Record Line"."Person Recorded")
                {
                }
                fieldelement(DateRecorded; "Phys. Invt. Record Line"."Date Recorded")
                {
                }
                fieldelement(TimeRecorded; "Phys. Invt. Record Line"."Time Recorded")
                {
                }

                trigger OnPreXmlItem()
                begin
                    PhysInvtRecordHeader.TestField("Order No.");
                    PhysInvtRecordHeader.TestField("Recording No.");
                    "Phys. Invt. Record Line".SetRange("Order No.", PhysInvtRecordHeader."Order No.");
                    "Phys. Invt. Record Line".SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";

    procedure Set(NewPhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
        PhysInvtRecordHeader := NewPhysInvtRecordHeader;
    end;
}

