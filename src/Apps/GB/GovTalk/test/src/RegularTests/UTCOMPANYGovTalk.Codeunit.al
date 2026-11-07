// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

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

}

