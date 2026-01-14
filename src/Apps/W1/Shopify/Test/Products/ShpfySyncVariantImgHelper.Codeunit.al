// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

codeunit 139557 "Shpfy Sync Variant Img Helper"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product API", OnBeforeUploadImage, '', false, false)]
    local procedure OnProductImageUpdated(var IsTestInProgress: Boolean)
    begin
        IsTestInProgress := true;
    end;
}
