// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Task;

table 5091 "Sales Cycle Stage"
{
    Caption = 'Sales Cycle Stage';
    DataCaptionFields = "Sales Cycle Code", Stage, Description;
    DataClassification = CustomerContent;
    LookupPageID = "Sales Cycle Stages";

    fields
    {
        field(1; "Sales Cycle Code"; Code[10])
        {
            Caption = 'Sales Cycle Code';
            NotBlank = true;
            TableRelation = "Sales Cycle";
        }
        field(2; Stage; Integer)
        {
            BlankZero = true;
            Caption = 'Stage';
            ToolTip = 'Specifies the number of the stage within the sales cycle.';
            MinValue = 1;
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the sales cycle stage.';
        }
        field(4; "Completed %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed %';
            ToolTip = 'Specifies the percentage of the sales cycle that has been completed when the opportunity reaches this stage.';
            DecimalPlaces = 0 : 0;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5; "Activity Code"; Code[10])
        {
            Caption = 'Activity Code';
            ToolTip = 'Specifies the code of the activity linked to this sales cycle stage (if there is one).';
            TableRelation = Activity;
        }
        field(6; "Quote Required"; Boolean)
        {
            Caption = 'Quote Required';
            ToolTip = 'Specifies that a quote is required at this stage before the opportunity can move to the next stage in the sales cycle.';
        }
        field(7; "Allow Skip"; Boolean)
        {
            Caption = 'Allow Skip';
            ToolTip = 'Specifies that it is possible to skip this stage and move the opportunity to the next stage.';
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const("Sales Cycle Stage"),
                                                                  "No." = field("Sales Cycle Code"),
                                                                  "Sub No." = field(Stage)));
            Caption = 'Comment';
            ToolTip = 'Specifies that comments exist for this sales cycle stage.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = const(true),
                                                           "Sales Cycle Code" = field("Sales Cycle Code"),
                                                           "Sales Cycle Stage" = field(Stage),
                                                           "Estimated Close Date" = field("Date Filter")));
            Caption = 'No. of Opportunities';
            ToolTip = 'Specifies the number of opportunities that are currently at this stage in the sales cycle. This field is not editable.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where(Active = const(true),
                                                                                 "Sales Cycle Code" = field("Sales Cycle Code"),
                                                                                 "Sales Cycle Stage" = field(Stage),
                                                                                 "Estimated Close Date" = field("Date Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where(Active = const(true),
                                                                                      "Sales Cycle Code" = field("Sales Cycle Code"),
                                                                                      "Sales Cycle Stage" = field(Stage),
                                                                                      "Estimated Close Date" = field("Date Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Average No. of Days"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = average("Opportunity Entry"."Days Open" where(Active = const(false),
                                                                         "Sales Cycle Code" = field("Sales Cycle Code"),
                                                                         "Sales Cycle Stage" = field(Stage),
                                                                         "Estimated Close Date" = field("Date Filter")));
            Caption = 'Average No. of Days';
            ToolTip = 'Specifies the average number of days the opportunities have remained at this stage of the sales cycle. This field is not editable.';
            DecimalPlaces = 0 : 2;
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Date Formula"; DateFormula)
        {
            Caption = 'Date Formula';
            ToolTip = 'Specifies how dates for planned activities are calculated when you run the Opportunity - Details report.';
        }
        field(15; "Chances of Success %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success %';
            ToolTip = 'Specifies the percentage of success that has been achieved when the opportunity reaches this stage.';
            MaxValue = 100;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Sales Cycle Code", Stage)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        OppEntry: Record "Opportunity Entry";
    begin
        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"Sales Cycle Stage");
        RMCommentLine.SetRange("No.", "Sales Cycle Code");
        RMCommentLine.SetRange("Sub No.", Stage);
        RMCommentLine.DeleteAll();

        OppEntry.SetRange(Active, true);
        OppEntry.SetRange("Sales Cycle Code", "Sales Cycle Code");
        OppEntry.SetRange("Sales Cycle Stage", Stage);
        if not OppEntry.IsEmpty() then
            Error(Text000);
    end;

    var
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";

#pragma warning disable AA0074
        Text000: Label 'You cannot delete a stage which has active entries.';
#pragma warning restore AA0074
}
