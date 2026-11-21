// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

enum 10045 "XML Schema Version IRIS" implements "IRIS XML Schema"
{
    Extensible = true;
    DefaultImplementation = "IRIS XML Schema" = "Unsupported IRIS Schema";
    UnknownValueImplementation = "IRIS XML Schema" = "Unsupported IRIS Schema";

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "2.0.3")       // tax years 2024 and 2025
    {
        Caption = '2.0.3', Locked = true;
        Implementation = "IRIS XML Schema" = "IRIS Schema 2.0.3";
    }
    value(2; "5.0.7")       // tax years 2025 and 2026
    {
        Caption = '5.0.7', Locked = true;
        Implementation = "IRIS XML Schema" = "IRIS Schema 5.0.7";
    }
}
