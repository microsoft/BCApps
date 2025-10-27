// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

enum 37200 "E-Document Format" implements "PEPPOL Attachment Handler"
                                            , "PEPPOL Delivery Info Provider"
                                            , "PEPPOL Document Info Provider"
                                           , "PEPPOL Line Info Provider"
                                            , "PEPPOL Monetary Info Provider"
                                            , "PEPPOL Party Info Provider"
                                            , "PEPPOL Payment Info Provider"
                                            , "PEPPOL Posted Document Iterator"
                                            , "PEPPOL Tax Info Provider"
                                            , "PEPPOL30 Validation"
{
    DefaultImplementation = "PEPPOL Attachment Handler" = "PEPPOL30 Management"
                            , "PEPPOL Delivery Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Document Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Line Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Monetary Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Party Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Payment Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL Posted Document Iterator" = "PEPPOL30 Management"
                            , "PEPPOL Tax Info Provider" = "PEPPOL30 Management"
                            , "PEPPOL30 Validation" = "PEPPOL30 Validation";
    Extensible = true;

    value(0; "PEPPOL 3.0")
    {
        Caption = 'PEPPOL 3.0';
    }
}