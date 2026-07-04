// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
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
                    EDocument.ViewSourceFile();
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
        EDocument: Record "E-Document";
        EDocDataStorage: Record "E-Doc. Data Storage";
        FileName: Text;
        ViewPDFVisible: Boolean;
        UploadedInvoiceTxt: Label 'Uploaded invoice';

    trigger OnAfterGetCurrRecord()
    var
        EntryNo: Integer;
    begin
        Clear(EDocument);
        Clear(EDocDataStorage);
        FileName := '';
        ViewPDFVisible := false;

        if not Evaluate(EntryNo, Rec."External ID") then
            exit;
        if not EDocument.Get(EntryNo) then
            exit;
        FileName := EDocument."Source Details";
        if EDocument."Unstructured Data Entry No." = 0 then
            exit;
        if not EDocDataStorage.Get(EDocument."Unstructured Data Entry No.") then
            exit;
        ViewPDFVisible := EDocDataStorage."File Format" = Enum::"E-Doc. File Format"::PDF;
    end;
}
