// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN25
namespace Microsoft.Foundation.Attachment;

page 1174 "Document Attachment Factbox"
{
    ObsoleteReason = 'The "Document Attachment FactBox" has been replaced by "Doc. Attachment List Factbox", which supports multiple files upload.';
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
    Caption = 'Documents Attached';
    PageType = CardPart;
    SourceTable = "Document Attachment";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                ShowCaption = false;
                field(Documents; NumberOfRecords)
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    StyleExpr = true;
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    begin
                        LoadAndRunDocumentAttachmentDetail();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeDrillDown(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(true, false)]
    internal procedure OnBeforeDocumentAttachmentDetailsRunModal(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var DocumentAttachmentDetails: Page "Document Attachment Details")
    begin
    end;

    local procedure LoadAndRunDocumentAttachmentDetail()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecRef: RecordRef;
    begin
        if Rec."Table ID" = 0 then
            exit;
        if not DocumentAttachmentMgmt.GetRefTable(RecRef, Rec) then
            OnBeforeDrillDown(Rec, RecRef);

        DocumentAttachmentDetails.OpenForRecRef(RecRef);
        OnBeforeDocumentAttachmentDetailsRunModal(Rec, RecRef, DocumentAttachmentDetails);
        DocumentAttachmentDetails.RunModal();
    end;

    trigger OnAfterGetCurrRecord()
    var
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnAfterGetCurrRecord(Rec, NumberOfRecords, IsHandled);
        if IsHandled then
            exit;

        DocumentAttachmentMgmt.UpdateNumOfRecForFactbox(Rec, NumberOfRecords);
    end;

    var
        NumberOfRecords: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnAfterGetCurrRecord(var DocumentAttachment: Record "Document Attachment"; var AttachmentCount: Integer; var IsHandled: Boolean)
    begin
    end;
}
#endif