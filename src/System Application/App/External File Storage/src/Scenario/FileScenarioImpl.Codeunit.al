// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System;

codeunit 9453 "File Scenario Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "File Scenario" = rimd;

    procedure GetFileAccount(Scenario: Enum "File Scenario"; var TempFileAccount: Record "File Account" temporary): Boolean
    var
        TempAllFileAccounts: Record "File Account" temporary;
        FileScenario: Record "File Scenario";
        FileAccounts: Codeunit "File Account";
    begin
        FileAccounts.GetAllAccounts(TempAllFileAccounts);

        // Find the account for the provided scenario
        if FileScenario.Get(Scenario) then
            if TempAllFileAccounts.Get(FileScenario."Account Id", FileScenario.Connector) then begin
                TempFileAccount := TempAllFileAccounts;
                exit(true);
            end;

        // Fallback to the default account if the scenario isn't mapped or the mapped account doesn't exist
        if FileScenario.Get(Enum::"File Scenario"::Default) then
            if TempAllFileAccounts.Get(FileScenario."Account Id", FileScenario.Connector) then begin
                TempFileAccount := TempAllFileAccounts;
                exit(true);
            end;
    end;

    procedure SetFileAccount(Scenario: Enum "File Scenario"; TempFileAccount: Record "File Account" temporary)
    var
        FileScenario: Record "File Scenario";
    begin
        if not FileScenario.Get(Scenario) then begin
            FileScenario.Scenario := Scenario;
            FileScenario.Insert();
        end;

        FileScenario."Account Id" := TempFileAccount."Account Id";
        FileScenario.Connector := TempFileAccount.Connector;

        FileScenario.Modify();
    end;

    procedure UnassignScenario(Scenario: Enum "File Scenario")
    var
        FileScenario: Record "File Scenario";
    begin
        if FileScenario.Get(Scenario) then
            FileScenario.Delete();
    end;

    /// <summary>
    /// Get a list of entries, representing a tree structure with file accounts and the scenarios, assigned to each account.
    /// </summary>
    /// <example>
    /// Account sales@cronus.com has scenarios "Sales Quote" and "Sales Credit Memo" assigned.
    /// Account purchase@cronus.com has scenarios "Purchase Quote" and "Purchase Invoice" assigned.
    /// The result of calling the function will be:
    /// sales@cronus.com, "Sales Quote", "Sales Credit Memo", purchase@cronus.com, "Purchase Quote", "Purchase Invoice"
    /// </example>
    /// <param name="TempFileAccountScenario">A flattened tree structure representing all the file accounts and the scenarios assigned to them.</param>
    procedure GetScenariosByFileAccount(var TempFileAccountScenario: Record "File Account Scenario" temporary)
    var
        TempDefaultFileAccount: Record "File Account" temporary;
        TempFileAccounts: Record "File Account" temporary;
        TempFileAccountScenarios: Record "File Account Scenario" temporary;
        FileAccount: Codeunit "File Account";
        Default: Boolean;
        Position: Integer;
        DisplayName: Text[2048];
    begin
        TempFileAccountScenario.Reset();
        TempFileAccountScenario.DeleteAll();

        FileAccount.GetAllAccounts(TempFileAccounts);

        if not TempFileAccounts.FindSet() then
            exit; // No accounts, nothing to do

        // The position is set in order to be able to properly sort the entries (by order of insertion)
        Position := 1;
        GetDefaultAccount(TempDefaultFileAccount);

        repeat
            Default := (TempFileAccounts."Account Id" = TempDefaultFileAccount."Account Id") and (TempFileAccounts.Connector = TempDefaultFileAccount.Connector);
            DisplayName := TempFileAccounts.Name;

            // Add entry for the file account. Scenario is -1, because it isn't needed when displaying the file account.
            AddEntry(TempFileAccountScenario, TempFileAccountScenario.EntryType::Account, -1, TempFileAccounts."Account Id", TempFileAccounts.Connector, DisplayName, Default, Position);

            // Get the file scenarios assigned to the current file account, sorted by "Display Name"
            GetFileScenariosForAccount(TempFileAccounts, TempFileAccountScenarios);

            if TempFileAccountScenarios.FindSet() then
                repeat
                    // Add entry for every scenario that is assigned to the current file account
                    AddEntry(TempFileAccountScenario, TempFileAccountScenarios.EntryType::Scenario, TempFileAccountScenarios.Scenario, TempFileAccountScenarios."Account Id", TempFileAccountScenarios.Connector, TempFileAccountScenarios."Display Name", false, Position);
                until TempFileAccountScenarios.Next() = 0;
        until TempFileAccounts.Next() = 0;

        // Order by position to show accurate results
        TempFileAccountScenario.SetCurrentKey(Position);
    end;

    local procedure GetFileScenariosForAccount(TempFileAccount: Record "File Account" temporary; var TempFileAccountScenarios: Record "File Account Scenario" temporary)
    var
        FileScenarios: Record "File Scenario";
        ValidFileScenarios: DotNet Hashtable;
        IsScenarioValid: Boolean;
        Scenario: Integer;
    begin
        TempFileAccountScenarios.Reset();
        TempFileAccountScenarios.DeleteAll();

        // Get all file scenarios assigned to the file account
        FileScenarios.SetRange("Account Id", TempFileAccount."Account Id");
        FileScenarios.SetRange(Connector, TempFileAccount.Connector);

        if not FileScenarios.FindSet() then
            exit;

        // Find all valid scenarios. Invalid scenario may occur if the extension that added them was removed.
        ValidFileScenarios := ValidFileScenarios.Hashtable();
        foreach Scenario in Enum::"File Scenario".Ordinals() do
            ValidFileScenarios.Add(Scenario, Scenario);

        // Convert File Scenario-s to File Account Scenario-s so they can be sorted by "Display Name"
        repeat
            IsScenarioValid := ValidFileScenarios.Contains(FileScenarios.Scenario.AsInteger());

            // Add entry for every scenario that exists and uses the file account. Skip the default scenario.
            if (FileScenarios.Scenario <> Enum::"File Scenario"::Default) and IsScenarioValid then begin
                TempFileAccountScenarios.Scenario := FileScenarios.Scenario.AsInteger();
                TempFileAccountScenarios."Account Id" := FileScenarios."Account Id";
                TempFileAccountScenarios.Connector := FileScenarios.Connector;
                TempFileAccountScenarios."Display Name" := Format(FileScenarios.Scenario);

                TempFileAccountScenarios.Insert();
            end;
        until FileScenarios.Next() = 0;

        TempFileAccountScenarios.SetCurrentKey("Display Name"); // sort scenarios by "Display Name"
    end;

    local procedure AddEntry(var TempFileAccountScenario: Record "File Account Scenario" temporary; EntryType: Enum "File Account Entry Type"; Scenario: Integer; AccountId: Guid; FileSystemConnector: Enum "Ext. File Storage Connector"; DisplayName: Text[2048]; Default: Boolean; var Position: Integer)
    begin
        // Add entry to the File Account Scenario while maintaining the position so that the tree represents the data correctly
        TempFileAccountScenario.Init();
        TempFileAccountScenario.EntryType := EntryType;
        TempFileAccountScenario.Scenario := Scenario;
        TempFileAccountScenario."Account Id" := AccountId;
        TempFileAccountScenario.Connector := FileSystemConnector;
        TempFileAccountScenario."Display Name" := DisplayName;
        TempFileAccountScenario.Default := Default;
        TempFileAccountScenario.Position := Position;
        TempFileAccountScenario.Insert();

        Position := Position + 1;
    end;

    procedure AddScenarios(TempFileAccountScenario: Record "File Account Scenario" temporary): Boolean
    var
        TempSelectedFileAccScenarios: Record "File Account Scenario" temporary;
        FileScenario: Record "File Scenario";
        FileScenariosForAccount: Page "File Scenarios for Account";
    begin
        FileAccountImpl.CheckPermissions();

        if TempFileAccountScenario.EntryType <> TempFileAccountScenario.EntryType::Account then // wrong entry, the entry should be of type "Account"
            exit;

        FileScenariosForAccount.Caption := StrSubstNo(ScenariosForAccountCaptionTxt, TempFileAccountScenario."Display Name");
        FileScenariosForAccount.LookupMode(true);
        FileScenariosForAccount.SetRecord(TempFileAccountScenario);

        if FileScenariosForAccount.RunModal() <> Action::LookupOK then
            exit;

        FileScenariosForAccount.GetSelectedScenarios(TempSelectedFileAccScenarios);

        if not TempSelectedFileAccScenarios.FindSet() then
            exit;

        repeat
            if not FileScenario.Get(TempSelectedFileAccScenarios.Scenario) then begin
                FileScenario."Account Id" := TempFileAccountScenario."Account Id";
                FileScenario.Connector := TempFileAccountScenario.Connector;
                FileScenario.Scenario := Enum::"File Scenario".FromInteger(TempSelectedFileAccScenarios.Scenario);

                FileScenario.Insert();
            end else begin
                FileScenario."Account Id" := TempFileAccountScenario."Account Id";
                FileScenario.Connector := TempFileAccountScenario.Connector;

                FileScenario.Modify();
            end;
        until TempSelectedFileAccScenarios.Next() = 0;

        exit(true);
    end;

    procedure GetAvailableScenariosForAccount(TempFileAccountScenario: Record "File Account Scenario" temporary; var TempFileAccountScenarios: Record "File Account Scenario" temporary)
    var
        Scenario: Record "File Scenario";
        FileScenario: Codeunit "File Scenario";
        CurrentScenario, i : Integer;
        IsAvailable: Boolean;
    begin
        TempFileAccountScenarios.Reset();
        TempFileAccountScenarios.DeleteAll();
        i := 1;

        foreach CurrentScenario in Enum::"File Scenario".Ordinals() do begin
            Clear(Scenario);
            Scenario.SetRange("Account Id", TempFileAccountScenarios."Account Id");
            Scenario.SetRange(Connector, TempFileAccountScenarios.Connector);
            Scenario.SetRange(Scenario, CurrentScenario);

            // If the scenario isn't already connected to the file account, then it's available. Natually, we skip the default scenario
            IsAvailable := Scenario.IsEmpty() and (not (CurrentScenario = Enum::"File Scenario"::Default.AsInteger()));

            // If the scenario is available, allow partner to determine if it should be shown
            if IsAvailable then
                FileScenario.OnBeforeInsertAvailableFileScenario(Enum::"File Scenario".FromInteger(CurrentScenario), IsAvailable);

            if IsAvailable then begin
                TempFileAccountScenarios."Account Id" := TempFileAccountScenarios."Account Id";
                TempFileAccountScenarios.Connector := TempFileAccountScenarios.Connector;
                TempFileAccountScenarios.Scenario := CurrentScenario;
                TempFileAccountScenarios."Display Name" := Format(Enum::"File Scenario".FromInteger(Enum::"File Scenario".Ordinals().Get(i)));

                TempFileAccountScenarios.Insert();
            end;

            i += 1;
        end;
    end;

    procedure ChangeAccount(var TempFileAccountScenario: Record "File Account Scenario" temporary): Boolean
    var
        TempSelectedFileAccount: Record "File Account" temporary;
        FileScenario: Record "File Scenario";
        FileAccount: Codeunit "File Account";
        AccountsPage: Page "File Accounts";
    begin
        FileAccountImpl.CheckPermissions();

        if not TempFileAccountScenario.FindSet() then
            exit;

        FileAccount.GetAllAccounts(false, TempSelectedFileAccount);
        if TempSelectedFileAccount.Get(TempFileAccountScenario."Account Id", TempFileAccountScenario.Connector) then;

        AccountsPage.EnableLookupMode();
        AccountsPage.SetRecord(TempSelectedFileAccount);
        AccountsPage.Caption := ChangeFileAccountForScenarioTxt;

        if AccountsPage.RunModal() <> Action::LookupOK then
            exit;

        AccountsPage.GetAccount(TempSelectedFileAccount);

        if IsNullGuid(TempSelectedFileAccount."Account Id") then // defensive check, no account was selected
            exit;

        repeat
            if FileScenario.Get(TempFileAccountScenario.Scenario) then begin
                FileScenario."Account Id" := TempSelectedFileAccount."Account Id";
                FileScenario.Connector := TempSelectedFileAccount.Connector;

                FileScenario.Modify();
            end;
        until TempFileAccountScenario.Next() = 0;

        exit(true);
    end;

    procedure DeleteScenario(var TempFileAccountScenario: Record "File Account Scenario" temporary): Boolean
    var
        FileScenario: Record "File Scenario";
    begin
        FileAccountImpl.CheckPermissions();

        if not TempFileAccountScenario.FindSet() then
            exit;

        repeat
            if TempFileAccountScenario.EntryType = TempFileAccountScenario.EntryType::Scenario then begin
                FileScenario.SetRange(Scenario, TempFileAccountScenario.Scenario);
                FileScenario.SetRange("Account Id", TempFileAccountScenario."Account Id");
                FileScenario.SetRange(Connector, TempFileAccountScenario.Connector);

                FileScenario.DeleteAll();
            end;
        until TempFileAccountScenario.Next() = 0;

        exit(true);
    end;

    local procedure GetDefaultAccount(var TempFileAccount: Record "File Account" temporary)
    var
        FileScenario: Record "File Scenario";
    begin
        if not FileScenario.Get(Enum::"File Scenario"::Default) then
            exit;

        TempFileAccount."Account Id" := FileScenario."Account Id";
        TempFileAccount.Connector := FileScenario.Connector;
    end;

    var
        FileAccountImpl: Codeunit "File Account Impl.";
        ChangeFileAccountForScenarioTxt: Label 'Change file account used for the selected scenarios';
        ScenariosForAccountCaptionTxt: Label 'Assign scenarios to account %1', Comment = '%1 = the name of the e-file account';
}