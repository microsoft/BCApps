// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.WithholdingTax.Employee;

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
            }
            field("Withholding Tax Exempt"; Rec."Withholding Tax Exempt")
            {
                ApplicationArea = Basic, Suite;
            }
            group(WHTCertificateDetails)
            {
                Caption = 'Withholding Tax Certificate';

                field("Withholding Certificate No."; Rec."Withholding Certificate No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Withholding Certificate Type"; Rec."Withholding Certificate Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}
