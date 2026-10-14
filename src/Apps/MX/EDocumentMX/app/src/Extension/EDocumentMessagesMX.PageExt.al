// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Message;

pageextension 3353 "EDoc Messages MX" extends "E-Document Messages FactBox"
{
    actions
    {
        addafter(ViewXML)
        {
            action(ViewResponseXMLMX)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Response XML';
                ToolTip = 'Downloads the original XML response returned by the PAC for this payment complement message.';
                Image = ExportFile;
                Visible = Rec."Message Type" = Enum::"E-Document Message Type"::"MX CFDI Payment Complement";

                trigger OnAction()
                var
                    Complement: Record "MX Payment Complement";
                    ResponseInStream: InStream;
                    FileName: Text;
                begin
                    Complement.SetRange("E-Document Message Entry No.", Rec."Entry No.");
                    if not Complement.FindFirst() then
                        Error(ResponseNotAvailableErr);
                    Complement.CalcFields("PAC Response XML");
                    if not Complement."PAC Response XML".HasValue() then
                        Error(ResponseNotAvailableErr);

                    Complement."PAC Response XML".CreateInStream(ResponseInStream, TextEncoding::UTF8);
                    FileName := StrSubstNo(ResponseFileNameTok, Rec."Entry No.");
                    DownloadFromStream(ResponseInStream, '', '', '', FileName);
                end;
            }
        }
    }

    var
        ResponseNotAvailableErr: Label 'No saved PAC response is available for this message. Responses are saved for successful payment complement transmissions after this feature is installed. For older messages, check the communication logs.';
        ResponseFileNameTok: Label 'MX-Payment-Response-%1.xml', Locked = true;
}