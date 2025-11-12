// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Globalization;

table 356 "Dim. Value per Account"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table ID"; Integer)
        {
        }
        field(2; "No."; Code[20])
        {
        }
        field(3; "Dimension Code"; Code[20])
        {
        }
        field(4; "Dimension Value Code"; Code[20])
        {
        }
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Dimension Value Type"; Option)
        {
            Caption = 'Dimension Value Type';
            OptionCaption = 'Standard,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Standard,Heading,Total,"Begin-Total","End-Total";
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Value"."Dimension Value Type" where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
        }
        field(8; Indentation; Integer)
        {
            Caption = 'Indentation';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Value".Indentation where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
        }
        field(10; Allowed; Boolean)
        {
            InitValue = true;

            trigger OnValidate()
            var
                DefaultDimension: Record "Default Dimension";
            begin
                if not Allowed then
                    if DefaultDimension.Get("Table ID", "No.", "Dimension Code") then
                        DefaultDimension.CheckDisallowedDimensionValue(Rec);
            end;
        }
    }

    keys
    {
        key(PK; "Table ID", "No.", "Dimension Code", "Dimension Value Code")
        {
            Clustered = true;
        }
    }

    var
        CaptionLbl: Label '%1 - %2 %3', Comment = '%1 = dimension code and %2- table name, %3 - account number', Locked = true;

    procedure GetCaption(): Text[250]
    begin
        exit(StrSubstNo(CaptionLbl, "Dimension Code", GetTableCaption(), "No."));
    end;

    procedure GetTableCaption(): Text[250]
    var
        ObjTransl: Record "Object Translation";
    begin
        exit(ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, "Table ID"));
    end;

    procedure RenameNo(TableId: Integer; OldNo: Code[20]; NewNo: Code[20]; DimensionCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Table ID", TableId);
        DimValuePerAccount.SetRange("No.", OldNo);
        DimValuePerAccount.SetRange("Dimension Code", DimensionCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", NewNo, DimValuePerAccount."Dimension Code", DimValuePerAccount."Dimension Value Code");
            until DimValuePerAccount.Next() = 0;
    end;

    procedure RenameDimension(OldDimensionCode: Code[20]; NewDimensionCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Dimension Code", OldDimensionCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", DimValuePerAccount."No.", NewDimensionCode, DimValuePerAccount."Dimension Value Code");
            until DimValuePerAccount.Next() = 0;
    end;

    procedure RenameDimensionValue(DimensionCode: Code[20]; OldDimensionValueCode: Code[20]; NewDimensionValueCode: Code[20])
    var
        DimValuePerAccount: Record "Dim. Value per Account";
    begin
        DimValuePerAccount.SetRange("Dimension Code", DimensionCode);
        DimValuePerAccount.SetRange("Dimension Value Code", OldDimensionValueCode);
        if DimValuePerAccount.FindSet() then
            repeat
                RenameDimValuePerAccount(DimValuePerAccount, DimValuePerAccount."Table ID", DimValuePerAccount."No.", DimValuePerAccount."Dimension Code", NewDimensionValueCode);
            until DimValuePerAccount.Next() = 0;
    end;

    local procedure RenameDimValuePerAccount(DimValuePerAccount: Record "Dim. Value per Account"; TableId: Integer; No: Code[20]; DimensionCode: Code[20]; DimensionValueCode: code[20])
    var
        DimValuePerAccountToRename: Record "Dim. Value per Account";
    begin
        DimValuePerAccountToRename := DimValuePerAccount;
        DimValuePerAccountToRename.Rename(TableId, No, DimensionCode, DimensionValueCode);
    end;
}
