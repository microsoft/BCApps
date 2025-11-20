// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;
using System.Utilities;

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

    procedure Initialise(var SelectedGenJnlLines: Record "Gen. Journal Line"; SelectedGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlLine.Copy(SelectedGenJnlLines);
        GenJnlBatch := SelectedGenJnlBatch;
    end;

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

    procedure GetStdGeneralJournal(var StdGenJnl1: Record "Standard General Journal"): Boolean
    begin
        if StdJournalCreated then
            StdGenJnl1.Copy(StdGenJnl);

        exit(StdJournalCreated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeStandardGenJnlLineInsert(var StandardGeneralJournalLine: Record "Standard General Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyGenJnlLineDimsOnBeforeStdGenJnlLineModify(var StdGenJnlLine: Record "Standard General Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterStandardGenJnlLineInsert(var StandardGeneralJournalLine: Record "Standard General Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

