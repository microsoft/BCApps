// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Posting;

codeunit 9066 "Check Purchase Document Line"
{
    TableNo = "Purchase Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        PurchaseHeader: Record "Purchase Header";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete %1 %2 because there is at least one outstanding Purchase %3 that includes this item.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetPurchaseHeader(NewPurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader := NewPurchaseHeader;
    end;

    local procedure RunCheck(var PurchaseLine: Record "Purchase Line")
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.TestPurchLine(PurchaseHeader, PurchaseLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckPurchaseLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    internal procedure CheckPurchaseLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchaseLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckPurchLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        PurchaseLine.SetCurrentKey(Type, "No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        OnCheckPurchLineOnAfterPurchLineSetFilters(Item, PurchaseLine, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
#if not CLEAN25
        Item.RunOnCheckPurchLineOnAfterPurchLineSetFilters(Item, PurchaseLine, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
#endif
        PurchaseLine.SetLoadFields("Document Type");
        if PurchaseLine.FindFirst() then begin
            if CurrentFieldNo = 0 then
                Error(
                    Text000,
                    Item.TableCaption(), Item."No.", PurchaseLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", PurchaseLine.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchaseLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckPurchLineOnAfterPurchLineSetFilters(Item: Record Item; var PurchaseLine: Record "Purchase Line"; CurrFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    begin
    end;
}
