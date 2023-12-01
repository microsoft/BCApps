// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.DataAdministration;

permissionset 3906 "Retention Policy - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = table "Retention Period" = X,
                  table "Retention Policy Setup" = X,
                  table "Retention Policy Setup Line" = X,
                  codeunit "Apply Retention Policy" = X,
                  codeunit "Reten. Pol. Allowed Tables" = X,
                  codeunit "Retention Policy Log" = X,
                  codeunit "Retention Policy Setup" = X,
                  page "Reten. Policy Setup ListPart" = X,
                  page "Retention Periods" = X,
                  page "Retention Policy Log Entries" = X,
                  page "Retention Policy Setup Card" = X,
                  page "Retention Policy Setup Lines" = X,
                  page "Retention Policy Setup List" = X;
}
