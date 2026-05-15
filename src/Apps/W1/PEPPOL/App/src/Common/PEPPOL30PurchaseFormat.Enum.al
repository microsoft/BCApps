// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

enum 37201 "PEPPOL 3.0 Purchase Format" implements "PEPPOL Purchase Attachment Provider",
                                                    "PEPPOL Purchase Delivery Info Provider",
                                                    "PEPPOL Purchase Document Info Provider",
                                                    "PEPPOL Purchase Line Info Provider",
                                                    "PEPPOL Purchase Monetary Info Provider",
                                                    "PEPPOL Purchase Party Info Provider",
                                                    "PEPPOL Purchase Payment Info Provider",
                                                    "PEPPOL Purchase Tax Info Provider"
{
    DefaultImplementation = "PEPPOL Purchase Attachment Provider" = "PEPPOL30",
                            "PEPPOL Purchase Delivery Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Document Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Line Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Monetary Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Party Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Payment Info Provider" = "PEPPOL30",
                            "PEPPOL Purchase Tax Info Provider" = "PEPPOL30";
    Extensible = true;

    value(0; "PEPPOL 3.0 - Purchase Order")
    {
        Caption = 'PEPPOL 3.0 - Purchase Order';
    }
}
