// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Reports;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;

report 5201 "Employee - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './HumanResources/Reports/EmployeeList.rdlc';
    ApplicationArea = BasicHR;
    Caption = 'Employee List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Employee; Employee)
        {
            RequestFilterFields = "No.", "Search Name", "Global Dimension 1 Code", "Global Dimension 2 Code";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Employee_TABLECAPTION__________EmployeeFilter; TableCaption + ': ' + EmployeeFilter)
            {
            }
            column(EmployeeFilter; EmployeeFilter)
            {
            }
            column(Employee__No__; "No.")
            {
            }
            column(EmployeeAddr_1_; EmployeeAddr[1])
            {
            }
            column(EmployeeAddr_2_; EmployeeAddr[2])
            {
            }
            column(EmployeeAddr_3_; EmployeeAddr[3])
            {
            }
            column(EmployeeAddr_4_; EmployeeAddr[4])
            {
            }
            column(EmployeeAddr_5_; EmployeeAddr[5])
            {
            }
            column(EmployeeAddr_6_; EmployeeAddr[6])
            {
            }
            column(EmployeeAddr_7_; EmployeeAddr[7])
            {
            }
            column(Employee__Emplymt__Contract_Code_; "Emplymt. Contract Code")
            {
            }
            column(Employee__Statistics_Group_Code_; "Statistics Group Code")
            {
            }
            column(Employee__Employment_Date_; Format("Employment Date"))
            {
            }
            column(Employee__Global_Dimension_1_Code_; "Global Dimension 1 Code")
            {
            }
            column(Employee__Global_Dimension_2_Code_; "Global Dimension 2 Code")
            {
            }
            column(Employee__Last_Date_Modified_; Format("Last Date Modified"))
            {
            }
            column(Employee__Mobile_Phone_No__; "Mobile Phone No.")
            {
            }
            column(Employee__E_Mail_; "E-Mail")
            {
            }
            column(Employee__Phone_No__; "Phone No.")
            {
            }
            column(EmployeeAddr_8_; EmployeeAddr[8])
            {
            }
            column(Employee__Alt__Address_Code_; "Alt. Address Code")
            {
            }
            column(Employee_Pager; Pager)
            {
            }
            column(Employee_Extension; Extension)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(Employee___ListCaption; Employee___ListCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Employee__No__Caption; FieldCaption("No."))
            {
            }
            column(Employee__Emplymt__Contract_Code_Caption; FieldCaption("Emplymt. Contract Code"))
            {
            }
            column(Employee__Statistics_Group_Code_Caption; FieldCaption("Statistics Group Code"))
            {
            }
            column(Employee__Employment_Date_Caption; Employee__Employment_Date_CaptionLbl)
            {
            }
            column(Employee__Global_Dimension_1_Code_Caption; CaptionClassTranslate('1,1,1'))
            {
            }
            column(Employee__Global_Dimension_2_Code_Caption; CaptionClassTranslate('1,1,2'))
            {
            }
            column(Employee__Last_Date_Modified_Caption; Employee__Last_Date_Modified_CaptionLbl)
            {
            }
            column(Employee__Alt__Address_Code_Caption; FieldCaption("Alt. Address Code"))
            {
            }
            column(Employee__Mobile_Phone_No__Caption; FieldCaption("Mobile Phone No."))
            {
            }
            column(Employee__E_Mail_Caption; FieldCaption("E-Mail"))
            {
            }
            column(Employee__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Employee_ExtensionCaption; FieldCaption(Extension))
            {
            }
            column(Employee_PagerCaption; FieldCaption(Pager))
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.Employee(EmployeeAddr, Employee);
                if Counter = RecPerPageNum then begin
                    GroupNo := GroupNo + 1;
                    Counter := 0;
                end;
                Counter := Counter + 1;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        EmployeeFilter := Employee.GetFilters();
        Counter := 0;
        GroupNo := 1;
        RecPerPageNum := 2;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        EmployeeFilter: Text;
        EmployeeAddr: array[8] of Text[100];
        Counter: Integer;
        RecPerPageNum: Integer;
        GroupNo: Integer;
        Employee___ListCaptionLbl: Label 'Employee - List';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Employee__Employment_Date_CaptionLbl: Label 'Employment Date';
        Employee__Last_Date_Modified_CaptionLbl: Label 'Last Date Modified';
}

