// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

codeunit 9901 "Data Upgrade In Progress"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Upgrade Mgt.", 'OnIsUpgradeInProgress', '', false, false)]
    local procedure OnIsUpgradeInProgressHandler(var UpgradeIsInProgress: Boolean)
    begin
        UpgradeIsInProgress := true;
    end;
}

