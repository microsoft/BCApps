page 135192 "Mock - Tax Area Entity"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'taxAreas', Locked = true;
    DelayedInsert = true;
    EntityName = 'taxArea';
    EntitySetName = 'taxAreas';
    PageType = API;
    SourceTable = "Tax Area Buffer";
    SourceTableTemporary = true;

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
                field(code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'code', Locked = true;
                }
                field(displayName; Description)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(taxType; Type)
                {
                    ApplicationArea = All;
                    Caption = 'taxType', Locked = true;
                    Editable = false;
                }
                field(lastModifiedDateTime; "Last Modified Date Time")
                {
                    ApplicationArea = All;
                    Caption = 'lastModifiedDateTime', Locked = true;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
    }
}
