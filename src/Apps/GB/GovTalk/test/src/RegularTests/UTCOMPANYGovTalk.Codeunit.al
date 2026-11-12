// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Company;

codeunit 144036 "UTCOMPANY GovTalk"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure BranchNumberExistOnCompanyInformationPage()
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationPage: TestPage "Company Information";
        BranchNumberValue: Text;
    begin
        BranchNumberValue := '009'; // This is a valid two-digit branch number for GB.
        CompanyInformationPage.OpenEdit();
        CompanyInformationPage."Branch Number GB".SetValue(BranchNumberValue);
        CompanyInformationPage.Close();
        CompanyInformation.Get();
        CompanyInformation.TestField("Branch Number GB", BranchNumberValue);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateBranchNumberThreeDigitNumericAndEmptyCompanyInformationTable()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Purpose of the test is to validate the On Validate trigger of the Branch Number field on Company Information Table.

        // Enter three digit value in Branch Number
        CompanyInformation.Validate("Branch Number GB", Format(LibraryRandom.RandIntInRange(100, 999)));
        CompanyInformation.Modify();

        // Verify: Verify that Branch Number field is able to blank on Company Information Table.
        CompanyInformation.Get();
        CompanyInformation.Validate("Branch Number GB", '');
        CompanyInformation.Modify();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsSkipsCalculatedLineStatus()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
    begin
        GovTalkHelperProcedures.TransferFields(
            Database::"ECSL VAT Report Line", ECSLVATReportLine.FieldNo("Line Status GB"), ECSLVATReportLine.FieldNo("Line Status GB"));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TransferFieldsCopiesGuidValuesIncludingEmptyGuid()
    var
        GovTalkSetup: Record "Gov Talk Setup";
        GovTalkHelperProcedures: Codeunit "GovTalk Helper Procedures";
        SourceGuid: Guid;
    begin
        GovTalkSetup.DeleteAll();
        SourceGuid := CreateGuid();
        GovTalkSetup.Init();
        GovTalkSetup.Id := 'GUID';
        GovTalkSetup.Password := SourceGuid;
        GovTalkSetup.Insert();
        GovTalkSetup.Init();
        GovTalkSetup.Id := 'EMPTY';
        GovTalkSetup."Vendor ID" := CreateGuid();
        GovTalkSetup.Insert();

        GovTalkHelperProcedures.TransferFields(
            Database::"Gov Talk Setup", GovTalkSetup.FieldNo(Password), GovTalkSetup.FieldNo("Vendor ID"));

        GovTalkSetup.Get('GUID');
        GovTalkSetup.TestField("Vendor ID", SourceGuid);
        GovTalkSetup.Get('EMPTY');
        GovTalkSetup.TestField("Vendor ID", GovTalkSetup.Password);
    end;

}

