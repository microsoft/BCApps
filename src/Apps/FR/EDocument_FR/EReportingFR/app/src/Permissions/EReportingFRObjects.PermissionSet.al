// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

permissionset 10970 "E-Reporting FR - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = table "FR E-Invoice Lifecycle" = X,
                  codeunit "FR E-Invoice Lifecycle Mgt." = X,
                  page "FR E-Invoice Lifecycles" = X;
}