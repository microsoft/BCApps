// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Stores individual dimension entries that form dimension sets for multi-dimensional analysis.
/// Core table for dimension set management enabling optimized storage and retrieval of dimension combinations.
/// </summary>
/// <remarks>
/// Central to dimension set architecture: dimension sets group multiple dimensions for transaction analysis.
/// Integrates with Dimension Set Tree Node for optimized duplicate detection and dimension set creation.
/// Extensibility: OnBeforeGetDimensionSetID and OnGetDimensionSetIDOnBeforeInsertTreeNode events for custom logic.
/// </remarks>
table 480 "Dimension Set Entry"
{
    Caption = 'Dimension Set Entry';
    DrillDownPageID = "Dimension Set Entries";
    LookupPageID = "Dimension Set Entries";
    Permissions = TableData "Dimension Set Entry" = rim,
                  TableData "Dimension Set Tree Node" = rim;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier linking multiple dimension entries into a single dimension set.
        /// </summary>
        field(1; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
        }
        /// <summary>
        /// Code identifying the dimension being specified (Department, Project, etc.).
        /// </summary>
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            ToolTip = 'Specifies the dimension.';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                if not DimMgt.CheckDim("Dimension Code") then
                    Error(DimMgt.GetDimErr());
                if "Dimension Code" <> xRec."Dimension Code" then begin
                    "Dimension Value Code" := '';
                    "Dimension Value ID" := 0;
                end;
            end;
        }
        /// <summary>
        /// Specific value for the dimension (Sales, Marketing, Europe, etc.).
        /// </summary>
        field(3; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            ToolTip = 'Specifies the dimension value.';
            NotBlank = true;
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"), Blocked = const(false));

            trigger OnValidate()
            begin
                if not DimMgt.CheckDimValue("Dimension Code", "Dimension Value Code") then
                    Error(DimMgt.GetDimErr());

                DimVal.Get("Dimension Code", "Dimension Value Code");
                "Dimension Value ID" := DimVal."Dimension Value ID";
            end;
        }
        /// <summary>
        /// Internal identifier for the dimension value used for optimized tree node operations.
        /// </summary>
        field(4; "Dimension Value ID"; Integer)
        {
            Caption = 'Dimension Value ID';
        }
        /// <summary>
        /// Display name of the dimension from the Dimension table.
        /// </summary>
        field(5; "Dimension Name"; Text[30])
        {
            CalcFormula = lookup(Dimension.Name where(Code = field("Dimension Code")));
            Caption = 'Dimension Name';
            ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Display name of the dimension value from the Dimension Value table.
        /// </summary>
        field(6; "Dimension Value Name"; Text[50])
        {
            CalcFormula = lookup("Dimension Value".Name where("Dimension Code" = field("Dimension Code"),
                                                               Code = field("Dimension Value Code")));
            Caption = 'Dimension Value Name';
            ToolTip = 'Specifies the descriptive name of the Dimension Value Code field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Shortcut dimension number (3-8) for this dimension if configured in General Ledger Setup.
        /// </summary>
        field(8; "Global Dimension No."; Integer)
        {
            Caption = 'Shortcut Dimension No.';
        }
    }

    keys
    {
        key(Key1; "Dimension Set ID", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "Dimension Value ID")
        {
        }
        key(Key3; "Dimension Code", "Dimension Value Code", "Dimension Set ID")
        {
        }
        key(Key4; SystemModifiedAt)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;

        "Global Dimension No." := GetGlobalDimNo();
    end;

    trigger OnModify()
    begin
        if DimVal.Get("Dimension Code", "Dimension Value Code") then
            "Dimension Value ID" := DimVal."Dimension Value ID"
        else
            "Dimension Value ID" := 0;

        "Global Dimension No." := GetGlobalDimNo();
    end;

    var
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;

    /// <summary>
    /// Creates or retrieves the dimension set ID for a collection of dimension entries.
    /// Uses tree structure optimization to avoid duplicate dimension sets and improve performance.
    /// </summary>
    /// <param name="DimSetEntry">Collection of dimension entries to process into a dimension set</param>
    /// <returns>Dimension set ID that uniquely identifies the dimension combination</returns>
    /// <remarks>
    /// Core engine for dimension set creation: checks for existing combinations before creating new sets.
    /// Integrates with Dimension Set Tree Node for optimized duplicate detection and storage.
    /// </remarks>
    procedure GetDimensionSetID(var DimSetEntry: Record "Dimension Set Entry"): Integer
    var
        DimSetEntry2: Record "Dimension Set Entry";
        DimSetTreeNode: Record "Dimension Set Tree Node";
        Found: Boolean;
    begin
        OnBeforeGetDimensionSetID(DimSetEntry);

        DimSetEntry2.Copy(DimSetEntry);
        if DimSetEntry."Dimension Set ID" > 0 then
            DimSetEntry.SetRange("Dimension Set ID", DimSetEntry."Dimension Set ID");

        DimSetEntry.SetCurrentKey("Dimension Value ID");
        DimSetEntry.SetFilter("Dimension Code", '<>%1', '');
        DimSetEntry.SetFilter("Dimension Value Code", '<>%1', '');

        if not DimSetEntry.FindSet() then begin
            DimSetEntry.Copy(DimSetEntry2);
            exit(0);
        end;

        Found := true;
        DimSetTreeNode."Dimension Set ID" := 0;
        repeat
            DimSetEntry.TestField("Dimension Value ID");
            if Found then
                if not DimSetTreeNode.Get(DimSetTreeNode."Dimension Set ID", DimSetEntry."Dimension Value ID") then begin
                    Found := false;
                    DimSetTreeNode.LockTable();
                end;
            OnGetDimensionSetIDOnBeforeInsertTreeNode(DimSetEntry, Found);
            if not Found then begin
                DimSetTreeNode."Parent Dimension Set ID" := DimSetTreeNode."Dimension Set ID";
                DimSetTreeNode."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                DimSetTreeNode."Dimension Set ID" := 0;
                DimSetTreeNode."In Use" := false;
                if not DimSetTreeNode.Insert(true) then
                    DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
        until DimSetEntry.Next() = 0;
        if not DimSetTreeNode."In Use" then begin
            if Found then begin
                DimSetTreeNode.LockTable();
                DimSetTreeNode.Get(DimSetTreeNode."Parent Dimension Set ID", DimSetTreeNode."Dimension Value ID");
            end;
            DimSetTreeNode."In Use" := true;
            DimSetTreeNode.Modify();
            InsertDimSetEntries(DimSetEntry, DimSetTreeNode."Dimension Set ID");
        end;

        DimSetEntry.Copy(DimSetEntry2);

        exit(DimSetTreeNode."Dimension Set ID");
    end;

    local procedure InsertDimSetEntries(var DimSetEntry: Record "Dimension Set Entry"; NewID: Integer)
    var
        DimSetEntry2: Record "Dimension Set Entry";
    begin
        DimSetEntry2.LockTable();
        if DimSetEntry.FindSet() then
            repeat
                DimSetEntry2 := DimSetEntry;
                DimSetEntry2."Dimension Set ID" := NewID;
                DimSetEntry2."Global Dimension No." := DimSetEntry2.GetGlobalDimNo();
                DimSetEntry2.Insert();
            until DimSetEntry.Next() = 0;
    end;

    /// <summary>
    /// Updates the global dimension number for all entries with the specified dimension code.
    /// Used when changing shortcut dimension assignments in General Ledger Setup.
    /// </summary>
    /// <param name="DimensionCode">Dimension code to update</param>
    /// <param name="GlobalDimensionNo">New global dimension number (3-8)</param>
    procedure UpdateGlobalDimensionNo(DimensionCode: Code[20]; GlobalDimensionNo: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.ModifyAll("Global Dimension No.", GlobalDimensionNo);
    end;

    /// <summary>
    /// Determines the global dimension number (3-8) for the current dimension code.
    /// Returns the shortcut dimension number configured in General Ledger Setup.
    /// </summary>
    /// <returns>Global dimension number (3-8) or 0 if not configured as shortcut dimension</returns>
    procedure GetGlobalDimNo(): Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GlobalDimensionNo: Integer;
    begin
        GeneralLedgerSetup.Get();
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 3 Code" then
            exit(3);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 4 Code" then
            exit(4);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 5 Code" then
            exit(5);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 6 Code" then
            exit(6);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 7 Code" then
            exit(7);
        if "Dimension Code" = GeneralLedgerSetup."Shortcut Dimension 8 Code" then
            exit(8);

        GlobalDimensionNo := 0;
        OnAfterGetGlobalDimNo("Dimension Code", GlobalDimensionNo);
        exit(GlobalDimensionNo);
    end;

    /// <summary>
    /// Integration event raised before starting dimension set ID creation or retrieval process.
    /// Enables custom preprocessing or validation of dimension entries before set processing.
    /// </summary>
    /// <param name="DimensionSetEntry">Dimension entries being processed into a set</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDimensionSetID(var DimensionSetEntry: Record "Dimension Set Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before inserting nodes into the dimension set tree structure.
    /// Enables custom logic during tree node creation and duplicate detection process.
    /// </summary>
    /// <param name="DimensionSetEntry">Current dimension entry being processed</param>
    /// <param name="Found">Whether matching tree node was found</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetDimensionSetIDOnBeforeInsertTreeNode(var DimensionSetEntry: Record "Dimension Set Entry"; var Found: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after determining global dimension number for a dimension code.
    /// Enables custom logic to assign global dimension numbers for dimensions not configured as shortcuts.
    /// </summary>
    /// <param name="DimensionCode">Dimension code being evaluated</param>
    /// <param name="GlobalDimensionNo">Determined global dimension number</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGlobalDimNo(DimensionCode: Code[20]; var GlobalDimensionNo: Integer)
    begin
    end;
}

