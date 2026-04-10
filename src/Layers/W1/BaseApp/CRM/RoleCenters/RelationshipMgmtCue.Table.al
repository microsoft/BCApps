// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.RoleCenters;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Document;

table 9063 "Relationship Mgmt. Cue"
{
    Caption = 'Relationship Mgmt. Cue';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; Contacts; Integer)
        {
            CalcFormula = count(Contact);
            Caption = 'Contacts';
            FieldClass = FlowField;
        }
        field(3; Segments; Integer)
        {
            CalcFormula = count("Segment Header");
            Caption = 'Segments';
            FieldClass = FlowField;
        }
        field(4; "Logged Segments"; Integer)
        {
            CalcFormula = count("Logged Segment");
            Caption = 'Logged Segments';
            FieldClass = FlowField;
        }
        field(5; "Open Opportunities"; Integer)
        {
            CalcFormula = count(Opportunity where(Closed = filter(false)));
            Caption = 'Open Opportunities';
            ToolTip = 'Specifies open opportunities.';
            FieldClass = FlowField;
        }
        field(6; "Closed Opportunities"; Integer)
        {
            CalcFormula = count(Opportunity where(Closed = filter(true)));
            Caption = 'Closed Opportunities';
            ToolTip = 'Specifies opportunities that have been closed.';
            FieldClass = FlowField;
        }
        field(7; "Opportunities Due in 7 Days"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = filter(true),
                                                           "Date Closed" = filter(0D),
                                                           "Estimated Close Date" = field("Due Date Filter")));
            Caption = 'Opportunities Due in 7 Days';
            ToolTip = 'Specifies opportunities with a due date in seven days or more.';
            FieldClass = FlowField;
        }
        field(8; "Overdue Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = filter(true),
                                                           "Date Closed" = filter(0D),
                                                           "Estimated Close Date" = field("Overdue Date Filter")));
            Caption = 'Overdue Opportunities';
            ToolTip = 'Specifies opportunities that have exceeded the due date.';
            FieldClass = FlowField;
        }
        field(9; "Sales Cycles"; Integer)
        {
            CalcFormula = count("Sales Cycle");
            Caption = 'Sales Cycles';
            FieldClass = FlowField;
        }
        field(10; "Sales Persons"; Integer)
        {
            CalcFormula = count("Salesperson/Purchaser");
            Caption = 'Sales Persons';
            FieldClass = FlowField;
        }
        field(11; "Contacts - Open Opportunities"; Integer)
        {
            CalcFormula = count(Contact where("No. of Opportunities" = filter(<> 0)));
            Caption = 'Contacts - Open Opportunities';
            FieldClass = FlowField;
        }
        field(12; "Contacts - Companies"; Integer)
        {
            CalcFormula = count(Contact where(Type = const(Company)));
            Caption = 'Contacts - Companies';
            ToolTip = 'Specifies contacts assigned to a company.';
            FieldClass = FlowField;
        }
        field(13; "Contacts - Persons"; Integer)
        {
            CalcFormula = count(Contact where(Type = const(Person)));
            Caption = 'Contacts - Persons';
            ToolTip = 'Specifies contact persons.';
            FieldClass = FlowField;
        }
        field(14; "Contacts - Duplicates"; Integer)
        {
            CalcFormula = count("Contact Duplicate");
            Caption = 'Contacts - Duplicates';
            ToolTip = 'Specifies contacts that have duplicates.';
            FieldClass = FlowField;
        }
        field(18; "Due Date Filter"; Date)
        {
            Caption = 'Due Date Filter';
            FieldClass = FlowFilter;
        }
        field(19; "Overdue Date Filter"; Date)
        {
            Caption = 'Overdue Date Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Open Sales Quotes"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Quote),
                                                      Status = filter(Open)));
            Caption = 'Open Sales Quotes';
            ToolTip = 'Specifies the number of sales quotes that are not yet converted to invoices or orders.';
            FieldClass = FlowField;
        }
        field(21; "Open Sales Orders"; Integer)
        {
            CalcFormula = count("Sales Header" where("Document Type" = filter(Order),
                                                      Status = filter(Open)));
            Caption = 'Open Sales Orders';
            ToolTip = 'Specifies the number of sales orders that are not fully posted.';
            FieldClass = FlowField;
        }
        field(22; "Active Campaigns"; Integer)
        {
            CalcFormula = count(Campaign where(Activated = filter(true)));
            Caption = 'Active Campaigns';
            ToolTip = 'Specifies marketing campaigns that are active.';
            FieldClass = FlowField;
        }
        field(23; "Uninvoiced Bookings"; Integer)
        {
            Caption = 'Uninvoiced Bookings';
            Editable = false;
        }
        field(24; "Coupled Data Synch Errors"; Integer)
        {
            CalcFormula = count("CRM Integration Record" where(Skipped = const(true)));
            Caption = 'Coupled Data Synch Errors';
            ToolTip = 'Specifies the number of errors that occurred in the latest synchronization of coupled data between Business Central and Dynamics 365 Sales.';
            FieldClass = FlowField;
        }
        field(25; "CDS Integration Errors"; Integer)
        {
            CalcFormula = count("Integration Synch. Job Errors");
            Caption = 'Dataverse Integration Errors';
            ToolTip = 'Specifies the number of errors related to data integration.';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

