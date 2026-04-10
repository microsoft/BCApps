#if not CLEAN29
namespace Microsoft.CRM.Outlook;

page 7031 "Contact Sync Queue List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Contact Sync Queue";
    Caption = 'Contact Sync Queue';
    Editable = false;
    ObsoleteReason = 'Removed due to Contact Sync redesign, will be deleted in future release.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                }
                field("Sync Status"; Rec."Sync Status")
                {
                    ApplicationArea = All;
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                }
                field("Given Name"; Rec."Given Name")
                {
                    ApplicationArea = All;
                }
                field(Surname; Rec.Surname)
                {
                    ApplicationArea = All;
                }
                field("Email Address"; Rec."Email Address")
                {
                    ApplicationArea = All;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                }
                field("Mobile Phone"; Rec."Mobile Phone")
                {
                    ApplicationArea = All;
                }
                field("Business Phone"; Rec."Business Phone")
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                }
                field("Contact ID"; Rec."Contact ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("BC Contact No."; Rec."BC Contact No.")
                {
                    ApplicationArea = All;
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                }
                field("Last Modified DateTime"; Rec."Last Modified DateTime")
                {
                    ApplicationArea = All;
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
#endif