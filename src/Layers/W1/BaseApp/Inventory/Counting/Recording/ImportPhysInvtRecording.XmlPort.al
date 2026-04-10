// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

xmlport 5876 "Import Phys. Invt. Recording"
{
    Caption = 'Import Phys. Invt. Recording';
    Direction = Import;
    Format = VariableText;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement("Phys. Invt. Record Line"; "Phys. Invt. Record Line")
            {
                XmlName = 'PhysInvtRecordLine';
                SourceTableView = sorting("Order No.", "Recording No.", "Line No.");
                UseTemporary = true;
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

                    PhysInvtRecordHeader.LockTable();
                    "Phys. Invt. Record Line".LockTable();

                    "Phys. Invt. Record Line".Reset();
                    "Phys. Invt. Record Line".SetRange("Order No.", PhysInvtRecordHeader."Order No.");
                    "Phys. Invt. Record Line".SetRange("Recording No.", PhysInvtRecordHeader."Recording No.");
                    if "Phys. Invt. Record Line".Find('+') then
                        NextLineNo := "Phys. Invt. Record Line"."Line No." + 10000
                    else
                        NextLineNo := 10000;
                end;

                trigger OnBeforeInsertRecord()
                begin
                    "Phys. Invt. Record Line".TestField("Order No.", PhysInvtRecordHeader."Order No.");
                    "Phys. Invt. Record Line".TestField("Recording No.", PhysInvtRecordHeader."Recording No.");

                    if PhysInvtRecordLine.Get(
                         "Phys. Invt. Record Line"."Order No.",
                         "Phys. Invt. Record Line"."Recording No.",
                         "Phys. Invt. Record Line"."Line No.")
                    then begin
                        PhysInvtRecordLine.TestField("Item No.", "Phys. Invt. Record Line"."Item No.");
                        PhysInvtRecordLine.TestField("Variant Code", "Phys. Invt. Record Line"."Variant Code");
                        PhysInvtRecordLine.TestField("Location Code", "Phys. Invt. Record Line"."Location Code");
                        PhysInvtRecordLine.TestField("Bin Code", "Phys. Invt. Record Line"."Bin Code");
                        PhysInvtRecordLine.TestField(Recorded, false);
                        PhysInvtRecordLine.Validate("Unit of Measure Code", "Phys. Invt. Record Line"."Unit of Measure Code");
                        PhysInvtRecordLine.Validate(Quantity, "Phys. Invt. Record Line".Quantity);
                        PhysInvtRecordLine.Validate("Date Recorded", "Phys. Invt. Record Line"."Date Recorded");
                        PhysInvtRecordLine.Validate("Time Recorded", "Phys. Invt. Record Line"."Time Recorded");
                        PhysInvtRecordLine.Validate("Person Recorded", "Phys. Invt. Record Line"."Person Recorded");
                        OnImportOnBeforePhysInvtRecordLineMofify(PhysInvtRecordLine);
                        PhysInvtRecordLine.Modify();
                    end else begin
                        PhysInvtRecordLine.Init();
                        PhysInvtRecordLine."Order No." := "Phys. Invt. Record Line"."Order No.";
                        PhysInvtRecordLine."Recording No." := "Phys. Invt. Record Line"."Recording No.";
                        if "Phys. Invt. Record Line"."Line No." <> 0 then begin
                            PhysInvtRecordLine."Line No." := "Phys. Invt. Record Line"."Line No.";
                            NextLineNo := "Phys. Invt. Record Line"."Line No." + 10000;
                        end else begin
                            PhysInvtRecordLine."Line No." := NextLineNo;
                            NextLineNo := NextLineNo + 10000;
                        end;
                        PhysInvtRecordLine.Validate("Item No.", "Phys. Invt. Record Line"."Item No.");
                        PhysInvtRecordLine.Validate("Variant Code", "Phys. Invt. Record Line"."Variant Code");
                        PhysInvtRecordLine.Validate("Location Code", "Phys. Invt. Record Line"."Location Code");
                        PhysInvtRecordLine.Validate("Bin Code", "Phys. Invt. Record Line"."Bin Code");
                        PhysInvtRecordLine.Validate("Unit of Measure Code", "Phys. Invt. Record Line"."Unit of Measure Code");
                        PhysInvtRecordLine.Validate(Quantity, "Phys. Invt. Record Line".Quantity);
                        PhysInvtRecordLine.Validate("Date Recorded", "Phys. Invt. Record Line"."Date Recorded");
                        PhysInvtRecordLine.Validate("Time Recorded", "Phys. Invt. Record Line"."Time Recorded");
                        PhysInvtRecordLine.Validate("Person Recorded", "Phys. Invt. Record Line"."Person Recorded");
                        OnImportOnBeforePhysInvtRecordLineInsert(PhysInvtRecordLine);
                        PhysInvtRecordLine.Insert();
                    end;
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
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        NextLineNo: Integer;

    procedure Set(NewPhysInvtRecordHeader: Record "Phys. Invt. Record Header")
    begin
        PhysInvtRecordHeader := NewPhysInvtRecordHeader;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportOnBeforePhysInvtRecordLineInsert(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportOnBeforePhysInvtRecordLineMofify(var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;
}

