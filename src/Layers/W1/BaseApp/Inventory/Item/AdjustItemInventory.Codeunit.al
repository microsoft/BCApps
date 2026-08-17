// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;

codeunit 1327 "Adjust Item Inventory"
{

    trigger OnRun()
    begin
    end;

    var
        CantFindTemplateOrBatchErr: Label 'Unable to find the correct item journal template or batch to post this change. Use the default item journal instead.';
        SimpleInvJnlNameTxt: Label 'DEFAULT', Comment = 'The default name of the item journal';

    procedure PostAdjustmentToItemLedger(Item: Record Item; NewInventory: Decimal) LastErrorText: Text
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemTemplate: Code[10];
    begin
        Item.CalcFields(Inventory);
        if Item.Inventory = NewInventory then
            exit;

        ItemTemplate := SelectItemTemplateForAdjustment();
        CreateItemJnlLine(ItemJnlLine, Item, ItemTemplate, CreateItemBatch(ItemTemplate), NewInventory);
        ItemJnlLine.Insert(true);

        LastErrorText := PostItemJnlLines(ItemJnlLine);
    end;

    procedure PostMultipleAdjustmentsToItemLedger(var TempItemJournalLine: Record "Item Journal Line" temporary) LastErrorText: Text
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ItemTemplate: Code[10];
        ItemBatch: Code[10];
    begin
        if not TempItemJournalLine.FindSet() then
            exit;

        ItemTemplate := SelectItemTemplateForAdjustment();
        ItemBatch := CreateItemBatch(ItemTemplate);

        repeat
            Item.Get(TempItemJournalLine."Item No.");
            Item.SetFilter("Location Filter", '%1', TempItemJournalLine."Location Code");
            OnPostMultipleAdjustmentsToItemLedgerOnAfterItemSetFilters(TempItemJournalLine, Item);
            Item.Inventory := TempItemJournalLine."Qty. (Calculated)";
            if Item.Inventory <> TempItemJournalLine.Quantity then begin
                CreateItemJnlLine(ItemJnlLine, Item, ItemTemplate, ItemBatch, TempItemJournalLine.Quantity);
                ItemJnlLine.Validate("Line No.", TempItemJournalLine."Line No.");
                ItemJnlLine.Validate("Location Code", TempItemJournalLine."Location Code");
                OnPostMultipleAdjustmentsToItemLedgerOnBeforeInsertItemJnlLine(TempItemJournalLine, ItemJnlLine);
                ItemJnlLine.Insert(true);
            end;
        until TempItemJournalLine.Next() = 0;

        ItemJnlLine.SetRange("Journal Template Name", ItemTemplate);
        ItemJnlLine.SetRange("Journal Batch Name", ItemBatch);
        if ItemJnlLine.IsEmpty() then begin
            DeleteItemBatch(ItemTemplate, ItemBatch);
            exit;
        end;

        LastErrorText := PostItemJnlLines(ItemJnlLine);
    end;

    procedure CreateItemJnlLine(var ItemJnlLine: Record "Item Journal Line"; var Item: Record Item; ItemTemplate: Code[10]; ItemBatch: Code[10]; NewInventory: Decimal)
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", ItemTemplate);
        ItemJnlLine.Validate("Journal Batch Name", ItemBatch);
        ItemJnlLine.Validate("Posting Date", WorkDate());
        ItemJnlLine."Document No." := Item."No.";

        if Item.Inventory < NewInventory then
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Positive Adjmt.")
        else
            ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::"Negative Adjmt.");

        ItemJnlLine.Validate("Item No.", Item."No.");
        ItemJnlLine.Validate(Description, Item.Description);
        ItemJnlLine.Validate(Quantity, Abs(NewInventory - Item.Inventory));
    end;

    procedure PostItemJnlLines(var ItemJournalLine: Record "Item Journal Line") LastErrorText: Text
    var
        Completed: Boolean;
    begin
        Commit();

        Completed := CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);

        DeleteItemBatch(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        if not Completed then begin
            LastErrorText := GetLastErrorText;
            Commit();
        end;
    end;

    procedure SelectItemTemplateForAdjustment(): Code[10]
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlManagement: Codeunit ItemJnlManagement;
        JnlSelected: Boolean;
    begin
        ItemJnlManagement.TemplateSelection(PAGE::"Item Journal", 0, false, ItemJnlLine, JnlSelected);

        ItemJnlTemplate.SetRange("Page ID", PAGE::"Item Journal");
        ItemJnlTemplate.SetRange(Recurring, false);
        ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type::Item);
        if not ItemJnlTemplate.FindFirst() then
            Error(CantFindTemplateOrBatchErr);

        exit(ItemJnlTemplate.Name);
    end;

    local procedure CreateItemBatch(TemplateName: Code[10]): Code[10]
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        ItemJnlBatch.Init();
        ItemJnlBatch."Journal Template Name" := TemplateName;
        ItemJnlBatch.Name := CreateBatchName();
        ItemJnlBatch.Description := SimpleInvJnlNameTxt;
        ItemJnlBatch.Insert();

        exit(ItemJnlBatch.Name);
    end;

    procedure FindOrCreateItemBatchWithCustomNameDesc(TemplateName: Code[10]; BatchName: Code[10]; BatchDescription: Text[50]): Code[10]
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        if ItemJnlBatch.Get(TemplateName, BatchName) then
            exit(BatchName);
        ItemJnlBatch.Init();
        ItemJnlBatch."Journal Template Name" := TemplateName;
        ItemJnlBatch.Name := BatchName;
        ItemJnlBatch.Description := BatchDescription;
        ItemJnlBatch.SetupNewBatch();
        ItemJnlBatch.Insert();
        exit(ItemJnlBatch.Name);
    end;

    procedure GetInventoryAdjustmentAllowed(): Boolean;
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.SetLoadFields("Allow Inventory Adjustment");
        InventorySetup.Get();
        exit(InventorySetup."Allow Inventory Adjustment");
    end;

    local procedure DeleteItemBatch(TemplateName: Code[10]; BatchName: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        if ItemJnlBatch.Get(TemplateName, BatchName) then
            ItemJnlBatch.Delete(true);
    end;

    local procedure CreateBatchName(): Code[10]
    var
        BatchName: Text;
    begin
        BatchName := Format(CreateGuid());
        exit(CopyStr(BatchName, 2, 10));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostMultipleAdjustmentsToItemLedgerOnAfterItemSetFilters(var TempItemJournalLine: Record "Item Journal Line" temporary; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostMultipleAdjustmentsToItemLedgerOnBeforeInsertItemJnlLine(var TempItemJournalLine: Record "Item Journal Line" temporary; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

