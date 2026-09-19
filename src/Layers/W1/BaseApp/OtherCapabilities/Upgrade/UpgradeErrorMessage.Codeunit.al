// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

#if not CLEAN30
codeunit 104055 "Upgrade - Error Message"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    local procedure UpdateErrorMessageDescription()
    begin
    end;

    local procedure UpdateErrorMessageRegisterDescription()
    begin
    end;
}
#endif