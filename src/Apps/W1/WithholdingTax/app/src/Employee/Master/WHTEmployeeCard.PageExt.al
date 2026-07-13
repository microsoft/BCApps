// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax;

using Microsoft.HumanResources.Employee;

pageextension 6801 "WHT Employee Card" extends "Employee Card"
{
    layout
    {
        addafter("Application Method")
        {
            field("Wthldg. Tax Bus. Post. Group"; Rec."Wthldg. Tax Bus. Post. Group")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the withholding tax business posting group for the employee.';
            }
            field("Withholding Tax Exempt"; Rec."Withholding Tax Exempt")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the employee is exempt from withholding tax.';
            }
            group(WHTCertificateDetails)
            {
                Caption = 'Withholding Tax Certificate';
                ShowCaption = false;
                Visible = false;

                field("Withholding Certificate No."; Rec."Withholding Certificate No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax certificate number for the employee.';
                }
                field("Withholding Certificate Type"; Rec."Withholding Certificate Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the withholding tax certificate type for the employee.';
                }
            }
        }
    }
}
