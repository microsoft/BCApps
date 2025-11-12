// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

table 355 "Dimension Set ID Filter Line"
{
    Caption = 'Dimension Set ID Filter Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Dimension Value Filter Part"; Text[250])
        {
            Caption = 'Dimension Value Filter Part';
        }
    }

    keys
    {
        key(Key1; "Code", "Dimension Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetDimensionValueFilter(DimensionValueFilter: Text)
    var
        ChunkLength: Integer;
        i: Integer;
    begin
        if "Dimension Code" = '' then
            exit;
        ChunkLength := MaxStrLen("Dimension Value Filter Part");
        Reset();
        SetRange(Code, Code);
        SetRange("Dimension Code", "Dimension Code");
        DeleteAll();
        Init();
        Code := Code;
        "Dimension Code" := "Dimension Code";
        for i := 1 to ((StrLen(DimensionValueFilter) div ChunkLength) + 1) do begin
            "Line No." := i;
            "Dimension Value Filter Part" := CopyStr(DimensionValueFilter, (i - 1) * ChunkLength + 1, i * ChunkLength);
            Insert();
        end;
    end;

    procedure GetDimensionValueFilter(NewCode: Code[20]; NewDimensionCode: Code[20]) DimensionValueFilter: Text
    var
        DimensionSetIDFilterLine: Record "Dimension Set ID Filter Line";
    begin
        DimensionSetIDFilterLine := Rec;
        DimensionSetIDFilterLine.CopyFilters(Rec);
        Reset();
        SetRange(Code, NewCode);
        SetRange("Dimension Code", NewDimensionCode);
        if FindSet() then begin
            DimensionValueFilter := "Dimension Value Filter Part";
            if DimensionSetIDFilterLine.Next() <> 0 then
                repeat
                    DimensionValueFilter += "Dimension Value Filter Part";
                until Next() = 0;
        end;
        Rec := DimensionSetIDFilterLine;
        CopyFilters(DimensionSetIDFilterLine);
    end;
}

