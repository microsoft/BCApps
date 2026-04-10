// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

report 751 "Save as Standard Item Journal"
{
    Caption = 'Save as Standard Item Journal';
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
                        NotBlank = true;
                        ToolTip = 'Specifies the code for the journal.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            StdItemJnl: Record "Standard Item Journal";
                            StdItemJnls: Page "Standard Item Journals";
                        begin
                            StdItemJnl.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
                            StdItemJnls.SetTableView(StdItemJnl);

                            StdItemJnls.LookupMode := true;
                            StdItemJnls.Editable := false;
                            if StdItemJnls.RunModal() = ACTION::LookupOK then begin
                                StdItemJnls.GetRecord(StdItemJnl);
                                Code := StdItemJnl.Code;
                                Description := StdItemJnl.Description;
                            end;
                        end;
                    }
                    field(Description; Description)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Description';
                        ToolTip = 'Specifies a description of the journal.';
                    }
                    field(SaveUnitAmount; SaveUnitAmount)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Save Unit Amount';
                        ToolTip = 'Specifies if you want the program to save the value(s) in the Unit Amount field of the item journal you are saving.';
                    }
                    field(SaveQuantity; SaveQuantity)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Save Quantity';
                        ToolTip = 'Specifies if you want the program to save the value(s) in the Quantity field of the item journal you are saving.';
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
        SaveItemJnlAsStandardJnl();
    end;

    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlBatch: Record "Item Journal Batch";
        StdItemJnl: Record "Standard Item Journal";
        "Code": Code[10];
        Description: Text[100];
        SaveUnitAmount: Boolean;
        SaveQuantity: Boolean;
        StdJournalCreated: Boolean;

#pragma warning disable AA0074
        Text000: Label 'Enter a code for Standard Item Journal.';
#pragma warning disable AA0470
        Text001: Label 'Standard Item Journal %1 already exists. Do you want to overwrite?';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Initialise(var SelectedItemJnlLines: Record "Item Journal Line"; SelectedItemJnlBatch: Record "Item Journal Batch")
    begin
        ItemJnlLine.Copy(SelectedItemJnlLines);
        ItemJnlBatch := SelectedItemJnlBatch;
    end;

    procedure InitializeRequest(NewCode: Code[10]; NewDescription: Text[50]; NewSaveUnitAmount: Boolean; NewSaveQuantity: Boolean)
    begin
        Code := NewCode;
        Description := NewDescription;
        SaveUnitAmount := NewSaveUnitAmount;
        SaveQuantity := NewSaveQuantity;
    end;

    local procedure SaveItemJnlAsStandardJnl()
    var
        StdItemJnlLine: Record "Standard Item Journal Line";
        NextLineNo: Integer;
    begin
        StdItemJnl.Init();
        StdItemJnl."Journal Template Name" := ItemJnlBatch."Journal Template Name";
        StdItemJnl.Code := Code;
        StdItemJnl.Description := Description;

        if StdItemJnlExists() then
            if not Confirm(Text001, false, StdItemJnl.Code) then
                exit;

        StdItemJnlLine.LockTable();
        StdItemJnl.LockTable();

        if StdItemJnlExists() then begin
            StdItemJnl.Modify(true);
            StdItemJnlLine.SetRange("Journal Template Name", StdItemJnl."Journal Template Name");
            StdItemJnlLine.SetRange("Standard Journal Code", StdItemJnl.Code);
            StdItemJnlLine.DeleteAll(true);
        end else
            StdItemJnl.Insert(true);

        NextLineNo := 10000;
        if ItemJnlLine.FindSet() then
            repeat
                StdItemJnlLine."Line No." := NextLineNo;
                NextLineNo := NextLineNo + 10000;
                StdItemJnlLine.Init();
                StdItemJnlLine."Journal Template Name" := StdItemJnl."Journal Template Name";
                StdItemJnlLine."Standard Journal Code" := StdItemJnl.Code;
                StdItemJnlLine.TransferFields(ItemJnlLine, false);
                if not SaveUnitAmount then begin
                    StdItemJnlLine."Unit Amount" := 0;
                    StdItemJnlLine.Amount := 0;
                    StdItemJnlLine."Unit Cost" := 0;
                    StdItemJnlLine."Indirect Cost %" := 0;
                end;
                if not SaveQuantity then
                    StdItemJnlLine.Validate(Quantity, 0);
                OnBeforeInsertStandardItemJournalLine(StdItemJnlLine, ItemJnlLine);
                StdItemJnlLine.Insert(true);
            until ItemJnlLine.Next() = 0;

        StdJournalCreated := true;
    end;

    local procedure StdItemJnlExists(): Boolean
    var
        StdItemJnl: Record "Standard Item Journal";
    begin
        StdItemJnl.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        StdItemJnl.SetRange(Code, Code);

        exit(StdItemJnl.FindFirst());
    end;

    procedure GetStdItemJournal(var StdItemJnl1: Record "Standard Item Journal"): Boolean
    begin
        if StdJournalCreated then
            StdItemJnl1.Copy(StdItemJnl);

        exit(StdJournalCreated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertStandardItemJournalLine(var StdItemJnlLine: Record "Standard Item Journal Line"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;
}

