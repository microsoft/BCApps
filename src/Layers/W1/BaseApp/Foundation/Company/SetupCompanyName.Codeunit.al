// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using System.IO;

codeunit 8624 "Setup Company Name"
{
    TableNo = "Company Information";

    trigger OnRun()
    begin
        Rec.Validate(Name, CompanyName);
        Rec.Validate("Ship-to Name", CompanyName);
        Rec.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Config. Table Processing Rule", 'OnDoesTableHaveCustomRuleInRapidStart', '', false, false)]
    local procedure CheckCompanyInformationOnDoesTableHaveCustomRuleInRapidStart(TableID: Integer; var Result: Boolean)
    begin
        if TableID = DATABASE::"Company Information" then
            Result := true;
    end;
}

