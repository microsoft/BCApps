// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Grants read access to all Avalara E-Document connector tables.
/// </summary>
permissionset 6374 "Avalara Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'Avalara E-Doc. - Read', MaxLength = 30;

    Permissions =
                tabledata "Activation Header" = r,
                tabledata "Activation Mandate" = r,
                tabledata "Avalara Input Field" = r,
                tabledata "Avl Message Event" = r,
                tabledata "Avl Message Response Header" = r,
                tabledata "Connection Setup" = r,
                tabledata "Media Types" = r;
}