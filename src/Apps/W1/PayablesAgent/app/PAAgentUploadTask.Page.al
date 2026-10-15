// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
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
                    PADetailedTask.ViewSourcePdf();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ViewFile_Promoted; ViewFile)
            { }
        }
    }

    var
        PAV1V2Compatibility: Codeunit "PA V1V2 Compatibility";
        PADetailedTask: Record "PA Detailed Task";
        FileName: Text;
        ViewPDFVisible: Boolean;
        UploadedInvoiceTxt: Label 'Uploaded invoice';

    trigger OnAfterGetCurrRecord()
    begin
        PAV1V2Compatibility.LoadPADetailedTask(Rec, PADetailedTask);
        FileName := PADetailedTask."File Name";
        ViewPDFVisible := PADetailedTask."Has Pdf";
    end;
}
