// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Foundation.UOM;

table 752 "Standard Item Journal"
{
    Caption = 'Standard Item Journal';
    LookupPageID = "Standard Item Journals";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            Editable = false;
            NotBlank = true;
            TableRelation = "Item Journal Template";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StdItemJnlLine: Record "Standard Item Journal Line";
    begin
        StdItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        StdItemJnlLine.SetRange("Standard Journal Code", Code);

        StdItemJnlLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        StdItemJnlLine: Record "Standard Item Journal Line";
    begin
        StdItemJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        StdItemJnlLine.SetRange("Standard Journal Code", Code);

        StdItemJnlLine.DeleteAll(true);
    end;

    var
        LastItemJnlLine: Record "Item Journal Line";
        ItemJnlLine: Record "Item Journal Line";
        UOMMgt: Codeunit "Unit of Measure Management";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfJournalsToBeCreated: Integer;
        NoOfJournalsCreated: Integer;
#pragma warning disable AA0074
        Text000: Label 'Getting Standard Item Journal Lines @1@@@@@@@';
#pragma warning restore AA0074

    procedure Initialize(StdItemJnl: Record "Standard Item Journal"; JnlBatchName: Code[10])
    begin
        ItemJnlLine."Journal Template Name" := StdItemJnl."Journal Template Name";
        ItemJnlLine."Journal Batch Name" := JnlBatchName;
        ItemJnlLine.SetRange("Journal Template Name", StdItemJnl."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", JnlBatchName);

        LastItemJnlLine.SetRange("Journal Template Name", StdItemJnl."Journal Template Name");
        LastItemJnlLine.SetRange("Journal Batch Name", JnlBatchName);

        if LastItemJnlLine.FindLast() then;
    end;

    procedure CreateItemJnlFromStdJnl(StdItemJnl: Record "Standard Item Journal"; JnlBatchName: Code[10])
    var
        StdItemJnlLine: Record "Standard Item Journal Line";
    begin
        Initialize(StdItemJnl, JnlBatchName);

        StdItemJnlLine.SetRange("Journal Template Name", StdItemJnl."Journal Template Name");
        StdItemJnlLine.SetRange("Standard Journal Code", StdItemJnl.Code);
        OpenWindow(Text000, StdItemJnlLine.Count);
        if StdItemJnlLine.Find('-') then
            repeat
                UpdateWindow();
                CopyItemJnlFromStdJnl(StdItemJnlLine);
            until StdItemJnlLine.Next() = 0;
    end;

    local procedure CopyItemJnlFromStdJnl(StdItemJnlLine: Record "Standard Item Journal Line")
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Line No." := 0;
        ItemJnlLine.SetUpNewLine(LastItemJnlLine);
        if LastItemJnlLine."Line No." <> 0 then
            ItemJnlLine."Line No." := LastItemJnlLine."Line No." + 10000
        else
            ItemJnlLine."Line No." := 10000;

        ItemJnlLine.TransferFields(StdItemJnlLine, false);

        if (ItemJnlLine."Item No." <> '') and (ItemJnlLine."Unit Amount" = 0) then
            ItemJnlLine.RecalculateUnitAmount();

        if (ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Output) and
           (ItemJnlLine."Value Entry Type" <> ItemJnlLine."Value Entry Type"::Revaluation)
        then
            ItemJnlLine."Invoiced Quantity" := 0
        else
            ItemJnlLine."Invoiced Quantity" := ItemJnlLine.Quantity;
        ItemJnlLine.TestField("Qty. per Unit of Measure");
        ItemJnlLine."Invoiced Qty. (Base)" :=
          Round(ItemJnlLine."Invoiced Quantity" * ItemJnlLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());

        ItemJnlLine."Dimension Set ID" := StdItemJnlLine."Dimension Set ID";
        ItemJnlLine.Insert(true);

        OnAfterCopyItemJnlFromStdJnl(ItemJnlLine, Rec, StdItemJnlLine);

        LastItemJnlLine := ItemJnlLine;
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfJournalsToBeCreated2: Integer)
    begin
        NoOfJournalsCreated := 0;
        NoOfJournalsToBeCreated := NoOfJournalsToBeCreated2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        NoOfJournalsCreated := NoOfJournalsCreated + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(NoOfJournalsCreated / NoOfJournalsToBeCreated * 10000, 1));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlFromStdJnl(var ItemJournalLine: Record "Item Journal Line"; var StandardItemJournal: Record "Standard Item Journal"; var StandardItemJournalLine: Record "Standard Item Journal Line")
    begin
    end;
}

