namespace Microsoft.Sample.Loyalty;

page 50101 "Loyalty Member API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'loyalty';
    APIVersion = 'v2';
    EntityName = 'Loyalty_Member';
    EntitySetName = 'Loyalty_Members';
    SourceTable = "Loyalty Member";
    DelayedInsert = false;
    Caption = 'Loyalty Member API';
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(number; Rec."No.")
                {
                    Caption = 'number';
                }
                field(Member_Name; Rec."Member Name")
                {
                    Caption = 'Member_Name';
                }
                field(emailAddress; Rec."Email Address")
                {
                    Caption = 'emailAddress';
                }
                field(pointsBalance; Rec."Points Balance")
                {
                    Caption = 'pointsBalance';
                }
            }
        }
    }
}
