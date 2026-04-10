namespace System.DateTime;

using System.Utilities;

page 749 "Date Lookup"
{
    Caption = 'Date Lookup';
    PageType = List;
    SourceTable = "Date Lookup Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the time period associated with the date lookup.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        YearFilter: Integer;
    begin
        Rec.CopyFilter("Period Type", Date."Period Type");
        YearFilter := Date2DMY(Today, 3);
        Date.SetRange("Period Start", DMY2Date(1, 1, YearFilter), DMY2Date(30, 12, YearFilter));
        Date.FindSet();
        repeat
            Rec.TransferFields(Date);
            Rec.Insert();
        until Date.Next() = 0;
        Rec.FindFirst();
    end;

    var
        Date: Record Date;
}

