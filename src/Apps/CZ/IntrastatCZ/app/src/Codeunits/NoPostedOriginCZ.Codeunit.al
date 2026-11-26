// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

codeunit 31165 "No Posted Origin CZ" implements "Intrastat Posted Origin CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    begin
        exit('');
    end;
}
