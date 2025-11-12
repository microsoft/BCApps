// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

table 2581 "Dim Correction Change"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        field(2; "Dimension Code"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = Dimension.Code;
        }

        field(3; "Dimension Value"; Text[100])
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Value".Name where("Dimension Code" = field("Dimension Code"));
        }

        field(4; "New Value"; Text[100])
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            var
                DimensionValue: Record "Dimension Value";
                DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
                DimensionManagement: Codeunit DimensionManagement;
            begin
                if "New Value" = '' then begin
                    Rec.Validate(Rec."Change Type", Rec."Change Type"::"No Change");
                    exit;
                end;

                DimensionCorrectionMgt.VerifyIfDimensionCanBeChanged(Rec);

                if Rec."Change Type" <> Rec."Change Type"::Add then
                    Rec."Change Type" := Rec."Change Type"::Change;

                DimensionValue.SetRange("Dimension Code", Rec."Dimension Code");
                DimensionValue.SetRange(Code, "New Value");
                DimensionValue.FindFirst();

                if not DimensionManagement.CheckDim(DimensionValue."Dimension Code") then
                    Error(DimensionManagement.GetDimErr());

                if not DimensionManagement.CheckDimValue(DimensionValue."Dimension Code", DimensionValue.Code) then
                    Error(DimensionManagement.GetDimErr());

                Rec."New Value ID" := DimensionValue."Dimension Value ID";
                Rec."New Value" := DimensionValue.Code;
            end;
        }

        field(5; "New Value ID"; Integer)
        {
            DataClassification = CustomerContent;
        }

        field(6; "Change Type"; Option)
        {
            DataClassification = CustomerContent;
            OptionMembers = "No Change","Change","Add","Remove";
            trigger OnValidate()
            var
                DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
            begin
                if Rec."Change Type" = Rec."Change Type"::Remove then
                    DimensionCorrectionMgt.VerifyIfDimensionCanBeChanged(Rec);

                if Rec."Change Type" in [Rec."Change Type"::"No change", Rec."Change Type"::"Remove"] then begin
                    Clear(Rec."New Value");
                    Clear(Rec."New Value ID");
                end;
            end;
        }

        field(10; "Dimension Values"; Blob)
        {
            DataClassification = CustomerContent;
        }

        field(11; "Dimension Value Count"; Integer)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Dimension Correction Entry No.", "Dimension Code")
        {
            Clustered = true;
        }
    }

    procedure SetDimensionValues(DimensionValues: List of [Integer])
    var
        DimValuesOutStream: OutStream;
        DimSetValue: Integer;
        DimSetValueFilter: Text;
    begin
        if DimensionValues.Count() = 0 then begin
            Clear(Rec."Dimension Values");
            exit;
        end;

        foreach DimSetValue in DimensionValues do
            if DimSetValueFilter = '' then
                DimSetValueFilter += Format(DimSetValue)
            else
                DimSetValueFilter += '|' + Format(DimSetValue);

        Rec."Dimension Values".CreateOutStream(DimValuesOutStream);
        DimValuesOutStream.WriteText(DimSetValueFilter);
    end;

    procedure GetDimensionValues(): Text
    var
        DimValuesInStream: InStream;
        DimSetValueFilter: Text;
    begin
        Rec.CalcFields(Rec."Dimension Values");
        if not Rec."Dimension Values".HasValue() then
            exit('');

        Rec."Dimension Values".CreateInStream(DimValuesInStream);
        DimValuesInStream.ReadText(DimSetValueFilter);
        exit(DimSetValueFilter);
    end;
}
