// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;

codeunit 5921 "ServComponent-Copy from BOM"
{
    TableNo = "Service Item";

    trigger OnRun()
    begin
        ServItem.Get(Rec."No.");
        ServItem.TestField("Item No.");

        ServItemComponent.LockTable();
        ServItemComponent.Reset();
        ServItemComponent.SetRange(Active, true);
        ServItemComponent.SetRange("Parent Service Item No.", ServItem."No.");
        if ServItemComponent.FindLast() then
            LineNo := ServItemComponent."Line No."
        else
            LineNo := 0;

        BOMComp.SetCurrentKey("Parent Item No.", "Line No.");
        BOMComp.SetRange("Parent Item No.", ServItem."Item No.");
        BOMComp.SetRange(Type, BOMComp.Type::Item);
        if BOMComp.Find('-') then
            repeat
                if BOMComp."Quantity per" <> Round(BOMComp."Quantity per", 1) then
                    Error(Text001, ServItem.TableCaption(), BOMComp.FieldCaption("Quantity per"));
                for Index := 1 to BOMComp."Quantity per" do begin
                    LineNo := LineNo + 10000;
                    Item.Get(BOMComp."No.");
                    Clear(ServItemComponent);
                    ServItemComponent.Active := true;
                    ServItemComponent.Init();
                    ServItemComponent."Parent Service Item No." := ServItem."No.";
                    ServItemComponent."Line No." := LineNo;
                    ServItemComponent.Type := ServItemComponent.Type::Item;
                    ServItemComponent."No." := BOMComp."No.";
                    ServItemComponent."Variant Code" := BOMComp."Variant Code";
                    ServItemComponent."Date Installed" := ServItem."Installation Date";
                    ServItemComponent.Description := Item.Description;
                    ServItemComponent."Description 2" := Item."Description 2";
                    ServItemComponent."From Line No." := 0;
                    OnRunOnBeforeServItemComponentInsert(ServItemComponent, BOMComp, Item);
                    if not ServItemComponent.Insert() then
                        ServItemComponent.Modify();
                end;
            until BOMComp.Next() = 0
        else
            ShowBOMComponentNotFoundError();
    end;

    var
        ServItem: Record "Service Item";
        BOMComp: Record "BOM Component";
        ServItemComponent: Record "Service Item Component";
        Item: Record Item;
        LineNo: Integer;
        Index: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 for %2 %3 cannot be found.';
        Text001: Label 'You cannot copy the component list for this %1 from BOM. The %2 of one or more BOM components is not a whole number.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ShowBOMComponentNotFoundError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowBOMComponentNotFoundError(BOMComp, ServItem, IsHandled);
        if IsHandled then
            exit;

        Error(Text000, BOMComp.TableCaption(), ServItem.FieldCaption("Item No."), ServItem."Item No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowBOMComponentNotFoundError(BOMComp: Record "BOM Component"; ServItem: Record "Service Item"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeServItemComponentInsert(var ServItemComponent: Record "Service Item Component"; BOMComp: Record "BOM Component"; Item: Record Item)
    begin
    end;
}

