// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

/// <summary>
/// Codeunit for retrieving shortcut dimension values from dimension sets.
/// Provides efficient access to global and shortcut dimension values using cached GL setup configuration.
/// </summary>
/// <remarks>
/// Single instance codeunit that caches GL setup for optimal performance during dimension value retrieval.
/// Supports both global dimensions (1-2) and all shortcut dimensions (1-8) extraction from dimension sets.
/// Uses temporary caching to minimize database reads during repetitive dimension value access.
/// </remarks>
codeunit 480 "Get Shortcut Dimension Values"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimensionSetEntry: Record "Dimension Set Entry";
        HasGotGLSetup: Boolean;
        WhenGotGLSetup: DateTime;
        GLSetupShortcutDimCode: array[8] of Code[20];

    /// <summary>
    /// Retrieves global dimension values (dimensions 1-2) from a dimension set.
    /// Extracts dimension value codes for global dimensions configured in General Ledger Setup.
    /// </summary>
    /// <param name="DimSetID">Dimension set ID to extract global dimension values from</param>
    /// <param name="ShortcutDimCode">Array to receive global dimension value codes (positions 1-2 populated)</param>
    /// <remarks>
    /// Only populates the first two positions of the array corresponding to global dimensions.
    /// Uses cached GL setup configuration for optimal performance during repeated calls.
    /// Returns empty codes for dimensions not present in the dimension set.
    /// </remarks>
    procedure GetGlobalDimensions(DimSetID: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        i: Integer;
    begin
        Clear(ShortcutDimCode);
        if DimSetID = 0 then
            exit;
        GetGLSetup();
        for i := 1 to 2 do
            if GLSetupShortcutDimCode[i] <> '' then
                if DimensionSetEntry.Get(DimSetID, GLSetupShortcutDimCode[i]) then
                    ShortcutDimCode[i] := DimensionSetEntry."Dimension Value Code";
    end;

    /// <summary>
    /// Retrieves all shortcut dimension values (dimensions 1-8) from a dimension set.
    /// Extracts dimension value codes for all shortcut dimensions configured in General Ledger Setup.
    /// </summary>
    /// <param name="DimSetID">Dimension set ID to extract shortcut dimension values from</param>
    /// <param name="ShortcutDimCode">Array to receive all shortcut dimension value codes (positions 1-8)</param>
    /// <remarks>
    /// Populates all eight positions of the array corresponding to shortcut dimensions 1-8.
    /// Uses temporary caching for improved performance during repetitive dimension access.
    /// Returns empty codes for dimensions not configured or not present in the dimension set.
    /// </remarks>
    procedure GetShortcutDimensions(DimSetID: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        i: Integer;
    begin
        Clear(ShortcutDimCode);
        if DimSetID = 0 then
            exit;
        GetGLSetup();
        for i := 1 to 8 do
            if GLSetupShortcutDimCode[i] <> '' then
                ShortcutDimCode[i] := GetDimSetEntry(DimSetID, GLSetupShortcutDimCode[i]);
    end;

    local procedure GetDimSetEntry(DimSetID: Integer; DimCode: Code[20]): Code[20]
    begin
        if TempDimSetEntry.Get(DimSetID, DimCode) then
            exit(TempDimSetEntry."Dimension Value Code");

        TempDimSetEntry.Init();
        if DimensionSetEntry.Get(DimSetID, DimCode) then
            TempDimSetEntry := DimensionSetEntry
        else begin
            TempDimSetEntry."Dimension Set ID" := DimSetID;
            TempDimSetEntry."Dimension Code" := DimCode;
        end;
        TempDimSetEntry.Insert();
        exit(TempDimSetEntry."Dimension Value Code");
    end;

    local procedure GetGLSetup()
    begin
        if WhenGotGLSetup = 0DT then
            WhenGotGLSetup := CurrentDateTime;
        if CurrentDateTime > WhenGotGLSetup + 60000 then
            HasGotGLSetup := false;
        if HasGotGLSetup then
            exit;
        GLSetup.Get();
        GLSetupShortcutDimCode[1] := GLSetup."Shortcut Dimension 1 Code";
        GLSetupShortcutDimCode[2] := GLSetup."Shortcut Dimension 2 Code";
        GLSetupShortcutDimCode[3] := GLSetup."Shortcut Dimension 3 Code";
        GLSetupShortcutDimCode[4] := GLSetup."Shortcut Dimension 4 Code";
        GLSetupShortcutDimCode[5] := GLSetup."Shortcut Dimension 5 Code";
        GLSetupShortcutDimCode[6] := GLSetup."Shortcut Dimension 6 Code";
        GLSetupShortcutDimCode[7] := GLSetup."Shortcut Dimension 7 Code";
        GLSetupShortcutDimCode[8] := GLSetup."Shortcut Dimension 8 Code";
        HasGotGLSetup := true;
        WhenGotGLSetup := CurrentDateTime;
    end;

    [EventSubscriber(ObjectType::Table, Database::"General Ledger Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnGLSetupModify(var Rec: Record "General Ledger Setup"; var xRec: Record "General Ledger Setup"; RunTrigger: Boolean)
    begin
        HasGotGLSetup := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Dimension Value", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnDimValueRename(var Rec: Record "Dimension Value"; var xRec: Record "Dimension Value"; RunTrigger: Boolean)
    begin
        TempDimSetEntry.SetRange("Dimension Code", Rec."Dimension Code");
        TempDimSetEntry.DeleteAll();
        TempDimSetEntry.SetRange("Dimension Code");
    end;
}

