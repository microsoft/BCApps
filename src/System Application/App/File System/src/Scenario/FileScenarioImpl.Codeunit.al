// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

using System;

codeunit 9453 "File Scenario Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "File Scenario" = rimd;

    procedure GetFileAccount(Scenario: Enum "File Scenario"; var FileAccount: Record "File Account"): Boolean
    var
        AllFileAccounts: Record "File Account";
        FileScenario: Record "File Scenario";
        FileAccounts: Codeunit "File Account";
    begin
        FileAccounts.GetAllAccounts(AllFileAccounts);

        // Find the account for the provided scenario
        if FileScenario.Get(Scenario) then
            if AllFileAccounts.Get(FileScenario."Account Id", FileScenario.Connector) then begin
                FileAccount := AllFileAccounts;
                exit(true);
            end;

        // Fallback to the default account if the scenario isn't mapped or the mapped account doesn't exist
        if FileScenario.Get(Enum::"File Scenario"::Default) then
            if AllFileAccounts.Get(FileScenario."Account Id", FileScenario.Connector) then begin
                FileAccount := AllFileAccounts;
                exit(true);
            end;
    end;

    procedure SetFileAccount(Scenario: Enum "File Scenario"; FileAccount: Record "File Account")
    var
        FileScenario: Record "File Scenario";
    begin
        if not FileScenario.Get(Scenario) then begin
            FileScenario.Scenario := Scenario;
            FileScenario.Insert();
        end;

        FileScenario."Account Id" := FileAccount."Account Id";
        FileScenario.Connector := FileAccount.Connector;

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
    /// <param name="FileAccountScenario">A flattened tree structure representing all the file accounts and the scenarios assigned to them.</param>
    procedure GetScenariosByFileAccount(var FileAccountScenario: Record "File Account Scenario")
    var
        DefaultFileAccount: Record "File Account";
        FileAccounts: Record "File Account";
        FileAccountScenarios: Record "File Account Scenario";
        FileAccount: Codeunit "File Account";
        Default: Boolean;
        Position: Integer;
        DisplayName: Text[2048];
    begin
        FileAccountScenario.Reset();
        FileAccountScenario.DeleteAll();

        FileAccount.GetAllAccounts(FileAccounts);

        if not FileAccounts.FindSet() then
            exit; // No accounts, nothing to do

        // The position is set in order to be able to properly sort the entries (by order of insertion)
        Position := 1;
        GetDefaultAccount(DefaultFileAccount);

        repeat
            Default := (FileAccounts."Account Id" = DefaultFileAccount."Account Id") and (FileAccounts.Connector = DefaultFileAccount.Connector);
            DisplayName := FileAccounts.Name;

            // Add entry for the file account. Scenario is -1, because it isn't needed when displaying the file account.
            AddEntry(FileAccountScenario, FileAccountScenario.EntryType::Account, -1, FileAccounts."Account Id", FileAccounts.Connector, DisplayName, Default, Position);

            // Get the file scenarios assigned to the current file account, sorted by "Display Name"
            GetFileScenariosForAccount(FileAccounts, FileAccountScenarios);

            if FileAccountScenarios.FindSet() then
                repeat
                    // Add entry for every scenario that is assigned to the current file account
                    AddEntry(FileAccountScenario, FileAccountScenarios.EntryType::Scenario, FileAccountScenarios.Scenario, FileAccountScenarios."Account Id", FileAccountScenarios.Connector, FileAccountScenarios."Display Name", false, Position);
                until FileAccountScenarios.Next() = 0;
        until FileAccounts.Next() = 0;

        // Order by position to show accurate results
        FileAccountScenario.SetCurrentKey(Position);
    end;

    local procedure GetFileScenariosForAccount(FileAccount: Record "File Account"; var FileAccountScenarios: Record "File Account Scenario")
    var
        FileScenarios: Record "File Scenario";
        ValidFileScenarios: DotNet Hashtable;
        IsScenarioValid: Boolean;
        Scenario: Integer;
    begin
        FileAccountScenarios.Reset();
        FileAccountScenarios.DeleteAll();

        // Get all file scenarios assigned to the file account
        FileScenarios.SetRange("Account Id", FileAccount."Account Id");
        FileScenarios.SetRange(Connector, FileAccount.Connector);

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
                FileAccountScenarios.Scenario := FileScenarios.Scenario.AsInteger();
                FileAccountScenarios."Account Id" := FileScenarios."Account Id";
                FileAccountScenarios.Connector := FileScenarios.Connector;
                FileAccountScenarios."Display Name" := Format(FileScenarios.Scenario);

                FileAccountScenarios.Insert();
            end;
        until FileScenarios.Next() = 0;

        FileAccountScenarios.SetCurrentKey("Display Name"); // sort scenarios by "Display Name"
    end;

    local procedure AddEntry(var FileAccountScenario: Record "File Account Scenario"; EntryType: Enum "File Acount Entry Type"; Scenario: Integer; AccountId: Guid; FileSystemConnector: Enum "File System Connector"; DisplayName: Text[2048]; Default: Boolean; var Position: Integer)
    begin
        // Add entry to the File Account Scenario while maintaining the position so that the tree represents the data correctly
        FileAccountScenario.Init();
        FileAccountScenario.EntryType := EntryType;
        FileAccountScenario.Scenario := Scenario;
        FileAccountScenario."Account Id" := AccountId;
        FileAccountScenario.Connector := FileSystemConnector;
        FileAccountScenario."Display Name" := DisplayName;
        FileAccountScenario.Default := Default;
        FileAccountScenario.Position := Position;
        FileAccountScenario.Insert();

        Position := Position + 1;
    end;

    procedure AddScenarios(FileAccountScenario: Record "File Account Scenario"): Boolean
    var
        SelectedFileAccScenarios: Record "File Account Scenario";
        FileScenario: Record "File Scenario";
        FileScenariosForAccount: Page "File Scenarios for Account";
    begin
        FileAccountImpl.CheckPermissions();

        if FileAccountScenario.EntryType <> FileAccountScenario.EntryType::Account then // wrong entry, the entry should be of type "Account"
            exit;

        FileScenariosForAccount.Caption := StrSubstNo(ScenariosForAccountCaptionTxt, FileAccountScenario."Display Name");
        FileScenariosForAccount.LookupMode(true);
        FileScenariosForAccount.SetRecord(FileAccountScenario);

        if FileScenariosForAccount.RunModal() <> Action::LookupOK then
            exit;

        FileScenariosForAccount.GetSelectedScenarios(SelectedFileAccScenarios);

        if not SelectedFileAccScenarios.FindSet() then
            exit;

        repeat
            if not FileScenario.Get(SelectedFileAccScenarios.Scenario) then begin
                FileScenario."Account Id" := FileAccountScenario."Account Id";
                FileScenario.Connector := FileAccountScenario.Connector;
                FileScenario.Scenario := Enum::"File Scenario".FromInteger(SelectedFileAccScenarios.Scenario);

                FileScenario.Insert();
            end else begin
                FileScenario."Account Id" := FileAccountScenario."Account Id";
                FileScenario.Connector := FileAccountScenario.Connector;

                FileScenario.Modify();
            end;
        until SelectedFileAccScenarios.Next() = 0;

        exit(true);
    end;

    procedure GetAvailableScenariosForAccount(FileAccountScenario: Record "File Account Scenario"; var FileAccountScenarios: Record "File Account Scenario")
    var
        Scenario: Record "File Scenario";
        FileScenario: Codeunit "File Scenario";
        CurrentScenario, i : Integer;
        IsAvailable: Boolean;
    begin
        FileAccountScenarios.Reset();
        FileAccountScenarios.DeleteAll();
        i := 1;

        foreach CurrentScenario in Enum::"File Scenario".Ordinals() do begin
            Clear(Scenario);
            Scenario.SetRange("Account Id", FileAccountScenarios."Account Id");
            Scenario.SetRange(Connector, FileAccountScenarios.Connector);
            Scenario.SetRange(Scenario, CurrentScenario);

            // If the scenario isn't already connected to the file account, then it's available. Natually, we skip the default scenario
            IsAvailable := Scenario.IsEmpty() and (not (CurrentScenario = Enum::"File Scenario"::Default.AsInteger()));

            // If the scenario is available, allow partner to determine if it should be shown
            if IsAvailable then
                FileScenario.OnBeforeInsertAvailableFileScenario(Enum::"File Scenario".FromInteger(CurrentScenario), IsAvailable);

            if IsAvailable then begin
                FileAccountScenarios."Account Id" := FileAccountScenarios."Account Id";
                FileAccountScenarios.Connector := FileAccountScenarios.Connector;
                FileAccountScenarios.Scenario := CurrentScenario;
                FileAccountScenarios."Display Name" := Format(Enum::"File Scenario".FromInteger(Enum::"File Scenario".Ordinals().Get(i)));

                FileAccountScenarios.Insert();
            end;

            i += 1;
        end;
    end;

    procedure ChangeAccount(var FileAccountScenario: Record "File Account Scenario"): Boolean
    var
        SelectedFileAccount: Record "File Account";
        FileScenario: Record "File Scenario";
        FileAccount: Codeunit "File Account";
        AccountsPage: Page "File Accounts";
    begin
        FileAccountImpl.CheckPermissions();

        if not FileAccountScenario.FindSet() then
            exit;

        FileAccount.GetAllAccounts(false, SelectedFileAccount);
        if SelectedFileAccount.Get(FileAccountScenario."Account Id", FileAccountScenario.Connector) then;

        AccountsPage.EnableLookupMode();
        AccountsPage.SetRecord(SelectedFileAccount);
        AccountsPage.Caption := ChangeFileAccountForScenarioTxt;

        if AccountsPage.RunModal() <> Action::LookupOK then
            exit;

        AccountsPage.GetAccount(SelectedFileAccount);

        if IsNullGuid(SelectedFileAccount."Account Id") then // defensive check, no account was selected
            exit;

        repeat
            if FileScenario.Get(FileAccountScenario.Scenario) then begin
                FileScenario."Account Id" := SelectedFileAccount."Account Id";
                FileScenario.Connector := SelectedFileAccount.Connector;

                FileScenario.Modify();
            end;
        until FileAccountScenario.Next() = 0;

        exit(true);
    end;

    procedure DeleteScenario(var FileAccountScenario: Record "File Account Scenario"): Boolean
    var
        FileScenario: Record "File Scenario";
    begin
        FileAccountImpl.CheckPermissions();

        if not FileAccountScenario.FindSet() then
            exit;

        repeat
            if FileAccountScenario.EntryType = FileAccountScenario.EntryType::Scenario then begin
                FileScenario.SetRange(Scenario, FileAccountScenario.Scenario);
                FileScenario.SetRange("Account Id", FileAccountScenario."Account Id");
                FileScenario.SetRange(Connector, FileAccountScenario.Connector);

                FileScenario.DeleteAll();
            end;
        until FileAccountScenario.Next() = 0;

        exit(true);
    end;

    local procedure GetDefaultAccount(var FileAccount: Record "File Account")
    var
        FileScenario: Record "File Scenario";
    begin
        if not FileScenario.Get(Enum::"File Scenario"::Default) then
            exit;

        FileAccount."Account Id" := FileScenario."Account Id";
        FileAccount.Connector := FileScenario.Connector;
    end;

    var
        FileAccountImpl: Codeunit "File Account Impl.";
        ChangeFileAccountForScenarioTxt: Label 'Change file account used for the selected scenarios';
        ScenariosForAccountCaptionTxt: Label 'Assign scenarios to account %1', Comment = '%1 = the name of the e-file account';
}