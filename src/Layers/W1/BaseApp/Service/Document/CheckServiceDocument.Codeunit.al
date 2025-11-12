// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Item;
using Microsoft.Service.Posting;
using Microsoft.Service.Contract;

codeunit 9065 "Check Service Document"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        CannotChangeItemWithOutstandingDocumentLinesErr: Label 'You cannot delete %1 %2 because there is at least one outstanding Service %3 that includes this item.', Comment = '%1 - Item, %2 - Item No., %3 - Service Document Type';

    local procedure RunCheck(var ServiceHeader: Record "Service Header")
    var
        TempServLine: Record "Service Line" temporary;
        ServicePost: Codeunit "Service-Post";
    begin
        ServicePost.CheckServiceDocument(ServiceHeader, TempServLine);
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckServiceLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
        CheckServiceContractLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    internal procedure CheckServiceLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServiceLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckServLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceLine.Reset();
        ServiceLine.SetCurrentKey(Type, "No.");
        ServiceLine.SetRange(Type, "Service Line Type"::Item);
        ServiceLine.SetRange("No.", Item."No.");
        if not ServiceLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    CannotChangeItemWithOutstandingDocumentLinesErr,
                    Item.TableCaption(), Item."No.", ServiceLine."Document Type");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", ServiceLine.TableCaption());
        end;
    end;

    internal procedure CheckServiceContractLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        ServiceContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServiceContractLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckServContractLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        ServiceContractLine.Reset();
        ServiceContractLine.SetRange("Item No.", Item."No.");
        if not ServiceContractLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    Item.GetCannotDeleteItemWithExistingDocumentLinesErr(),
                    Item.TableCaption(), Item."No.", ServiceContractLine.TableCaption());
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(),
                    CheckFieldCaption, Item.TableCaption(), Item."No.", ServiceContractLine.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServiceLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServiceContractLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}