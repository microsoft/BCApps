// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.TaxEngine.TaxTypeHandler;

permissionset 20232 "TAX ENGINE TAX TYPE HANDLER"
{
    Access = Public;
    Assignable = true;
    Caption = 'Tax Engine Tax Type Handler';

    Permissions = tabledata "Entity Attribute Mapping" = RIMD,
                  tabledata "Record Attribute Mapping" = RIMD,
                  tabledata "Tax Attribute Value Mapping" = RIMD,
                  tabledata "Tax Component" = RIMD,
                  tabledata "Tax Acc. Period Setup" = RIMD,
                  tabledata "Tax Entity" = RIMD,
                  tabledata "Tax Type" = RIMD,
                  tabledata "Tax Transaction Value" = RIMD,
                  tabledata "Tax Attribute" = RIMD,
                  tabledata "Tax Attribute Value" = RIMD,
                  tabledata "Tax Rate" = RIMD,
                  tabledata "Tax Rate Column Setup" = RIMD,
                  tabledata "Tax Rate Value" = RIMD;
}
