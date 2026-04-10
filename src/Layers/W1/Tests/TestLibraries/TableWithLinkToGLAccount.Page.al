page 134093 "Table With Link To G/L Account"
{
    PageType = List;
    SourceTable = "Table With Link To G/L Account";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field("Account No."; "Account No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
    }
}

