// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

codeunit 1807 "Assisted Setup Upgrade"
{
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Guided Experience Item" = r;
    ObsoleteReason = 'Table "Asssited Setup" has been removed in version 26.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    procedure DeleteAssistedSetup()
    begin
    end;

    procedure UpgradeToGuidedExperienceItem()
    begin
    end;
}