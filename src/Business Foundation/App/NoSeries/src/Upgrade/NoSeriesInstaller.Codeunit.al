#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 329 "No. Series Installer"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Upgrade logic is moved to No. Series Upgrade codeunit 328.';
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
}
#endif