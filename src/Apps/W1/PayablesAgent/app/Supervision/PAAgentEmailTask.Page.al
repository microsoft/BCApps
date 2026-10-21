// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

page 3305 "PA Agent Email Task"
{
    Caption = 'Email Task';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Agent Task Message";
    DataCaptionExpression = GetCaption();
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Email)
            {
                Caption = 'Header';
                field(EmailFrom; EmailFrom)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'From';
                    ToolTip = 'Specifies the sender of the email.';
                }
                field(EmailSubject; EmailSubject)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Subject';
                    ToolTip = 'Specifies the subject of the email.';
                }

            }
            group(EmailContentGroup)
            {
                Caption = 'Body';
                field(EmailContent; EmailContent)
                {
                    ShowCaption = false;
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ViewMailMessage)
            {
                ApplicationArea = All;
                Caption = 'View e-mail message';
                ToolTip = 'View the source e-mail message.';
                Image = Email;

                trigger OnAction()
                var
                    WebLink: Text;
                begin
                    WebLink := Presentation.GetEmailWebLink(PATask);
                    if WebLink <> '' then
                        HyperLink(WebLink);
                end;
            }
            action(ViewFile)
            {
                ApplicationArea = All;
                Caption = 'View pdf';
                ToolTip = 'View the received pdf.';
                Image = ViewDetails;
                Visible = ViewPDFVisible;

                trigger OnAction()
                begin
                    Presentation.ViewSourcePdf(PATask);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ViewMailMessage_Promoted; ViewMailMessage)
            {
            }
            actionref(ViewFile_Promoted; ViewFile)
            { }
        }
    }

    var
        PATask: Codeunit "Payables Agent Task";
        Presentation: Codeunit "PA Task Presentation";
        EmailSubject: Text;
        EmailFrom: Text;
        EmailContent: Text;
        ViewPDFVisible: Boolean;
        PDFReceivedFromEmailTxt: label 'Email received with PDF attachment';
        NoPDFReceivedFromEmailTxt: label 'Email received without PDF attachment';
        EmailFromTxt: Label '%1 <%2>', Comment = '%1 = sender name, %2 = sender address';

    trigger OnAfterGetCurrRecord()
    var
        Data: Record "PA Detailed Task" temporary;
    begin
        if PATask.Load(Rec."Task ID") then;
        PATask.GetRecord(Data);
        EmailFrom := Data."Email From";
        if Data."Sender Name" <> '' then
            EmailFrom := StrSubstNo(EmailFromTxt, Data."Sender Name", Data."Email From");
        EmailSubject := PATask.GetEmailSubject();
        EmailContent := PATask.GetSourceEmailBody();
        ViewPDFVisible := PATask.HasPdf();
    end;

    local procedure GetCaption(): Text[250]
    var
        CaptionPATask: Codeunit "Payables Agent Task";
    begin
        if CaptionPATask.Load(Rec."Task ID") then;
        if CaptionPATask.HasPdf() then
            exit(PDFReceivedFromEmailTxt);
        exit(NoPDFReceivedFromEmailTxt);
    end;
}
