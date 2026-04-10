// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.DataAdministration;

/// <summary>
/// The values in this enum represent the pages in the Data Administration Guide page
/// </summary>

enum 9041 "Data Administration Guide Page"
{
    Extensible = true;
    Access = Public;
    Caption = 'Data Administration Guide Page';

    /// <summary>
    /// this value should not be used.
    /// </summary>
    value(0; Blank)
    {
        Caption = 'Blank';
    }

    /// <summary>
    /// This value is used to identify the introduction page.
    /// </summary>
    value(1; Introduction)
    {
        Caption = 'Introduction';
    }

    /// <summary>
    /// This value is used to identify the retention policy introduction page.
    /// </summary>
    value(2; RetenPolIntro)
    {
        Caption = 'Retention Policy Introduction';
    }

    /// <summary>
    /// This value is used to identify the companies introduction page.
    /// </summary>
    value(3; CompaniesIntro)
    {
        Caption = 'Companies Introduction';
    }

    /// <summary>
    /// This value is used to identify the date compression introduction page.
    /// </summary>
    value(4; DateCompressionIntro)
    {
        Caption = 'Date Compression Intro';
    }

    /// <summary>
    /// This value is used to identify the date compression entries selection page.
    /// </summary>
    value(5; DateCompressionSelection)
    {
        Caption = 'Date Compression Entries Selection';
    }

    /// <summary>
    /// This value is used to identify the date compression options page.
    /// </summary>
    value(6; DateCompressionOptions)
    {
        Caption = 'Date Compression Options';
    }

    /// <summary>
    /// This value is used to identify the second date compression options selection page.
    /// </summary>
    value(7; DateCompressionOptions2)
    {
        Caption = 'Date Compression Options 2';
    }

    /// <summary>
    /// This value is used to identify the run date compression page.
    /// </summary>
    value(8; DateCompressionRun)
    {
        Caption = 'Run Date Compression';
    }

    /// <summary>
    /// This value is used to identify the date compression results page.
    /// </summary>
    value(9; DateCompressionResult)
    {
        Caption = 'Date Compression Result';
    }

    /// <summary>
    /// This value is used to identify the conclusion page.
    /// </summary>
    value(10; Conclusion)
    {
        Caption = 'Conclusion';
    }
}