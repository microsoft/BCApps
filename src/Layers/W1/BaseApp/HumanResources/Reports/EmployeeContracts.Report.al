// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;

report 5212 "Employee - Contracts"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeContracts.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee Contracts';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Employment Contract"; "Employment Contract")
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employment_Contract__TABLECAPTION__________EmploymentContractFilter; TableCaption + ': ' + EmploymentContractFilter)
            {
            }
            column(EmploymentContractFilter; EmploymentContractFilter)
            {
            }
            column(Employment_Contract_Code; Code)
            {
            }
            column(Employment_Contract_Description; Description)
            {
            }
            column(Employee___ContractsCaption; Employee___ContractsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Full_NameCaption; Full_NameCaptionLbl)
            {
            }
            column(Employee__No__Caption; Employee.FieldCaption("No."))
            {
            }
            dataitem(Employee; Employee)
            {
                DataItemLink = "Emplymt. Contract Code" = field(Code);
                DataItemTableView = sorting(Status, "Emplymt. Contract Code");
                column(Employee__No__; "No.")
                {
                }
                column(FullName; FullName())
                {
                }
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        EmploymentContractFilter := "Employment Contract".GetFilters();
    end;

    var
        EmploymentContractFilter: Text;
        Employee___ContractsCaptionLbl: Label 'Employee - Contracts';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Full_NameCaptionLbl: Label 'Full Name';
}

