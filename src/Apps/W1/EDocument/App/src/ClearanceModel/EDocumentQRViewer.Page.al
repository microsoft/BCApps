// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;


page 6170 "E-Document QR Viewer"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'QR Code Viewer';
    SourceTable = "EDoc QR Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            field(QRCodeBase64Preview; QRCodePreviewTxt)
            {
                ApplicationArea = All;
                Caption = 'QR Code (preview)';
                Editable = false;
                ToolTip = 'Specifies the Base64 representation of the QR code. Drill down to export the QR code image to a file.';

                trigger OnDrillDown()
                var
                    EDocQRCodeMgr: Codeunit "EDocument QR Code Management";
                begin
                    EDocQRCodeMgr.ExportQRCodeToFile(Rec);
                end;
            }
            field(QRImage; Rec."QR Code Image")
            {
                ApplicationArea = All;
                Caption = 'QR Code Image';
                ToolTip = 'Specifies the image about the QR code';
                Editable = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportQRCode)
            {
                ApplicationArea = All;
                Caption = 'Export QR Code';
                Image = Export;
                ToolTip = 'Export QR code image to file';

                trigger OnAction()
                var
                    EDocQRCodeMgr: Codeunit "EDocument QR Code Management";
                begin
                    EDocQRCodeMgr.ExportQRCodeToFile(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        EDocQRCodeMgr: Codeunit "EDocument QR Code Management";
        InStr: InStream;
    begin
        Clear(QRCodePreviewTxt);
        Rec.CalcFields("QR Code Base64");
        if not Rec."QR Code Base64".HasValue then
            exit;

        Rec."QR Code Base64".CreateInStream(InStr, TextEncoding::UTF8);
        InStr.ReadText(QRCodePreviewTxt, 1024);

        EDocQRCodeMgr.SetQRCodeImageFromBase64(Rec);
    end;

    var
        QRCodePreviewTxt: Text;
}
