// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Diagnostics;

/// <summary>
/// Updates global dimension numbers in dimension set entries based on general ledger setup configuration.
/// Manages the synchronization of global dimension assignments across all dimension set entries when dimension setup changes.
/// </summary>
/// <remarks>
/// Used primarily during dimension setup changes to ensure dimension set entries reflect current global dimension assignments.
/// Includes progress tracking and change log integration for dimension number updates across large datasets.
/// </remarks>
codeunit 482 "Update Dim. Set Glbl. Dim. No."
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "General Ledger Setup" = rm,
                  tabledata "Dimension Set Entry" = rm;

    trigger OnRun()
    begin
        UpdateDimSetEntryGlobalDimNo();
    end;

    var
        Counter: Integer;
        Window: Dialog;
        ProgressBarMsg: Label 'Processing: @1@@@@@@@';

    /// <summary>
    /// Updates global dimension numbers in all dimension set entries based on current general ledger setup.
    /// Processes dimension set entries with progress tracking and change log integration.
    /// </summary>
    /// <remarks>
    /// Clears existing global dimension numbers and assigns new values based on shortcut dimension configuration.
    /// Uses event subscription to ensure change log tracking during the update process.
    /// </remarks>
    procedure UpdateDimSetEntryGlobalDimNo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        UpdateDimSetGlblDimNo: Codeunit "Update Dim. Set Glbl. Dim. No.";
    begin
        GeneralLedgerSetup.Get();
        OpenProgressDialog();

        BlankGlobalDimensionNo();
        BindSubscription(UpdateDimSetGlblDimNo);
        SetGlobalDimensionNos(GeneralLedgerSetup);
        UnbindSubscription(UpdateDimSetGlblDimNo);

        CloseProgressDialog();
    end;

    local procedure OpenProgressDialog()
    begin
        Counter := 0;
        if GuiAllowed then
            Window.Open(ProgressBarMsg);
    end;

    local procedure UpdateProgressDialog()
    begin
        Counter += 1;
        if GuiAllowed then
            Window.Update(1, Round(counter / 7 * 10000, 1));
    end;

    local procedure CloseProgressDialog()
    begin
        if GuiAllowed then
            Window.Close();
    end;

    /// <summary>
    /// Clears all global dimension number assignments from dimension set entries.
    /// Resets global dimension numbers to zero as preparation for reassignment based on current setup.
    /// </summary>
    procedure BlankGlobalDimensionNo()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetLoadFields("Global Dimension No.");
        DimensionSetEntry.SetFilter("Global Dimension No.", '>0');
        DimensionSetEntry.ModifyAll("Global Dimension No.", 0, false);
        UpdateProgressDialog();
    end;

    /// <summary>
    /// Assigns global dimension numbers to dimension set entries based on general ledger setup configuration.
    /// Updates dimension set entries for shortcut dimensions 3-8 with their corresponding global dimension numbers.
    /// </summary>
    /// <param name="GeneralLedgerSetup">General ledger setup record containing shortcut dimension configuration</param>
    procedure SetGlobalDimensionNos(GeneralLedgerSetup: Record "General Ledger Setup")
    begin
        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 3 Code", 3);
        UpdateProgressDialog();

        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 4 Code", 4);
        UpdateProgressDialog();

        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 5 Code", 5);
        UpdateProgressDialog();

        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 6 Code", 6);
        UpdateProgressDialog();

        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 7 Code", 7);
        UpdateProgressDialog();

        SetGlobalDimensionNo(GeneralLedgerSetup."Shortcut Dimension 8 Code", 8);
        UpdateProgressDialog();
    end;

    local procedure SetGlobalDimensionNo(ShortcutDimensionCode: Code[20]; GlobalDimNo: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if ShortcutDimensionCode = '' then
            exit;

        DimensionSetEntry.SetLoadFields("Dimension Code", "Global Dimension No.");
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.ModifyAll("Global Dimension No.", GlobalDimNo, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Change Log Management", 'OnAfterIsAlwaysLoggedTable', '', false, false)]
    local procedure OnAfterIsAlwaysLoggedTableHandler(TableID: Integer; var AlwaysLogTable: Boolean)
    begin
        if TableID = Database::"Dimension Set Entry" then
            AlwaysLogTable := true;
    end;
}
