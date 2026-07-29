// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

pageextension 11391 "VAT Statement NL" extends "VAT Statement"
{
    layout
    {
        addafter("Row No.")
        {
            field("Elec. Tax Decl. Category Code"; Rec."Elec. Tax Decl. Category Code")
            {
                ApplicationArea = VAT;
                ToolTip = 'Specifies the electronic tax declaration category that is used to map the VAT Statement Line data to an XML element in the electronic statement.';
            }
        }
        modify("Box No.")
        {
            Visible = false;
        }
    }
}
