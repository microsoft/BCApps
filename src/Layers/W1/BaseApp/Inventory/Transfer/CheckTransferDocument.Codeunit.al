// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Item;

codeunit 9134 "Check Transfer Document"
{
    var
        CannotChangeItemWithOutstandingDocumentLinesErr: Label 'You cannot delete %1 %2 because there are one or more outstanding transfer orders that include this item.', Comment = '%1 - Item, %2 - Item No.';

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterCheckDocuments', '', false, false)]
    local procedure ItemOnBeforeCheckDocuments(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text);
    begin
        CheckTransferLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption);
    end;

    internal procedure CheckTransferLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text)
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferLines(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#if not CLEAN25
        Item.RunOnBeforeCheckTransLine(Item, CurrentFieldNo, CheckFieldNo, CheckFieldCaption, IsHandled);
#endif
        if IsHandled then
            exit;

        TransferLine.SetCurrentKey("Item No.");
        TransferLine.SetRange("Item No.", Item."No.");
        if not TransferLine.IsEmpty() then begin
            if CurrentFieldNo = 0 then
                Error(
                    CannotChangeItemWithOutstandingDocumentLinesErr, Item.TableCaption(), Item."No.");
            if CurrentFieldNo = CheckFieldNo then
                Error(
                    Item.GetCannotChangeItemWithExistingDocumentLinesErr(), CheckFieldCaption, Item.TableCaption(), Item."No.", TransferLine.TableCaption());
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferLines(Item: Record Item; CurrentFieldNo: Integer; CheckFieldNo: Integer; CheckFieldCaption: Text; var IsHandled: Boolean)
    begin
    end;
}
