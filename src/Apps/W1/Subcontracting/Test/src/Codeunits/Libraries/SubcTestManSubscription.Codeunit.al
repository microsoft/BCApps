// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Subcontracting;

codeunit 139985 "Subc. Test Man. Subscription"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Subc. Purchase Order Creator", OnBeforeShowCreatedPurchaseOrder, '', false, false)]
    local procedure OnBeforeShowCreatedPurchaseOrder(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}