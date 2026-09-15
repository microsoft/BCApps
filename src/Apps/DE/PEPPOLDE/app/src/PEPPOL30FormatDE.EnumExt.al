// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.DE;

using Microsoft.Peppol;

enumextension 37400 "PEPPOL 3.0 Format DE" extends "PEPPOL 3.0 Format"
{
    value(37400; "PEPPOL 3.0 - Sales DE")
    {
        Caption = 'PEPPOL 3.0 - Germany Sales Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 DE Sales Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator",
                         "PEPPOL Document Info Provider" = "PEPPOL30 DE Doc Info",
                         "PEPPOL Party Info Provider" = "PEPPOL30 DE Party Info";
    }
    value(37401; "PEPPOL 3.0 - Service DE")
    {
        Caption = 'PEPPOL 3.0 - Germany Service Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 DE Service Validation",
                         "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator",
                         "PEPPOL Document Info Provider" = "PEPPOL30 DE Doc Info",
                         "PEPPOL Party Info Provider" = "PEPPOL30 DE Party Info";
    }
}
