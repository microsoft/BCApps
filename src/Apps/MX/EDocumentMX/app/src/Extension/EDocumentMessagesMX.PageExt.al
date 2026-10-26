// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

pageextension 3353 "EDoc Messages MX" extends "E-Document Messages FactBox"
{
    layout
    {
        addafter(Status)
        {
            field(StampedUUIDMX; StampedUUID)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'UUID';
                ToolTip = 'Specifies the UUID assigned by SAT when the payment complement was stamped.';
            }
            field(CancellationStatusMX; CancellationStatus)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancellation Status';
                ToolTip = 'Specifies the SAT cancellation status of the payment complement.';
            }
        }
    }

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
                Enabled = IsPaymentComplement;
                Scope = Repeater;

                trigger OnAction()
                var
                    Complement: Record "MX Payment Complement";
                begin
                    GetComplement(Complement);
                    Complement.CalcFields("PAC Response XML");
                    if not Complement."PAC Response XML".HasValue() then
                        Error(ResponseNotAvailableErr);
                    DownloadBlob(Complement, Complement.FieldNo("PAC Response XML"), StrSubstNo(ResponseFileNameTok, Rec."Entry No."));
                end;
            }
            action(ViewCancellationResponseMX)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Cancellation Response';
                ToolTip = 'Downloads the XML response returned by the PAC for the last cancellation request of this payment complement.';
                Image = ExportFile;
                Enabled = IsPaymentComplement;
                Scope = Repeater;

                trigger OnAction()
                var
                    Complement: Record "MX Payment Complement";
                begin
                    GetComplement(Complement);
                    Complement.CalcFields("Cancellation Response XML");
                    if not Complement."Cancellation Response XML".HasValue() then
                        Error(CancellationResponseNotAvailableErr);
                    DownloadBlob(Complement, Complement.FieldNo("Cancellation Response XML"), StrSubstNo(CancellationFileNameTok, Rec."Entry No."));
                end;
            }
            action(CancelCFDIMX)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel Payment Complement';
                ToolTip = 'Cancels the stamped payment complement in SAT, checks the status of a cancellation in progress, marks it as canceled, or resets the cancellation request.';
                Image = Cancel;
                Enabled = IsPaymentComplement;
                Scope = Repeater;

                trigger OnAction()
                var
                    Complement: Record "MX Payment Complement";
                    MXPaymentComplCancel: Codeunit "MX Payment Compl. Cancel";
                begin
                    GetComplement(Complement);
                    MXPaymentComplCancel.RunCancelAction(Complement);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Complement: Record "MX Payment Complement";
    begin
        Clear(CancellationStatus);
        Clear(StampedUUID);
        if Rec."Message Type" <> Enum::"E-Document Message Type"::"MX CFDI Payment Complement" then
            exit;
        Complement.SetLoadFields("Cancellation Status", "Stamped UUID");
        Complement.SetRange("E-Document Message Entry No.", Rec."Entry No.");
        if Complement.FindFirst() then begin
            CancellationStatus := Complement."Cancellation Status";
            StampedUUID := Complement."Stamped UUID";
        end;
    end;

    trigger OnAfterGetCurrRecord()
    begin
        IsPaymentComplement := Rec."Message Type" = Enum::"E-Document Message Type"::"MX CFDI Payment Complement";
    end;

    local procedure GetComplement(var Complement: Record "MX Payment Complement")
    begin
        Complement.SetRange("E-Document Message Entry No.", Rec."Entry No.");
        if not Complement.FindFirst() then
            Error(ComplementNotFoundErr);
    end;

    local procedure DownloadBlob(var Complement: Record "MX Payment Complement"; FieldNo: Integer; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        TempBlob.FromRecord(Complement, FieldNo);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        DownloadFromStream(InStream, '', '', '', FileName);
    end;

    var
        CancellationStatus: Enum "MX Compl. Cancel Status";
        StampedUUID: Text[50];
        IsPaymentComplement: Boolean;
        ResponseNotAvailableErr: Label 'No saved PAC response is available for this message.';
        CancellationResponseNotAvailableErr: Label 'No cancellation response is available for this payment complement.';
        ComplementNotFoundErr: Label 'No payment complement is linked to this message.';
        ResponseFileNameTok: Label 'MX-Payment-Response-%1.xml', Locked = true;
        CancellationFileNameTok: Label 'MX-Payment-Cancellation-%1.xml', Locked = true;
}
