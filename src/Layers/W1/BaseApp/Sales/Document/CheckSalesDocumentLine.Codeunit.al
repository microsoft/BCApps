// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;
using Microsoft.Sales.Posting;

codeunit 9069 "Check Sales Document Line"
{
    TableNo = "Sales Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        SalesHeader: Record "Sales Header";
#pragma warning disable AA0470
        CannotDeleteItemIfSalesDocExistErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Sales %3 that includes this item.', Comment = '1: Type, 2 Item No. and 3 : Type of document Order,Invoice';
#pragma warning restore AA0470

    procedure SetSalesHeader(NewSalesHeader: Record "Sales Header")
    begin
        SalesHeader := NewSalesHeader;
    end;

    local procedure RunCheck(var SalesLine: Record "Sales Line")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.TestSalesLine(SalesHeader, SalesLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckSalesLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    internal procedure CheckSalesLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckSalesLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        SalesLine.SetCurrentKey(Type, "No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.SetLoadFields("Document Type");
        if SalesLine.FindFirst() then begin
            if CurrentFieldNo = 0 then
                Error(
                    CannotDeleteItemIfSalesDocExistErr, Item.TableCaption(), Item."No.", SalesLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", SalesLine.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}
