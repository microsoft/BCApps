codeunit 118230 "Create Data Exch. Column Def"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        DirectoryInfo: DotNet DirectoryInfo;
        FileInfo: DotNet FileInfo;
        Enumerator: DotNet IEnumerator;
        Path: Text;
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Path to Picture Folder" = '' then
            Path := TemporaryPath() + '\..\' + 'PostingExchangeDefinitions'
        else
            Path := DemoDataSetup."Path to Picture Folder" + 'PostingExchangeDefinitions';

        DirectoryInfo := DirectoryInfo.DirectoryInfo(Path);

        if DirectoryInfo.Exists then begin
            if Exists(StrSubstNo('%1\%2', Path, ExportFileNameTxt)) then
                Erase(StrSubstNo('%1\%2', Path, ExportFileNameTxt));

            if not Exists(Path + '\Sepa Camt.xml') then
                Error(NoFileErr, Path);
            Enumerator := DirectoryInfo.GetFiles('*.xml').GetEnumerator();
            while Enumerator.MoveNext() do begin
                FileInfo := Enumerator.Current;
                ImportDataExchDef(FileInfo.FullName);
            end;
            CreateBankExportImportSetup();
            ExportDataExchDef(Path);
            PopulateDataExchangeTypesTable();
        end else
            Error(NoDirectoryErr);
    end;

    var
        NoFileErr: Label 'There is no Sepa Camt.xml file in the path %1.';
        NoDirectoryErr: Label 'There is no PostingExchangeDefinitions directory in the temporary path.';
        ExportFileNameTxt: Label 'DefaultDataExchangeSetup.xml', Locked = true;

    procedure ImportDataExchDef(FullPath: Text)
    var
        InputFile: File;
        InStream: InStream;
    begin
        InputFile.Open(FullPath);
        InputFile.CreateInStream(InStream);

        XMLPORT.Import(XMLPORT::"Imp / Exp Data Exch Def & Map", InStream)
    end;

    procedure CreateBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DataExchDef: Record "Data Exch. Def";
    begin
        DataExchDef.SetFilter(Type, '%1|%2', DataExchDef.Type::"Bank Statement Import", DataExchDef.Type::"Payment Export");
        if DataExchDef.FindSet() then
            repeat
                BankExportImportSetup.Init();
                BankExportImportSetup.Code := DataExchDef.Code;
                BankExportImportSetup.Name := DataExchDef.Name;
                BankExportImportSetup."Data Exch. Def. Code" := DataExchDef.Code;
                BankExportImportSetup."Processing Codeunit ID" := CODEUNIT::"Exp. Launcher Gen. Jnl.";
                case DataExchDef.Type of
                    DataExchDef.Type::"Bank Statement Import":
                        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Import;
                    DataExchDef.Type::"Payment Export":
                        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
                end;
                BankExportImportSetup.Insert();
            until DataExchDef.Next() = 0;
    end;

    procedure ExportDataExchDef(FullPath: Text)
    var
        OutputFile: File;
        OutStream: OutStream;
    begin
        OutputFile.Create(StrSubstNo('%1\%2', FullPath, ExportFileNameTxt));
        OutputFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"Imp / Exp Data Exch Def & Map", OutStream)
    end;

    local procedure PopulateDataExchangeTypesTable()
    begin
        PopulateDataExchangeType('PEPPOLINVOICE');
        PopulateDataExchangeType('PEPPOLCREDITMEMO');
        PopulateDataExchangeType('OCRINVOICE');
        PopulateDataExchangeType('OCRCREDITMEMO');
    end;

    local procedure PopulateDataExchangeType(DataExchDefCode: Code[20])
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchangeType: Record "Data Exchange Type";
    begin
        DataExchDef.SetRange(Code, DataExchDefCode);
        if DataExchDef.FindFirst() then begin
            DataExchangeType.Init();
            DataExchangeType.Code := DataExchDef.Code;
            DataExchangeType.Description := DataExchDef.Name;
            DataExchangeType."Data Exch. Def. Code" := DataExchDef.Code;
            DataExchangeType.Insert(true);
        end;
    end;
}

