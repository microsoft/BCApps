// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7434 "EA Corp Card Providers"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Providers';
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
                field("Source Payload Records"; Rec."Source Payload Record Count")
                {
                    ApplicationArea = Basic, Suite;
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
                field("Last Statement Entry No."; Rec."Last Statement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest imported statement entry.';
                }
                field("Corp Card Bank Account No."; Rec."Corp Card Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account that represents the corporate card liability.';
                }
                field("Payment Bank Account No."; Rec."Payment Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the real bank account from which settlements are paid.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(Import)
            {
                Caption = 'Import';

                action(UploadSourcePayload)
                {
                    Caption = 'Upload Source File';
                    ApplicationArea = Basic, Suite;
                    Image = Import;
                    ToolTip = 'Upload a source file to the selected provider for statement imports.';

                    trigger OnAction()
                    begin
                        UploadSourcePayloadForProvider();
                    end;
                }
                action(ClearSourcePayload)
                {
                    Caption = 'Clear Source File';
                    ApplicationArea = Basic, Suite;
                    Image = Delete;
                    ToolTip = 'Clear the stored source file and file name for the selected provider.';

                    trigger OnAction()
                    begin
                        ClearSourcePayloadForProvider();
                    end;
                }
                action(ImportStatement)
                {
                    Caption = 'Import Statement';
                    ApplicationArea = Basic, Suite;
                    Image = Import;
                    ToolTip = 'Import a statement immediately for the selected provider.';

                    trigger OnAction()
                    begin
                        ImportStatementForProvider();
                    end;
                }
            }
            group(Scheduling)
            {
                Caption = 'Scheduling';

                action(ScheduleImport)
                {
                    Caption = 'Schedule Import';
                    ApplicationArea = Basic, Suite;
                    Image = Calendar;
                    ToolTip = 'Schedule recurring imports for the selected provider.';

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
                    ToolTip = 'Remove the scheduled import job for the selected provider.';

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
                    ToolTip = 'View the scheduled import job for the selected provider.';

                    trigger OnAction()
                    begin
                        ViewProviderSchedule();
                    end;
                }
            }
            group(Setup)
            {
                Caption = 'Setup';

                action(InitializeDataExchange)
                {
                    Caption = 'Initialize Data Exchange';
                    ApplicationArea = Basic, Suite;
                    Image = Setup;
                    ToolTip = 'Create or repair the data exchange definition and mappings for the selected provider.';

                    trigger OnAction()
                    begin
                        InitializeDataExchangeForProvider();
                    end;
                }
            }
        }
        area(Navigation)
        {
            group(Provider)
            {
                Caption = 'Provider';

                action(Statements)
                {
                    Caption = 'Statements';
                    ApplicationArea = Basic, Suite;
                    Image = Documents;
                    RunObject = Page "EA Corp Card Statements";
                    RunPageLink = "Provider Code" = field(Code);
                    ToolTip = 'View statements for the selected provider.';
                }
                action(Settlements)
                {
                    Caption = 'Settlements';
                    ApplicationArea = Basic, Suite;
                    Image = Payment;
                    RunObject = Page "EA Corp Card Settlements";
                    RunPageLink = "Provider Code" = field(Code);
                    ToolTip = 'View settlements for the selected provider.';
                }
                action(OpenLatestStatement)
                {
                    Caption = 'Latest Statement';
                    ApplicationArea = Basic, Suite;
                    Image = Navigate;
                    ToolTip = 'Open the latest imported statement for the selected provider.';

                    trigger OnAction()
                    begin
                        OpenLatestStatementForProvider();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ImportStatement_Promoted; ImportStatement)
                {
                }
                actionref(UploadSourcePayload_Promoted; UploadSourcePayload)
                {
                }
                actionref(ViewSchedule_Promoted; ViewSchedule)
                {
                }
            }
            group(Category_Provider)
            {
                Caption = 'Provider';

                actionref(Statements_Promoted; Statements)
                {
                }
                actionref(Settlements_Promoted; Settlements)
                {
                }
            }
        }
    }

    var
        UploadCanceledMsg: Label 'Upload was canceled.';
        SourcePayloadClearedMsg: Label 'Source payload was cleared for provider %1.', Comment = '%1 = Provider code';
        SourcePayloadSavedMsg: Label 'Source payload was uploaded for provider %1.', Comment = '%1 = Provider code';
        ImportTriggeredMsg: Label 'Import was triggered for provider %1.', Comment = '%1 = Provider code';
        ProviderScheduledMsg: Label 'Provider %1 scheduled for daily import.', Comment = '%1 = Provider code';
        UnscheduleProviderQst: Label 'Are you sure you want to unschedule imports for provider %1?', Comment = '%1 = Provider code';
        ScheduleManagementMsg: Label 'Import scheduling is managed via the Schedule Import and Unschedule Import actions.';
        DataExchangeInitializedMsg: Label 'Data Exchange setup is ready for provider %1 (Definition: %2, Mapping: %3).', Comment = '%1 = Provider code, %2 = Data Exch Def Code, %3 = Data Exch Map Code';
        ReplacePayloadQst: Label 'Provider %1 already has source payload. Do you want to replace it?', Comment = '%1 = Provider code';
        NoStatementFoundErr: Label 'No imported statement exists yet for provider %1.', Comment = '%1 = Provider code';
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
        Clear(OutStr);
        Rec."Source File Name" := CopyStr(FileName, 1, MaxStrLen(Rec."Source File Name"));
        Rec.UpdateSourcePayloadRecordCount();
        Rec.Modify(true);

        CurrPage.Update(false);
        Message(SourcePayloadSavedMsg, Rec.Code);
    end;

    local procedure ClearSourcePayloadForProvider()
    begin
        Clear(Rec."Source Payload");
        Rec."Source File Name" := '';
        Rec."Source Payload Record Count" := 0;
        Rec.Modify(true);

        CurrPage.Update(false);
        Message(SourcePayloadClearedMsg, Rec.Code);
    end;

    local procedure ImportStatementForProvider()
    var
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
    begin
        CorpCardFeedMgt.RunImport(Rec.Code);
        Message(ImportTriggeredMsg, Rec.Code);
    end;

    local procedure OpenLatestStatementForProvider()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
    begin
        if Rec."Last Statement Entry No." = 0 then
            Error(NoStatementFoundErr, Rec.Code);

        CorpCardStatement.SetRange("Provider Code", Rec.Code);
        CorpCardStatement.SetRange("Statement Entry No.", Rec."Last Statement Entry No.");
        Page.RunModal(Page::"EA Corp Card Statement", CorpCardStatement);
    end;

    local procedure ScheduleProviderImport()
    var
        JQMgt: Codeunit "EA Corp Card JQ Mgt";
    begin
        JQMgt.ScheduleProviderImport(Rec.Code, 1440, 080000T, Today());
        Message(ProviderScheduledMsg, Rec.Code);
    end;

    local procedure UnscheduleProviderImport()
    var
        JQMgt: Codeunit "EA Corp Card JQ Mgt";
    begin
        if Confirm(UnscheduleProviderQst, false, Rec.Code) then
            JQMgt.UnscheduleProviderImport(Rec.Code);
    end;

    local procedure ViewProviderSchedule()
    begin
        Message(ScheduleManagementMsg);
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

}