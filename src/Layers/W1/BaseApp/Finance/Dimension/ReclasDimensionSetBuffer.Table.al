// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

table 482 "Reclas. Dimension Set Buffer"
{
    Caption = 'Reclas. Dimension Set Buffer';
    DrillDownPageID = "Dimension Set Entries";
    LookupPageID = "Dimension Set Entries";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if "Dimension Code" <> xRec."Dimension Code" then begin
                    "Dimension Value Code" := '';
                    "Dimension Value ID" := 0;
                    "New Dimension Value Code" := '';
                    "New Dimension Value ID" := 0;
                end;
            end;
        }
        field(2; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                "Dimension Value ID" := GetDimValID("Dimension Code", "Dimension Value Code");
            end;
        }
        field(3; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
            DataClassification = SystemMetadata;
        }
        field(4; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                "New Dimension Value ID" := GetDimValID("Dimension Code", "New Dimension Value Code");
            end;
        }
        field(5; "New Dimension Value ID"; Integer)
        {
            Caption = 'New Dimension Value ID';
            DataClassification = SystemMetadata;
        }
        field(6; "Dimension Name"; Text[30])
        {
            CalcFormula = lookup (Dimension.Name where(Code = field("Dimension Code")));
            Caption = 'Dimension Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup ("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "New Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup ("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("New Dimension Value Code")));
            Caption = 'New Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetDimSetID(var ReclasDimSetBuf: Record "Reclas. Dimension Set Buffer"): Integer
    begin
        exit(GetDimSetID2(ReclasDimSetBuf, false));
    end;

    procedure GetNewDimSetID(var ReclasDimSetBuf: Record "Reclas. Dimension Set Buffer"): Integer
    begin
        exit(GetDimSetID2(ReclasDimSetBuf, true));
    end;

    local procedure GetDimSetID2(var ReclasDimSetBuf: Record "Reclas. Dimension Set Buffer"; NewVal: Boolean): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
    begin
        ReclasDimSetBuf.Reset();
        ReclasDimSetBuf.SetFilter("Dimension Code", '<>%1', '');
        if NewVal then
            ReclasDimSetBuf.SetFilter("New Dimension Value Code", '<>%1', '')
        else
            ReclasDimSetBuf.SetFilter("Dimension Value Code", '<>%1', '');
        if not ReclasDimSetBuf.FindSet() then
            exit(0);
        repeat
            TempDimSetEntry."Dimension Set ID" := 0;
            TempDimSetEntry."Dimension Code" := ReclasDimSetBuf."Dimension Code";
            if NewVal then begin
                TempDimSetEntry."Dimension Value Code" := ReclasDimSetBuf."New Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := ReclasDimSetBuf."New Dimension Value ID";
            end else begin
                TempDimSetEntry."Dimension Value Code" := ReclasDimSetBuf."Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := ReclasDimSetBuf."Dimension Value ID";
            end;
            TempDimSetEntry.Insert();
        until ReclasDimSetBuf.Next() = 0;
        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure GetDimValID(DimCode: Code[20]; DimValCode: Code[20]): Integer
    var
        DimVal: Record "Dimension Value";
    begin
        if DimValCode = '' then
            exit(0);

        DimVal.Get(DimCode, DimValCode);
        exit(DimVal."Dimension Value ID");
    end;
}

