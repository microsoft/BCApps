// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol.SE;

using Microsoft.Peppol;

enumextension 37450 "PEPPOL 3.0 Format SE" extends "PEPPOL 3.0 Format"
{
    value(37450; "PEPPOL 3.0 - SE Sales")
    {
        Caption = 'PEPPOL 3.0 - Sweden Sales Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Sales Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator",
                        "PEPPOL Party Info Provider" = "PEPPOL30 SE Party Info";
    }
    value(37451; "PEPPOL 3.0 - SE Service")
    {
        Caption = 'PEPPOL 3.0 - Sweden Service Format';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Service Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator",
                        "PEPPOL Party Info Provider" = "PEPPOL30 SE Party Info";
    }
}
