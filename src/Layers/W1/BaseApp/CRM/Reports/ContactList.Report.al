// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;

report 5050 "Contact - List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/ContactList.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Contact List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Contact; Contact)
        {
            RequestFilterFields = "No.", "Search Name", Type, "Salesperson Code", "Post Code", "Country/Region Code";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Contact_TABLECAPTION__________ContactFilter; TableCaption + ': ' + ContactFilter)
            {
            }
            column(ShowContactFilter; ContactFilter)
            {
            }
            column(Contact__No__; "No.")
            {
            }
            column(Contact__Cost__LCY__; "Cost (LCY)")
            {
            }
            column(Contact__Estimated_Value__LCY__; "Estimated Value (LCY)")
            {
            }
            column(Contact__Calcd__Current_Value__LCY__; "Calcd. Current Value (LCY)")
            {
            }
            column(Contact__No__of_Opportunities_; "No. of Opportunities")
            {
            }
            column(Contact__Duration__Min___; "Duration (Min.)")
            {
            }
            column(Contact__Next_Task_Date_; Format("Next Task Date"))
            {
            }
            column(Contact_Type; Type)
            {
            }
            column(GroupNo; GroupNo)
            {
            }
            column(ContAddr_1_; ContAddr[1])
            {
            }
            column(ContAddr_2_; ContAddr[2])
            {
            }
            column(ContAddr_3_; ContAddr[3])
            {
            }
            column(ContAddr_4_; ContAddr[4])
            {
            }
            column(ContAddr_5_; ContAddr[5])
            {
            }
            column(ContAddr_6_; ContAddr[6])
            {
            }
            column(ContAddr_7_; ContAddr[7])
            {
            }
            column(ContAddr_8_; ContAddr[8])
            {
            }
            column(Contact___ListCaption; Contact___ListCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(Contact__No__Caption; FieldCaption("No."))
            {
            }
            column(Contact_TypeCaption; FieldCaption(Type))
            {
            }
            column(Contact__Cost__LCY__Caption; FieldCaption("Cost (LCY)"))
            {
            }
            column(Contact__No__of_Opportunities_Caption; FieldCaption("No. of Opportunities"))
            {
            }
            column(Contact__Estimated_Value__LCY__Caption; FieldCaption("Estimated Value (LCY)"))
            {
            }
            column(Contact__Calcd__Current_Value__LCY__Caption; FieldCaption("Calcd. Current Value (LCY)"))
            {
            }
            column(Contact__Duration__Min___Caption; FieldCaption("Duration (Min.)"))
            {
            }
            column(Contact__Next_Task_Date_Caption; Contact__Next_Task_Date_CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.ContactAddr(ContAddr, Contact);
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
        AboutTitle = 'About Contact List';
        AboutText = 'Get list of all your contacts, including related opportunities and to-dos.';

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
        ContactFilter := Contact.GetFilters();

        GroupNo := 1;
        RecPerPageNum := 4;
    end;

    var
        FormatAddr: Codeunit "Format Address";
        ContAddr: array[8] of Text[100];
        ContactFilter: Text;
        GroupNo: Integer;
        Counter: Integer;
        RecPerPageNum: Integer;
        Contact___ListCaptionLbl: Label 'Contact - List';
        PageCaptionLbl: Label 'Page';
        Contact__Next_Task_Date_CaptionLbl: Label 'Next Task Date';
}

