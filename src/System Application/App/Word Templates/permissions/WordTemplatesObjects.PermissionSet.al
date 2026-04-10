// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Word;

permissionset 9988 "Word Templates - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Word Template" = X,
                  codeunit "Word Template Custom Field" = X,
                  codeunit "Word Template Field Value" = X,
                  page "Word Templates" = X,
                  page "Word Template Creation Wizard" = X,
                  page "Word Template Selection Wizard" = X,
                  page "Word Template To Text Wizard" = X,
                  table "Word Template" = X;
}
