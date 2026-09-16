// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.JsonExchange;

permissionset 20360 "TAX ENGINE JSON EXCHANGE"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Json Exchange';

    Permissions = tabledata "Use Case Archival Log Entry" = RIMD,
                  tabledata "Upgraded Use Cases" = RIMD,
                  tabledata "Tax Type Archival Log Entry" = RIMD;
}
