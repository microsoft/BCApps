// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

page 3312 "PA Agent Upload Task"
{
    Caption = 'Upload Task';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Agent Task Message";
    DataCaptionExpression = UploadedInvoiceTxt;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Upload)
            {
                Caption = 'Header';
                field(FileName; FileName)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'File name';
                    ToolTip = 'Specifies the name of the uploaded file.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ViewFile)
            {
                ApplicationArea = All;
                Caption = 'View pdf';
                ToolTip = 'View the uploaded pdf.';
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
            actionref(ViewFile_Promoted; ViewFile)
            { }
        }
    }
    trigger OnAfterGetCurrRecord()
    begin
        if PATask.Load(Rec."Task ID") then;
        FileName := PATask.GetFileName();
        ViewPDFVisible := PATask.HasPdf();
    end;
    var
        PATask: Codeunit "Payables Agent Task";
        Presentation: Codeunit "PA Task Presentation";
        FileName: Text;
        ViewPDFVisible: Boolean;
        UploadedInvoiceTxt: Label 'Uploaded invoice';
}
