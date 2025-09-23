pageextension 37200 "Company Information" extends "Company Information"
{
    layout
    {
        addlast(content)
        {
            group("E-Documents")
            {
                Caption = 'E-Documents';
                field("E-Document Format"; Rec."E-Document Format")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}