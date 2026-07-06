// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using Microsoft.Sales.Customer;
using System.Agents;
using System.EMail;
using System.Utilities;

page 4409 "SOA Create Task"
{
    PageType = Card;
    ApplicationArea = All;
    Caption = 'Create task';
    DataCaptionExpression = '';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Message)
            {
                Caption = 'Message';
                grid(FixedControl)
                {
                    group(MessageFields)
                    {
                        ShowCaption = false;
                        field(Sender; Sender)
                        {
                            Caption = 'Sender';
                            OptionCaption = 'Contact,Customer';
                            ToolTip = 'Specifies which list the assist edit button on the sender''s email field opens.';

                            trigger OnValidate()
                            begin
                                SenderEmail := '';
                                SOACreateTaskImpl.ClearSelectedSender();
                            end;
                        }
                        field(SenderEmail; SenderEmail)
                        {
                            Caption = 'Sender''s email';
                            ExtendedDatatype = EMail;
                            ShowMandatory = true;
                            ToolTip = 'Specifies the email address the message is from. Use the assist edit button to pick from the selected list, or type any email address.';

                            trigger OnValidate()
                            var
                                MailManagement: Codeunit "Mail Management";
                            begin
                                if SenderEmail <> '' then
                                    MailManagement.CheckValidEmailAddresses(SenderEmail);
                            end;

                            trigger OnAssistEdit()
                            var
                                Contact: Record Contact;
                                Customer: Record Customer;
                                SalespersonCode: Code[20];
                            begin
                                SalespersonCode := SOACreateTaskImpl.GetCurrentUserSalespersonCode();
                                case Sender of
                                    Sender::Contact:
                                        begin
                                            Contact.SetRange("Contact Business Relation", Contact."Contact Business Relation"::Customer);
                                            if SalespersonCode <> '' then
                                                Contact.SetRange("Salesperson Code", SalespersonCode);
                                            if SenderEmail <> '' then begin
                                                Contact.SetRange("E-Mail", SenderEmail);
                                                if Contact.FindFirst() then;
                                                Contact.SetRange("E-Mail");
                                            end;
                                            if Page.RunModal(0, Contact) = Action::LookupOK then begin
                                                SenderEmail := Contact."E-Mail";
                                                SOACreateTaskImpl.SetSelectedContact(Contact);
                                            end;
                                        end;
                                    Sender::Customer:
                                        begin
                                            if SalespersonCode <> '' then
                                                Customer.SetRange("Salesperson Code", SalespersonCode);
                                            if SenderEmail <> '' then begin
                                                Customer.SetRange("E-Mail", SenderEmail);
                                                if Customer.FindFirst() then;
                                                Customer.SetRange("E-Mail");
                                            end;
                                            if Page.RunModal(0, Customer) = Action::LookupOK then begin
                                                SenderEmail := Customer."E-Mail";
                                                SOACreateTaskImpl.SetSelectedCustomer(Customer);
                                            end;
                                        end;
                                end;
                            end;
                        }
                        group(SampleMessageGroup)
                        {
                            ShowCaption = false;
                            InstructionalText = 'The agent will process the message as coming from the sender, including sending replies. Enter the message text, or use the sample message for a quick start.';

                            field(UseSampleMessageLink; UseSampleMessageLbl)
                            {
                                ShowCaption = false;
                                Editable = false;
                                Style = StandardAccent;
                                StyleExpr = true;
                                ToolTip = 'Fills the page with a sample message so you can quickly try the agent.';

                                trigger OnDrillDown()
                                var
                                    SampleChoice: Integer;
                                begin
                                    if SenderEmail = '' then
                                        Error(SenderEmailRequiredErr);

                                    SampleChoice := StrMenu(SampleMessageOptionsQst, 1, SampleMessageInstructionQst);
                                    case SampleChoice of
                                        1:
                                            LoadSampleMessage();
                                        2:
                                            LoadSampleMessageWithAttachment();
                                    end;
                                end;
                            }
                        }
                    }
                }
            }
            group(MessageTextGroup)
            {
                ShowCaption = false;

                field(MessageText; MessageText)
                {
                    Caption = 'Message text';
                    ToolTip = 'Specifies the text of the message that the agent will process.';
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                    ShowMandatory = true;
                }
            }
            part(MessageAttachments; "SOA Create Task Attachments")
            {
                ApplicationArea = All;
                Caption = 'Attachments';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempAgentTaskFile: Record "Agent Task File" temporary;
    begin
        if not (CloseAction in [Action::Ok, Action::LookupOK, Action::Yes]) then
            exit(true);

        if CurrPage.MessageAttachments.Page.GetUploadedFiles(TempAgentTaskFile) then;
        SOACreateTaskImpl.CreateTask(SenderEmail, MessageText, TempAgentTaskFile);
        exit(true);
    end;

    internal procedure SetAgentUserSecurityID(NewAgentUserSecurityID: Guid)
    begin
        SOACreateTaskImpl.SetAgentUserSecurityID(NewAgentUserSecurityID);
    end;

    local procedure LoadSampleMessage()
    begin
        SOACreateTaskImpl.LoadSampleMessage(SenderEmail, MessageText);
        CurrPage.MessageAttachments.Page.ClearAttachments();
        CurrPage.Update(false);
    end;

    local procedure LoadSampleMessageWithAttachment()
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        SOACreateTaskImpl.LoadSampleMessageWithAttachment(SenderEmail, MessageText, TempBlob);
        CurrPage.MessageAttachments.Page.ClearAttachments();
        CurrPage.MessageAttachments.Page.AddSampleAttachment(
            SOACreateTaskImpl.GetSampleAttachmentName(),
            SOACreateTaskImpl.GetSampleAttachmentMimeType(), TempBlob);
        CurrPage.Update(false);
    end;

    var
        SOACreateTaskImpl: Codeunit "SOA Create Task Impl";
        MessageText: Text;
        SenderEmail: Text[250];
        Sender: Option Contact,Customer;
        UseSampleMessageLbl: Label 'Use sample message';
        SampleMessageOptionsQst: Label 'Message with text only,Message with attachment', Comment = 'Comma-separated options shown when choosing which sample message to load.';
        SampleMessageInstructionQst: Label 'Use a sample:';
        SenderEmailRequiredErr: Label 'You must specify the sender''s email before you can use a sample message.';
}
