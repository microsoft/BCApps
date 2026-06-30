#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

codeunit 99001569 "Subc. Feature Flag Handler"
{
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
    ObsoleteReason = 'This codeunit is a temporary transition guard for the migration from Legacy Subcontracting to the Subcontracting App. It will be removed once the Legacy Subcontracting field and all related conditional compilation blocks are cleaned up.';

    [Obsolete('This codeunit is a temporary transition guard for the migration from Legacy Subcontracting to the Subcontracting App. It will be removed once the Legacy Subcontracting field and all related conditional compilation blocks are cleaned up.', '28.0')]
    procedure IsSubcontractingEnabled(): Boolean
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.SetLoadFields("Legacy Subcontracting");
        if not ManufacturingSetup.Get() then
            exit(false);
        exit(not ManufacturingSetup."Legacy Subcontracting");
    end;
}
#endif