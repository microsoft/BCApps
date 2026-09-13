// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7224 "EA Corp Card Providers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Providers';
    PageType = List;
    UsageCategory = Administration;
    SourceTable = "EA Corp Card Provider";

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
                field("Source Payload Records"; GetSourcePayloadRecordCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Source Payload Records';
                    Editable = false;
                    ToolTip = 'Specifies the number of transaction records detected in the uploaded source payload.';
                }
                field("Detected Source Format"; GetDetectedSourceFormat())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detected Source Format';
                    ToolTip = 'Specifies the detected import file format for the provider, based on source file name and data exchange definition.';
                    Editable = false;
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
            action(ScheduleImport)
            {
                Caption = 'Schedule Import';
                ApplicationArea = Basic, Suite;
                Image = Calendar;
                ToolTip = 'Schedules recurring imports for the selected provider.';

                trigger OnAction()
                begin
                    ScheduleProviderImport();
                end;
            }
            action(UnscheduleImport)
            {
                Caption = 'Unschedule Import';
                ApplicationArea = Basic, Suite;
                Image = Delete;
                ToolTip = 'Removes the scheduled import job for the selected provider.';

                trigger OnAction()
                begin
                    UnscheduleProviderImport();
                end;
            }
            action(ViewSchedule)
            {
                Caption = 'View Schedule';
                ApplicationArea = Basic, Suite;
                Image = List;
                ToolTip = 'Views the scheduled import job for the selected provider.';

                trigger OnAction()
                begin
                    ViewProviderSchedule();
                end;
            }
            action(InitializeDataExchange)
            {
                Caption = 'Initialize Data Exchange';
                ApplicationArea = Basic, Suite;
                Image = Setup;
                ToolTip = 'Creates or repairs Data Exchange definition and mappings for the selected provider.';

                trigger OnAction()
                begin
                    InitializeDataExchangeForProvider();
                end;
            }
        }
    }

    var
        UploadCanceledMsg: Label 'Upload was canceled.';
        SourcePayloadClearedMsg: Label 'Source payload was cleared for provider %1.', Comment = '%1 = Provider code';
        SourcePayloadSavedMsg: Label 'Source payload was uploaded for provider %1.', Comment = '%1 = Provider code';
        ImportTriggeredMsg: Label 'Import was triggered for provider %1.', Comment = '%1 = Provider code';
        DataExchangeInitializedMsg: Label 'Data Exchange setup is ready for provider %1 (Definition: %2, Mapping: %3).', Comment = '%1 = Provider code, %2 = Data Exch Def Code, %3 = Data Exch Map Code';
        ReplacePayloadQst: Label 'Provider %1 already has source payload. Do you want to replace it?', Comment = '%1 = Provider code';
        NoBatchFoundErr: Label 'No import batch exists yet for provider %1.', Comment = '%1 = Provider code';
        CsvLbl: Label 'CSV', Locked = true;
        XmlLbl: Label 'XML', Locked = true;
        CamtLbl: Label 'CAMT', Locked = true;
        NotSetLbl: Label 'Not set', Locked = true;
        UnknownLbl: Label 'Unknown', Locked = true;

    local procedure UploadSourcePayloadForProvider()
    var
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
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
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunImport(Rec.Code);
        Message(ImportTriggeredMsg, Rec.Code);
    end;

    local procedure OpenLatestBatchForProvider()
    var
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        if Rec."Last Batch No." = 0 then
            Error(NoBatchFoundErr, Rec.Code);

        CorpCardBatch.SetRange("Provider Code", Rec.Code);
        CorpCardBatch.SetRange("Batch No.", Rec."Last Batch No.");
        Page.RunModal(Page::"EA Corp Card Batches", CorpCardBatch);
    end;

    local procedure ScheduleProviderImport()
    var
        JQMgt: Codeunit "EA Corp Card JQ Mgt";
    begin
        JQMgt.ScheduleProviderImport(Rec.Code, 1440, 080000T, Today());
        Message('Provider %1 scheduled for daily import.', Rec.Code);
    end;

    local procedure UnscheduleProviderImport()
    var
        JQMgt: Codeunit "EA Corp Card JQ Mgt";
    begin
        if Confirm('Are you sure you want to unschedule imports for provider %1?', false, Rec.Code) then
            JQMgt.UnscheduleProviderImport(Rec.Code);
    end;

    local procedure ViewProviderSchedule()
    begin
        Message('Import scheduling is managed via the Schedule Import and Unschedule Import actions.');
    end;

    local procedure InitializeDataExchangeForProvider()
    var
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
    begin
        CreateCorpCardSetup.EnsureDataExchangeForProvider(Rec);
        CurrPage.Update(false);
        Message(DataExchangeInitializedMsg, Rec.Code, Rec."Data Exch Def Code", Rec."Data Exch Map Code");
    end;

    local procedure GetDetectedSourceFormat(): Text[30]
    var
        FileNameLower: Text;
    begin
        FileNameLower := LowerCase(Rec."Source File Name");

        if (StrPos(FileNameLower, 'camt') > 0) or (StrPos(UpperCase(Rec."Data Exch Def Code"), 'CAMT') > 0) then
            exit(CamtLbl);

        if (StrPos(FileNameLower, '.xml') > 0) or (StrPos(UpperCase(Rec."Data Exch Def Code"), 'XML') > 0) then
            exit(XmlLbl);

        if (StrPos(FileNameLower, '.csv') > 0) or (StrPos(UpperCase(Rec."Data Exch Def Code"), 'CSV') > 0) then
            exit(CsvLbl);

        if Rec."Source File Name" = '' then
            exit(NotSetLbl);

        exit(UnknownLbl);
    end;

    local procedure GetSourcePayloadRecordCount(): Integer
    var
        ProviderRefreshed: Record "EA Corp Card Provider";
        PayloadInStr: InStream;
        PayloadTxt: Text;
        SourceFileNameLower: Text;
        DataExchDefCodeUpper: Text;
    begin
        if not ProviderRefreshed.Get(Rec.Code) then
            exit(0);

        ProviderRefreshed.CalcFields("Source Payload");
        if not ProviderRefreshed."Source Payload".HasValue then
            exit(0);

        ProviderRefreshed."Source Payload".CreateInStream(PayloadInStr, TextEncoding::UTF8);
        PayloadTxt := ReadStreamAsText(PayloadInStr);
        if PayloadTxt = '' then
            exit(0);

        SourceFileNameLower := LowerCase(ProviderRefreshed."Source File Name");
        DataExchDefCodeUpper := UpperCase(ProviderRefreshed."Data Exch Def Code");

        if (StrPos(SourceFileNameLower, '.csv') > 0) or (StrPos(DataExchDefCodeUpper, 'CSV') > 0) then
            exit(GetCsvRecordCount(PayloadTxt));

        if (StrPos(SourceFileNameLower, 'camt054') > 0) or (StrPos(SourceFileNameLower, 'camt.054') > 0) or (StrPos(DataExchDefCodeUpper, 'CAMT054') > 0) then
            exit(CountOccurrences(PayloadTxt, '<TxDtls>'));

        if (StrPos(SourceFileNameLower, 'camt') > 0) or (StrPos(DataExchDefCodeUpper, 'CAMT') > 0) then
            exit(CountOccurrences(PayloadTxt, '<Ntry>'));

        if (StrPos(SourceFileNameLower, '.xml') > 0) or (StrPos(DataExchDefCodeUpper, 'XML') > 0) or (StrPos(DataExchDefCodeUpper, 'ISO') > 0) then
            exit(CountOccurrences(PayloadTxt, '<Transaction>'));

        exit(CountOccurrences(PayloadTxt, '<Transaction>'));
    end;

    local procedure ReadStreamAsText(var PayloadInStr: InStream): Text
    var
        LineTxt: Text;
        NewLineChar: Char;
        ResultTxt: Text;
    begin
        NewLineChar := 10;
        while not PayloadInStr.EOS do begin
            PayloadInStr.ReadText(LineTxt);
            if ResultTxt <> '' then
                ResultTxt += Format(NewLineChar);
            ResultTxt += LineTxt;
        end;

        exit(ResultTxt);
    end;

    local procedure GetCsvRecordCount(PayloadTxt: Text): Integer
    var
        Count: Integer;
        Remaining: Text;
        LineTxt: Text;
        NewLinePos: Integer;
        HeaderHandled: Boolean;
        CRChar: Char;
    begin
        Remaining := PayloadTxt;
        CRChar := 13;
        while Remaining <> '' do begin
            NewLinePos := StrPos(Remaining, Format(10));
            if NewLinePos = 0 then begin
                LineTxt := Remaining;
                Remaining := '';
            end else begin
                LineTxt := CopyStr(Remaining, 1, NewLinePos - 1);
                Remaining := CopyStr(Remaining, NewLinePos + 1);
            end;

            LineTxt := LineTxt.Replace(Format(CRChar), '').Trim();
            if LineTxt = '' then
                continue;

            if not HeaderHandled then begin
                HeaderHandled := true;
                if IsCsvHeaderLine(LineTxt) then
                    continue;
            end;

            Count += 1;
        end;

        exit(Count);
    end;

    local procedure IsCsvHeaderLine(LineTxt: Text): Boolean
    var
        LowerLineTxt: Text;
    begin
        LowerLineTxt := LowerCase(LineTxt);
        exit((StrPos(LowerLineTxt, 'providertransid') > 0) and (StrPos(LowerLineTxt, 'cardid') > 0));
    end;

    local procedure CountOccurrences(SourceTxt: Text; Token: Text): Integer
    var
        Count: Integer;
        Position: Integer;
        SearchFrom: Integer;
    begin
        if (SourceTxt = '') or (Token = '') then
            exit(0);

        SearchFrom := 1;
        repeat
            Position := StrPos(CopyStr(SourceTxt, SearchFrom), Token);
            if Position = 0 then
                break;

            Count += 1;
            SearchFrom := SearchFrom + Position + StrLen(Token) - 1;
        until SearchFrom > StrLen(SourceTxt);

        exit(Count);
    end;

}