reportextension 104903 CompositeLayoutDesigns extends "Tenant Report Defaults"
{

    rendering
    {
        layout(External_Default)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalDefault.docx';
            Caption = 'External Default';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email and fax number. Standard external layout for customer-facing documents.';
        }
        layout(External_Modern)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalModern.docx';
            Caption = 'External Modern';
            Summary = 'Header/footer design for portrait or landscape, modern style without logo. Header with report name, document date and company name in uppercase; footer with page number and full contact/company details (homepage, phone, email, fax, VAT, giro, bank).';
        }
        layout(External_Default_Detailed)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalDefaultDetailed.docx';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Detailed external layout.';

        }
        layout(External_Modern_Detailed)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalModernDetailed.docx';
            Summary = 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Modern external layout.';
        }
        layout(External_Minimalistic)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalMinimalistic.docx';
            Caption = 'External Minimalistic';
            Summary = 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name only; footer with page number, company name, homepage, phone, email and fax. A clean, light external layout.';
        }
        layout(External_Minimalistic_Centered)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\ExternalMinimalisticCentered.docx';
            Summary = 'Header/footer design for portrait or landscape, minimalist and centred. Header with centred logo, report name and document date; footer with page number, homepage, phone, email, fax and bank/giro/IBAN details.';

        }
        layout(Internal_Default)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = '.\Foundation\Reports\HeaderFooterDesign\InternalDefault.docx';
            Caption = 'Internal Default';
            Summary = '';
        }
        layout(Default)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = '.\Foundation\Reports\ReportTheme\Default.dotx';
            Caption = 'Default Theme';
            Summary = '';
        }
        layout(Calm)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = '.\Foundation\Reports\ReportTheme\Calm.dotx';
            Caption = 'Calm Theme';
            Summary = '';
        }
        layout(Playful)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = '.\Foundation\Reports\ReportTheme\Playful.dotx';
            Caption = 'Playful Theme';
            Summary = '';
        }
    }
}