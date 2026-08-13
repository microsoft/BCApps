// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

report 1175 "Composite Layout Designs"
{

    UsageCategory = Administration;
    ApplicationArea = All;
    DefaultRenderingLayout = External_default;

    dataset
    {
    }
    requestpage
    {
    }

    rendering
    {/*
        layout(External_Default)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalDefault.docx';
            Caption = 'External Default';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email and fax number. Standard external layout for customer-facing documents.';
        }
        layout(External_Modern)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalModern.docx';
            Caption = 'External Modern';
            Summary = 'Header/footer design for portrait or landscape, modern style without logo. Header with report name, document date and company name in uppercase; footer with page number and full contact/company details (homepage, phone, email, fax, VAT, giro, bank).';
        }
        layout(External_Default_Detailed)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalDefaultDetailed.docx';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Detailed external layout.';

        }
        layout(External_Modern_Logo)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalModernLogo.docx';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Modern external layout.';
            Caption = 'External Modern Logo';
        }
        layout(External_Minimalistic)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalMinimalistic.docx';
            Caption = 'External Minimalistic';
            Summary = 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name only; footer with page number, company name, homepage, phone, email and fax. A clean, light external layout.';
        }
        layout(External_Minimalistic_Centered)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\ExternalMinimalisticCentered.docx';
            Summary = 'Header/footer design for portrait or landscape, minimalist and centred. Header with centred logo, report name and document date; footer with page number, homepage, phone, email, fax and bank/giro/IBAN details.';

        }
        layout(Internal_Default)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\InternalDefault.docx';
            Caption = 'Internal Default';
            Summary = '';
        }
        layout(Internal_Minimalistic_Centered)
        {
            Type = Word;
            SubType = HeaderFooter;
            LayoutFile = '.\Foundation\Reporting\HeaderFooterDesign\InternalMinimalisticCentered.docx';
            Caption = 'Internal Minimalistic Centered';
            Summary = '';
        }

        layout(Default)
        {
            Type = Word;
            SubType = Theme;
            LayoutFile = '.\Foundation\Reporting\ReportTheme\Default.dotx';
            Caption = 'Default Theme';
            Summary = 'Simple and clear, so the details that matter stand out. Styling-only theme: neutral Segoe UI in semibold and regular for hierarchy, dark-grey text on white, calm accent colours, and softly banded table rows. Works for most reports out of the box.';
        }
        layout(Calm)
        {
            Type = Word;
            SubType = Theme;
            LayoutFile = '.\Foundation\Reporting\ReportTheme\Calm.dotx';
            Caption = 'Calm Theme';
            Summary = 'Classic and calm, and easy to read. Styling-only theme: Sitka serif in semibold and regular for hierarchy, with dark-green text on a soft beige background. A timeless look that gives your reports a quieter, more classic feel.';
        }
        layout(Playful)
        {
            Type = Word;
            SubType = Theme;
            LayoutFile = '.\Foundation\Reporting\ReportTheme\Playful.dotx';
            Caption = 'Playful Theme';
            Summary = 'Dynamic and lively, a fresh take on a professional report. Styling-only theme: geometric Bahnschrift in semibold and regular for hierarchy, with backgrounds alternating between green and pink for an energetic, modern feel.';
        }
        */
    }
}