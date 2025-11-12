#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104045 "Upgrade Cortana Intelligence"
{
    Subtype = Upgrade;
    ObsoleteReason = 'Cortana related fiels have been deleted in version 26.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
}
#endif