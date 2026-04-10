// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Header table for storing global dimension change configuration parameters.
/// Controls the settings and parameters for changing global dimensions across all Business Central tables.
/// </summary>
/// <remarks>
/// Single-record table that stores configuration for global dimension change operations.
/// Supports both sequential and parallel processing modes with change type tracking.
/// Integrates with Change Global Dimensions functionality to update dimension references system-wide.
/// </remarks>
table 484 "Change Global Dim. Header"
{
    Caption = 'Change Global Dim. Header';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key field for the single configuration record.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Previous global dimension 1 code before the change operation.
        /// </summary>
        field(2; "Old Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Old Global Dimension 1 Code';
            ToolTip = 'Specifies the dimension that is currently defined as Global Dimension 1.';
            DataClassification = SystemMetadata;
            TableRelation = Dimension;
        }
        /// <summary>
        /// Previous global dimension 2 code before the change operation.
        /// </summary>
        field(3; "Old Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Old Global Dimension 2 Code';
            ToolTip = 'Specifies the dimension that is currently defined as Global Dimension 2.';
            DataClassification = SystemMetadata;
            TableRelation = Dimension;
        }
        /// <summary>
        /// New global dimension 1 code to be set after the change operation.
        /// </summary>
        field(4; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies another global dimension that you want to use. The second field on the row will show the current global dimension.';
            DataClassification = SystemMetadata;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                ValidateDimCode("Global Dimension 1 Code");
                if "Global Dimension 1 Code" = "Global Dimension 2 Code" then begin
                    "Global Dimension 2 Code" := '';
                    "Change Type 2" := "Change Type 2"::Blank;
                end;
                CalcChangeType("Change Type 1", "Global Dimension 1 Code", "Old Global Dimension 1 Code", "Old Global Dimension 2 Code");
            end;
        }
        /// <summary>
        /// New global dimension 2 code to be set after the change operation.
        /// </summary>
        field(5; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies another global dimension that you want to use. The second field on the row will show the current global dimension.';
            DataClassification = SystemMetadata;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                ValidateDimCode("Global Dimension 2 Code");
                if "Global Dimension 2 Code" = "Global Dimension 1 Code" then begin
                    "Global Dimension 1 Code" := '';
                    "Change Type 1" := "Change Type 1"::Blank;
                end;
                CalcChangeType("Change Type 2", "Global Dimension 2 Code", "Old Global Dimension 2 Code", "Old Global Dimension 1 Code");
            end;
        }
        /// <summary>
        /// Enables parallel processing for dimension change operations to improve performance.
        /// </summary>
        field(6; "Parallel Processing"; Boolean)
        {
            Caption = 'Parallel Processing';
            ToolTip = 'Specifies if the change will be processed by parallel background jobs.';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Type of change operation for global dimension 1 (None, Blank, Replace, or New).
        /// </summary>
        field(7; "Change Type 1"; Option)
        {
            Caption = 'Change Type 1';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Blank,Replace,New';
            OptionMembers = "None",Blank,Replace,New;
        }
        /// <summary>
        /// Type of change operation for global dimension 2 (None, Blank, Replace, or New).
        /// </summary>
        field(8; "Change Type 2"; Option)
        {
            Caption = 'Change Type 2';
            DataClassification = SystemMetadata;
            OptionCaption = 'None,Blank,Replace,New';
            OptionMembers = "None",Blank,Replace,New;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimIsUsedInGLSetupErr: Label 'The dimension %1 is used in General Ledger Setup window as a shortcut dimension.', Comment = '%1 - a dimension code, like PROJECT';

    local procedure CalcChangeType(var ChangeType: Option "None",Blank,Replace,New; "Code": Code[20]; OldCode: Code[20]; OtherOldCode: Code[20])
    begin
        if Code = OtherOldCode then
            ChangeType := ChangeType::Replace
        else
            if Code = OldCode then
                ChangeType := ChangeType::None
            else
                if Code = '' then
                    ChangeType := ChangeType::Blank
                else
                    ChangeType := ChangeType::New
    end;

    /// <summary>
    /// Refreshes the dimension change configuration by loading current GL setup values.
    /// Resets change types to None for both global dimensions.
    /// </summary>
    procedure Refresh()
    begin
        RefreshCurrentDimCodes();
        "Global Dimension 1 Code" := GeneralLedgerSetup."Global Dimension 1 Code";
        "Global Dimension 2 Code" := GeneralLedgerSetup."Global Dimension 2 Code";
        "Change Type 1" := "Change Type 1"::None;
        "Change Type 2" := "Change Type 2"::None;
    end;

    /// <summary>
    /// Refreshes the old dimension codes by retrieving current values from General Ledger Setup.
    /// </summary>
    procedure RefreshCurrentDimCodes()
    begin
        GeneralLedgerSetup.Get();
        "Old Global Dimension 1 Code" := GeneralLedgerSetup."Global Dimension 1 Code";
        "Old Global Dimension 2 Code" := GeneralLedgerSetup."Global Dimension 2 Code";
    end;

    local procedure IsUsedInShortcurDims(DimensionCode: Code[20]): Boolean
    begin
        GeneralLedgerSetup.Get();
        exit(
          DimensionCode in
          [GeneralLedgerSetup."Shortcut Dimension 3 Code",
           GeneralLedgerSetup."Shortcut Dimension 4 Code",
           GeneralLedgerSetup."Shortcut Dimension 5 Code",
           GeneralLedgerSetup."Shortcut Dimension 6 Code",
           GeneralLedgerSetup."Shortcut Dimension 7 Code",
           GeneralLedgerSetup."Shortcut Dimension 8 Code"]);
    end;

    local procedure ValidateDimCode(NewCode: Code[20])
    var
        Dimension: Record Dimension;
    begin
        if NewCode <> '' then begin
            Dimension.Get(NewCode);
            if IsUsedInShortcurDims(NewCode) then
                Error(DimIsUsedInGLSetupErr, NewCode);
        end;
    end;
}

