namespace System.Automation;

using System.Security.User;

page 666 "Overdue Approval Entries"
{
    ApplicationArea = Suite;
    Caption = 'Overdue Approval Entries';
    Editable = false;
    PageType = List;
    Permissions = TableData "Overdue Approval Entry" = d;
    SourceTable = "Overdue Approval Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the document is due for approval.';
                }
                field("Approver ID"; Rec."Approver ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who must approve the document.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Approver ID");
                    end;
                }
                field("Sent to ID"; Rec."Sent to ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who sent the mail notifying the approver that they has document approvals that are overdue.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Sent to ID");
                    end;
                }
                field("Sent Date"; Rec."Sent Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the overdue notification mail was sent to the approver who should approve the document.';
                }
                field("Sent Time"; Rec."Sent Time")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the time when the overdue notification mail was sent to the approver who should approve the document.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the table where the record that is subject to approval is stored.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the type of document that an approval entry has been created for. Approval entries can be created for six different types of sales or purchase documents:';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the document that was sent for approval. The number is copied from the relevant sales or purchase document, such as a purchase order or a sales quote.';
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the user to whom the overdue notification was sent.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Show")
            {
                Caption = '&Show';
                Image = View;
                action("&Record")
                {
                    ApplicationArea = Suite;
                    Caption = '&Record';
                    Image = Document;
                    ToolTip = 'Open the document, journal, or card that the approval request applies to.';

                    trigger OnAction()
                    begin
                        Rec.ShowRecord();
                    end;
                }
                action("&App. Entry")
                {
                    ApplicationArea = Suite;
                    Caption = '&App. Entry';
                    Image = Approvals;
                    ToolTip = 'Open the approval entry.';

                    trigger OnAction()
                    begin
                        DisplayEntry(Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Delete Entries")
            {
                ApplicationArea = Suite;
                Caption = '&Delete Entries';
                Image = Delete;
                ToolTip = 'Delete the overdue approval entries.';

                trigger OnAction()
                var
                    UserSetup: Record "User Setup";
                    OverdueEntry: Record "Overdue Approval Entry";
                begin
                    UserSetup.Get(UserId);
                    if not UserSetup."Approval Administrator" then
                        Error(MustBeAdminErr);
                    CurrPage.SetSelectionFilter(OverdueEntry);
                    if OverdueEntry.FindFirst() then
                        OverdueEntry.DeleteAll();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Delete Entries_Promoted"; "&Delete Entries")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        UserSetup: Record "User Setup";
        Filterstring: Text;
    begin
        if UserSetup.Get(UserId) then
            if not UserSetup."Approval Administrator" then begin
                Rec.FilterGroup(2);
                Filterstring := Rec.GetFilters();
                Rec.FilterGroup(0);
                if StrLen(Filterstring) = 0 then begin
                    Rec.FilterGroup(2);
                    Rec.SetCurrentKey("Approver ID");
                    Rec.SetRange("Approver ID", UserSetup."User ID");
                    Rec.FilterGroup(0);
                end else
                    Rec.SetCurrentKey("Table ID", "Document Type", "Document No.");
            end;
    end;

    var
        MustBeAdminErr: Label 'You must be an Approval Administrator to delete this entry.';

    local procedure DisplayEntry(OverdueApprovalEntry: Record "Overdue Approval Entry")
    var
        ApprovalEntry: Record "Approval Entry";
        AppEntryForm: Page "Approval Entries";
    begin
        ApprovalEntry.SetRange("Table ID", OverdueApprovalEntry."Table ID");
        ApprovalEntry.SetRange("Record ID to Approve", OverdueApprovalEntry."Record ID to Approve");
        ApprovalEntry.SetRange("Sequence No.", OverdueApprovalEntry."Sequence No.");

        AppEntryForm.CalledFrom();
        AppEntryForm.SetTableView(ApprovalEntry);
        AppEntryForm.Run();
    end;
}

