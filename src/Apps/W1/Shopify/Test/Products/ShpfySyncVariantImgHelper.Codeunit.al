// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.Environment;

codeunit 139557 "Shpfy Sync Variant Img Helper"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product API", OnBeforeUploadImage, '', false, false)]
    local procedure OnBeforeUploadImage(var TenantMedia: Record "Tenant Media"; var ResourceUrl: Text)
    begin
        // Clear TenantMedia so that UploadImage skips the HTTP PUT call.
        // The TryFunction will return true (no error), allowing the flow to continue
        // to SetVariantImage which is handled by the test's HttpClientHandler.
        Clear(TenantMedia);
    end;
}
