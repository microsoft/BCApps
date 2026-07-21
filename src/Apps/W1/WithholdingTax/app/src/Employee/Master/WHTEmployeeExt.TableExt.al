// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.HumanResources.Employee;

tableextension 6809 "WHT Employee Ext" extends Employee
{
    fields
    {
        field(6784; "Wthldg. Tax Bus. Post. Group"; Code[20])
        {
            Caption = 'Withholding Tax Bus. Post. Group';
            TableRelation = "Wthldg. Tax Bus. Post. Group";
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the withholding tax business posting group for the employee.';
        }
        field(6785; "Withholding Certificate No."; Code[20])
        {
            Caption = 'Withholding Tax Certificate No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the withholding tax certificate number for the employee.';
        }
        field(6786; "Withholding Certificate Type"; Code[20])
        {
            Caption = 'Withholding Tax Certificate Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the withholding tax certificate type for the employee.';
        }
        field(6787; "Withholding Tax Exempt"; Boolean)
        {
            Caption = 'Withholding Tax Exempt';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies if the employee is exempt from withholding tax.';
        }
    }
}
