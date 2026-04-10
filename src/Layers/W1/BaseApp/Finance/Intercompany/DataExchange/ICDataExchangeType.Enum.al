// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Defines the available data exchange mechanisms for intercompany communication.
/// Determines how intercompany data is transmitted and synchronized between partner companies.
/// </summary>
enum 532 "IC Data Exchange Type" implements "IC Data Exchange"
{
    Extensible = false;
    /// <summary>
    /// Direct database connectivity for intercompany data exchange between companies in the same database.
    /// </summary>
    value(0; Database)
    {
        Implementation = "IC Data Exchange" = "IC Data Exchange Database";
    }
    /// <summary>
    /// API-based data exchange for intercompany communication across different systems and databases.
    /// </summary>
    value(1; API)
    {
        Implementation = "IC Data Exchange" = "IC Data Exchange API";
    }
}
