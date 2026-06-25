namespace Microsoft.Sample.Loyalty;

page 50103 "Loyalty Member Data"
{
    PageType = API;
    SourceTable = "Loyalty Member";
    ODataKeyFields = "No.";
    Caption = 'Loyalty Member Data';

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(no; Rec."No.")
                {
                    Caption = 'no';
                }
                field(memberName; Rec."Member Name")
                {
                    Caption = 'memberName';
                }
                field(emailAddress; Rec."Email Address")
                {
                    Caption = 'emailAddress';
                }
                field(phoneNo; Rec."Phone No.")
                {
                    Caption = 'phoneNo';
                }
                field(pointsBalance; Rec."Points Balance")
                {
                    Caption = 'pointsBalance';

                    trigger OnValidate()
                    var
                        LoyaltyManagement: Codeunit "Loyalty Management";
                    begin
                        LoyaltyManagement.RecalculateAllBalances();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
    end;
}
