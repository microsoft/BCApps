#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

codeunit 99001569 "Subc. Feature Flag Handler"
{
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    ObsoleteReason = 'Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App so this codeunit will be removed in a future release.';

    [Obsolete('Legacy Subcontracting will be discontinued, environments should move to the Subcontracting App so this codeunit will be removed in a future release.', '29.0')]
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