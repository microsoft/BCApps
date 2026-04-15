#pragma warning disable AA0247
page 8050 "Sales Person API"
{
    APIGroup = 'subsBilling';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    EntityName = 'salesperson';
    EntitySetName = 'salesperson';
    PageType = API;
    SourceTable = "Salesperson/Purchaser";
    ODataKeyFields = SystemId;
    AboutText = 'Exposes salesperson and purchaser records including their code and name. Provides read-only access for external systems to retrieve salesperson data needed for mapping sales representatives in subscription billing and contract management integrations.';

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(systemId; Rec.SystemId)
                {
                }
                field(code; Rec."Code")
                {
                }
                field(name; Rec.Name)
                {
                }
            }
        }
    }
}
