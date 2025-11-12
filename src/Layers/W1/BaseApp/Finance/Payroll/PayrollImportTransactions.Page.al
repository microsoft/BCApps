// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Utilities;
using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

page 1661 "Payroll Import Transactions"
{
    Caption = 'Import Payroll Transactions';
    InsertAllowed = false;
    PageType = NavigatePage;
    SourceTable = "Import G/L Transaction";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to Import Payroll Transactions")
                {
                    Caption = 'Welcome to Import Payroll Transactions';
                    Visible = FirstStepVisible;
                    group(Control18)
                    {
                        InstructionalText = 'To import payroll transactions, you first select the file from the payroll provider and then you map external accounts in the file to the relevant G/L accounts.';
                        ShowCaption = false;
                    }
                }
                group("Let's go!")
                {
                    Caption = 'Let''s go!';
                    Visible = FirstStepVisible;
                    group(Control22)
                    {
                        InstructionalText = 'Choose Next to start importing payroll transactions.';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                    }
                }
            }
            group(Control2)
            {
                InstructionalText = 'Map the external accounts to the relevant G/L accounts.';
                ShowCaption = false;
                Visible = ProviderStepVisible;
                repeater(Control7)
                {
                    ShowCaption = false;
                    field("Entry No."; Rec."Entry No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("External Account"; Rec."External Account")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field("G/L Account"; Rec."G/L Account")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        var
                            TempImportGLTransaction: Record "Import G/L Transaction" temporary;
                            ImportGLTransaction: Record "Import G/L Transaction";
                        begin
                            if Rec."G/L Account" <> '' then begin
                                ImportGLTransaction.SetRange("App ID", Rec."App ID");
                                ImportGLTransaction.SetRange("External Account", Rec."External Account");
                                ImportGLTransaction.SetRange("G/L Account", Rec."G/L Account");
                                if ImportGLTransaction.IsEmpty() then begin
                                    ImportGLTransaction."App ID" := Rec."App ID";
                                    ImportGLTransaction."G/L Account" := Rec."G/L Account";
                                    ImportGLTransaction."External Account" := Rec."External Account";
                                    ImportGLTransaction.Insert();
                                end
                            end else
                                if xRec."G/L Account" <> '' then begin
                                    ImportGLTransaction.SetRange("App ID", Rec."App ID");
                                    ImportGLTransaction.SetRange("External Account", Rec."External Account");
                                    ImportGLTransaction.SetRange("G/L Account", xRec."G/L Account");
                                    ImportGLTransaction.DeleteAll();
                                end;
                            TempImportGLTransaction := Rec;
                            Rec.SetRange("External Account", Rec."External Account");
                            Rec.ModifyAll("G/L Account", Rec."G/L Account");
                            Rec.SetRange("External Account");
                            Rec := TempImportGLTransaction;
                            Rec.Find();
                        end;
                    }
                    field("G/L Account Name"; Rec."G/L Account Name")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Transaction Date"; Rec."Transaction Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field(Amount; Rec.Amount)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field(Description; Rec.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                    }
                    field("Map to"; LinktoLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Map to';
                        Editable = false;
                        Visible = false;
                    }
                }
            }
            group(Control12)
            {
                ShowCaption = false;
                Visible = SettingsStepVisible;
            }
            group(Control17)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control25)
                    {
                        InstructionalText = 'To finalize the import of payroll transactions, choose Finish.';
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                    if Step = 0 then
                        Rec.DeleteAll();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    case Step of
                        0:
                            begin
                                OnImportPayrollTransactions(TempServiceConnection, TempImportGLTransaction);
                                if TempImportGLTransaction.FindSet() then
                                    repeat
                                        Rec := TempImportGLTransaction;
                                        Rec.Insert();
                                    until TempImportGLTransaction.Next() = 0;
                                if Rec.FindFirst() then begin
                                    Rec.SetCurrentKey("Entry No.");
                                    NextStep(false);
                                end;
                            end;
                        else
                            NextStep(false);
                    end;
                end;
            }
            action(ActionCreateSampleFile)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get Sample File';
                Image = Import;
                InFooterBar = true;
                Visible = ShowGetSampleFile;

                trigger OnAction()
                begin
                    OnCreateSampleFile(TempServiceConnection);
                end;
            }
            action(ActionResetLinkto)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Remove Mapping';
                Image = Reuse;
                InFooterBar = true;
                Visible = ShowResetLinks;

                trigger OnAction()
                begin
                    ResetLinks();
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        IsDemoCompany := CompanyInformation."Demo Company";
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        Step := Step::Start;
        EnableControls();
        Rec.SetCurrentKey("Entry No.");
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if CloseAction = ACTION::OK then
            if GuidedExperience.AssistedSetupExistsAndIsNotComplete(ObjectType::Page, Page::"Payroll Import Transactions") then
                if not Confirm(NAVNotSetUpQst, false) then
                    Error('');
    end;

    var
        TempServiceConnection: Record "Service Connection" temporary;
        GenJournalLine: Record "Gen. Journal Line";
        TempImportGLTransaction: Record "Import G/L Transaction" temporary;
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,LinkAccounts,Finish;
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        ProviderStepVisible: Boolean;
        SettingsStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        NAVNotSetUpQst: Label 'No payroll transactions have been imported.\\Are you sure you want to exit?';
        LinktoLbl: Label 'Map to';
        PayrollImportedMsg: Label 'The payroll transactions are imported.';
        ShowGetSampleFile: Boolean;
        ShowResetLinks: Boolean;
        ResetLinksQst: Label 'Do you want to reset all existing mapping suggestions?';
        IsDemoCompany: Boolean;

    local procedure EnableControls()
    begin
        ResetControls();

        case Step of
            Step::Start:
                ShowStartStep();
            Step::LinkAccounts:
                ShowProviderStep();
            Step::Finish:
                ShowFinishStep();
        end;
    end;

    local procedure FinishAction()
    var
        NewGenJournalLine: Record "Gen. Journal Line";
        GuidedExperience: Codeunit "Guided Experience";
        NextLinieNo: Integer;
    begin
        NextLinieNo := 0;
        NewGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        NewGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        if NewGenJournalLine.FindLast() then
            NextLinieNo := NewGenJournalLine."Line No.";

        if Rec.FindSet() then begin
            repeat
                NewGenJournalLine.Init();
                NewGenJournalLine."Journal Template Name" := GenJournalLine."Journal Template Name";
                NewGenJournalLine."Journal Batch Name" := GenJournalLine."Journal Batch Name";
                NextLinieNo += 10000;
                NewGenJournalLine."Line No." := NextLinieNo;
                NewGenJournalLine.Insert();
                NewGenJournalLine.SetUpNewLine(GenJournalLine, 0, false);
                NewGenJournalLine.Validate("Account Type", NewGenJournalLine."Account Type"::"G/L Account");
                NewGenJournalLine.Validate("Account No.", Rec."G/L Account");
                NewGenJournalLine.Validate("Posting Date", Rec."Transaction Date");
                NewGenJournalLine.Validate(Amount, Rec.Amount);
                NewGenJournalLine.Validate(Description, Rec.Description);
                NewGenJournalLine.Modify();
            until Rec.Next() = 0;

            GenJournalLine := NewGenJournalLine;
            GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Payroll Import Transactions");

            Message(PayrollImportedMsg);
        end;

        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then
            Step := Step - 1
        else
            Step := Step + 1;

        EnableControls();
    end;

    local procedure ShowStartStep()
    begin
        FirstStepVisible := true;
        FinishActionEnabled := true;
        BackActionEnabled := false;
        ShowGetSampleFile := IsDemoCompany and FirstStepVisible;
    end;

    local procedure ShowProviderStep()
    begin
        ProviderStepVisible := true;
        ShowResetLinks := true;
    end;

    local procedure ShowFinishStep()
    begin
        FinalStepVisible := true;
        NextActionEnabled := false;
    end;

    local procedure ResetControls()
    begin
        BackActionEnabled := true;
        NextActionEnabled := true;

        FirstStepVisible := false;
        ProviderStepVisible := false;
        SettingsStepVisible := false;
        FinalStepVisible := false;
        ShowGetSampleFile := false;
        ShowResetLinks := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    /// <summary>
    /// Integration event raised to import payroll transactions from external sources.
    /// Enables custom payroll import functionality for different service providers.
    /// </summary>
    /// <param name="TempServiceConnection">Service connection record for external payroll service</param>
    /// <param name="TempImportGLTransaction">Temporary table to store imported G/L transactions</param>
    /// <remarks>
    /// Raised from ImportPayrollTransactions procedure to allow external payroll service integration.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnImportPayrollTransactions(var TempServiceConnection: Record "Service Connection" temporary; var TempImportGLTransaction: Record "Import G/L Transaction" temporary)
    begin
    end;

    /// <summary>
    /// Integration event raised to create sample payroll import files.
    /// Enables generation of sample files for payroll import format demonstration.
    /// </summary>
    /// <param name="TempServiceConnection">Service connection record for external payroll service</param>
    /// <remarks>
    /// Raised from CreateSampleFile procedure to generate sample payroll import files.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnCreateSampleFile(TempServiceConnection: Record "Service Connection" temporary)
    begin
    end;

    procedure Set(var SetServiceConnection: Record "Service Connection"; SetGenJournalLine: Record "Gen. Journal Line")
    begin
        TempServiceConnection := SetServiceConnection;
        GenJournalLine := SetGenJournalLine;
    end;

    local procedure ResetLinks()
    var
        ImportGLTransaction: Record "Import G/L Transaction";
        TempImportGLTransaction: Record "Import G/L Transaction" temporary;
    begin
        ImportGLTransaction.SetRange("App ID", Rec."App ID");
        if ImportGLTransaction.FindFirst() then
            if Confirm(ResetLinksQst) then begin
                ImportGLTransaction.DeleteAll();
                TempImportGLTransaction := Rec;
                if Rec.FindSet() then
                    repeat
                        Rec."G/L Account" := '';
                        Rec.Modify();
                    until Rec.Next() = 0;
                Rec := TempImportGLTransaction;
                CurrPage.Update();
            end;
    end;
}

