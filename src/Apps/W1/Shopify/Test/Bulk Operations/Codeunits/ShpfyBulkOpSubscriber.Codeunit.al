// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

codeunit 139615 "Shpfy Bulk Op. Subscriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Bulk Operation Mgt.", 'OnInvalidUser', '', true, false)]
    local procedure OnInvalidUser(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}
