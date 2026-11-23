// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

codeunit 31159 "Item Card Origin CZ" implements "Intrastat Origin Mode CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    begin
        exit('');
    end;
}
