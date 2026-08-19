page 135191 "Mock - Aut. Permission Sets"
{
    APIGroup = 'webhook';
    APIPublisher = 'mock';
    APIVersion = 'v0.1';
    Caption = 'permissionSets', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    EntityName = 'permissionSet';
    EntitySetName = 'permissionSets';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = API;
    SourceTable = "Aggregate Permission Set";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; "Role ID")
                {
                    ApplicationArea = All;
                    Caption = 'id', Locked = true;
                }
                field(displayName; Name)
                {
                    ApplicationArea = All;
                    Caption = 'displayName', Locked = true;
                }
                field(appId; "App ID")
                {
                    ApplicationArea = All;
                    Caption = 'appId', Locked = true;
                }
                field(extensionName; "App Name")
                {
                    ApplicationArea = All;
                    Caption = 'extensionName', Locked = true;
                }
                field(scope; Scope)
                {
                    ApplicationArea = All;
                    Caption = 'scope', Locked = true;
                }
            }
        }
    }

    actions
    {
    }
}
