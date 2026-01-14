namespace Microsoft.CRM.Outlook;

page 7031 "Contact Sync Queue List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Contact Sync Queue";
    Caption = 'Contact Sync Queue';
    Editable = false;

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
                field("Contact ID"; Rec."Contact ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the O365 contact ID.';
                    Visible = false;
                }
                field("BC Contact No."; Rec."BC Contact No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the BC contact number.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the queue entry was created.';
                }
                field("Last Modified DateTime"; Rec."Last Modified DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the contact was last modified.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteSelected)
            {
                ApplicationArea = All;
                Caption = 'Delete Selected';
                Image = Delete;
                ToolTip = 'Delete the selected queue entry.';

                trigger OnAction()
                begin
                    if Confirm('Are you sure you want to delete the selected entry?', false) then begin
                        Rec.Delete(true);
                        CurrPage.Update(false);
                        Message('Entry deleted successfully.');
                    end;
                end;
            }
            action(DeleteAll)
            {
                ApplicationArea = All;
                Caption = 'Delete All';
                Image = DeleteAllBreakpoints;
                ToolTip = 'Delete all entries from the queue.';

                trigger OnAction()
                var
                    SyncQueue: Record "Contact Sync Queue";
                begin
                    if Confirm('Are you sure you want to delete ALL queue entries?', false) then begin
                        SyncQueue.Reset();
                        SyncQueue.DeleteAll();
                        Message('All queue entries have been deleted.');
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the page.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(DeleteSelected_Promoted; DeleteSelected)
                {
                }
                actionref(DeleteAll_Promoted; DeleteAll)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
            }
        }
    }

}
