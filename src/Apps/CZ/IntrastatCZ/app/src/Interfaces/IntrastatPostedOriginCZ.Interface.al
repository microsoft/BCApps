// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

interface "Intrastat Posted Origin CZ"
{
    /// <summary>
    /// Returns the country/region of origin code stored in the posted entry the Intrastat report line was created from.
    /// </summary>
    /// <param name="IntrastatReportLine">Intrastat report line referencing the posted entry.</param>
    /// <returns>Country/region of origin code or blank if the posted entry does not provide one.</returns>
    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10];
}
