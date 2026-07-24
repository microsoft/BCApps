// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

pageextension 11361 "Company Information NL" extends "Company Information"
{
    layout
    {
        addafter("Industrial Classification")
        {
            field("Fiscal Entity No."; Rec."Fiscal Entity No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the fiscal entity number is the VAT number assigned to a group of companies to report one consolidated VAT declaration.';
            }
        }
        modify("EORI Number")
        {
            Visible = true;
        }
    }
}

