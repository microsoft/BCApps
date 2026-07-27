// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7224 EACorpCardProviders
{
    Caption = 'Corp Card Providers';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = EACorpCardProvider;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider description.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether this provider is enabled for import.';
                }
                field("Feed Type"; Rec."Feed Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the feed type used to import transactions.';
                }
                field("Data Exch Def Code"; Rec."Data Exch Def Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange definition code used for file-based imports.';
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source file name associated with the payload content.';
                }
                field("Last Import DT"; Rec."Last Import DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date-time of the latest import run.';
                }
                field("Last Batch No."; Rec."Last Batch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest import batch number.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UploadSourcePayload)
            {
                Caption = 'Upload Source Payload';
                ApplicationArea = Basic, Suite;
                Image = Import;
                ToolTip = 'Uploads a source file payload to the selected provider for test imports.';

                trigger OnAction()
                begin
                    UploadSourcePayloadForProvider();
                end;
            }
            action(ClearSourcePayload)
            {
                Caption = 'Clear Source Payload';
                ApplicationArea = Basic, Suite;
                Image = Delete;
                ToolTip = 'Clears the stored source payload and file name for the selected provider.';

                trigger OnAction()
                begin
                    ClearSourcePayloadForProvider();
                end;
            }
            action(TestImport)
            {
                Caption = 'Test Import';
                ApplicationArea = Basic, Suite;
                Image = TestFile;
                ToolTip = 'Runs import immediately for the selected provider.';

                trigger OnAction()
                begin
                    RunTestImportForProvider();
                end;
            }
            action(OpenLatestBatch)
            {
                Caption = 'Open Latest Batch';
                ApplicationArea = Basic, Suite;
                Image = Navigate;
                ToolTip = 'Opens the latest import batch for the selected provider.';

                trigger OnAction()
                begin
                    OpenLatestBatchForProvider();
                end;
            }
        }
    }

    var
        UploadCanceledMsg: Label 'Upload was canceled.';
        SourcePayloadClearedMsg: Label 'Source payload was cleared for provider %1.', Comment = '%1 = Provider code';
        SourcePayloadSavedMsg: Label 'Source payload was uploaded for provider %1.', Comment = '%1 = Provider code';
        ImportTriggeredMsg: Label 'Import was triggered for provider %1.', Comment = '%1 = Provider code';
        ReplacePayloadQst: Label 'Provider %1 already has source payload. Do you want to replace it?', Comment = '%1 = Provider code';
        DataExchDefMissingErr: Label 'Data Exchange Definition Code must be set for provider %1.', Comment = '%1 = Provider code';
        UnsupportedFeedTypeErr: Label 'Provider %1 feed type %2 is not supported for Data Exchange test payload.', Comment = '%1 = Provider code, %2 = Feed type';
        NoBatchFoundErr: Label 'No import batch exists yet for provider %1.', Comment = '%1 = Provider code';

    local procedure UploadSourcePayloadForProvider()
    var
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        ValidateProviderForDataExch();
        Rec.CalcFields("Source Payload");
        if Rec."Source Payload".HasValue then
            if not Confirm(ReplacePayloadQst, false, Rec.Code) then
                exit;

        if not UploadIntoStream('', '', '', FileName, InStr) then begin
            Message(UploadCanceledMsg);
            exit;
        end;

        Clear(Rec."Source Payload");
        Rec."Source Payload".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        Rec."Source File Name" := CopyStr(FileName, 1, MaxStrLen(Rec."Source File Name"));
        Rec.Modify(true);

        CurrPage.Update(false);
        Message(SourcePayloadSavedMsg, Rec.Code);
    end;

    local procedure ClearSourcePayloadForProvider()
    begin
        Clear(Rec."Source Payload");
        Rec."Source File Name" := '';
        Rec.Modify(true);

        CurrPage.Update(false);
        Message(SourcePayloadClearedMsg, Rec.Code);
    end;

    local procedure RunTestImportForProvider()
    var
        CorpCardFeedMgt: Codeunit EACorpCardFeedMgt;
    begin
        ValidateProviderForDataExch();
        CorpCardFeedMgt.RunImport(Rec.Code);
        Message(ImportTriggeredMsg, Rec.Code);
    end;

    local procedure OpenLatestBatchForProvider()
    var
        CorpCardBatch: Record EACorpCardBatch;
    begin
        if Rec."Last Batch No." = 0 then
            Error(NoBatchFoundErr, Rec.Code);

        CorpCardBatch.SetRange("Provider Code", Rec.Code);
        CorpCardBatch.SetRange("Batch No.", Rec."Last Batch No.");
        Page.RunModal(Page::EACorpCardBatches, CorpCardBatch);
    end;

    local procedure ValidateProviderForDataExch()
    begin
        if Rec."Data Exch Def Code" = '' then
            Error(DataExchDefMissingErr, Rec.Code);

        case Rec."Feed Type" of
            Rec."Feed Type"::DataExch,
            Rec."Feed Type"::CAMT,
            Rec."Feed Type"::ISO20022,
            Rec."Feed Type"::CSV:
                ;
            else
                Error(UnsupportedFeedTypeErr, Rec.Code, Format(Rec."Feed Type"));
        end;
    end;
}