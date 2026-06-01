// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Setup;

codeunit 99001569 "Subc. Feature Flag Handler"
{
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
