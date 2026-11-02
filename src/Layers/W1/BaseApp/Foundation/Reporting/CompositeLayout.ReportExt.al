//------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Administration.Reports;

reportextension 9666 "Composite Layout" extends "Tenant Report Defaults"
{
    rendering
    {
        layout("DefaultTheme")
        {
            Caption = 'Default Theme';
            LayoutFile = 'Foundation\Reporting\ReportParts\ReportTheme\Default.dotx';
            Type = Word;
            Subtype = Theme;
            Summary = 'Simple and clear, so the details that matter stand out. Styling-only theme: neutral Segoe UI in semibold and regular for hierarchy, dark-grey text on white, calm accent colours, and softly banded table rows. Works for most reports out of the box.';
        }

        layout("ExternalDefaultHFDesign")
        {
            Caption = 'External Default';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalDefault.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email and fax number. Standard external layout for customer-facing documents.';
        }

        layout("ExternalDefaultDetailedHFDesign")
        {
            Caption = 'External Default Detailed';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalDefaultDetailed.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Detailed external layout.';
        }

        layout("ExternalMinimalisticHFDesign")
        {
            Caption = 'External Minimalistic';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalMinimalistic.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name only; footer with page number, company name, homepage, phone, email and fax. A clean, light external layout.';
        }

        layout("ExternalMinimalisticDetailedHFDesign")
        {
            Caption = 'External Minimalistic Detailed';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalMinimalisticDetailed.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name; footer with page number, company name, homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no.';
        }

        layout("ExternalModernHFDesign")
        {
            Caption = 'External Modern';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalModern.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, modern style without logo. Header with report name, document date and company name in uppercase; footer with page number and full contact details (homepage, phone, email, fax, VAT, giro, bank).';
        }

        layout("ExternalModernLogoHFDesign")
        {
            Caption = 'External Modern Logo';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\ExternalModernLogo.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Modern external layout.';
        }

        layout("InternalDefaultHFDesign")
        {
            Caption = 'Internal Default';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\InternalDefault.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, for internal documents. Header with company logo, report name and document date; footer with page number.';
        }

        layout("InternalMinimalisticCenteredHFDesign")
        {
            Caption = 'Internal Minimalistic Centered';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\InternalMinimalisticCentered.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, minimalist and centred, for internal documents. Header with centred logo, report name and document date; footer with page number.';
        }

        layout("InternalMinimalisticHFDesign")
        {
            Caption = 'Internal Minimalistic';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\InternalMinimalistic.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, minimalistic, for internal documents. Header with report name and document date; footer with page number.';
        }

        layout("InternalModernHFDesign")
        {
            Caption = 'Internal Modern';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\InternalModern.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, modern style, for internal documents. Header with company logo, report name and document date; footer with page number.';
        }

        layout("InternalModernMaxiHFDesign")
        {
            Caption = 'Internal Modern Maxi';
            LayoutFile = 'Foundation\Reporting\ReportParts\HeaderFooterDesign\InternalModernMaxi.docx';
            Type = Word;
            Subtype = HeaderFooter;
            Summary = 'Header/footer design for portrait or landscape, modern style with a large header, for internal documents. Header with company logo, report name and document date; footer with page number.';
        }

        layout("CalmTheme")
        {
            Caption = 'Calm';
            LayoutFile = 'Foundation\Reporting\ReportParts\ReportTheme\Calm.dotx';
            Type = Word;
            Subtype = Theme;
            Summary = 'Classic and calm, and easy to read. Styling-only theme: Sitka serif in semibold and regular for hierarchy, with dark-green text on a soft beige background. A timeless look that gives your reports a quieter, more classic feel.';
        }

        layout("PlayfulTheme")
        {
            Caption = 'Playful';
            LayoutFile = 'Foundation\Reporting\ReportParts\ReportTheme\Playful.dotx';
            Type = Word;
            Subtype = Theme;
            Summary = 'Dynamic and lively, a fresh take on a professional report. Styling-only theme: geometric Bahnschrift in semibold and regular for hierarchy, with backgrounds alternating between green and pink for an energetic, modern feel.';
        }
    }
}