// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.HumanResources.Payables;

tableextension 6810 "WHT Empl. Ledger Entry Ext" extends "Employee Ledger Entry"
{
    fields
    {
        field(6784; "WHT Amount"; Decimal)
        {
            Caption = 'WHT Amount';
            AutoFormatType = 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(6785; "WHT Base Amount"; Decimal)
        {
            Caption = 'WHT Base Amount';
            AutoFormatType = 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}
