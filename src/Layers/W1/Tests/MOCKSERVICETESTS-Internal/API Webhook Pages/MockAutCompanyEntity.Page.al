page 135193 "Mock - Aut. Company Entity"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'automationCompany', Locked = true;
    DelayedInsert = true;
    EntityName = 'automationCompany';
    EntitySetName = 'automationCompanies';
    ODataKeyFields = Id;
    PageType = API;
    SourceTable = Company;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                    Editable = false;
                }
                field(name; Name)
                {
                    ApplicationArea = All;
                    Caption = 'name', Locked = true;
                    Editable = false;
                }
                field(evaluationCompany; "Evaluation Company")
                {
                    ApplicationArea = All;
                    Caption = 'evaluationCompany', Locked = true;
                    Editable = false;
                }
                field(displayName; "Display Name")
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                    NotBlank = true;
                }
                field(businessProfileId; "Business Profile Id")
                {
                    ApplicationArea = All;
                    Caption = 'businessProfileId', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}
