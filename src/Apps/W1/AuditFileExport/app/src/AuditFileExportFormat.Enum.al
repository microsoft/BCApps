// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

enum 5262 "Audit File Export Format" implements "Audit File Export Data Handling", "Audit File Export Data Check", "Audit File Export Page Visibility"
{
    Extensible = true;
    DefaultImplementation = "Audit File Export Data Handling" = "Audit File Data Handling",
                         "Audit File Export Data Check" = "Audit File Data Check",
                         "Audit File Export Page Visibility" = "Audit File Page Visibility";

    value(0; None)
    {
        Caption = 'None';
        Implementation = "Audit File Export Data Handling" = "Audit File Data Handling",
                         "Audit File Export Data Check" = "Audit File Data Check",
                         "Audit File Export Page Visibility" = "Audit File Page Visibility";
    }
}
