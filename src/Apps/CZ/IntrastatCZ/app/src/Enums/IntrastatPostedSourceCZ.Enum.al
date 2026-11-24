// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

/// <summary>
/// Maps the values of the "Intrastat Report Source Type" enum (by ordinal) to the implementation
/// that reads the country/region of origin from the posted entry.
/// To support a new source type, extend both enums with a value using the same ordinal.
/// </summary>
enum 31303 "Intrastat Posted Source CZ" implements "Intrastat Posted Origin CZ"
{
    Extensible = true;
    DefaultImplementation = "Intrastat Posted Origin CZ" = "No Posted Origin CZ";

    value(1; "Item Entry")
    {
        Caption = 'Item Entry';
        Implementation = "Intrastat Posted Origin CZ" = "Item Entry Origin CZ";
    }
    value(2; "Job Entry")
    {
        Caption = 'Job Entry';
        Implementation = "Intrastat Posted Origin CZ" = "Job Entry Origin CZ";
    }
}
