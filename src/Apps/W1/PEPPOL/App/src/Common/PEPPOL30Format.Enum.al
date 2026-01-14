// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

enum 37200 "PEPPOL 3.0 Format" implements "PEPPOL Attachment Provider",
                                            "PEPPOL Delivery Info Provider",
                                            "PEPPOL Document Info Provider",
                                            "PEPPOL Line Info Provider",
                                            "PEPPOL Monetary Info Provider",
                                            "PEPPOL Party Info Provider",
                                            "PEPPOL Payment Info Provider",
                                            "PEPPOL Posted Document Iterator",
                                            "PEPPOL Tax Info Provider",
                                            "PEPPOL30 Validation"
{
    DefaultImplementation = "PEPPOL Attachment Provider" = "PEPPOL30",
                            "PEPPOL Delivery Info Provider" = "PEPPOL30",
                            "PEPPOL Document Info Provider" = "PEPPOL30",
                            "PEPPOL Line Info Provider" = "PEPPOL30",
                            "PEPPOL Monetary Info Provider" = "PEPPOL30",
                            "PEPPOL Party Info Provider" = "PEPPOL30",
                            "PEPPOL Payment Info Provider" = "PEPPOL30",
                            "PEPPOL Tax Info Provider" = "PEPPOL30";
    Extensible = true;

    value(0; "PEPPOL 3.0 - Sales")
    {
        Caption = 'PEPPOL 3.0 - Sales';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Sales Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Sales Iterator";
    }
    value(1; "PEPPOL 3.0 - Service")
    {
        Caption = 'PEPPOL 3.0 - Service';
        Implementation = "PEPPOL30 Validation" = "PEPPOL30 Service Validation",
                        "PEPPOL Posted Document Iterator" = "PEPPOL30 Services Iterator";
    }
}