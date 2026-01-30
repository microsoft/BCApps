/// <summary>
/// Extends E-Documents page with Avalara document receiving and download capabilities.
/// </summary>
pageextension 6373 "E-Docs." extends "E-Documents"
{
    actions
    {
        addlast(Processing)
        {
            action(ReceiveAvalaraDocuments)
            {
                ApplicationArea = All;
                Caption = 'Receive E-Documents from Avalara';
                Image = Import;
                ToolTip = 'Receives available E-Documents from the Avalara service.';

                trigger OnAction()
                var
                    EDocService: Record "E-Document Service";
                    AvalaraDocMgt: Codeunit "Avalara Document Management";
                    ReceivedCount: Integer;
                begin
                    if not SelectAvalaraService(EDocService) then
                        exit;

                    ReceivedCount := AvalaraDocMgt.ReceiveAndProcessDocuments(EDocService, Rec);
                    if ReceivedCount > 0 then
                        Message(DocumentsReceivedMsg, ReceivedCount);
                end;
            }

            action(DownloadAvalaraDocuments)
            {
                ApplicationArea = All;
                Caption = 'Download E-Document';
                Enabled = Rec."Avalara Document Id" <> '';
                Image = Download;
                ToolTip = 'Downloads the selected E-Document from Avalara in all available formats.';

                trigger OnAction()
                var
                    EDocService: Record "E-Document Service";
                    AvalaraDocMgt: Codeunit "Avalara Document Management";
                begin
                    if not SelectAvalaraService(EDocService) then
                        exit;

                    if AvalaraDocMgt.DownloadDocumentWithAllMediaTypes(Rec, EDocService, Rec."Avalara Document Id") then
                        Message(DocumentDownloadedMsg);
                end;
            }
            action(ViewDocumentStatus)
            {
                ApplicationArea = All;
                Caption = 'View Document Status';
                Enabled = Rec."Avalara Document Id" <> '';
                Image = Status;
                ToolTip = 'Displays the current status of the E-Document in Avalara.';

                trigger OnAction()
                var
                    AvalaraDocMgt: Codeunit "Avalara Document Management";
                begin
                    Rec.TestField("Avalara Document Id");
                    AvalaraDocMgt.ShowDocumentStatus(Rec);
                end;
            }
        }

        addlast(Promoted)
        {
            group(Avalara)
            {
                actionref(ReceiveAvalaraDocuments_Promoted; ReceiveAvalaraDocuments) { }
                actionref(DownloadAvalaraDocuments_Promoted; DownloadAvalaraDocuments) { }
                actionref(ViewDocumentStatus_Promoted; ViewDocumentStatus) { }
            }
        }
    }

    var
        DocumentDownloadedMsg: Label 'Document(s) downloaded successfully.';
        DocumentsReceivedMsg: Label '%1 document(s) received from Avalara.', Comment = '%1 = number of documents';
        ServiceSelectionCaptionTxt: Label 'Select Avalara Service';

    /// <summary>
    /// Prompts user to select an Avalara E-Document service.
    /// </summary>
    /// <param name="EDocService">Returns the selected E-Document Service record.</param>
    /// <returns>True if a service was selected, false if cancelled.</returns>
    local procedure SelectAvalaraService(var EDocService: Record "E-Document Service"): Boolean
    var
        EDocServicesPage: Page "E-Document Services";
    begin
        EDocService.SetRange("Service Integration V2", Enum::"Service Integration"::Avalara);
        EDocServicesPage.SetTableView(EDocService);
        EDocServicesPage.LookupMode := true;
        EDocServicesPage.Caption := ServiceSelectionCaptionTxt;

        if EDocServicesPage.RunModal() <> Action::LookupOK then
            exit(false);

        EDocServicesPage.GetRecord(EDocService);
        exit(true);
    end;
}
