// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

enum 103 "Import Consolidation Data" implements "Import Consolidation Data"
{
    Extensible = true;
    value(0; "Import Consolidation Data from API")
    {
        Implementation = "Import Consolidation Data" = "Import Consolidation from API";
    }
    value(1; "Import Consolidation Data from DB")
    {
        Implementation = "Import Consolidation Data" = "Import Consolidation from DB";
    }
}
