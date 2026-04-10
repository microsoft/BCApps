namespace System.Test.Tooling;

using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;

codeunit 149140 "BCPT Create Item Journal"
{
    SingleInstance = true;

    trigger OnRun();
    begin
        CreateItemJournal();
    end;

    local procedure CreateItemJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        DocumentNo: Code[20];
        i, j : Integer;
    begin
        for j := 1 to 3 do begin
            DocumentNo := SelectItemJournal(ItemJournalBatch);
            case j of
                1:
                    Item.SetFilter("No.", '11*');
                2:
                    Item.SetFilter("No.", '70*');
                3:
                    Item.SetFilter("No.", '13*');
            end;
            Item.SetRange(Type, Item.Type::"Inventory");
            Item.SetLoadFields("No.");
            Item.FindSet();
            for i := 1 to 1000 do begin
                CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1, i * 10000, DocumentNo);
                if i < 1000 then
                    if Item.Next() = 0 then
                        Item.FindSet();
            end;
        end;
        if Item.Next() = 0 then;  // necessary to satisfy error AA0181
    end;

    procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Text[20]; NewQuantity: Decimal; lineno: Integer; DocumentNo: Code[20])
    begin
        CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatch, EntryType, lineno, DocumentNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, NewQuantity);
        ItemJournalLine.Modify(true);
    end;

    procedure CreateItemJnlLineWithNoItem(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; lineno: Integer; DocumentNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesSingle: Codeunit "No. Series";
    begin
        Clear(ItemJournalLine);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Line No.", lineno);
        ItemJournalLine.Validate("Posting Date", WorkDate());
        ItemJournalLine.Validate("Entry Type", EntryType);
        if NoSeries.Get(ItemJournalBatch."No. Series") then
            DocumentNo := NoSeriesSingle.GetNextNo(ItemJournalBatch."No. Series", ItemJournalLine."Posting Date", false)
        else
            DocumentNo := 'TEST00001';
        ItemJournalLine.Validate("Document No.", DocumentNo);

        ItemJournalLine.Insert(true);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch"): Code[20]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        exit(SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name));
    end;

    procedure SelectItemJournalTemplateName(var ItemJournalTemplate: Record "Item Journal Template"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        // Find Item Journal Template for the given Template Type.
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplateType);
        ItemJournalTemplate.SetRange(Recurring, false);
        if ItemJournalTemplate.FindFirst() then;
    end;

    procedure SelectItemJournalBatchName(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalBatchTemplateType: Enum "Item Journal Template Type"; ItemJournalTemplateName: Code[10]): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        // Find Name for Batch Name.
        ItemJournalBatch.SetRange("Template Type", ItemJournalBatchTemplateType);
        ItemJournalBatch.SetRange("Journal Template Name", ItemJournalTemplateName);

        ItemJournalBatch."Template Type" := ItemJournalBatch."Template Type"::Item;
        ItemJournalBatch."Journal Template Name" := ItemJournalTemplateName;
        ItemJournalBatch.SetupNewBatch();
        ItemJournalBatch.Name := Format(CreateGuid(), 10, 3);
        ItemJournalBatch.Description := 'Auto created journal batch';
        ItemJournalBatch."No. Series" := Format(CreateGuid(), 10, 3);
        ItemJournalBatch.Insert(true);
        NoSeries.Code := ItemJournalBatch."No. Series";
        NoSeries.Description := 'Auto created No. Series';
        NoSeries.Insert(true);
        NoSeriesLine."Series Code" := NoSeries.Code;
        NoSeriesLine."Line No." := 10000;
        NoSeriesLine."Starting No." := CopyStr(NoSeries.Code, 1, 5) + '00001';
        NoSeriesLine.Insert(true);
        exit(NoSeriesLine."Starting No.");
    end;
}