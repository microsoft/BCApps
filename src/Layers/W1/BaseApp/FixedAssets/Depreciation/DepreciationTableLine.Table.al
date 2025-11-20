// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

table 5643 "Depreciation Table Line"
{
    Caption = 'Depreciation Table Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Depreciation Table Code"; Code[10])
        {
            Caption = 'Depreciation Table Code';
            NotBlank = true;
            TableRelation = "Depreciation Table Header";
        }
        field(2; "Period No."; Integer)
        {
            Caption = 'Period No.';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; "Period Depreciation %"; Decimal)
        {
            Caption = 'Period Depreciation %';
            DecimalPlaces = 2 : 8;
            MinValue = 0;

            trigger OnValidate()
            begin
                DeprTableHeader.Get("Depreciation Table Code");
                if DeprTableHeader."Total No. of Units" <> 0 then
                    "No. of Units in Period" :=
                      Round(DeprTableHeader."Total No. of Units" * "Period Depreciation %" / 100, 0.00001);
            end;
        }
        field(4; "No. of Units in Period"; Decimal)
        {
            Caption = 'No. of Units in Period';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                DeprTableHeader.Get("Depreciation Table Code");
                if DeprTableHeader."Total No. of Units" <> 0 then
                    "Period Depreciation %" :=
                      Round("No. of Units in Period" / DeprTableHeader."Total No. of Units" * 100, 0.00000001);
            end;
        }
    }

    keys
    {
        key(Key1; "Depreciation Table Code", "Period No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        DeprTableHeader: Record "Depreciation Table Header";
    begin
        LockTable();
        DeprTableHeader.Get("Depreciation Table Code");
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        DeprTableHeader: Record "Depreciation Table Header";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure NewRecord()
    var
        DeprTableLine: Record "Depreciation Table Line";
    begin
        DeprTableLine.SetRange("Depreciation Table Code", "Depreciation Table Code");
        if DeprTableLine.FindLast() then;
        "Period No." := DeprTableLine."Period No." + 1;
    end;
}

