// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;

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

