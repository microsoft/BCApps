// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

enumextension 37301 "NA PEPPOL 3.0 Format" extends "PEPPOL 3.0 Format"
{
    value(100; "NA PEPPOL 3.0 - Sales")
    {
        Caption = 'NA PEPPOL 3.0 - Sales';
        Implementation = "PEPPOL Line Info Provider" = "NA PEPPOL Line Info Provider",
                        "PEPPOL30 Validation" = "PEPPOL30 Sales Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator";
    }
    value(101; "NA PEPPOL 3.0 - Service")
    {
        Caption = 'NA PEPPOL 3.0 - Service';
        Implementation = "PEPPOL Line Info Provider" = "NA PEPPOL Line Info Provider",
                        "PEPPOL30 Validation" = "PEPPOL30 Service Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator";
    }
}
