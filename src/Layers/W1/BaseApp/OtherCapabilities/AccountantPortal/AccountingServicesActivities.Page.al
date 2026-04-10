namespace Microsoft.AccountantPortal;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Task;
using Microsoft.Sales.Document;
using System.Device;

page 9070 "Accounting Services Activities"
{
    Caption = 'Accounting Services';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Accounting Services Cue";

    layout
    {
        area(content)
        {
            cuegroup(Documents)
            {
                Caption = 'Documents';
                field("My Incoming Documents"; Rec."My Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies incoming documents that are assigned to you.';
                }
                field("Ongoing Sales Invoices"; Rec."Ongoing Sales Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies sales invoices that are not posted or only partially posted.';
                }
            }
            cuegroup(Camera)
            {
                Caption = 'Scan documents';
                Visible = HasCamera;

                actions
                {
                    action(CreateIncomingDocumentFromCamera)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create Incoming Doc. from Camera';
                        Image = TileCamera;
                        ToolTip = 'Specifies if you want to create an incoming document, by taking a photo of the document with your mobile device camera. The photo will be attached to the new document.';

                        trigger OnAction()
                        var
                            IncomingDocument: Record "Incoming Document";
                            InStr: InStream;
                            PictureName: Text;
                        begin
                            if not Camera.GetPicture(InStr, PictureName) then
                                exit;

                            IncomingDocument.CreateIncomingDocument(InStr, PictureName);
                            CurrPage.Update();
                        end;
                    }
                }
            }
            cuegroup(Approvals)
            {
                Caption = 'Approvals';
                field("Requests to Approve"; Rec."Requests to Approve")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies requests for certain accounting activities that you must approve for other users before they can proceed.';
                }
            }
            cuegroup("My User Tasks")
            {
                Caption = 'My User Tasks';
                field("UserTaskManagement.GetMyPendingUserTasksCount"; UserTaskManagement.GetMyPendingUserTasksCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pending User Tasks';
                    Image = Checklist;
                    ToolTip = 'Specifies the number of pending tasks that are assigned to you or to a group that you are a member of.';

                    trigger OnDrillDown()
                    var
                        UserTaskList: Page "User Task List";
                    begin
                        UserTaskList.SetPageToShowMyPendingUserTasks();
                        UserTaskList.Run();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        Rec.SetRange("User ID Filter", UserId);

        HasCamera := Camera.IsAvailable();
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        Camera: Codeunit Camera;
        HasCamera: Boolean;
}

