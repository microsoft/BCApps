// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

codeunit 148137 "Test Posted Origin CZ" implements "Intrastat Posted Origin CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    var
        TestCZTok: Label 'TESTCZ', locked = true;
    begin
        exit(TestCZTok);
    end;
}
