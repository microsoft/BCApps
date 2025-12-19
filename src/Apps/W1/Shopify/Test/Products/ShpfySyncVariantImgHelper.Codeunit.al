// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

codeunit 139541 "Shpfy Sync Variant Img Helper"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Bulk Operation API", 'OnBeforeUploadJsonl', '', false, false)]
    local procedure HandleOnBeforeUploadJsonl(JsonLData: Text; FileName: Text; ContentType: Text; BulkOperationType: Enum "Shpfy Bulk Operation Type"; var BulkOperationInput: Text; var IsHandled: Boolean)
    var
        VariantMediaImageMutationTok: Label 'mutation productVariantsBulkUpdate($productId: ID!, $variants: [ProductVariantsBulkInput!]!) { productVariantsBulkUpdate(productId: $productId, variants: $variants) { productVariants { id } } }', Locked = true;
    begin
        if BulkOperationType = BulkOperationType::UpdateVariantImage then begin
            BulkOperationInput := VariantMediaImageMutationTok;
            IsHandled := true;
        end;
    end;
}
