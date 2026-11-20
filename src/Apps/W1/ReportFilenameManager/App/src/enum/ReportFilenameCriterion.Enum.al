// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

enum 8130 "Report Filename Criterion"
{
    // The first pattern criterion a document fails, in the order naming checks them, so Test
    // Pattern can say why a pattern does not apply. None means the pattern applies.

    Extensible = false;
    Caption = 'Report Filename Criterion';
    Access = Internal;

    value(0; None)
    {
        Caption = 'None';
    }
    value(1; "File Name Pattern")
    {
        Caption = 'File Name Pattern';
    }
    value(2; Report)
    {
        Caption = 'Report';
    }
    value(3; "Table")
    {
        Caption = 'Table';
    }
    value(4; "Output Route")
    {
        Caption = 'Output Route';
    }
    value(5; Language)
    {
        Caption = 'Language';
    }
    value(6; "Table Filter")
    {
        Caption = 'Table Filter';
    }
}
