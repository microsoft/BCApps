// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

codeunit 31160 "Posted Entries Origin CZ" implements "Intrastat Origin Mode CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    var
        IntrastatPostedSource: Enum "Intrastat Posted Source CZ";
        IntrastatPostedOrigin: Interface "Intrastat Posted Origin CZ";
        SourceTypeOrdinal: Integer;
    begin
        SourceTypeOrdinal := IntrastatReportLine."Source Type".AsInteger();
        if not IntrastatPostedSource.Ordinals().Contains(SourceTypeOrdinal) then
            exit('');
        IntrastatPostedSource := Enum::"Intrastat Posted Source CZ".FromInteger(SourceTypeOrdinal);
        IntrastatPostedOrigin := IntrastatPostedSource;
        exit(IntrastatPostedOrigin.GetCountryOfOriginCode(IntrastatReportLine));
    end;
}
