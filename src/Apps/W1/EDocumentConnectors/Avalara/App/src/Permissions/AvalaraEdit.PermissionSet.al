// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

permissionset 6373 "Avalara Edit"
{
    Access = Public;
    Assignable = true;
    Caption = 'Avalara E-Doc. - Edit', MaxLength = 30;
    IncludedPermissionSets = "Avalara Read";

    Permissions =
                tabledata "Activation Header" = imd,
                tabledata "Activation Mandate" = imd,
                tabledata "Avalara Input Field" = imd,
                tabledata "Connection Setup" = imd,
                tabledata "Media Types" = imd,
                tabledata "Message Event" = imd,
                tabledata "Message Response Header" = imd;
}