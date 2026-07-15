// APIVersion is omitted, so the endpoint defaults to beta instead of publishing
// an intended explicit stable contract.
page 50070 "CWM Widget API"
{
    PageType = API;
    APIPublisher = 'contoso';
    APIGroup = 'widgets';
    EntityName = 'widget';
    EntitySetName = 'widgets';
    SourceTable = "CWM Widget";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(records)
            {
                field(number; Rec."No.")
                {
                    Caption = 'number';
                }
                field(description; Rec.Description)
                {
                    Caption = 'description';
                }
                field(contactEmail; Rec."Contact Email")
                {
                    Caption = 'contactEmail';
                }
            }
        }
    }
}
