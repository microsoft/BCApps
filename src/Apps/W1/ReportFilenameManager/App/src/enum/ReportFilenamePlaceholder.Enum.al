// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50113 "Report Filename Placeholder" implements "Report Filename Placeholder"
{
    // The computed values a pattern can use. Extensible on purpose: this is the enum section 5
    // of the design names as the extension point, so a partner adds a value by extending this
    // and shipping one codeunit, without touching anything here.

    Extensible = true;
    Caption = 'Report Filename Placeholder';
    // Public: extensible means an extension adds values, which requires reaching it.
    Access = Public;

    value(0; CompanyPrefix)
    {
        // The value's name stays CompanyPrefix: it is the identifier an extension writes, and
        // it is what the saved binding records. Only the caption is corrected, because what
        // this hands over is the whole company name rather than a prefix of anything.
        Caption = 'Your Company Name';
        Implementation = "Report Filename Placeholder" = "Report Filename Company Plh.";
    }
    value(1; Created)
    {
        Caption = 'Report Run Date';
        Implementation = "Report Filename Placeholder" = "Report Filename Created Plh.";
    }
    value(2; UserId)
    {
        Caption = 'Report Run By';
        Implementation = "Report Filename Placeholder" = "Report Filename User Plh.";
    }
    value(3; ReportName)
    {
        // Report Name, the caption the Report Inbox and Report Selections give the same value.
        Caption = 'Report Name';
        Implementation = "Report Filename Placeholder" = "Report Filename Report Plh.";
    }
    value(4; TotalInclVat)
    {
        Caption = 'Total Incl. VAT';
        Implementation = "Report Filename Placeholder" = "Report Filename Total Plh.";
    }
    value(5; KindOfDocument)
    {
        // Not Document Type. That is a field on the unposted Sales Header, and a posted invoice
        // has none - so borrowing the name would promise a field the record does not carry.
        // Kind of Document says what the value is: what Business Central calls this kind of
        // document, in the document's own language.
        Caption = 'Kind of Document';
        Implementation = "Report Filename Placeholder" = "Report Filename Doc. Kind Plh.";
    }
    value(6; Period)
    {
        // Report 25's own caption for the same value ("Period", and "Period Ending").
        Caption = 'Period';
        Implementation = "Report Filename Placeholder" = "Report Filename Period Plh.";
    }
}
