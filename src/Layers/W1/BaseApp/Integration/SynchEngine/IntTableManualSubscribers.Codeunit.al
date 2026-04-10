// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Inventory.Item;

codeunit 5368 "Int. Table Manual Subscribers"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnValidateBaseUnitOfMeasure', '', false, false)]
    local procedure HandleOnValidateBaseUnitOfMeasure(var ValidateBaseUnitOfMeasure: Boolean)
    begin
        ValidateBaseUnitOfMeasure := true;
    end;
}