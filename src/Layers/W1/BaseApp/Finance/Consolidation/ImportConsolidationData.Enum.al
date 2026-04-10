// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Defines data import methods for consolidation processing from subsidiary companies.
/// Controls how consolidation data is retrieved from business units during consolidation.
/// </summary>
enum 103 "Import Consolidation Data" implements "Import Consolidation Data"
{
    Extensible = true;
    /// <summary>
    /// Imports consolidation data through Business Central API calls to subsidiary companies.
    /// </summary>
    value(0; "Import Consolidation Data from API")
    {
        Implementation = "Import Consolidation Data" = "Import Consolidation from API";
    }
    /// <summary>
    /// Imports consolidation data through direct database connections to subsidiary companies.
    /// </summary>
    value(1; "Import Consolidation Data from DB")
    {
        Implementation = "Import Consolidation Data" = "Import Consolidation from DB";
    }
}
