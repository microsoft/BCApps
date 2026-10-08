namespace System.Visualization;

using System.Reflection;

table 9183 "Generic Chart Query Column"
{
    Caption = 'Generic Chart Query Column';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Query No."; Integer)
        {
            Caption = 'Query No.';
        }
        field(2; "Query Column No."; Integer)
        {
            Caption = 'Query Column No.';
        }
        field(3; "Column Name"; Text[50])
        {
            Caption = 'Column Name';
        }
        field(4; "Column Data Type"; Option)
        {
            Caption = 'Column Data Type';
            OptionCaption = 'Date,Time,DateFormula,Decimal,Text,Code,Binary,Boolean,Integer,Option,BigInteger,DateTime';
            OptionMembers = Date,Time,DateFormula,Decimal,Text,"Code",Binary,Boolean,"Integer",Option,BigInteger,DateTime;
        }
        field(5; "Column Type"; Option)
        {
            Caption = 'Column Type';
            OptionCaption = 'Filter Column,Column';
            OptionMembers = "Filter Column",Column;
        }
        field(6; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(7; "Aggregation Type"; Option)
        {
            Caption = 'Aggregation Type';
            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
            OptionMembers = "None","Count","Sum","Min","Max",Avg;
        }
    }

    keys
    {
        key(Key1; "Query No.", "Query Column No.", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        NoneAggrTypeTok: Label 'NONE', Comment = 'NONE';
        CountAggrTypeTok: Label 'COUNT', Comment = 'COUNT';
        SumAggrTypeTok: Label 'SUM', Comment = 'SUM';
        MinAggrTypeTok: Label 'MIN', Comment = 'MIN';
        MaxAggrTypeTok: Label 'MAX', Comment = 'MAX';
        AverageAggrTypeTok: Label 'AVERAGE', Comment = 'AVERAGE';

    procedure SetAggregationType(InputTxt: Text)
    begin
        case UpperCase(InputTxt) of
            NoneAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::None;
            CountAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::Count;
            SumAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::Sum;
            MinAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::Min;
            MaxAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::Max;
            AverageAggrTypeTok:
                "Aggregation Type" := "Aggregation Type"::Avg;
        end;
    end;

    procedure SetColumnDataType(FieldType: Option)
    var
        "Field": Record "Field";
    begin
        case FieldType of
            Field.Type::Date:
                "Column Data Type" := "Column Data Type"::Date;
            Field.Type::Time:
                "Column Data Type" := "Column Data Type"::Time;
            Field.Type::DateFormula:
                "Column Data Type" := "Column Data Type"::DateFormula;
            Field.Type::Decimal:
                "Column Data Type" := "Column Data Type"::Decimal;
            Field.Type::Text:
                "Column Data Type" := "Column Data Type"::Text;
            Field.Type::Code:
                "Column Data Type" := "Column Data Type"::Code;
            Field.Type::Binary:
                "Column Data Type" := "Column Data Type"::Binary;
            Field.Type::Boolean:
                "Column Data Type" := "Column Data Type"::Boolean;
            Field.Type::Integer:
                "Column Data Type" := "Column Data Type"::Integer;
            Field.Type::Option:
                "Column Data Type" := "Column Data Type"::Option;
            Field.Type::BigInteger:
                "Column Data Type" := "Column Data Type"::BigInteger;
            Field.Type::DateTime:
                "Column Data Type" := "Column Data Type"::DateTime;
        end;
    end;
}

