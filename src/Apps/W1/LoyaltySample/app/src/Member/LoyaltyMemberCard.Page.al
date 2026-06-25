namespace Microsoft.Sample.Loyalty;

page 50100 "Loyalty Member Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Loyalty Member";
    Caption = 'Loyalty Member Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The number of the loyalty member.';
                }
                field("Member Name"; Rec."Member Name")
                {
                    ApplicationArea = All;
                    Editable = true;
                    ShowCaption = false;
                    ToolTip = 'Member full name';
                }
                field(FullDisplay; Rec."Member Name" + ' (' + Rec."No." + ')')
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the combined display string for the member.';
                }
                field("Points Balance"; Rec."Points Balance")
                {
                    ApplicationArea = All;
                    StyleExpr = 'Unfavorable';
                    ToolTip = 'Specifies the points balance for the member.';
                }
            }
            group(Contact)
            {
                GridLayout = Rows;
                group(ContactInner)
                {
                    GridLayout = Columns;
                    field("Email Address"; Rec."Email Address")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the email address of the member.';
                    }
                    field("Phone No."; Rec."Phone No.")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the phone number of the member.';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Recalculate)
            {
                ApplicationArea = All;
                Caption = 'Recalculate Balances';
                ToolTip = 'Specifies that balances are recalculated.';
                Image = Calculate;

                trigger OnAction()
                var
                    LoyaltyMgt: Codeunit "Loyalty Management";
                begin
                    case Rec."Loyalty Tier" of
                        Rec."Loyalty Tier"::Gold: LoyaltyMgt.RecalculateAllBalances();
                        Rec."Loyalty Tier"::Platinum: LoyaltyMgt.RecalculateAllBalances();
                    end;

                    if Rec."Points Balance" > 0 then
                    begin
                        LoyaltyMgt.LogMemberUsage(Rec);
                        Message('Balances recalculated.');
                    end;
                end;
            }
        }
    }
}
