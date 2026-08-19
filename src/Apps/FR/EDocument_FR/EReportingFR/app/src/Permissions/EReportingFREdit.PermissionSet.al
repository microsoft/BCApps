// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

permissionset 10972 "E-Reporting FR Edit"
{
    Access = Public;
    Assignable = true;
    Caption = 'E-Reporting FR - Edit';

    IncludedPermissionSets = "E-Reporting FR Read";

    Permissions = tabledata "FR E-Invoice Lifecycle" = im,
                  tabledata "FR E-Invoice Lifecycle VAT" = i,
                  tabledata "FR E-Invoice Lifecycle Resp." = ri,
                  tabledata "FR E-Invoice Buyer Response" = rim,
                  codeunit "FR E-Invoice Lifecycle Import" = X,
                  codeunit "FR E-Inv. Buyer Resp. Mgt." = X,
                  codeunit "FR E-Invoice Lifecycle Worker" = X,
                  codeunit "FR E-Invoice Lifecycle Error" = X,
                  codeunit "FR E-Invoice Lifecycle Mgt." = X;
}