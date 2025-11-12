// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Email;

page 5961 "Service Email Queue"
{
    ApplicationArea = Service;
    Caption = 'View Service Email Queue';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Service Email Queue";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the type of document linked to this entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document linked to this entry.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the message status.';
                }
                field("Sending Date"; Rec."Sending Date")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the date the message was sent.';
                }
                field("Sending Time"; Rec."Sending Time")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    ToolTip = 'Specifies the time the message was sent.';
                }
                field("To Address"; Rec."To Address")
                {
                    ApplicationArea = Service;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the recipient when an email is sent to notify customers that their service items are ready.';
                }
                field("Subject Line"; Rec."Subject Line")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the email subject line.';
                }
                field("Body Line"; Rec."Body Line")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the text of the body of the email.';
                    Visible = false;
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
            group("&Queue")
            {
                Caption = '&Queue';
                Image = CheckList;
                action("&Send by Email")
                {
                    ApplicationArea = Service;
                    Caption = '&Send by Email';
                    Image = Email;
                    ToolTip = 'Notify the customer that their service items are ready. ';

                    trigger OnAction()
                    begin
                        if Rec.IsEmpty() then
                            Error(Text001);

                        if Rec.Status = Rec.Status::Processed then
                            Error(Text000);

                        Clear(ServMailMgt);

                        ClearLastError();

                        if ServMailMgt.Run(Rec) then begin
                            Rec.Status := Rec.Status::Processed;
                            CurrPage.Update();
                        end else
                            Error(GetLastErrorText);
                    end;
                }
                action("&Delete Service Order Email Queue")
                {
                    ApplicationArea = Service;
                    Caption = '&Delete Service Order Email Queue';
                    Ellipsis = true;
                    Image = Delete;
                    ToolTip = 'Delete emails that are waiting to be sent automatically.';

                    trigger OnAction()
                    var
                        EMailQueue: Record "Service Email Queue";
                    begin
                        Clear(EMailQueue);
                        EMailQueue.SetCurrentKey("Document Type", "Document No.");
                        EMailQueue.SetRange("Document Type", Rec."Document Type");
                        EMailQueue.SetRange("Document No.", Rec."Document No.");
                        REPORT.Run(REPORT::"Delete Service Email Queue", false, false, EMailQueue);
                    end;
                }
                action("D&elete Service Email Queue")
                {
                    ApplicationArea = Service;
                    Caption = 'D&elete Service Email Queue';
                    Image = Delete;
                    ToolTip = 'Cancel the sending of email messages to notify customers when their service items are ready.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Delete Service Email Queue");
                    end;
                }
            }
        }
    }

    var
        ServMailMgt: Codeunit ServMailManagement;

#pragma warning disable AA0074
        Text000: Label 'This email  has already been sent.';
        Text001: Label 'There are no items to process.';
#pragma warning restore AA0074
}

