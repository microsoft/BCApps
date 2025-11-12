// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

table 7009 "Duplicate Price Line"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Price List Code"; Code[20])
        {
            Caption = 'Price List Code';
            DataClassification = SystemMetadata;
            TableRelation = "Price List Header";
        }
        field(2; "Price List Line No."; Integer)
        {
            Caption = 'Price List Line No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Duplicate To Line No."; Integer)
        {
            Caption = 'Duplicate To Line No.';
            DataClassification = SystemMetadata;
        }
        field(5; Remove; Boolean)
        {
            Caption = 'Remove';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if xRec.Remove = Remove then
                    exit;

                if Remove then
                    Remove := false
                else
                    MarkOtherDuplicateLinesForRemoval();
            end;
        }
    }

    keys
    {
        key(PK; "Price List Code", "Price List Line No.")
        {
        }
        key(Key1; "Duplicate To Line No.", "Line No.")
        {
        }
    }

    procedure Add(var LineNo: Integer; DuplicateToLineNo: Integer; PriceListLine: Record "Price List Line")
    begin
        LineNo += 1;
        "Line No." := LineNo;
        if DuplicateToLineNo = 0 then
            "Duplicate To Line No." := LineNo
        else
            "Duplicate To Line No." := DuplicateToLineNo;
        Remove := "Duplicate To Line No." <> "Line No.";
        "Price List Code" := PriceListLine."Price List Code";
        "Price List Line No." := PriceListLine."Line No.";
        Insert();
    end;

    procedure Add(var LineNo: Integer; PriceListLine: Record "Price List Line"; DuplicatePriceListLine: Record "Price List Line")
    begin
        Add(LineNo, 0, PriceListLine);
        Add(LineNo, "Line No.", DuplicatePriceListLine);
    end;

    local procedure MarkOtherDuplicateLinesForRemoval()
    var
        DuplicatePriceLine: Record "Duplicate Price Line";
    begin
        DuplicatePriceLine.Copy(Rec, true);
        DuplicatePriceLine.SetRange("Duplicate To Line No.", "Duplicate To Line No.");
        DuplicatePriceLine.SetFilter("Line No.", '<>%1', "Line No.");
        DuplicatePriceLine.ModifyAll(Remove, true);
    end;
}