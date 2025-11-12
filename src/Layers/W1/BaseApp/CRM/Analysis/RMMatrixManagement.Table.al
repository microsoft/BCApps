// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;

table 5102 "RM Matrix Management"
{
    Caption = 'RM Matrix Management';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Company Name"; Text[50])
        {
            Caption = 'Company Name';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; Type; Enum "Contact Type")
        {
            Caption = 'Type';
        }
        field(5; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = const(true),
                                                           "Salesperson Code" = field("Salesperson Filter"),
                                                           "Campaign No." = field("Campaign Filter"),
                                                           "Contact No." = field("Contact Filter"),
                                                           "Contact Company No." = field("Contact Company Filter"),
                                                           "Estimated Close Date" = field("Date Filter"),
                                                           "Action Taken" = field("Action Taken Filter"),
                                                           "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                           "Probability %" = field("Probability % Filter"),
                                                           "Completed %" = field("Completed % Filter"),
                                                           "Chances of Success %" = field("Chances of Success % Filter"),
                                                           "Close Opportunity Code" = field("Close Opportunity Filter"),
                                                           "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                           "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where(Active = const(true),
                                                                                 "Salesperson Code" = field("Salesperson Filter"),
                                                                                 "Campaign No." = field("Campaign Filter"),
                                                                                 "Contact No." = field("Contact Filter"),
                                                                                 "Contact Company No." = field("Contact Company Filter"),
                                                                                 "Estimated Close Date" = field("Date Filter"),
                                                                                 "Action Taken" = field("Action Taken Filter"),
                                                                                 "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                 "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                 "Probability %" = field("Probability % Filter"),
                                                                                 "Completed %" = field("Completed % Filter"),
                                                                                 "Chances of Success %" = field("Chances of Success % Filter"),
                                                                                 "Close Opportunity Code" = field("Close Opportunity Filter"),
                                                                                 "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                                                 "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where(Active = const(true),
                                                                                      "Salesperson Code" = field("Salesperson Filter"),
                                                                                      "Campaign No." = field("Campaign Filter"),
                                                                                      "Contact No." = field("Contact Filter"),
                                                                                      "Contact Company No." = field("Contact Company Filter"),
                                                                                      "Estimated Close Date" = field("Date Filter"),
                                                                                      "Action Taken" = field("Action Taken Filter"),
                                                                                      "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                      "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                      "Probability %" = field("Probability % Filter"),
                                                                                      "Completed %" = field("Completed % Filter"),
                                                                                      "Chances of Success %" = field("Chances of Success % Filter"),
                                                                                      "Close Opportunity Code" = field("Close Opportunity Filter"),
                                                                                      "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                                                      "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Avg. Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = average("Opportunity Entry"."Estimated Value (LCY)" where(Active = const(true),
                                                                                     "Salesperson Code" = field("Salesperson Filter"),
                                                                                     "Campaign No." = field("Campaign Filter"),
                                                                                     "Contact No." = field("Contact Filter"),
                                                                                     "Contact Company No." = field("Contact Company Filter"),
                                                                                     "Estimated Close Date" = field("Date Filter"),
                                                                                     "Action Taken" = field("Action Taken Filter"),
                                                                                     "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                     "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                     "Probability %" = field("Probability % Filter"),
                                                                                     "Completed %" = field("Completed % Filter"),
                                                                                     "Chances of Success %" = field("Chances of Success % Filter"),
                                                                                     "Close Opportunity Code" = field("Close Opportunity Filter"),
                                                                                     "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                                                     "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter")));
            Caption = 'Avg. Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Avg.Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = average("Opportunity Entry"."Calcd. Current Value (LCY)" where(Active = const(true),
                                                                                          "Salesperson Code" = field("Salesperson Filter"),
                                                                                          "Campaign No." = field("Campaign Filter"),
                                                                                          "Contact No." = field("Contact Filter"),
                                                                                          "Contact Company No." = field("Contact Company Filter"),
                                                                                          "Estimated Close Date" = field("Date Filter"),
                                                                                          "Action Taken" = field("Action Taken Filter"),
                                                                                          "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                                                          "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                                                          "Probability %" = field("Probability % Filter"),
                                                                                          "Completed %" = field("Completed % Filter"),
                                                                                          "Close Opportunity Code" = field("Close Opportunity Filter"),
                                                                                          "Chances of Success %" = field("Chances of Success % Filter"),
                                                                                          "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                                                          "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter")));
            Caption = 'Avg.Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(11; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(12; "Contact Filter"; Code[20])
        {
            Caption = 'Contact Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Action Taken Filter"; Enum "Opportunity Action Taken")
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
        }
        field(15; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(16; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Filter"));
        }
        field(17; "Probability % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(18; "Completed % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(19; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact where(Type = const(Company));
        }
        field(20; "Contact Company Filter"; Code[20])
        {
            Caption = 'Contact Company Filter';
            FieldClass = FlowFilter;
            TableRelation = Contact where(Type = const(Company));
        }
        field(21; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(23; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(24; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(25; "No. of Tasks"; Integer)
        {
            CalcFormula = count("To-do" where(Date = field("Date Filter"),
                                               "Salesperson Code" = field("Salesperson Filter"),
                                               "Team Code" = field("Team Filter"),
                                               "Campaign No." = field("Campaign Filter"),
                                               "Contact No." = field("Contact Filter"),
                                               "Contact Company No." = field("Contact Company Filter"),
                                               Status = field("Task Status Filter"),
                                               Closed = field("Task Closed Filter"),
                                               Priority = field("Priority Filter"),
                                               "System To-do Type" = field("System Task Type Filter")));
            Caption = 'No. of Tasks';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Estimated Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(27; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(28; "Chances of Success % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(29; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(30; "System Task Type Filter"; Option)
        {
            Caption = 'System Task Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Organizer,Salesperson Attendee,Contact Attendee,Team';
            OptionMembers = Organizer,"Salesperson Attendee","Contact Attendee",Team;
        }
    }

    keys
    {
        key(Key1; "Company Name", Type, Name, "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
