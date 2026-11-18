// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

codeunit 148138 "Test Origin Mode CZ" implements "Intrastat Origin Mode CZ"
{
    Access = Internal;

    procedure GetCountryOfOriginCode(IntrastatReportLine: Record "Intrastat Report Line"): Code[10]
    var
        TestModeCZTok: Label 'TESTMODE', locked = true;
    begin
        exit(TestModeCZTok);
    end;
}
