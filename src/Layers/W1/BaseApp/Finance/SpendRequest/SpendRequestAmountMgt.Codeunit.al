// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.SpendRequest;

codeunit 6841 "Spend Request Amount Mgt."
{
    Access = Internal;
    Permissions = tabledata "Spend Request" = m;

    internal procedure ApplyDelta(var SpendRequest: Record "Spend Request"; DeltaLCY: Decimal)
    begin
        SpendRequest.Validate("Total Expected Amount (LCY)", SpendRequest."Total Expected Amount (LCY)" + DeltaLCY);
        SpendRequest.Modify();
    end;
}
