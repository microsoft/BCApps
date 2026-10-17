// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.UseCaseBuilder;

permissionset 20283 "TAX ENGINE USE CASE"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Use Case Builder';

    Permissions = tabledata "Switch Case" = RIMD,
                  tabledata "Switch Statement" = RIMD,
                  tabledata "Tax Component Expression" = RIMD,
                  tabledata "Tax Component Expr. Token" = RIMD,
                  tabledata "Tax Table Relation" = RIMD,
                  tabledata "Use Case Tree Node" = RIMD,
                  tabledata "Tax Component Summary" = RIMD,
                  tabledata "Tax Use Case" = RIMD,
                  tabledata "Use Case Attribute Mapping" = RIMD,
                  tabledata "Use Case Component Calculation" = RIMD,
                  tabledata "Use Case Rate Column Relation" = RIMD;
}
