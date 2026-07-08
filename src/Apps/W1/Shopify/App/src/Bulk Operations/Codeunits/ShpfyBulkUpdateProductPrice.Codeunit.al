// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;
using System.Reflection;

codeunit 30281 "Shpfy Bulk UpdateProductPrice" implements "Shpfy IBulk Operation"
{
    Access = Internal;

    var
        NameLbl: Label 'Update product price';
        PriceSyncRevertedWithErrorLbl: Label 'The product price update was reverted because Shopify returned an error: %1', Comment = '%1 = the error message returned by Shopify';
        PriceSyncRevertedLbl: Label 'The product price update was reverted because Shopify did not confirm the update.';

    procedure GetGraphQL(): Text
    begin
        exit('mutation call($productId: ID!, $variants: [ProductVariantsBulkInput!]!) { productVariantsBulkUpdate(productId: $productId, variants: $variants) { productVariants {id updatedAt}, userErrors {field, message}}}');
    end;

    procedure GetInput(): Text
    begin
        // %4 carries the entire optional ', "compareAtPrice": <value>' fragment (or empty
        // string to omit the field, in which case Shopify preserves the existing value).
        // It must include the leading comma and field name when present.
        exit('{ "productId": "gid://shopify/Product/%1", "variants": [{ "id": "gid://shopify/ProductVariant/%2", "price": "%3"%4, "inventoryItem": { "cost": "%5" }}]}');
    end;

    procedure GetName(): Text[250]
    begin
        exit(NameLbl);
    end;

    procedure GetType(): Text
    begin
        exit('mutation');
    end;

    procedure RevertFailedRequests(var BulkOperation: Record "Shpfy Bulk Operation")
    var
        Shop: Record "Shpfy Shop";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        JsonHelper: Codeunit "Shpfy Json Helper";
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        TypeHelper: Codeunit "Type Helper";
        JsonlResult: Text;
        Result: List of [Text];
        Line: Text;
        JLine: JsonObject;
        JVariants: JsonArray;
        JVariant: JsonToken;
        SuccessList: List of [BigInteger];
        LineErrors: Dictionary of [BigInteger, Text];
        LineNumber: BigInteger;
        BaseLineNumber: BigInteger;
        HasBaseLineNumber: Boolean;
        IsSuccess: Boolean;
    begin
        if not Shop.Get(BulkOperation."Shop Code") then
            exit;

        BaseLineNumber := 0;
        JsonlResult := BulkOperationMgt.GetBulkOperationResult(Shop, BulkOperation);
        if JsonlResult = '' then
            exit;

        Result := JsonlResult.Split(TypeHelper.LFSeparator());
        foreach Line in Result do
            if JLine.ReadFrom(Line) then begin
                if JsonHelper.ContainsToken(JLine, '__lineNumber') then begin
                    LineNumber := JsonHelper.GetValueAsBigInteger(JLine, '__lineNumber');
                    if (not HasBaseLineNumber) or (LineNumber < BaseLineNumber) then begin
                        BaseLineNumber := LineNumber;
                        HasBaseLineNumber := true;
                    end;
                end;

                IsSuccess := false;
                if JsonHelper.ContainsToken(JLine, 'data.productVariantsBulkUpdate.productVariants') then begin
                    JVariants := JsonHelper.GetJsonArray(JLine, 'data.productVariantsBulkUpdate.productVariants');
                    if JVariants.Count = 1 then
                        if JVariants.Get(0, JVariant) then
                            if JsonHelper.GetValueAsDateTime(JVariant, 'updatedAt') > 0DT then begin
                                SuccessList.Add(CommunicationMgt.GetIdOfGId(JsonHelper.GetValueAsText(JVariant, 'id')));
                                IsSuccess := true;
                            end;
                end;

                if (not IsSuccess) and JsonHelper.ContainsToken(JLine, '__lineNumber') then
                    LineErrors.Set(LineNumber, GetLineErrorMessage(JLine, JsonHelper));
            end;

        RevertRequests(BulkOperation, SuccessList, LineErrors, BaseLineNumber, Shop, true);
    end;

    local procedure RevertRequests(var BulkOperation: Record "Shpfy Bulk Operation"; var SuccessList: List of [BigInteger]; var LineErrors: Dictionary of [BigInteger, Text]; BaseLineNumber: BigInteger; Shop: Record "Shpfy Shop"; LogSkipped: Boolean)
    var
        ShopifyVariant: Record "Shpfy Variant";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        JRequestData: JsonArray;
        JRequest: JsonToken;
        JVariant: JsonObject;
        VariantId: BigInteger;
        Index: Integer;
    begin
        JRequestData := BulkOperation.GetRequestData();
        Index := 0;
        foreach JRequest in JRequestData do begin
            JVariant := JRequest.AsObject();
            VariantId := JVariant.GetBigInteger('id');
            if not SuccessList.Contains(VariantId) then
                if ShopifyVariant.Get(VariantId) then begin
                    ShopifyVariant.Price := JVariant.GetDecimal('price');
                    ShopifyVariant."Compare at Price" := JVariant.GetDecimal('compareAtPrice');
                    ShopifyVariant."Updated At" := JVariant.GetDateTime('updatedAt');
                    if JVariant.Contains('unitCost') then
                        ShopifyVariant."Unit Cost" := JVariant.GetDecimal('unitCost');
                    ShopifyVariant.Modify();

                    if LogSkipped then
                        SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, GetBCRecordId(ShopifyVariant), CopyStr(GetSkippedReason(LineErrors, BaseLineNumber + Index), 1, 250), Shop);
                end;
            Index += 1;
        end;
    end;

    procedure RevertAllRequests(var BulkOperation: Record "Shpfy Bulk Operation")
    var
        Shop: Record "Shpfy Shop";
        EmptyList: List of [BigInteger];
        EmptyErrors: Dictionary of [BigInteger, Text];
    begin
        RevertRequests(BulkOperation, EmptyList, EmptyErrors, 0, Shop, false);
    end;

    local procedure GetLineErrorMessage(JLine: JsonObject; JsonHelper: Codeunit "Shpfy Json Helper") Messages: Text
    var
        JErrors: JsonArray;
        JError: JsonToken;
        ErrorMessage: Text;
    begin
        if JsonHelper.ContainsToken(JLine, 'data.productVariantsBulkUpdate.userErrors') then
            JErrors := JsonHelper.GetJsonArray(JLine, 'data.productVariantsBulkUpdate.userErrors')
        else
            if JsonHelper.ContainsToken(JLine, 'errors') then
                JErrors := JsonHelper.GetJsonArray(JLine, 'errors');

        foreach JError in JErrors do begin
            ErrorMessage := JsonHelper.GetValueAsText(JError, 'message');
            if ErrorMessage <> '' then
                if Messages = '' then
                    Messages := ErrorMessage
                else
                    Messages += '; ' + ErrorMessage;
        end;
    end;

    local procedure GetSkippedReason(var LineErrors: Dictionary of [BigInteger, Text]; LineNumber: BigInteger): Text
    begin
        if LineErrors.ContainsKey(LineNumber) then
            if LineErrors.Get(LineNumber) <> '' then
                exit(StrSubstNo(PriceSyncRevertedWithErrorLbl, LineErrors.Get(LineNumber)));
        exit(PriceSyncRevertedLbl);
    end;

    local procedure GetBCRecordId(ShopifyVariant: Record "Shpfy Variant"): RecordId
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        // Resolve the skipped record back to the linked BC Item Variant (preferred) or Item, so the
        // user sees which product failed. Falls back to the Shopify variant when no BC link exists.
        if (not IsNullGuid(ShopifyVariant."Item Variant SystemId")) and ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId") then
            exit(ItemVariant.RecordId());
        if (not IsNullGuid(ShopifyVariant."Item SystemId")) and Item.GetBySystemId(ShopifyVariant."Item SystemId") then
            exit(Item.RecordId());
        exit(ShopifyVariant.RecordId());
    end;
}