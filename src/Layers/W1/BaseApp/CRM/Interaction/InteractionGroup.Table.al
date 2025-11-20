// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

table 5063 "Interaction Group"
{
    Caption = 'Interaction Group';
    DataCaptionFields = "Code", Description;
    DataClassification = CustomerContent;
    LookupPageID = "Interaction Groups";

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
        field(3; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(4; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Interaction Group Code" = field(Code),
                                                               Canceled = const(false),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Interaction Group Code" = field(Code),
                                                                          Canceled = const(false),
                                                                          Date = field("Date Filter"),
                                                                          Postponed = const(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Interaction Group Code" = field(Code),
                                                                               Canceled = const(false),
                                                                               Date = field("Date Filter"),
                                                                               Postponed = const(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
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
}
