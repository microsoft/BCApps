#if not CLEAN26
#pragma warning disable AS0072 // Obsolete permission set
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;


/// <summary>
/// Obsolete permission set granting edit access to Avalara tables. Replaced by permission set 6373 "Avalara Edit".
/// </summary>
permissionset 6372 Edit
{
    Access = Public;
    Assignable = true;
    Caption = 'Avalara E-Document Connector - Edit';
    IncludedPermissionSets = "Avalara Read";
    ObsoleteReason = 'This permission set is obsolete. Use Avalara Edit permission set instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    Permissions =
                tabledata "Activation Header" = imd,
                tabledata "Activation Mandate" = imd,
                tabledata "Avalara Input Field" = imd,
                tabledata "Avl Message Event" = imd,
                tabledata "Avl Message Response Header" = imd,
                tabledata "Connection Setup" = imd,
                tabledata "Media Types" = imd;
}

#pragma warning restore AS0072 // Obsolete permission set
#endif