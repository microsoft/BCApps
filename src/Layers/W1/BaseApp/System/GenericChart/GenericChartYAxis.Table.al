namespace System.Visualization;

table 9182 "Generic Chart Y-Axis"
{
    Caption = 'Generic Chart Y-Axis';
    DataClassification = CustomerContent;

    fields
    {
        field(2; ID; Code[20])
        {
            Caption = 'ID';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Y-Axis Measure Field ID"; Integer)
        {
            Caption = 'Y-Axis Measure Field ID';
        }
        field(11; "Y-Axis Measure Field Name"; Text[50])
        {
            Caption = 'Y-Axis Measure Field Name';
        }
        field(12; "Measure Operator"; Option)
        {
            Caption = 'Measure Operator';
            OptionCaption = 'Sum,Count';
            OptionMembers = "Sum","Count";
        }
        field(13; "Y-Axis Measure Field Caption"; Text[250])
        {
            Caption = 'Y-Axis Measure Field Caption';
        }
        field(20; "Show Title"; Boolean)
        {
            Caption = 'Show Title';
        }
        field(21; Aggregation; Option)
        {
            Caption = 'Aggregation';
            OptionCaption = 'None,Count,Sum,Min,Max,Avg';
            OptionMembers = "None","Count","Sum","Min","Max",Avg;
        }
        field(22; "Chart Type"; Option)
        {
            Caption = 'Chart Type';
            OptionCaption = 'Column,Point,Line,ColumnStacked,ColumnStacked100,Area,AreaStacked,AreaStacked100,StepLine,Pie,Doughnut,Range,Radar,Funnel';
            OptionMembers = Column,Point,Line,ColumnStacked,ColumnStacked100,"Area",AreaStacked,AreaStacked100,StepLine,Pie,Doughnut,Range,Radar,Funnel;
        }
    }

    keys
    {
        key(Key1; ID, "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        TestField("Y-Axis Measure Field ID");
    end;
}

