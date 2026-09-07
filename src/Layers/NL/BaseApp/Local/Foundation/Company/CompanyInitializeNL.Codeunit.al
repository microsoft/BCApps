// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Bank.Journal;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.AuditCodes;

codeunit 11427 "Company-Initialize NL"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitSetupTables', '', false, false)]
    local procedure InitializeElectronicTaxDeclarationSetup()
    var
        ElecTaxDeclarationSetup: Record "Elec. Tax Declaration Setup";
    begin
        if not ElecTaxDeclarationSetup.FindFirst() then begin
            ElecTaxDeclarationSetup.Init();
            ElecTaxDeclarationSetup.Insert();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnBeforeSourceCodeSetupInsert', '', false, false)]
    local procedure InitializeSourceCodes(var SourceCodeSetup: Record "Source Code Setup")
    var
        CompanyInitialize: Codeunit "Company-Initialize";
    begin
        CompanyInitialize.InsertSourceCode(SourceCodeSetup."Cash Journal", CashJnlTxt, CompanyInitialize.PageName(Page::"Cash Journal"));
        CompanyInitialize.InsertSourceCode(SourceCodeSetup."Bank Journal", BankJnlTxt, CompanyInitialize.PageName(Page::"Bank/Giro Journal"));
    end;

    var
        CashJnlTxt: Label 'CASHJNL';
        BankJnlTxt: Label 'BANKJNL';
}
