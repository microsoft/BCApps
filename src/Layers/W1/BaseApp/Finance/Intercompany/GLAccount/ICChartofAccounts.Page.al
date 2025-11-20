// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.GLAccount;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Intercompany.Setup;
using System.IO;
using System.Telemetry;

page 605 "IC Chart of Accounts"
{
    ApplicationArea = Intercompany;
    Caption = 'Intercompany Chart of Accounts';
    CardPageID = "IC G/L Account Card";
    PageType = List;
    SourceTable = "IC G/L Account";
    UsageCategory = Administration;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Intercompany;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the name of the IC general ledger account.';
                }
                field("Income/Balance"; Rec."Income/Balance")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(OpenChartOfAccountsMapping)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Chart of Accounts Mapping';
                    Image = Intercompany;
                    RunObject = Page "IC Mapping Chart of Account";
                    ToolTip = 'Open the mapping between the intercompany chart of accounts and the chart of accounts of the current company.';
                }
                action("Copy from Chart of Accounts")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Copy from Chart of Accounts';
                    Image = CopyFromChartOfAccounts;
                    ToolTip = 'Create intercompany accounts from G/L accounts.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        CopyFromChartOfAccounts();
                        FeatureTelemetry.LogUptake('0000IL7', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                action("In&dent IC Chart of Accounts")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'In&dent IC Chart of Accounts';
                    Image = Indent;
                    ToolTip = 'Indent accounts between a Begin-Total and the matching End-Total one level to make the chart of accounts easier to read.';

                    trigger OnAction()
                    var
                        IndentCOA: Codeunit "G/L Account-Indent";
                    begin
                        IndentCOA.RunICAccountIndent();
                    end;
                }
                separator(Action21)
                {
                }
                action(Import)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Import';
                    Ellipsis = true;
                    Image = Import;
                    ToolTip = 'Import an intercompany chart of accounts from a file.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        ImportFromXML();
                        FeatureTelemetry.LogUptake('0000IL8', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                action("E&xport")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'E&xport';
                    Ellipsis = true;
                    Image = Export;
                    ToolTip = 'Export the intercompany chart of accounts to a file.';

                    trigger OnAction()
                    var
                        FeatureTelemetry: Codeunit "Feature Telemetry";
                        ICMapping: Codeunit "IC Mapping";
                    begin
                        ExportToXML();
                        FeatureTelemetry.LogUptake('0000IL9', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
                    end;
                }
                action(SynchronizationSetup)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Synchronization Setup';
                    Image = Setup;
                    ShortcutKey = 'S';
                    ToolTip = 'Open the setup for the synchronization of the chart of accounts of intercompany.';
                    Enabled = EnableSynchronization;

                    trigger OnAction()
                    var
                        ICSetup: Record "IC Setup";
                        ICMapping: Codeunit "IC Mapping";
                        ICChartOfAccountsSetup: Page "IC Chart of Accounts Setup";
                        ICPartnerCode: Code[20];
                    begin
                        ICSetup.Get();
                        if ICSetup."IC Inbox Type" <> ICSetup."IC Inbox Type"::Database then begin
                            Message(OnlyAvailableForICUsingDatabaseLbl);
                            exit;
                        end;
                        ICPartnerCode := ICSetup."Partner Code for Acc. Syn.";
                        if (ICPartnerCode <> '') then
                            if Confirm(StrSubstNo(SynchronizeIntercompanyQst, ICPartnerCode), true) then begin
                                ICMapping.SynchronizeAccounts(false, ICPartnerCode);
                                exit;
                            end;
                        ICChartOfAccountsSetup.Run();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(OpenChartOfAccountsMapping_Promoted; OpenChartOfAccountsMapping)
                {
                }
                actionref("Copy from Chart of Accounts_Promoted"; "Copy from Chart of Accounts")
                {
                }
                actionref("In&dent IC Chart of Accounts_Promoted"; "In&dent IC Chart of Accounts")
                {
                }
                actionref(SynchronizationSetup_Promoted; SynchronizationSetup)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Import/Export', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Import_Promoted; Import)
                {
                }
                actionref("E&xport_Promoted"; "E&xport")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ICSetup: Record "IC Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000ILA', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        if ICSetup.FindFirst() then
            EnableSynchronization := (ICSetup."IC Inbox Type" = ICSetup."IC Inbox Type"::Database);
    end;

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        FormatLine();
    end;

    var
        Emphasize: Boolean;
        NameIndent: Integer;
        EnableSynchronization: Boolean;
        SelectFileToImportLbl: Label 'Select file to import into the chart of accounts of intercompany';
        DefaultNameForExportFileLbl: Label 'ICChartOfAccounts.xml';
        CopyFromChartOfAccountsQst: Label 'Are you sure you want to copy from chart of accounts?';
        RequestUserForFileNameLbl: Label 'Enter the file name.';
        SupportedFileTypesLbl: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        CleanICAccountsBeforeCopyingChartOfAccountsQst: Label 'This will clear the existing IC Chart of Accounts before copying. Do you want to continue?';
        SplitMessageTxt: Label '%1\%2', Comment = '%1 = First part of the message, %2 = Second part of the message.', Locked = true;
        SynchronizeIntercompanyQst: Label 'Partner %1 has been set for the synchronization of intercompany. Do you want to synchronize instead of switching to another partner?', Comment = '%1 = IC Partner code';
        OnlyAvailableForICUsingDatabaseLbl: Label 'Synchronization is only available for companies using a database for intercompany transactions. Select this option in the setup if you want to use this action.';

    local procedure CopyFromChartOfAccounts()
    var
        GLAccount: Record "G/L Account";
        ICAccount: Record "IC G/L Account";
        PrevIndentation: Integer;
    begin
        if GuiAllowed() then
            if not UserConfirmsToProceedWithChanges() then
                exit;

        ICAccount.LockTable();
        if GLAccount.Find('-') then
            repeat
                if GLAccount."Account Type" = GLAccount."Account Type"::"End-Total" then
                    PrevIndentation := PrevIndentation - 1;
                if not GLAccount.Blocked then begin
                    ICAccount.Init();
                    ICAccount."No." := GLAccount."No.";
                    ICAccount.Name := GLAccount.Name;
                    ICAccount."Account Type" := GLAccount."Account Type";
                    ICAccount."Income/Balance" := GLAccount."Income/Balance";
                    ICAccount.Validate(Indentation, PrevIndentation);
                    OnCopyFromChartOfAccountsOnBeforeICGLAccInsert(ICAccount, GLAccount);
                    ICAccount.Insert();
                end;
                PrevIndentation := GLAccount.Indentation;
                if GLAccount."Account Type" = GLAccount."Account Type"::"Begin-Total" then
                    PrevIndentation := PrevIndentation + 1;
            until GLAccount.Next() = 0;
    end;

    local procedure UserConfirmsToProceedWithChanges(): Boolean
    var
        ICAccount: Record "IC G/L Account";
        MessageText: Text;
        ICAccountIsEmpty: Boolean;
        UserResponse: Boolean;
    begin
        MessageText := CopyFromChartOfAccountsQst;

        ICAccountIsEmpty := ICAccount.IsEmpty();
        if not ICAccountIsEmpty then
            MessageText := StrSubstNo(SplitMessageTxt, MessageText, CleanICAccountsBeforeCopyingChartOfAccountsQst);

        UserResponse := Confirm(MessageText, false);
        if not ICAccountIsEmpty and UserResponse then
            ICAccount.DeleteAll();

        exit(UserResponse);
    end;

    local procedure ImportFromXML()
    var
        ICSetup: Record "IC Setup";
        ICGLAccIO: XMLport "IC G/L Account Import/Export";
        IFile: File;
        IStr: InStream;
        FileName: Text[1024];
        StartFileName: Text[1024];
    begin
        ICSetup.Get();

        StartFileName := ICSetup."IC Inbox Details";
        if StartFileName <> '' then begin
            if StartFileName[StrLen(StartFileName)] <> '\' then
                StartFileName := StartFileName + '\';
            StartFileName := StartFileName + '*.xml';
        end;

        if not Upload(SelectFileToImportLbl, '', SupportedFileTypesLbl, StartFileName, FileName) then
            Error(RequestUserForFileNameLbl);

        IFile.Open(FileName);
        IFile.CreateInStream(IStr);
        ICGLAccIO.SetSource(IStr);
        ICGLAccIO.Import();
    end;

    local procedure ExportToXML()
    var
        ICSetup: Record "IC Setup";
        FileMgt: Codeunit "File Management";
        ICGLAccIO: XMLport "IC G/L Account Import/Export";
        OFile: File;
        OStr: OutStream;
        FileName: Text;
        DefaultFileName: Text;
    begin
        ICSetup.Get();

        DefaultFileName := ICSetup."IC Inbox Details";
        if DefaultFileName <> '' then
            if DefaultFileName[StrLen(DefaultFileName)] <> '\' then
                DefaultFileName := DefaultFileName + '\';
        DefaultFileName := DefaultFileName + DefaultNameForExportFileLbl;

        FileName := FileMgt.ServerTempFileName('xml');
        if FileName = '' then
            exit;

        OFile.Create(FileName);
        OFile.CreateOutStream(OStr);
        ICGLAccIO.SetDestination(OStr);
        ICGLAccIO.Export();
        OFile.Close();
        Clear(OStr);

        Download(FileName, 'Export', TemporaryPath, '', DefaultFileName);
    end;

    local procedure FormatLine()
    begin
        NameIndent := Rec.Indentation;
        Emphasize := Rec."Account Type" <> Rec."Account Type"::Posting;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromChartOfAccountsOnBeforeICGLAccInsert(var ICGLAccount: Record "IC G/L Account"; GLAccount: Record "G/L Account")
    begin
    end;
}
