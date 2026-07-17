// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 10975 "FR E-Invoice Lifecycle Msg." implements IEDocMessageBuilder
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure BuildMessage(EDocument: Record "E-Document"; ResponseType: Enum "E-Doc. Response Type"; var TempBlob: Codeunit "Temp Blob")
    var
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
    begin
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocument."Entry No");
        FREInvoiceLifecycle.SetRange("E-Document Message Entry No.", 0);
        if not FREInvoiceLifecycle.FindFirst() then
            Error(NoCapturedOccurrenceErr, EDocument."Entry No");

        BuildLifecycleMessage(EDocument, FREInvoiceLifecycle, TempBlob);
    end;

    internal procedure BuildLifecycleMessage(EDocument: Record "E-Document"; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; var TempBlob: Codeunit "Temp Blob")
    var
        XmlDoc: XmlDocument;
        RootElement: XmlElement;
        OutStream: OutStream;
    begin
        FREInvoiceLifecycle.TestField("E-Document Entry No.", EDocument."Entry No");

        XmlDoc := XmlDocument.Create();
        XmlDoc.SetDeclaration(XmlDeclaration.Create('1.0', 'UTF-8', 'no'));
        RootElement := BuildLifecycleElement(EDocument, FREInvoiceLifecycle);
        XmlDoc.Add(RootElement);

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        XmlDoc.WriteTo(OutStream);
    end;

    local procedure BuildLifecycleElement(EDocument: Record "E-Document"; FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle") RootElement: XmlElement
    begin
        RootElement := XmlElement.Create('InvoiceLifecycleMessage');
        RootElement.Add(XmlElement.Create('MessageID', '', Format(FREInvoiceLifecycle."Source Occurrence ID")));
        RootElement.Add(XmlElement.Create('InvoiceID', '', EDocument."Document No."));
        RootElement.Add(XmlElement.Create('Status', '', LifecycleStatusCode(FREInvoiceLifecycle."Lifecycle Status")));
        RootElement.Add(XmlElement.Create('EventDate', '', Format(FREInvoiceLifecycle."Event Date", 0, '<Year4>-<Month,2>-<Day,2>')));
        RootElement.Add(BuildAmountElement(FREInvoiceLifecycle));
        if FREInvoiceLifecycle."Original Occurrence Entry No." <> 0 then
            RootElement.Add(XmlElement.Create('OriginalOccurrenceID', '', GetOriginalOccurrenceID(FREInvoiceLifecycle."Original Occurrence Entry No.")));
    end;

    local procedure BuildAmountElement(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle") AmountElement: XmlElement
    begin
        AmountElement := XmlElement.Create('Amount', '', Format(FREInvoiceLifecycle."Reported Amount", 0, 9));
        AmountElement.Add(XmlAttribute.Create('currencyID', FREInvoiceLifecycle."Currency Code"));
    end;

    local procedure GetOriginalOccurrenceID(OriginalOccurrenceEntryNo: Integer): Text
    var
        OriginalOccurrence: Record "FR E-Invoice Lifecycle";
    begin
        OriginalOccurrence.Get(OriginalOccurrenceEntryNo);
        exit(Format(OriginalOccurrence."Source Occurrence ID"));
    end;

    local procedure LifecycleStatusCode(LifecycleStatus: Enum "FR E-Invoice Lifecycle Status"): Text
    begin
        case LifecycleStatus of
            LifecycleStatus::Collected:
                exit('COLLECTED');
            LifecycleStatus::"Negative Collected":
                exit('NEGATIVE_COLLECTED');
            LifecycleStatus::Refused:
                exit('REFUSED');
            LifecycleStatus::Submitted:
                exit('SUBMITTED');
            LifecycleStatus::Rejected:
                exit('REJECTED');
            LifecycleStatus::Accepted:
                exit('ACCEPTED');
        end;
    end;

    var
        NoCapturedOccurrenceErr: Label 'No unprocessed French invoice lifecycle occurrence exists for E-Document entry %1.', Comment = '%1 = E-Document entry number';
}