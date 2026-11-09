// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8128 "Report Filename Placeholder" implements "Report Filename Placeholder"
{
    // The computed values a pattern can use. Extension point: a partner adds a value by
    // extending this enum and shipping one codeunit implementing the interface.

    Extensible = true;
    Caption = 'Report Filename Placeholder';
    Access = Public;

    value(0; CompanyPrefix)
    {
        // Despite the name, the value is the whole company name. Bindings record the canonical
        // name 'Your Company Name', not this value name.
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
        Caption = 'Kind of Document';
        Implementation = "Report Filename Placeholder" = "Report Filename Doc. Kind Plh.";
    }
    value(6; Period)
    {
        Caption = 'Period';
        Implementation = "Report Filename Placeholder" = "Report Filename Period Plh.";
    }
}
