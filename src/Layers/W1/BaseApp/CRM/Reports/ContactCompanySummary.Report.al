// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Reports;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Task;
using Microsoft.Foundation.Address;

report 5051 "Contact - Company Summary"
{
    DefaultLayout = RDLC;
    RDLCLayout = './CRM/Reports/ContactCompanySummary.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Contact - Company Summary';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = Contact;

    dataset
    {
        dataitem(Contact; Contact)
        {
            DataItemTableView = sorting("Company No.") where(Type = const(Company));
            RequestFilterFields = "Company No.", "Salesperson Code", "Post Code", "Country/Region Code";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Contact_TABLECAPTION__________ContactFilter; TableCaption + ': ' + ContactFilter)
            {
            }
            column(ContactFilter; ContactFilter)
            {
            }
            column(Contact__Company_No__; "Company No.")
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
            column(Contact__Phone_No__; "Phone No.")
            {
            }
            column(Contact__E_Mail_; "E-Mail")
            {
            }
            column(Contact___Company_SummaryCaption; Contact___Company_SummaryCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Contact__Company_No__Caption; FieldCaption("Company No."))
            {
            }
            column(Contact__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Contact__E_Mail_Caption; FieldCaption("E-Mail"))
            {
            }
            dataitem("<ContactPerson>"; Contact)
            {
                DataItemLink = "Company No." = field("Company No.");
                DataItemTableView = sorting("Company No.") where(Type = filter(Person));
                column(ContactPerson___No__; "No.")
                {
                }
                column(ContactPerson__Name; Name)
                {
                }
                column(ContactPerson___Job_Title_; "Job Title")
                {
                }
                column(ContactPerson___Phone_No__; "Phone No.")
                {
                }
                column(ContactPerson___E_Mail_; "E-Mail")
                {
                }
                column(ContactPerson__NameCaption; FieldCaption(Name))
                {
                }
                column(ContactPerson___No__Caption; FieldCaption("No."))
                {
                }
                column(PersonsCaption; PersonsCaptionLbl)
                {
                }
                column(ContactPerson___Job_Title_Caption; FieldCaption("Job Title"))
                {
                }
                column(ContactPerson___Phone_No__Caption; FieldCaption("Phone No."))
                {
                }
                column(ContactPerson___E_Mail_Caption; FieldCaption("E-Mail"))
                {
                }
            }
            dataitem("To-do"; "To-do")
            {
                DataItemLink = "Contact Company No." = field("Company No.");
                DataItemTableView = sorting("Contact Company No.", "Contact No.", Closed, Date) where("System To-do Type" = const("Contact Attendee"));
                RequestFilterFields = Closed, Date, Type;
                column(Task_Description; Description)
                {
                }
                column(Task_Date; Format(Date))
                {
                }
                column(Task_Status; Status)
                {
                }
                column(Task_Priority; Priority)
                {
                }
                column(Task_Type; Type)
                {
                }
                column(Task__Team_Code_; "Team Code")
                {
                }
                column(Task__Salesperson_Code_; "Salesperson Code")
                {
                }
                column(Task__Contact_No__; "Contact No.")
                {
                }
                column(Task__No__; "No.")
                {
                }
                column(Format_Closed; Format(Closed))
                {
                }
                column(TasksCaption; TasksCaptionLbl)
                {
                }
                column(DateCaption; DateCaptionLbl)
                {
                }
                column(DescriptionCaption; DescriptionCaptionLbl)
                {
                }
                column(TypeCaption; TypeCaptionLbl)
                {
                }
                column(StatusCaption; StatusCaptionLbl)
                {
                }
                column(PriorityCaption; PriorityCaptionLbl)
                {
                }
                column(Team_CodeCaption; Team_CodeCaptionLbl)
                {
                }
                column(Salesperson_CodeCaption; Salesperson_CodeCaptionLbl)
                {
                }
                column(ClosedCaption; ClosedCaptionLbl)
                {
                }
                column(Task__Contact_No__Caption; FieldCaption("Contact No."))
                {
                }
                column(Task__No__Caption; FieldCaption("No."))
                {
                }
            }
            dataitem("<Interaction Log Entry>"; "Interaction Log Entry")
            {
                DataItemLink = "Contact Company No." = field("Company No.");
                DataItemTableView = sorting("Contact Company No.", "Contact No.", Date) where(Postponed = const(false));
                RequestFilterFields = Date, "Interaction Group Code", "Interaction Template Code", "Information Flow", "Initiated By";
                column(Interaction_Log_Entry__Description; Description)
                {
                }
                column(Interaction_Log_Entry___Information_Flow_; "Information Flow")
                {
                }
                column(Interaction_Log_Entry___Initiated_By_; "Initiated By")
                {
                }
                column(Interaction_Log_Entry__Date; Format(Date))
                {
                }
                column(Interaction_Log_Entry___Contact_No__; "Contact No.")
                {
                }
                column(Interaction_Log_Entry___Task_No__; "To-do No.")
                {
                }
                column(Interaction_Log_Entry___Entry_No__; "Entry No.")
                {
                }
                column(Interaction_Log_Entry___Salesperson_Code_; "Salesperson Code")
                {
                }
                column(InteractionsCaption; InteractionsCaptionLbl)
                {
                }
                column(Interaction_Log_Entry__DescriptionCaption; FieldCaption(Description))
                {
                }
                column(Interaction_Log_Entry___Information_Flow_Caption; FieldCaption("Information Flow"))
                {
                }
                column(Interaction_Log_Entry___Initiated_By_Caption; FieldCaption("Initiated By"))
                {
                }
                column(DateCaption_Control88; DateCaption_Control88Lbl)
                {
                }
                column(Interaction_Log_Entry___Contact_No__Caption; FieldCaption("Contact No."))
                {
                }
                column(Interaction_Log_Entry___Task_No__Caption; FieldCaption("To-do No."))
                {
                }
                column(Interaction_Log_Entry___Entry_No__Caption; FieldCaption("Entry No."))
                {
                }
                column(Interaction_Log_Entry___Salesperson_Code_Caption; FieldCaption("Salesperson Code"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddr.ContactAddr(ContAddr, Contact);
            end;
        }
    }

    requestpage
    {
        AboutTitle = 'About Contact - Company Summary';
        AboutText = 'Get an overview of your contact companies, including related interactions and to-dos.';

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
    end;

    var
        FormatAddr: Codeunit "Format Address";
        ContactFilter: Text;
        ContAddr: array[8] of Text[100];
        Contact___Company_SummaryCaptionLbl: Label 'Contact - Company Summary';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        PersonsCaptionLbl: Label 'Persons';
        TasksCaptionLbl: Label 'Tasks';
        DateCaptionLbl: Label 'Date';
        DescriptionCaptionLbl: Label 'Description';
        TypeCaptionLbl: Label 'Type';
        StatusCaptionLbl: Label 'Status';
        PriorityCaptionLbl: Label 'Priority';
        Team_CodeCaptionLbl: Label 'Team Code';
        Salesperson_CodeCaptionLbl: Label 'Salesperson Code';
        ClosedCaptionLbl: Label 'Closed';
        InteractionsCaptionLbl: Label 'Interactions';
        DateCaption_Control88Lbl: Label 'Date';
}

