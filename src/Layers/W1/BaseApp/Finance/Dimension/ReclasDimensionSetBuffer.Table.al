// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Temporary buffer table for dimension reclassification operations.
/// Manages old and new dimension value mappings during dimension set reclassification processes.
/// </summary>
/// <remarks>
/// Used in dimension reclassification scenarios to track dimension value changes and generate updated dimension sets.
/// Supports validation and lookup of dimension values during reclassification operations.
/// Integrates with dimension management for dimension set creation and modification.
/// </remarks>
table 482 "Reclas. Dimension Set Buffer"
{
    Caption = 'Reclas. Dimension Set Buffer';
    DrillDownPageID = "Dimension Set Entries";
    LookupPageID = "Dimension Set Entries";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Code of the dimension being reclassified.
        /// </summary>
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            ToolTip = 'Specifies a dimension code to attach a dimension to a journal line.';
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
        /// <summary>
        /// Original dimension value code before reclassification.
        /// </summary>
        field(2; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            ToolTip = 'Specifies the original dimension value to register the transfer of items from the original dimension value to the new dimension value.';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                "Dimension Value ID" := GetDimValID("Dimension Code", "Dimension Value Code");
            end;
        }
        /// <summary>
        /// Unique identifier for the original dimension value.
        /// </summary>
        field(3; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// New dimension value code to replace the original value during reclassification.
        /// </summary>
        field(4; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
            ToolTip = 'Specifies the new dimension value to register the transfer of items, from the original dimension value to the new dimension value.';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));

            trigger OnValidate()
            begin
                "New Dimension Value ID" := GetDimValID("Dimension Code", "New Dimension Value Code");
            end;
        }
        /// <summary>
        /// Unique identifier for the new dimension value.
        /// </summary>
        field(5; "New Dimension Value ID"; Integer)
        {
            Caption = 'New Dimension Value ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Display name of the dimension for user interface presentation.
        /// </summary>
        field(6; "Dimension Name"; Text[30])
        {
            CalcFormula = lookup(Dimension.Name where(Code = field("Dimension Code")));
            Caption = 'Dimension Name';
            ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display name of the original dimension value for user interface presentation.
        /// </summary>
        field(7; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            ToolTip = 'Specifies the descriptive name of the original Dimension Value Code field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display name of the new dimension value for user interface presentation.
        /// </summary>
        field(8; "New Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("New Dimension Value Code")));
            Caption = 'New Dimension Value Name';
            ToolTip = 'Specifies the descriptive name of the New Dimension Value Code field.';
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

    /// <summary>
    /// Generates dimension set ID from original dimension values in the buffer.
    /// Creates dimension set ID based on current dimension value codes before reclassification.
    /// </summary>
    /// <param name="ReclasDimSetBuf">Reclassification dimension set buffer containing dimension mappings</param>
    /// <returns>Dimension set ID for the original dimension values</returns>
    /// <remarks>
    /// Used to identify the original dimension set before reclassification operations.
    /// Delegates to GetDimSetID2 with NewVal set to false for original values.
    /// </remarks>
    procedure GetDimSetID(var ReclasDimSetBuf: Record "Reclas. Dimension Set Buffer"): Integer
    begin
        exit(GetDimSetID2(ReclasDimSetBuf, false));
    end;

    /// <summary>
    /// Generates dimension set ID from new dimension values in the buffer.
    /// Creates dimension set ID based on new dimension value codes after reclassification.
    /// </summary>
    /// <param name="ReclasDimSetBuf">Reclassification dimension set buffer containing dimension mappings</param>
    /// <returns>Dimension set ID for the new dimension values</returns>
    /// <remarks>
    /// Used to create the target dimension set for reclassification operations.
    /// Delegates to GetDimSetID2 with NewVal set to true for new values.
    /// </remarks>
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

