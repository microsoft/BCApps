// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

/// <summary>
/// Extends the E-Documents page with actions to receive and download documents from the Avalara service.
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
                ToolTip = 'Receives available E-Documents from the Avalara service using the standard E-Document import pipeline.';

                trigger OnAction()
                var
                    EDocService: Record "E-Document Service";
                    EDocImport: Codeunit "E-Doc. Import";
                begin
                    if not SelectAvalaraService(EDocService) then
                        exit;

                    EDocImport.ReceiveAndProcessAutomatically(EDocService);
                    CurrPage.Update(false);
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
                    AvalaraFunctions: Codeunit "Avalara Functions";
                    SuccessCount: Integer;
                    MediaTypes: List of [Text];
                    MediaType: Text;
                begin
                    if not SelectAvalaraService(EDocService) then
                        exit;

                    MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate(EDocService."Avalara Mandate");

                    SuccessCount := 0;
                    foreach MediaType in MediaTypes do
                        if AvalaraDocMgt.DownloadDocument(Rec, Rec."Avalara Document Id", MediaType) then
                            SuccessCount += 1;

                    if SuccessCount > 0 then
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
        EDocService.SetRange("Service Integration V2", EDocService."Service Integration V2"::Avalara);
        EDocServicesPage.SetTableView(EDocService);
        EDocServicesPage.LookupMode := true;
        EDocServicesPage.Caption := ServiceSelectionCaptionTxt;

        if EDocServicesPage.RunModal() <> Action::LookupOK then
            exit(false);

        EDocServicesPage.GetRecord(EDocService);
        exit(true);
    end;
}
