// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.euBP;

using Microsoft.Finance.AuditFileExport;

enumextension 6542 "Audit File Export Format euBP" extends "Audit File Export Format"
{
    value(6542; euBP)
    {
        Caption = 'euBP';
        Implementation = "Audit File Export Data Handling" = "euBP Data Handling",
                         "Audit File Export Data Check" = "euBP Data Check";
    }
}
