// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using System.Reflection;

/// <summary>
/// Temporary buffer table for dimension change operations and batch processing scenarios.
/// Stores original and new dimension value combinations during dimension modifications and global dimension changes.
/// </summary>
/// <remarks>
/// Used primarily for Change Global Dimensions functionality and dimension correction processes.
/// Provides validation for dimension codes and dimension values through table relations.
/// </remarks>
table 360 "Dimension Buffer"
{
    Caption = 'Dimension Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Identifier of the source table containing the entries with dimensions to be changed.
        /// </summary>
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        /// <summary>
        /// Entry number from the source table identifying the specific record with dimensions to be changed.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Code of the dimension being changed during dimension modification operations.
        /// </summary>
        field(3; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
        /// <summary>
        /// Current dimension value code that needs to be changed to a new value.
        /// </summary>
        field(4; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"), Blocked = const(false));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
        /// <summary>
        /// Target dimension value code that the current dimension value should be changed to.
        /// </summary>
        field(5; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
            DataClassification = SystemMetadata;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"), Blocked = const(false));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "New Dimension Value Code") then
                    Error(DimMgt.GetDimErr());
            end;
        }
        /// <summary>
        /// Line number for ordering and identification purposes in batch dimension change operations.
        /// </summary>
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Count of dimensions associated with the record for statistical and filtering purposes.
        /// </summary>
        field(7; "No. Of Dimensions"; Integer)
        {
            Caption = 'No. Of Dimensions';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Entry No.", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "No. Of Dimensions")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;
}

