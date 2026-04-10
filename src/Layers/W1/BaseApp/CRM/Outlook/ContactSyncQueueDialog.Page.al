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
#if not CLEANSCHEMA29
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Sync Direction"; Rec."Sync Direction")
                {
                    ApplicationArea = All;
                }
#endif
                field("Sync Status"; Rec."Sync Status")
                {
                    ApplicationArea = All;
                }
                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                }
                field("Initials"; Rec.Initials)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the initials.';
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
                field(County; Rec.County)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the county/state.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = All;
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the post code.';
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
                Caption = 'Exclude';
                Image = RemoveLine;
                Scope = Repeater;
                ToolTip = 'Remove the selected record from the queue.';

                trigger OnAction()
                begin
                    if Confirm(DeleteConfirmMsg, false) then
                        Rec.Delete();
                end;
            }
            action(DeleteSelected)
            {
                ApplicationArea = All;
                Caption = 'Exclude Selected';
                Image = RemoveContacts;
                ToolTip = 'Remove all selected records from the queue.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(Rec);
                    if Rec.FindSet() then begin
                        if Confirm(DeleteSelectedConfirmMsg, false) then begin
                            Rec.DeleteAll();
                            Message(SelectedRecordsRemovedMsg);
                        end;
                    end else
                        Message(NoRecordsSelectedMsg);
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteAll)
            {
                ApplicationArea = All;
                Caption = 'Exclude All';
                Image = DeleteAllBreakpoints;
                ToolTip = 'Remove all entries from the queue.';

                trigger OnAction()
                begin
                    if Confirm(DeleteAllConfirmMsg, false) then begin
                        Rec.Reset();
                        Rec.DeleteAll();
                        Message(AllEntriesRemovedMsg);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    var
        DeleteConfirmMsg: Label 'Are you sure you want to remove this record from the queue?';
        DeleteSelectedConfirmMsg: Label 'Are you sure you want to remove the selected records?';
        DeleteAllConfirmMsg: Label 'Are you sure you want to remove ALL queue entries?';
        SelectedRecordsRemovedMsg: Label 'Selected records have been removed.';
        AllEntriesRemovedMsg: Label 'All queue entries have been removed.';
        NoRecordsSelectedMsg: Label 'No records selected.';
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
