namespace Microsoft.Sample.Loyalty;

page 50102 "Loyalty Member List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Loyalty Member";
    CardPageId = "Loyalty Member Card";
    Caption = 'Loyalty Members';

    layout
    {
        area(Content)
        {
            repeater(Members)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the member.';
                }
                field("Member Name"; Rec."Member Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the member.';
                }
                field("Loyalty Tier"; Rec."Loyalty Tier")
                {
                    ApplicationArea = All;
                    StyleExpr = TierStyle;
                    ToolTip = 'Specifies the loyalty tier of the member.';
                }
                field("Points Balance"; Rec."Points Balance")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current points balance.';
                }
            }
        }
    }

    var
        TierStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Points Balance" < 0 then
            TierStyle := 'Unfavorable'
        else
            TierStyle := 'Favorable';
    end;
}
