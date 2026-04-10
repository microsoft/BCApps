// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;
using System.Utilities;

/// <summary>
/// Report for saving general journal lines as standard journal templates for reuse in future journal entry scenarios.
/// Enables users to capture frequently used journal line configurations as reusable standard journal templates.
/// </summary>
/// <remarks>
/// Journal template creation functionality for recurring journal entry patterns. Saves journal line configurations
/// including account assignments, dimensions, amounts, and posting settings as reusable standard journal templates.
/// Key features: Journal line template creation, dimension preservation, standard journal code assignment, template description.
/// Integration: Creates entries in standard journal tables, supports dimension copying, enables template reuse workflows.
/// Usage: Ideal for recurring journal entries, month-end accruals, and standardized posting patterns.
/// </remarks>
report 750 "Save as Standard Gen. Journal"
{
    Caption = 'Save as Standard Gen. Journal';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Code"; Code)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Code';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the code for the journal.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            StdGenJnl: Record "Standard General Journal";
                            StdGenJnls: Page "Standard General Journals";
                        begin
                            StdGenJnl.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                            StdGenJnls.SetTableView(StdGenJnl);

                            StdGenJnls.LookupMode := true;
                            StdGenJnls.Editable := false;
                            if StdGenJnls.RunModal() = ACTION::LookupOK then begin
                                StdGenJnls.GetRecord(StdGenJnl);
                                Code := StdGenJnl.Code;
                                Description := StdGenJnl.Description;
                            end;
                        end;
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the journal.';
                    }
                    field(SaveAmount; SaveAmount)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Save Amount';
                        ToolTip = 'Specifies if you want to save the values in the Amount field of the standard journal.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if Code = '' then
            Error(Text000);

        StdJournalCreated := false;
        SaveGenJnlAsStandardJnl();
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        StdGenJnl: Record "Standard General Journal";
        "Code": Code[10];
        Description: Text[100];
#pragma warning disable AA0074
        Text000: Label 'Enter a code for Standard General Journal.';
#pragma warning disable AA0470
        Text001: Label 'Standard General Journal %1 already exists. Do you want to overwrite?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        SaveAmount: Boolean;
        StdJournalCreated: Boolean;
        NextLineNo: Integer;

    /// <summary>
    /// Initializes the report with selected journal lines and batch information for standard journal creation.
    /// Sets up the source data and batch context for processing journal lines into standard journal template.
    /// </summary>
    /// <param name="SelectedGenJnlLines">General journal lines selected for conversion to standard journal.</param>
    /// <param name="SelectedGenJnlBatch">General journal batch containing the selected lines.</param>
    procedure Initialise(var SelectedGenJnlLines: Record "Gen. Journal Line"; SelectedGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlLine.Copy(SelectedGenJnlLines);
        GenJnlBatch := SelectedGenJnlBatch;
    end;

    /// <summary>
    /// Initializes request parameters for standard journal creation with specified settings.
    /// Configures the standard journal code, description, and amount saving preferences for processing.
    /// </summary>
    /// <param name="NewCode">Code for the new standard general journal to be created.</param>
    /// <param name="NewDescription">Description for the new standard general journal.</param>
    /// <param name="NewSaveAmount">Boolean indicating whether to save amounts from source journal lines.</param>
    procedure InitializeRequest(NewCode: Code[10]; NewDescription: Text[50]; NewSaveAmount: Boolean)
    begin
        Code := NewCode;
        Description := NewDescription;
        SaveAmount := NewSaveAmount;
    end;

    local procedure SaveGenJnlAsStandardJnl()
    var
        StdGenJnlLine: Record "Standard General Journal Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        StdGenJnl.Init();
        StdGenJnl."Journal Template Name" := GenJnlBatch."Journal Template Name";
        StdGenJnl.Code := Code;
        StdGenJnl.Description := Description;

        if StdGenJnlExists() then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text001, StdGenJnl.Code), true) then
                exit;

        StdGenJnlLine.LockTable();
        StdGenJnl.LockTable();

        if StdGenJnlExists() then begin
            StdGenJnl.Modify(true);
            StdGenJnlLine.SetRange("Journal Template Name", StdGenJnl."Journal Template Name");
            StdGenJnlLine.SetRange("Standard Journal Code", StdGenJnl.Code);
            StdGenJnlLine.DeleteAll(true);
        end else
            StdGenJnl.Insert(true);

        NextLineNo := 10000;
        if GenJnlLine.Find('-') then
            repeat
                StdGenJnlLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 10000;
                StdGenJnlLine.Init();
                StdGenJnlLine."Journal Template Name" := StdGenJnl."Journal Template Name";
                StdGenJnlLine."Standard Journal Code" := StdGenJnl.Code;
                StdGenJnlLine.TransferFields(GenJnlLine, false);
                StdGenJnlLine."Shortcut Dimension 1 Code" := '';
                StdGenJnlLine."Shortcut Dimension 2 Code" := '';
                if not SaveAmount then begin
                    StdGenJnlLine.Amount := 0;
                    StdGenJnlLine."Debit Amount" := 0;
                    StdGenJnlLine."Credit Amount" := 0;
                    StdGenJnlLine."Amount (LCY)" := 0;
                    StdGenJnlLine."VAT Amount" := 0;
                    StdGenJnlLine."VAT Base Amount" := 0;
                    StdGenJnlLine."VAT Difference" := 0;
                    StdGenJnlLine."Bal. VAT Amount" := 0;
                    StdGenJnlLine."Bal. VAT Base Amount" := 0;
                    StdGenJnlLine."Bal. VAT Difference" := 0;
                    StdGenJnlLine."Balance (LCY)" := 0;
                end;
                OnBeforeStandardGenJnlLineInsert(StdGenJnlLine, GenJnlLine);
                StdGenJnlLine.Insert(true);
                CopyGenJnlLineDims(GenJnlLine, StdGenJnlLine);
                OnAfterStandardGenJnlLineInsert(StdGenJnlLine, GenJnlLine);
            until GenJnlLine.Next() = 0;

        StdJournalCreated := true;
    end;

    local procedure CopyGenJnlLineDims(GenJnlLine: Record "Gen. Journal Line"; StdGenJnlLine: Record "Standard General Journal Line")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", StdGenJnlLine."Shortcut Dimension 1 Code",
          StdGenJnlLine."Shortcut Dimension 2 Code");
        StdGenJnlLine."Dimension Set ID" := GenJnlLine."Dimension Set ID";

        OnCopyGenJnlLineDimsOnBeforeStdGenJnlLineModify(StdGenJnlLine);
        StdGenJnlLine.Modify();
    end;

    local procedure StdGenJnlExists(): Boolean
    var
        StdGenJnl: Record "Standard General Journal";
    begin
        StdGenJnl.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        StdGenJnl.SetRange(Code, Code);

        exit(StdGenJnl.FindFirst());
    end;

    /// <summary>
    /// Retrieves the created standard general journal record and indicates if creation was successful.
    /// Returns the standard journal that was created during the report processing.
    /// </summary>
    /// <param name="StdGenJnl1">Standard general journal record to populate with created journal information.</param>
    /// <returns>True if standard journal was successfully created, false otherwise.</returns>
    procedure GetStdGeneralJournal(var StdGenJnl1: Record "Standard General Journal"): Boolean
    begin
        if StdJournalCreated then
            StdGenJnl1.Copy(StdGenJnl);

        exit(StdJournalCreated);
    end;

    /// <summary>
    /// Integration event raised before inserting standard general journal line during conversion process.
    /// Enables custom modification of standard journal line fields before database insertion.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line record being created from source journal line.</param>
    /// <param name="GenJnlLine">Source general journal line record providing data for conversion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeStandardGenJnlLineInsert(var StandardGeneralJournalLine: Record "Standard General Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before modifying standard general journal line during dimension copying process.
    /// Enables custom processing during dimension transfer from general journal to standard journal lines.
    /// </summary>
    /// <param name="StdGenJnlLine">Standard general journal line being modified with dimension information.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCopyGenJnlLineDimsOnBeforeStdGenJnlLineModify(var StdGenJnlLine: Record "Standard General Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised after inserting standard general journal line during conversion process.
    /// Enables custom processing after standard journal line creation and initial setup.
    /// </summary>
    /// <param name="StandardGeneralJournalLine">Standard journal line record that was inserted.</param>
    /// <param name="GenJournalLine">Source general journal line record that provided data for conversion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterStandardGenJnlLineInsert(var StandardGeneralJournalLine: Record "Standard General Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

