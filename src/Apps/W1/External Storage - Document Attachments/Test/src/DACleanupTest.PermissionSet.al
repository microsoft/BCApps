// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

permissionset 136820 "DA Cleanup Test"
{
    Assignable = true;
    Caption = 'DA Cleanup Test', MaxLength = 30;
    Permissions = table "DA Cleanup Media Owner" = X,
                  tabledata "DA Cleanup Media Owner" = RIMD;
}
