// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

enum 404 "Consolidation Method" implements "Consolidation Method"
{
    Extensible = true;
    value(0; Default)
    {
        Implementation = "Consolidation Method" = "Default Consolidation Method";
    }
}
