namespace System.Integration;

table 1797 "Data Migration Error"
{
    Caption = 'Data Migration Error';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(2; "Migration Type"; Text[250])
        {
            Caption = 'Migration Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Destination Table ID"; Integer)
        {
            Caption = 'Destination Table ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Source Staging Table Record ID"; RecordID)
        {
            Caption = 'Source Staging Table Record ID';
            DataClassification = CustomerContent;
        }
        field(5; "Error Message"; Text[250])
        {
            Caption = 'Error Message';
            DataClassification = CustomerContent;
        }
        field(6; "Scheduled For Retry"; Boolean)
        {
            Caption = 'Scheduled For Retry';
            DataClassification = SystemMetadata;
        }
        field(9; "Error Dismissed"; Boolean)
        {
            Caption = 'Error Dismissed';
            DataClassification = SystemMetadata;
        }
        field(10; "Exception Message"; BLOB)
        {
            DataClassification = CustomerContent;
        }
        field(11; "Exception Call Stack"; BLOB)
        {
            DataClassification = CustomerContent;
        }
        field(12; "Last Record Under Processing"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Last record under processing';
        }
        field(15; "Records Under Processing Log"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Log of Last record under processing';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
        key(Key2; "Destination Table ID", "Migration Type")
        {
        }
    }

    fieldgroups
    {
    }

    procedure CreateEntryWithMessage(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID; ErrorMessage: Text[2048])
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        Init();
        if DataMigrationError.FindLast() then
            Id := DataMigrationError.Id + 1
        else
            Id := 1;
        Validate("Migration Type", MigrationType);
        Validate("Destination Table ID", DestinationTableId);
        Validate("Source Staging Table Record ID", SourceStagingTableRecordId);
        Validate("Error Message", ErrorMessage);
        Validate("Scheduled For Retry", false);
        Insert(true);

        UpdateErrorLogging(Rec);

        OnAfterErrorInserted(MigrationType, ErrorMessage);
    end;

    local procedure UpdateErrorLogging(var DataMigrationError: Record "Data Migration Error")
    var
        DataMigrationErrorLogging: Codeunit "Data Migration Error Logging";
    begin
        if DataMigrationErrorLogging.GetLastRecordUnderProcessing() = '' then
            exit;

        DataMigrationError."Last Record Under Processing" := CopyStr(DataMigrationErrorLogging.GetLastRecordUnderProcessing(), 1, MaxStrLen(DataMigrationError."Last Record Under Processing"));
        DataMigrationError.SetExceptionCallStack(GetLastErrorCallStack());
        DataMigrationError.SetFullExceptionMessage(GetLastErrorText());
        DataMigrationError.SetLastRecordUnderProcessingLog(DataMigrationErrorLogging.GetFullListOfLastRecordsUnderProcessingAsText());
    end;

    procedure CreateEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        CreateEntryWithMessage(MigrationType, DestinationTableId, SourceStagingTableRecordId, CopyStr(GetLastErrorText, 1, 250));
    end;

    procedure CreateEntryNoStagingTable(MigrationType: Text[250]; DestinationTableId: Integer)
    var
        DummyRecordId: RecordID;
    begin
        CreateEntry(MigrationType, DestinationTableId, DummyRecordId);
    end;

    procedure CreateEntryNoStagingTableWithMessage(MigrationType: Text[250]; DestinationTableId: Integer; ErrorMessage: Text[250])
    var
        DummyRecordId: RecordID;
    begin
        CreateEntryWithMessage(MigrationType, DestinationTableId, DummyRecordId, ErrorMessage);
    end;

    procedure ClearEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        if FindEntry(MigrationType, DestinationTableId, SourceStagingTableRecordId) then
            Delete(true);
    end;

    procedure ClearEntryNoStagingTable(MigrationType: Text[250]; DestinationTableId: Integer)
    var
        DummyRecordId: RecordID;
    begin
        ClearEntry(MigrationType, DestinationTableId, DummyRecordId);
    end;

    procedure FindEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID): Boolean
    begin
        FilterOnParameters(MigrationType, DestinationTableId, SourceStagingTableRecordId);
        exit(FindFirst());
    end;

    procedure ExistsEntry(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID): Boolean
    begin
        FilterOnParameters(MigrationType, DestinationTableId, SourceStagingTableRecordId);
        exit(not IsEmpty);
    end;

    local procedure FilterOnParameters(MigrationType: Text[250]; DestinationTableId: Integer; SourceStagingTableRecordId: RecordID)
    begin
        SetRange("Migration Type", MigrationType);
        SetRange("Destination Table ID", DestinationTableId);
        SetRange("Source Staging Table Record ID", SourceStagingTableRecordId);
    end;

    procedure Ignore()
    var
        DataMigrationStatusFacade: Codeunit "Data Migration Status Facade";
        RecordRef: RecordRef;
    begin
        RecordRef.Get("Source Staging Table Record ID");
        RecordRef.Delete(true);
        Delete(true);
        DataMigrationStatusFacade.IgnoreErrors("Migration Type", "Destination Table ID", 1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterErrorInserted(MigrationType: Text; ErrorMessage: Text)
    begin
    end;

    procedure GetErrorMessage(MigrationType: Text[250]; SourceRecordId: RecordID; var ErrorMessage: Text[250])
    begin
        SetRange("Migration Type", MigrationType);
        SetRange("Source Staging Table Record ID", SourceRecordId);
        if FindFirst() then
            ErrorMessage := "Error Message"
        else
            ErrorMessage := '';
    end;

    procedure GetFullExceptionMessage(): Text
    var
        ExceptionMessageInStream: InStream;
        ExceptionMessage: Text;
    begin
        Rec.CalcFields("Exception Message");
        if not Rec."Exception Message".HasValue() then
            exit('');

        Rec."Exception Message".CreateInStream(ExceptionMessageInStream, GetDefaultTextEncoding());
        ExceptionMessageInStream.Read(ExceptionMessage);
        exit(ExceptionMessage);
    end;

    procedure SetFullExceptionMessage(ExceptionMessage: Text)
    var
        ExceptionMessageOutStream: OutStream;
    begin
        Rec."Exception Message".CreateOutStream(ExceptionMessageOutStream, GetDefaultTextEncoding());
        ExceptionMessageOutStream.Write(ExceptionMessage);
        Rec.Modify(true);
    end;

    procedure GetExceptionCallStack(): Text
    var
        ExceptionCallStackInStream: InStream;
        ExceptionCallStack: Text;
    begin
        Rec.CalcFields("Exception Call Stack");
        if not Rec."Exception Call Stack".HasValue() then
            exit('');

        Rec."Exception Call Stack".CreateInStream(ExceptionCallStackInStream, GetDefaultTextEncoding());
        ExceptionCallStackInStream.Read(ExceptionCallStack);
        exit(ExceptionCallStack);
    end;

    procedure GetExceptionMessageWithStackTrace(): Text
    var
        FullExceptionMessage: Text;
        NewLine: Text;
    begin
        FullExceptionMessage := Rec.GetFullExceptionMessage();

        if FullExceptionMessage = '' then
            exit('');

        NewLine[1] := 10;
        FullExceptionMessage := FullExceptionMessage;
        FullExceptionMessage += NewLine + NewLine + Rec.GetExceptionCallStack();
        exit(FullExceptionMessage);
    end;

    procedure SetExceptionCallStack(ExceptionCallStack: Text)
    var
        ExceptionCallStackOutStream: OutStream;
    begin
        Rec."Exception Call Stack".CreateOutStream(ExceptionCallStackOutStream, GetDefaultTextEncoding());
        ExceptionCallStackOutStream.Write(ExceptionCallStack);
        Rec.Modify(true);
    end;

    procedure SetLastRecordUnderProcessingLog(RecordsUnderProcessingLog: Text)
    var
        RecordsUnderProcessingOutStreamLog: OutStream;
    begin
        Rec."Records Under Processing Log".CreateOutStream(RecordsUnderProcessingOutStreamLog, GetDefaultTextEncoding());
        RecordsUnderProcessingOutStreamLog.Write(RecordsUnderProcessingLog);
        Rec.Modify(true);
    end;

    procedure GetLastRecordsUnderProcessingLog(): Text
    var
        RecordsUnderProcessingLogInStream: InStream;
        RecordsUnderProcessingLog: Text;
    begin
        Rec.CalcFields("Records Under Processing Log");
        if not Rec."Records Under Processing Log".HasValue() then
            exit('');

        Rec."Records Under Processing Log".CreateInStream(RecordsUnderProcessingLogInStream, GetDefaultTextEncoding());
        RecordsUnderProcessingLogInStream.Read(RecordsUnderProcessingLog);
        exit(RecordsUnderProcessingLog);
    end;

    local procedure GetDefaultTextEncoding(): TextEncoding
    begin
        exit(TEXTENCODING::UTF16);
    end;
}

