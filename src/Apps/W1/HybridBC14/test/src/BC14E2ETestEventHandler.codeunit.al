// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14;

codeunit 148145 "BC14 E2E Test Event Handler"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Management", 'OnCreateSessionForUpgrade', '', false, false)]
    local procedure HandleOnCreateSessionForUpgrade(var CreateSession: Boolean)
    begin
        CreateSession := false;
    end;
}
