// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Journal;

using Microsoft.Inventory.Item;

codeunit 240 ItemJnlManagement
{
    Permissions = TableData "Item Journal Template" = rimd,
                  TableData "Item Journal Batch" = rimd;

    trigger OnRun()
    begin
    end;

    var
#if not CLEAN26
        MfgItemJournalMgt: Codeunit "Mfg. Item Journal Mgt.";
#endif
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 journal';
        Text001: Label 'RECURRING';
        Text002: Label 'Recurring Item Journal';
        Text003: Label 'DEFAULT';
        Text004: Label 'Default Journal';
        OldItemNo: Code[20];
        Text005: Label 'REC-';
        Text006: Label 'Recurring ';
#pragma warning restore AA0074
#pragma warning restore AA0470
        OpenFromBatch: Boolean;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Option Item,Transfer,"Phys. Inventory",Revaluation,Consumption,Output,Capacity,"Prod. Order"; RecurringJnl: Boolean; var ItemJnlLine: Record "Item Journal Line"; var JnlSelected: Boolean)
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        JnlSelected := true;

        ItemJnlTemplate.Reset();
        ItemJnlTemplate.SetRange("Page ID", PageID);
        ItemJnlTemplate.SetRange(Recurring, RecurringJnl);
        ItemJnlTemplate.SetRange(Type, PageTemplate);
        OnTemplateSelectionSetFilter(ItemJnlTemplate, PageTemplate);

        OnBeforeTemplateSelection(ItemJnlLine, JnlSelected);

        case ItemJnlTemplate.Count of
            0:
                begin
                    ItemJnlTemplate.Init();
                    ItemJnlTemplate.Recurring := RecurringJnl;
                    ItemJnlTemplate.Validate(Type, PageTemplate);
                    ItemJnlTemplate.Validate("Page ID");
                    if not RecurringJnl then begin
                        ItemJnlTemplate.Name := Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name));
                        ItemJnlTemplate.Description := StrSubstNo(Text000, ItemJnlTemplate.Type);
                    end else
                        if ItemJnlTemplate.Type = ItemJnlTemplate.Type::Item then begin
                            ItemJnlTemplate.Name := Text001;
                            ItemJnlTemplate.Description := Text002;
                        end else begin
                            ItemJnlTemplate.Name :=
                              Text005 + Format(ItemJnlTemplate.Type, MaxStrLen(ItemJnlTemplate.Name) - StrLen(Text005));
                            ItemJnlTemplate.Description := Text006 + StrSubstNo(Text000, ItemJnlTemplate.Type);
                        end;
                    ItemJnlTemplate.Insert();
                    Commit();
                end;
            1:
                ItemJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ItemJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            ItemJnlLine.FilterGroup := 2;
            ItemJnlLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
            ItemJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                ItemJnlLine."Journal Template Name" := '';
                PAGE.Run(ItemJnlTemplate."Page ID", ItemJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var ItemJnlBatch: Record "Item Journal Batch")
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        OpenFromBatch := true;
        ItemJnlTemplate.Get(ItemJnlBatch."Journal Template Name");
        ItemJnlTemplate.TestField("Page ID");
        ItemJnlBatch.TestField(Name);

        ItemJnlLine.FilterGroup := 2;
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        ItemJnlLine.FilterGroup := 0;

        ItemJnlLine."Journal Template Name" := '';
        ItemJnlLine."Journal Batch Name" := ItemJnlBatch.Name;
        PAGE.Run(ItemJnlTemplate."Page ID", ItemJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, ItemJnlLine);

        CheckTemplateName(ItemJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        ItemJnlLine.FilterGroup := 2;
        ItemJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ItemJnlLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var ItemJnlBatch: Record "Item Journal Batch")
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlLine: Record "Item Journal Line";
        ToTemplateType: Enum "Item Journal Template Type";
        JnlSelected: Boolean;
    begin
        if ItemJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        ItemJnlBatch.FilterGroup(2);
        if ItemJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            ItemJnlBatch.FilterGroup(0);
            OnBeforeExitItemJnlBatchGetFilter(ItemJnlBatch);
            exit;
        end;
        ItemJnlBatch.FilterGroup(0);

        if not ItemJnlBatch.Find('-') then begin
            ToTemplateType := ItemJnlTemplate.GetProdOrderTemplateType();
            if ToTemplateType = ToTemplateType::Item then
                ToTemplateType := ToTemplateType::Revaluation;
            for ItemJnlTemplate.Type := ItemJnlTemplate.Type::Item to ToTemplateType do begin
                ItemJnlTemplate.SetRange(Type, ItemJnlTemplate.Type);
                if not ItemJnlTemplate.FindFirst() then
                    TemplateSelection(0, ItemJnlTemplate.Type.AsInteger(), false, ItemJnlLine, JnlSelected);
                if ItemJnlTemplate.FindFirst() then
                    CheckTemplateName(ItemJnlTemplate.Name, ItemJnlBatch.Name);
                if ItemJnlTemplate.Type in [ItemJnlTemplate.Type::Item,
                                            ItemJnlTemplate.GetConsumptionTemplateType(),
                                            ItemJnlTemplate.GetOutputTemplateType(),
                                            ItemJnlTemplate.GetCapacityTemplateType()]
                then begin
                    ItemJnlTemplate.SetRange(Recurring, true);
                    if not ItemJnlTemplate.FindFirst() then
                        TemplateSelection(0, ItemJnlTemplate.Type.AsInteger(), true, ItemJnlLine, JnlSelected);
                    if ItemJnlTemplate.FindFirst() then
                        CheckTemplateName(ItemJnlTemplate.Name, ItemJnlBatch.Name);
                    ItemJnlTemplate.SetRange(Recurring);
                end;
            end;
        end;

        ItemJnlBatch.Find('-');
        JnlSelected := true;
        ItemJnlBatch.CalcFields("Template Type", Recurring);
        ItemJnlTemplate.SetRange(Recurring, ItemJnlBatch.Recurring);
        if not ItemJnlBatch.Recurring then
            ItemJnlTemplate.SetRange(Type, ItemJnlBatch."Template Type");
        if ItemJnlBatch.GetFilter("Journal Template Name") <> '' then
            ItemJnlTemplate.SetRange(Name, ItemJnlBatch.GetFilter("Journal Template Name"));
        OnOpenJnlBatchOnBeforeCaseSelectItemJnlTemplate(ItemJnlTemplate, ItemJnlBatch);
        case ItemJnlTemplate.Count of
            1:
                ItemJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, ItemJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        ItemJnlBatch.FilterGroup(0);
        ItemJnlBatch.SetRange("Journal Template Name", ItemJnlTemplate.Name);
        ItemJnlBatch.FilterGroup(2);
    end;

    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        OnBeforeCheckTemplateName(CurrentJnlTemplateName, CurrentJnlBatchName, ItemJnlBatch);
        ItemJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not ItemJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not ItemJnlBatch.FindFirst() then begin
                ItemJnlBatch.Init();
                ItemJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                ItemJnlBatch.SetupNewBatch();
                ItemJnlBatch.Name := Text003;
                ItemJnlBatch.Description := Text004;
                ItemJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := ItemJnlBatch.Name
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlBatch: Record "Item Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckName(CurrentJnlBatchName, ItemJnlLine, IsHandled);
        if IsHandled then
            exit;

        ItemJnlBatch.Get(ItemJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.FilterGroup := 2;
        ItemJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ItemJnlLine.FilterGroup := 0;
        OnSetNameOnAfterAppliesFilterOnItemJnlLine(ItemJnlLine, CurrentJnlBatchName);
        if ItemJnlLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line")
    var
        ItemJnlBatch: Record "Item Journal Batch";
        IsHandled: Boolean;
    begin
        Commit();
        ItemJnlBatch."Journal Template Name" := ItemJnlLine.GetRangeMax("Journal Template Name");
        ItemJnlBatch.Name := ItemJnlLine.GetRangeMax("Journal Batch Name");
        ItemJnlBatch.FilterGroup(2);
        ItemJnlBatch.SetRange("Journal Template Name", ItemJnlBatch."Journal Template Name");
        ItemJnlBatch.FilterGroup(0);
        IsHandled := false;
        OnBeforeLookupName(ItemJnlBatch, IsHandled, CurrentJnlBatchName, ItemJnlLine);
        if not IsHandled then
            if PAGE.RunModal(0, ItemJnlBatch) = ACTION::LookupOK then begin
                CurrentJnlBatchName := ItemJnlBatch.Name;
                SetName(CurrentJnlBatchName, ItemJnlLine);
            end;
    end;

    procedure GetItem(ItemNo: Code[20]; var ItemDescription: Text[100])
    var
        Item: Record Item;
    begin
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
            OldItemNo := ItemNo;
        end;

        OnAfterGetItem(Item, ItemDescription);
    end;

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Journal Management', '26.0')]
    procedure GetConsump(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderDescription: Text[100])
    begin
        MfgItemJournalMgt.GetConsump(ItemJnlLine, ProdOrderDescription);
    end;
#endif

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Journal Management', '26.0')]
    procedure GetOutput(var ItemJnlLine: Record "Item Journal Line"; var ProdOrderDescription: Text[100]; var OperationDescription: Text[100])
    begin
        MfgItemJournalMgt.GetOutput(ItemJnlLine, ProdOrderDescription, OperationDescription);
    end;
#endif

#if not CLEAN26
    [Obsolete('Moved to codeunit Mfg. Item Journal Management', '26.0')]
    procedure GetCapacity(CapType: Enum Microsoft.Manufacturing.Capacity."Capacity Type"; CapNo: Code[20]; var CapDescription: Text[100])
    begin
        MfgItemJournalMgt.GetCapacity(CapType, CapNo, CapDescription);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckName(CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10]; var ItemJournalBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var ItemJnlBatch: Record "Item Journal Batch"; var IsHandled: Boolean; var CurrentJnlBatchName: Code[10]; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenJnlBatchOnBeforeCaseSelectItemJnlTemplate(var ItemJnlTemplate: Record "Item Journal Template"; var ItemJnlBatch: Record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionSetFilter(var ItemJnlTemplate: Record "Item Journal Template"; var PageTemplate: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(Item: Record Item; var ItemDescription: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetNameOnAfterAppliesFilterOnItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; CurrentJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExitItemJnlBatchGetFilter(var ItemJnlBatch: record "Item Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelection(var ItemJnlLine: Record "Item Journal Line"; var JnlSelected: Boolean)
    begin
    end;
}

