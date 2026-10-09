// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
enum 50115 "Report Filename Criterion"
{
    // Which of a pattern's criteria a document does not meet, in the order naming checks them,
    // so that Test Pattern can say why a pattern does not apply instead of guessing. None means
    // the pattern applies.

    // Not extensible: an internal enum cannot be reached by another extension, so declaring
    // it extensible would promise something impossible.
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
