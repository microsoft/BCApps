// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Team;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Task;

table 5083 Team
{
    Caption = 'Team';
    DataCaptionFields = "Code", Name;
    DataClassification = CustomerContent;
    DrillDownPageID = Teams;
    LookupPageID = Teams;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(3; "Next Task Date"; Date)
        {
            CalcFormula = min("To-do".Date where("Team Code" = field(Code),
                                                  Closed = const(false)));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(6; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact where(Type = const(Company));
        }
        field(7; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(8; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(9; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(11; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(12; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(13; "Task Entry Exists"; Boolean)
        {
            CalcFormula = exist("To-do" where("Team Code" = field(Code),
                                               "Contact No." = field("Contact Filter"),
                                               "Contact Company No." = field("Contact Company Filter"),
                                               "Salesperson Code" = field("Salesperson Filter"),
                                               "Campaign No." = field("Campaign Filter"),
                                               Status = field("Task Status Filter"),
                                               Closed = field("Task Closed Filter"),
                                               Priority = field("Priority Filter"),
                                               Date = field("Date Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TeamSalesperson: Record "Team Salesperson";
    begin
        TeamSalesperson.Reset();
        TeamSalesperson.SetRange("Team Code", Code);
        TeamSalesperson.DeleteAll();
    end;
}

