#if not CLEAN26
#pragma warning disable AS0072 // Obsolete permission set
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Obsolete permission set granting read access to Avalara tables. Replaced by permission set 6374 "Avalara Read".
/// </summary>
permissionset 6371 Read
{
    Access = Public;
    Assignable = true;
    Caption = 'Avalara E-Document Connector - Read';
    ObsoleteReason = 'This permission set is obsolete. Use Avalara Read permission set instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    Permissions =
                tabledata "Activation Header" = r,
                tabledata "Activation Mandate" = r,
                tabledata "Avalara Input Field" = r,
                tabledata "Avl Message Event" = r,
                tabledata "Avl Message Response Header" = r,
                tabledata "Connection Setup" = r,
                tabledata "Media Types" = r;
}
#pragma warning restore AS0072 // Obsolete permission set
#endif