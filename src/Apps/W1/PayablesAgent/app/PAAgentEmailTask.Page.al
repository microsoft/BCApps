// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
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
                    WebLink := SourceBuffer.GetSourceEmailWebLink();
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
                    SourceBuffer.ViewSourcePdf();
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
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
        SourceBuffer: Record "PA Detailed Task" temporary;
        EmailSubject: Text;
        EmailFrom: Text;
        EmailContent: Text;
        ViewPDFVisible: Boolean;
        PDFReceivedFromEmailTxt: label 'Email received with PDF attachment';
        NoPDFReceivedFromEmailTxt: label 'Email received without PDF attachment';

    trigger OnAfterGetCurrRecord()
    begin
        PAV1V2Compatibility.LoadPADetailedTask(Rec, SourceBuffer);
        EmailFrom := SourceBuffer."Email From";
        EmailSubject := SourceBuffer."Email Subject";
        EmailContent := SourceBuffer.GetSourceEmailBody();
        ViewPDFVisible := SourceBuffer."Has Pdf";
    end;

    local procedure GetCaption(): Text[250]
    var
        LocalBuffer: Record "PA Detailed Task" temporary;
    begin
        PAV1V2Compatibility.LoadPADetailedTask(Rec, LocalBuffer);
        if LocalBuffer."Has Pdf" then
            exit(PDFReceivedFromEmailTxt);
        exit(NoPDFReceivedFromEmailTxt);
    end;
}
