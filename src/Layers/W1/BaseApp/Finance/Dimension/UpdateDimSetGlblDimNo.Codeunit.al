// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Diagnostics;

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

    procedure BlankGlobalDimensionNo()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetLoadFields("Global Dimension No.");
        DimensionSetEntry.SetFilter("Global Dimension No.", '>0');
        DimensionSetEntry.ModifyAll("Global Dimension No.", 0, false);
        UpdateProgressDialog();
    end;

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
