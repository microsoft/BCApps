// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

permissionset 10988 "E-Reporting FR User"
{
    Assignable = true;
    Caption = 'E-Reporting FR - User';

    IncludedPermissionSets = "E-Doc. Core - User";

    Permissions =
        table "FR E-Invoice Message" = X,
        tabledata "FR E-Invoice Message" = R,
        table "FR E-Invoice Message VAT" = X,
        tabledata "FR E-Invoice Message VAT" = R,
        codeunit "FR E-Invoice Message Mgt." = X,
        codeunit "FR E-Invoice Message Builder" = X,
        codeunit "FR E-Invoice Profile Validator" = X,
        codeunit "FR E-Invoice Message API" = X,
        page "FR E-Invoice Refusal Dialog" = X,
        page "FR E-Invoice Messages" = X;
}