// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

permissionset 10971 "E-Reporting FR - Read"
{
    Access = Public;
    Assignable = true;
    Caption = 'E-Reporting FR - Read';

    Permissions = tabledata "FR E-Invoice Lifecycle" = R,
                  tabledata "FR E-Invoice Lifecycle VAT" = R;
}