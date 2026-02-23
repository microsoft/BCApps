// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

permissionset 6374 "Avalara Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'Avalara E-Doc. - Read', MaxLength = 30;

    Permissions =
                tabledata "Activation Header" = r,
                tabledata "Activation Mandate" = r,
                tabledata "Avalara Input Field" = r,
                tabledata "Connection Setup" = r,
                tabledata "Media Types" = r,
                tabledata "Message Event" = r,
                tabledata "Message Response Header" = r;
}