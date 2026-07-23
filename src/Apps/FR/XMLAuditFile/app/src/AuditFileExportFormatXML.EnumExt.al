// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

enumextension 10803 "Audit File Export Format XML" extends "Audit File Export Format"
{
    value(10803; "GL Entries XML FR")
    {
        Caption = 'GL Entries XML FR';
        Implementation = "Audit File Export Data Handling" = "Data Handling XML",
                         "Audit File Export Data Check" = "Data Check XML",
                         "Audit File Export Page Visibility" = "Page Visibility XML";
    }
}
