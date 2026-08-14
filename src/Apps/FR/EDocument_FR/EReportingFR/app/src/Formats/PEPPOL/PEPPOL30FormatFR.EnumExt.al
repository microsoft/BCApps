// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.Peppol;

enumextension 10995 "PEPPOL 3.0 Format FR" extends "PEPPOL 3.0 Format"
{
    value(10979; "PEPPOL 3.0 - Sales FR")
    {
        Caption = 'PEPPOL 3.0 - France Sales Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 FR Sales Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator";
    }
    value(10980; "PEPPOL 3.0 - Service FR")
    {
        Caption = 'PEPPOL 3.0 - France Service Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 FR Service Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator";
    }
}