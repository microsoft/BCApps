#pragma warning disable AA0247
page 12445 "Select Reporting Period"
{
    Caption = 'Extern. Report Month Select';
    Editable = false;
    PageType = List;
    SourceTable = Date;
    SourceTableView = sorting("Period Type", "Period Start");

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("FORMAT(""Period End"",0,Text000)"; Format(Rec."Period End", 0, Text000))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                }
                field("FORMAT(""Period Start"",0,Text001)"; Format(Rec."Period Start", 0, Text001))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Specifies the year.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    var
#pragma warning disable AA0074
        Text000: Label '<Month Text>', Locked = true;
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label '<Year4>', Locked = true;
#pragma warning restore AA0074
}

