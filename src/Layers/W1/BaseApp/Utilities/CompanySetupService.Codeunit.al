// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Foundation.Company;

codeunit 1801 "Company Setup Service"
{

    trigger OnRun()
    begin
    end;

    procedure ConfigureCompany(Name: Text[50]; Address: Text[50]; Address2: Text[50]; City: Text[30]; County: Text[30]; PostCode: Code[20]; CountryCode: Code[10]; PhoneNo: Text[30]): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.LockTable();
        if not CompanyInformation.Get() then
            CompanyInformation.Insert();
        CompanyInformation.Name := Name;
        CompanyInformation.Address := Address;
        CompanyInformation."Address 2" := Address2;
        CompanyInformation.City := City;
        CompanyInformation.County := County;
        CompanyInformation."Post Code" := PostCode;
        CompanyInformation."Country/Region Code" := CountryCode;
        CompanyInformation."Phone No." := PhoneNo;
        exit(CompanyInformation.Modify());
    end;
}

