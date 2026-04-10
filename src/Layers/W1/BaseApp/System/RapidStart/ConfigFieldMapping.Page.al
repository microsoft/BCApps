namespace System.IO;

page 8636 "Config. Field Mapping"
{
    Caption = 'Config. Field Mapping';
    PageType = List;
    SourceTable = "Config. Field Map";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Old Value"; Rec."Old Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the old value in the data that you want to map to new value. Usually, the value is one that is based on an option list.';
                }
                field("New Value"; Rec."New Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value in the data in Business Central to which you want to map the old value. Usually, the value is one that is in an existing option list.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.FilterGroup(2);
        Rec."Package Code" := CopyStr(Rec.GetFilter("Package Code"), 1, MaxStrLen(rec."Package Code"));
        if Evaluate(Rec."Table ID", Rec.GetFilter("Table ID")) then;
        if Evaluate(Rec."Field ID", Rec.GetFilter("Field ID")) then;
        Rec.FilterGroup(0);
    end;
}

