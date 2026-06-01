// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Service.History;

pageextension 6172 "Posted Service CrMemo with QR" extends "Posted Service Credit Memo"
{
    actions
    {
        addafter("E-Document")
        {
            action(ViewQRCode)
            {
                ApplicationArea = All;
                Caption = 'View QR Code';
                Image = Picture;
                ToolTip = 'View the QR code assigned by the authority';
                Visible = ShowQRCodeAction;

                trigger OnAction()
                var
                    EDocQRCodeMgr: Codeunit "EDocument QR Code Management";
                begin
                    EDocQRCodeMgr.InitializeAndRunQRCodeViewer(Rec);
                end;
            }
        }
    }

    var
        ShowQRCodeAction: Boolean;

    trigger OnAfterGetRecord()
    begin
        ShowQRCodeAction := Rec."QR Code Image".Count > 0;
    end;
}