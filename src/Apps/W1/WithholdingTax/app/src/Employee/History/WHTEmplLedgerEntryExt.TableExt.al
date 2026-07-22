// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

using Microsoft.HumanResources.Payables;

tableextension 6810 "WHT Empl. Ledger Entry Ext" extends "Employee Ledger Entry"
{
    fields
    {
        field(6784; "Withholding Tax Amount"; Decimal)
        {
            Caption = 'Withholding Tax Amount';
            AutoFormatType = 1;
            Editable = false;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the withholding tax amount for the employee ledger entry.';
        }
        field(6785; "Withholding Tax Base Amount"; Decimal)
        {
            Caption = 'Withholding Tax Base Amount';
            AutoFormatType = 1;
            Editable = false;
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the withholding tax base amount for the employee ledger entry.';
        }
    }
}
