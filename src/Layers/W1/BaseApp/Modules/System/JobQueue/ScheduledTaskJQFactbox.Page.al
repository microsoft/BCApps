namespace System.Threading;

page 3846 "Scheduled Task JQ Factbox"
{
    PageType = CardPart;
    Editable = false;
    Extensible = false;
    SourceTable = "Job Queue Entry";

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                ShowCaption = false;

                field(ObjectType; Rec."Object Type to Run")
                {
                    ApplicationArea = All;
                    Caption = 'Object Type to Run';
                    ToolTip = 'Specifies the type of object, either a report or a codeunit, that the job queue entry will run.';
                }
                field(ObjectCaption; Rec."Object Caption to Run")
                {
                    ApplicationArea = All;
                    Caption = 'Object Caption to Run';
                    ToolTip = 'Specifies the name of the object that the job queue entry will run.';
                }
                field(ObjectId; Rec."Object ID to Run")
                {
                    ApplicationArea = All;
                    Caption = 'Object ID to Run';
                    ToolTip = 'Specifies the ID of the object that the job queue entry will run.';
                }
                field(UserId; Rec."User ID")
                {
                    ApplicationArea = All;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the ID of the user who created the job queue entry. The ID is used, for example, when logging changes.';
                }
                field(Desc; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Description of the job queue entry.';
                }
            }

            group(JQDetails)
            {
                ShowCaption = false;
                Visible = ShowJQDetails;

                field(ShowJQDetailsTxt; ShowJQDetailsTxt)
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    ToolTip = 'Open the Job Queue Entry Card page.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Job Queue Entry Card", Rec);
                    end;
                }
            }
        }
    }

    var
        ShowJQDetails: Boolean;
        ShowJQDetailsTxt: Label 'Show Job Queue details.';

    trigger OnAfterGetCurrRecord()
    begin
        ShowJQDetails := not IsNullGuid(Rec.ID);
    end;
}