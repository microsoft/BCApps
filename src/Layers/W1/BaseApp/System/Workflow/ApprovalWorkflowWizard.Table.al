namespace System.Automation;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Reflection;
using System.Security.User;

table 1804 "Approval Workflow Wizard"
{
    Caption = 'Approval Workflow Wizard';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";
        }
        field(3; "Sales Invoice App. Workflow"; Boolean)
        {
            Caption = 'Sales Invoice App. Workflow';
        }
        field(4; "Sales Amount Approval Limit"; Integer)
        {
            Caption = 'Sales Amount Approval Limit';
            MinValue = 0;
        }
        field(5; "Purch Invoice App. Workflow"; Boolean)
        {
            Caption = 'Purch Invoice App. Workflow';
        }
        field(6; "Purch Amount Approval Limit"; Integer)
        {
            Caption = 'Purch Amount Approval Limit';
            MinValue = 0;
        }
        field(7; "Use Exist. Approval User Setup"; Boolean)
        {
            Caption = 'Use Exist. Approval User Setup';
        }
        field(10; "Field"; Integer)
        {
            Caption = 'Field';
            TableRelation = Field."No." where(TableNo = const(18));
        }
        field(11; TableNo; Integer)
        {
            Caption = 'TableNo';
        }
        field(12; "Field Caption"; Text[250])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field(TableNo),
                                                              "No." = field(Field)));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
        field(13; "Custom Message"; Text[250])
        {
            Caption = 'Custom Message';
        }
        field(14; "App. Trigger"; Option)
        {
            Caption = 'App. Trigger';
            OptionCaption = 'The user sends an approval requests manually,The user changes a specific field';
            OptionMembers = "The user sends an approval requests manually","The user changes a specific field";
        }
        field(15; "Field Operator"; Option)
        {
            Caption = 'Field Operator';
            OptionCaption = 'Increased,Decreased,Changed';
            OptionMembers = Increased,Decreased,Changed;
        }
        field(38; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name;
        }
        field(39; "For All Batches"; Boolean)
        {
            Caption = 'For All Batches';
        }
        field(40; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
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

