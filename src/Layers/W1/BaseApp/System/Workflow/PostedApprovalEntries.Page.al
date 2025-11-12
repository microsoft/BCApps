namespace System.Automation;

using System.Security.User;

page 659 "Posted Approval Entries"
{
    ApplicationArea = Suite;
    Caption = 'Posted Approval Entries';
    DataCaptionFields = "Document No.";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Approval Entry";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(PostedRecordID; PostedRecordID)
                {
                    ApplicationArea = Suite;
                    Caption = 'Approved';
                    ToolTip = 'Specifies that the approval request has been approved.';
                }
                field("Iteration No."; Rec."Iteration No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of handling iterations that this approval request has reached.';
                }
                field("Sequence No."; Rec."Sequence No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the order of approvers when an approval workflow involves more than one approver.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the table where the record that is subject to approval is stored.';
                    Visible = false;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document number copied from the relevant sales or purchase document, such as a purchase order or a sales quote.';
                }
                field("Sender ID"; Rec."Sender ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the user who sent the approval request for the document to be approved.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Sender ID");
                    end;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the salesperson or purchaser that was in the document to be approved. It is not a mandatory field, but is useful if a salesperson or a purchaser responsible for the customer/vendor needs to approve the document before it is sent.';
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
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the approval status for the entry:';
                }
                field("Date-Time Sent for Approval"; Rec."Date-Time Sent for Approval")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date and the time that the document was sent for approval.';
                }
                field("Last Date-Time Modified"; Rec."Last Date-Time Modified")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the approval entry was last modified. If, for example, the document approval is canceled, this field will be updated accordingly.';
                }
                field("Last Modified By ID"; Rec."Last Modified By ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the person who last modified the approval entry. If, for example, the document approval is canceled, this field will be updated accordingly.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation(Rec."Last Modified By ID");
                    end;
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies whether there are comments related to the approval of the document. If you want to read the comments, click the field to open the Comment Sheet window.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the document is due for approval by the approver.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the total amount (excl. VAT) on the document waiting for approval. The amount is stated in the local currency.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the currency of the amounts on the sales or purchase lines.';
                }
                field("Delegation Date Formula"; Rec."Delegation Date Formula")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies for the posted approval entry when an overdue approval request was automatically delegated to the relevant substitute. The field is filled with the value in the Delegate After field in the Workflow Responses window, translated to a date formula. The date of automatic delegation is then calculated based on the Date-Time Sent for Approval field in the Approval Entries window.';
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
                Visible = true;
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
                action(Comments)
                {
                    ApplicationArea = Suite;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    var
                        PostedApprovalCommentLine: Record "Posted Approval Comment Line";
                    begin
                        PostedApprovalCommentLine.FilterGroup(2);
                        PostedApprovalCommentLine.SetRange("Posted Record ID", Rec."Posted Record ID");
                        PostedApprovalCommentLine.FilterGroup(0);
                        PAGE.Run(PAGE::"Posted Approval Comments", PostedApprovalCommentLine);
                    end;
                }
                action("Record")
                {
                    ApplicationArea = Suite;
                    Caption = 'Record';
                    Image = Document;
                    ToolTip = 'Open the document, journal line, or card that the approval request is for.';

                    trigger OnAction()
                    begin
                        Rec.ShowRecord();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Record_Promoted; Record)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        PostedRecordID := Format(Rec."Posted Record ID", 0, 1);
    end;

    trigger OnAfterGetRecord()
    begin
        PostedRecordID := Format(Rec."Posted Record ID", 0, 1);
    end;

    var
        PostedRecordID: Text;
}

