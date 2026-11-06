// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

interface "Intrastat Origin Mode CZ"
{
    /// <summary>
    /// Returns the country/region of origin code for the Intrastat report line according to the mode selected in the Intrastat Report Setup.
    /// </summary>
    /// <param name="IntrastatReportLine">Intrastat report line the country/region of origin code is determined for.</param>
    /// <returns>Country/region of origin code or blank if the standard logic should determine it.</returns>
    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10];
}
