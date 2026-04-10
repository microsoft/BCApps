#pragma warning disable AA0247
page 26577 "Create Acc. Schedule"
{
    Caption = 'Create Acc. Schedule';
    PageType = Card;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ReportCode; ReportCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Report Code';
                    Editable = false;
                }
                field(TableName; TableName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Table Code';
                    Editable = false;
                }
                field(AccSchedName; AccSchedName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Acc. Schedule Name';
                    TableRelation = "Acc. Schedule Name";
                }
                field(ColumnLayoutName; ColumnLayoutName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Layout Name';
                    TableRelation = "Column Layout Name";
                    ToolTip = 'Specifies the name of the column layout that you want to use in the window.';
                }
                field(ReplaceExistLines; ReplaceExistLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Replace Existing Lines';
                }
            }
        }
    }

    actions
    {
    }

    var
        StatutoryReportTable: Record "Statutory Report Table";
        AccScheduleName: Record "Acc. Schedule Name";
        AccSchedName: Code[10];
        ColumnLayoutName: Code[10];
        ReportCode: Code[20];
        TableName: Code[20];
        ReplaceExistLines: Boolean;

    [Scope('OnPrem')]
    procedure SetParameters(NewReportCode: Code[20]; NewTableName: Code[20])
    begin
        ReportCode := NewReportCode;
        TableName := NewTableName;

        StatutoryReportTable.Get(ReportCode, TableName);
        if StatutoryReportTable."Int. Source Type" = StatutoryReportTable."Int. Source Type"::"Acc. Schedule" then begin
            StatutoryReportTable.TestField("Int. Source No.");
            AccScheduleName.Get(StatutoryReportTable."Int. Source No.");
            AccSchedName := AccScheduleName.Name;
            ColumnLayoutName := StatutoryReportTable."Int. Source Col. Name";
        end;
    end;

    [Scope('OnPrem')]
    procedure GetParameters(var NewAccScheduleName: Code[10]; var NewColumnLayoutName: Code[10]; var NewReplExistLines: Boolean)
    begin
        NewAccScheduleName := AccSchedName;
        NewColumnLayoutName := ColumnLayoutName;
        NewReplExistLines := ReplaceExistLines;
    end;
}

