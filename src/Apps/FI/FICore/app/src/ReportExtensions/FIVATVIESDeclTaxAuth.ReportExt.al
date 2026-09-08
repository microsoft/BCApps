// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

reportextension 13412 "FI VAT VIES Decl. Tax Auth" extends "VAT- VIES Declaration Tax Auth"
{
    rendering
    {
        layout("VAT VIES Declaration FI")
        {
            Type = RDLC;
            LayoutFile = './src/ReportExtensions/Layouts/VATVIESDeclarationTaxAuth.rdlc';
            Caption = 'VAT VIES Declaration FI (RDLC)';
            Summary = 'The VAT VIES Declaration FI layout includes Finnish company information.';
        }
    }
}