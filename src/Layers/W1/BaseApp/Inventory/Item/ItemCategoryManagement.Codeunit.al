// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using System.Utilities;

codeunit 5722 "Item Category Management"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempItemCategory: Record "Item Category" temporary;

    procedure UpdatePresentationOrder()
    var
        ItemCategory: Record "Item Category";
    begin
        TempItemCategory.Reset();
        TempItemCategory.DeleteAll();

        // This is to cleanup wrong created blank entries created by an import mistake
        if ItemCategory.Get('') then
            ItemCategory.Delete();

        if ItemCategory.FindSet(false) then
            repeat
                TempItemCategory.TransferFields(ItemCategory);
                TempItemCategory.Insert();
            until ItemCategory.Next() = 0;
        UpdatePresentationOrderIterative();
    end;

    local procedure UpdatePresentationOrderIterative()
    var
        ItemCategory: Record "Item Category";
        TempStack: Record TempStack temporary;
        TempCurItemCategory: Record "Item Category" temporary;
        CurItemCategoryID: RecordID;
        PresentationOrder: Integer;
        Indentation: Integer;
        HasChildren: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePresentationOrderIterative(TempItemCategory, IsHandled);
        if IsHandled then
            exit;

        PresentationOrder := 0;

        TempCurItemCategory.Copy(TempItemCategory, true);

        TempItemCategory.SetCurrentKey("Parent Category");
        TempItemCategory.Ascending(false);
        TempItemCategory.SetRange("Parent Category", '');
        if TempItemCategory.FindSet(false) then
            repeat
                TempStack.Push(TempItemCategory.RecordId());
            until TempItemCategory.Next() = 0;

        while TempStack.Pop(CurItemCategoryID) do begin
            TempCurItemCategory.Get(CurItemCategoryID);
            HasChildren := false;

            TempItemCategory.SetRange("Parent Category", TempCurItemCategory.Code);
            if TempItemCategory.FindSet(false) then
                repeat
                    TempStack.Push(TempItemCategory.RecordId());
                    HasChildren := true;
                until TempItemCategory.Next() = 0;

            if TempCurItemCategory."Parent Category" <> '' then begin
                TempItemCategory.Get(TempCurItemCategory."Parent Category");
                Indentation := TempItemCategory.Indentation + 1;
            end else
                Indentation := 0;
            PresentationOrder := PresentationOrder + 10000;

            if (TempCurItemCategory."Presentation Order" <> PresentationOrder) or
               (TempCurItemCategory.Indentation <> Indentation) or (TempCurItemCategory."Has Children" <> HasChildren)
            then begin
                ItemCategory.Get(TempCurItemCategory.Code);
                ItemCategory.Validate("Presentation Order", PresentationOrder);
                ItemCategory.Validate(Indentation, Indentation);
                ItemCategory.Validate("Has Children", HasChildren);
                ItemCategory.Modify();
                TempItemCategory.Get(TempCurItemCategory.Code);
                TempItemCategory.Validate("Presentation Order", PresentationOrder);
                TempItemCategory.Validate(Indentation, Indentation);
                TempItemCategory.Validate("Has Children", HasChildren);
                TempItemCategory.Modify();
            end;
        end;
    end;

    procedure DoesValueExistInItemCategories(Text: Code[20]; var ItemCategory: Record "Item Category"): Boolean
    begin
        ItemCategory.Reset();
        ItemCategory.SetFilter(Code, '@' + Text);
        exit(ItemCategory.FindSet());
    end;

    procedure FindMatchInCategories(SearchTerm: Text; var ItemCategory: Record "Item Category"; ExactMatchOnly: Boolean): Boolean
    var
        FilterPattern: Text;
    begin
        SearchTerm := DelChr(SearchTerm, '=', '.&|<>=*@()?%#''');

        if SearchTerm = '' then
            exit(false);

        if ExactMatchOnly then
            FilterPattern := '@%1'
        else
            FilterPattern := '@*%1*';

        ItemCategory.Reset();
        ItemCategory.SetFilter(Code, StrSubstNo(FilterPattern, CopyStr(SearchTerm, 1, MaxStrLen(ItemCategory.Code))));
        ItemCategory.SetCurrentKey(Indentation);
        ItemCategory.SetAscending(Indentation, false);
        if ItemCategory.FindFirst() then
            exit(true);

        ItemCategory.Reset();
        ItemCategory.SetFilter(Description, StrSubstNo(FilterPattern, CopyStr(SearchTerm, 1, MaxStrLen(ItemCategory.Description))));
        ItemCategory.SetCurrentKey(Indentation);
        ItemCategory.SetAscending(Indentation, false);
        if ItemCategory.FindFirst() then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CalcPresentationOrder(var ItemCategory: Record "Item Category")
    var
        ItemCategorySearch: Record "Item Category";
        ItemCategoryPrev: Record "Item Category";
        ItemCategoryNext: Record "Item Category";
        ItemCategoryPrevExists: Boolean;
        ItemCategoryNextExists: Boolean;
    begin
        if ItemCategory.HasChildren() then begin
            ItemCategory."Presentation Order" := 0;
            exit;
        end;

        ItemCategoryPrev.SetRange("Parent Category", ItemCategory."Parent Category");
        ItemCategoryPrev.SetFilter(Code, '<%1', ItemCategory.Code);
        ItemCategoryPrevExists := ItemCategoryPrev.FindLast();
        if not ItemCategoryPrevExists then
            ItemCategoryPrevExists := ItemCategoryPrev.Get(ItemCategory."Parent Category")
        else
            ItemCategoryPrev.Get(GetLastChildCode(ItemCategoryPrev.Code));

        ItemCategoryNext.SetRange("Parent Category", ItemCategory."Parent Category");
        ItemCategoryNext.SetFilter(Code, '>%1', ItemCategory.Code);
        ItemCategoryNextExists := ItemCategoryNext.FindFirst();
        if not ItemCategoryNextExists and ItemCategoryPrevExists then begin
            ItemCategoryNext.Reset();
            ItemCategoryNext.SetCurrentKey("Presentation Order");
            ItemCategoryNext.SetFilter(Code, '<>%1', ItemCategory.Code);
            ItemCategoryNext.SetFilter("Presentation Order", '>%1', ItemCategoryPrev."Presentation Order");
            ItemCategoryNextExists := ItemCategoryNext.FindFirst();
        end;

        case true of
            not ItemCategoryPrevExists and not ItemCategoryNextExists:
                ItemCategory."Presentation Order" := 10000;
            not ItemCategoryPrevExists and ItemCategoryNextExists:
                ItemCategory."Presentation Order" := ItemCategoryNext."Presentation Order" div 2;
            ItemCategoryPrevExists and not ItemCategoryNextExists:
                ItemCategory."Presentation Order" := ItemCategoryPrev."Presentation Order" + 10000;
            ItemCategoryPrevExists and ItemCategoryNextExists:
                ItemCategory."Presentation Order" := (ItemCategoryPrev."Presentation Order" + ItemCategoryNext."Presentation Order") div 2;
        end;

        ItemCategorySearch.SetRange("Presentation Order", ItemCategory."Presentation Order");
        ItemCategorySearch.SetFilter(Code, '<>%1', ItemCategory.Code);
        if not ItemCategorySearch.IsEmpty() then
            ItemCategory."Presentation Order" := 0;
    end;

    [Scope('OnPrem')]
    procedure CheckPresentationOrder()
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetRange("Presentation Order", 0);
        if not ItemCategory.IsEmpty() then
            UpdatePresentationOrder();
    end;

    local procedure GetLastChildCode(ParentCode: Code[20]) ChildCode: Code[20]
    var
        TempStack: Record TempStack temporary;
        ItemCategory: Record "Item Category";
        RecId: RecordID;
    begin
        ChildCode := ParentCode;

        ItemCategory.Ascending(false);
        ItemCategory.SetRange("Parent Category", ParentCode);
        if ItemCategory.FindSet() then
            repeat
                TempStack.Push(ItemCategory.RecordId());
            until ItemCategory.Next() = 0;

        while TempStack.Pop(RecId) do begin
            ItemCategory.Get(RecId);
            ChildCode := ItemCategory.Code;

            ItemCategory.SetRange("Parent Category", ItemCategory.Code);
            if ItemCategory.FindSet() then
                repeat
                    TempStack.Push(ItemCategory.RecordId());
                until ItemCategory.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePresentationOrderIterative(var TempItemCategory: Record "Item Category" temporary; var IsHandled: Boolean)
    begin
    end;
}

