namespace Microsoft.CRM.Outlook;

page 7032 "Contact Sync Queue Dialog"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Contact Sync Queue";
    SourceTableTemporary = true;
    Editable = false;
    DeleteAllowed = true;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sync direction.';
                }
                field("Sync Status"; Rec."Sync Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sync status.';
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the display name.';
                }
                field("Given Name"; Rec."Given Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the first name.';
                }
                field(Surname; Rec.Surname)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the surname.';
                }
                field("Email Address"; Rec."Email Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the email address.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name.';
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the job title.';
                }
                field("Mobile Phone"; Rec."Mobile Phone")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the mobile phone.';
                }
                field("Business Phone"; Rec."Business Phone")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the business phone.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the city.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the country/region code.';
                }
            }
        }

    }

    actions
    {
        area(Processing)
        {
            action(DeleteRecord)
            {
                ApplicationArea = All;
                Caption = 'Remove';
                Image = RemoveLine;
                Scope = Repeater;
                ToolTip = 'Remove the selected record from the queue.';

                trigger OnAction()
                begin
                    if Confirm(DeleteConfirmMsg, false) then
                        Rec.Delete();
                end;
            }
        }
    }

    var
        DeleteConfirmMsg: Label 'Are you sure you want to remove this record from the queue?';
        SyncQueueCaptionLbl: Text;

    procedure SetData(var TempSyncQueue: Record "Contact Sync Queue" temporary)
    begin
        Rec.Copy(TempSyncQueue, true);
        if Rec.FindSet() then;
    end;

    procedure setCaption(CaptionText: Text)
    begin
        SyncQueueCaptionLbl := CaptionText;
    end;

    trigger OnOpenPage()
    begin
        CurrPage.Caption := SyncQueueCaptionLbl;
    end;
}
