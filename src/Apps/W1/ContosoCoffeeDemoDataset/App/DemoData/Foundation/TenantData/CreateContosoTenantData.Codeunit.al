// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AS0018

namespace Microsoft.DemoData.Foundation;


codeunit 5691 "Create Contoso Tenant Data"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    EventSubscriberInstance = Manual;
    Description = 'Populate App Database, only run in the gate after generating Contoso Demo Data.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to internal app';
    ObsoleteTag = '27.0';
}
#pragma warning restore AS0018