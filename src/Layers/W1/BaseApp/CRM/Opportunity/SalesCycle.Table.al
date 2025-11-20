// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Opportunity;

using Microsoft.CRM.Comment;

table 5090 "Sales Cycle"
{
    Caption = 'Sales Cycle';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Sales Cycles";

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Probability Calculation"; Option)
        {
            Caption = 'Probability Calculation';
            OptionCaption = 'Multiply,Add,Chances of Success %,Completed %';
            OptionMembers = Multiply,Add,"Chances of Success %","Completed %";
        }
        field(4; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(5; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = const(true),
                                                           "Sales Cycle Code" = field(Code),
                                                           "Action Taken" = filter(<> Won & <> Lost),
                                                           "Estimated Close Date" = field("Date Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where(Active = const(true),
                                                                                 "Sales Cycle Code" = field(Code),
                                                                                 "Action Taken" = filter(<> Won & <> Lost),
                                                                                 "Estimated Close Date" = field("Date Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where(Active = const(true),
                                                                                      "Sales Cycle Code" = field(Code),
                                                                                      "Action Taken" = filter(<> Won & <> Lost),
                                                                                      "Estimated Close Date" = field("Date Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const("Sales Cycle"),
                                                                  "No." = field(Code),
                                                                  "Sub No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
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
    begin
        CalcFields("No. of Opportunities");
        TestField("No. of Opportunities", 0);

        SalesCycleStage.SetRange("Sales Cycle Code", Code);
        SalesCycleStage.DeleteAll(true);

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::"Sales Cycle");
        RMCommentLine.SetRange("No.", Code);
        RMCommentLine.DeleteAll();
    end;

    var
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        SalesCycleStage: Record "Sales Cycle Stage";
}
