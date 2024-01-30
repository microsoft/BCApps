// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Text;

permissionset 2010 "Entity Text - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions = codeunit "Entity Text" = X,
                  table "Entity Text" = X,
#if not CLEAN24
#pragma warning disable AL0432
                  table "Azure OpenAi Settings" = X,
                  page "Azure OpenAi Settings" = X,
                  page "Copilot Information" = X,
                  page "Entity Text Part" = X,
                  page "Entity Text" = X,
#pragma warning restore AL0432
#endif
                  page "Entity Text Factbox Part" = X;
}