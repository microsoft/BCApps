// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Stores dimension value filter components for complex dimension set ID filtering operations.
/// Supports breakdown of long dimension value filters into manageable text segments for processing.
/// </summary>
/// <remarks>
/// Enables dimension filtering that exceeds single field length limitations through segmented storage.
/// Supports reconstruction of complete dimension value filters from component parts for advanced filtering scenarios.
/// </remarks>
table 355 "Dimension Set ID Filter Line"
{
    Caption = 'Dimension Set ID Filter Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier code for the dimension filter group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        /// <summary>
        /// Dimension code for which the filter value segments apply.
        /// </summary>
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        /// <summary>
        /// Sequential line number for ordering dimension value filter segments.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Segment of dimension value filter text for reconstruction into complete filter expression.
        /// </summary>
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

    /// <summary>
    /// Stores a long dimension value filter by breaking it into text segments across multiple records.
    /// Enables handling of complex dimension filters that exceed single field length limitations.
    /// </summary>
    /// <param name="DimensionValueFilter">Complete dimension value filter text to segment and store</param>
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

    /// <summary>
    /// Reconstructs complete dimension value filter text from stored segments for a specific dimension.
    /// Combines all filter parts in sequence to rebuild the original filter expression.
    /// </summary>
    /// <param name="NewCode">Filter group code to retrieve</param>
    /// <param name="NewDimensionCode">Dimension code to retrieve filter for</param>
    /// <returns>Complete reconstructed dimension value filter text</returns>
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

