// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

enum 11003 "Data Export File Encoding"
{
    Extensible = true;

    value(0; UTF8)
    {
        Caption = 'UTF8';
    }
    value(1; UTF7)
    {
        Caption = 'UTF7';
    }
    value(2; UTF16)
    {
        Caption = 'UTF16';
    }
    value(3; ANSI)
    {
        Caption = 'ANSI';
    }
    value(4; Macintosh)
    {
        Caption = 'Macintosh';
    }
    value(5; OEM)
    {
        Caption = 'OEM';
    }
}
