codeunit 147127 "ERM Bank Statement RU"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        ExpectedVendorErr: Label 'Vendor was defined incorrectly.';
        LibraryRandom: Codeunit "Library - Random";
        FileDoesNotExistErr: Label 'File %1 does not exist.';
        ExportedDataIsWrongErr: Label 'The data from the export file does not match the expected value.';

    [Test]
    [Scope('OnPrem')]
    procedure TestImportColumnsAsRows()
    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
        VendorBankAcc: Record "Vendor Bank Account";
        BankAcc: Record "Bank Account";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        BankAccReconLine: Record "Bank Acc. Reconciliation Line";
        DataExchDef: Record "Data Exch. Def";
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchMapping: Record "Data Exch. Mapping";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
        DataExchField: Record "Data Exch. Field";
        DataExch: Record "Data Exch.";
        DataExchLineDef: Record "Data Exch. Line Def";
        TempBlob: Codeunit "Temp Blob";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        ProcessDataExch: Codeunit "Process Data Exch.";
        InStream: InStream;
        RecRef: RecordRef;
    begin
        CompanyInfo.Get();
        LibraryERM.CreateBankAccount(BankAcc);

        BankAcc."Bank Account No." :=
          LibraryUtility.GenerateRandomCode(BankAcc.FieldNo("Bank Account No."), DATABASE::"Bank Account");
        BankAcc.Modify();
        LibraryERM.CreateBankAccReconciliation(BankAccRecon, BankAcc."No.",
          BankAccRecon."Statement Type"::"Bank Reconciliation");
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorBankAccount(VendorBankAcc, Vendor."No.");

        DataExchDef.InsertRec(
          LibraryUtility.GenerateRandomCode(1, DATABASE::"Data Exch. Def"), 'RU Test Mapping',
          DataExchDef.Type::"Bank Statement Import", XMLPORT::"Data Exch. Import - CSV", 0, '', '');
        DataExchLineDef.InsertRec(DataExchDef.Code, '', '', 0);
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 1, 'DocumentNo', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(
          DataExchDef.Code, '', 2, 'DocumentDate', true, DataExchColumnDef."Data Type"::Date, 'ddMMyy', 'da-DK', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 3, 'DocumentAmount', true, DataExchColumnDef."Data Type"::Decimal, '', 'en-US', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 4, 'SenderBankAccNo', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 5, 'SenderVATRegNo', true, DataExchColumnDef."Data Type"::Text, '', '', '');
        DataExchColumnDef.InsertRec(DataExchDef.Code, '', 6, 'RecipientBankAccNo', true, DataExchColumnDef."Data Type"::Text, '', '', '');

        DataExchMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 'RU Test Mapping', 0,
          BankAccReconLine.FieldNo("Data Exch. Entry No."),
          BankAccReconLine.FieldNo("Data Exch. Line No."));
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 1, 4, false, 0);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 2, 5, false, 0);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 3, 7, false, 1);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 4, 12401, false, 0);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 5, 12402, false, 0);
        DataExchFieldMapping.InsertRec(
          DataExchDef.Code, '', DATABASE::"Bank Acc. Reconciliation Line", 6, 12409, false, 0);

        TempBlob.CreateInStream(InStream);
        DataExch.InsertRec('C:\AnyPath\AnyCSVFileName.txt', InStream, DataExchDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 1, 'DocNo1', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 2, '010113', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 3, '-100', DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 4, BankAcc."Bank Account No.", DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 5, CompanyInfo."VAT Registration No.", DataExchLineDef.Code);
        DataExchField.InsertRec(DataExch."Entry No.", 1, 6, VendorBankAcc."Bank Account No.", DataExchLineDef.Code);

        BankAccReconLine.Init();
        BankAccReconLine.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        BankAccReconLine.SetRange("Statement No.", BankAccRecon."Statement No.");
        BankAccReconLine."Statement No." := BankAccRecon."Statement No.";
        BankAccReconLine."Bank Account No." := BankAccRecon."Bank Account No.";

        RecRef.GetTable(BankAccReconLine);
        ProcessDataExch.ProcessAllLinesColumnMapping(DataExch, RecRef);

        VerifyBankAccReconLineWithVendor(BankAccRecon, BankAccReconLine, Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportColumnsAsRows()
    var
        DataExch: Record "Data Exch.";
        FileName: Text[1024];
    begin
        //Initialize();

        // Setup
        InsertDataExchLinesWithColumnsAsRows(DataExch);

        // Exercise
        ExportDataExchToCSVFile(DataExch."Entry No.", FileName);

        // Verify
        VerifyFileContentAsRows(DataExch, FileName);
    end;

    local procedure VerifyBankAccReconLineWithVendor(BankAccRecon: Record "Bank Acc. Reconciliation"; BankAccReconLine: Record "Bank Acc. Reconciliation Line"; VendorNo: Code[20])
    begin
        BankAccReconLine.Reset();
        BankAccReconLine.SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
        BankAccReconLine.SetRange("Statement No.", BankAccRecon."Statement No.");
        if BankAccReconLine.FindFirst() then;
        Assert.IsTrue(BankAccReconLine."Entity No." = VendorNo, ExpectedVendorErr);
    end;

    local procedure InsertDataExchLinesWithColumnsAsRows(var DataExch: Record "Data Exch.")
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchField: Record "Data Exch. Field";
        i: Integer;
        j: Integer;
    begin
        DataExchDef.Code := LibraryUtility.GenerateGUID();
        DataExchDef."Columns as Rows" := true;
        DataExchDef.Insert();

        InsertDataExch(DataExch);
        DataExch."Data Exch. Def Code" := DataExchDef.Code;
        DataExch.Modify();

        for i := 1 to LibraryRandom.RandIntInRange(2, 10) do begin
            DataExchField.Init();
            DataExchField."Data Exch. No." := DataExch."Entry No.";
            DataExchField."Line No." := i;
            for j := 1 to 3 do begin
                DataExchField."Column No." := j;
                DataExchField."Column Type" := j - 1;
                case DataExchField."Column Type" of
                    DataExchField."Column Type"::Header,
                  DataExchField."Column Type"::Footer:
                        DataExchField.Value := Format(DataExchField."Column Type");
                    else
                        DataExchField.Value := StrSubstNo('Line %1 - Column %2', DataExchField."Line No.", DataExchField."Column No.");
                end;
                DataExchField.Insert();
            end;
        end;
    end;

    local procedure IsFirstHeader(DataExchFieldHeader: Record "Data Exch. Field"): Boolean
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchFieldHeader."Data Exch. No.");
        DataExchField.SetRange("Column No.", DataExchFieldHeader."Column No.");
        DataExchField.SetFilter("Line No.", '<%1', DataExchFieldHeader."Line No.");
        exit(DataExchField.IsEmpty);
    end;

    local procedure IsLastFooter(DataExchFieldFooter: Record "Data Exch. Field"): Boolean
    var
        DataExchField: Record "Data Exch. Field";
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchFieldFooter."Data Exch. No.");
        DataExchField.SetRange("Column No.", DataExchFieldFooter."Column No.");
        DataExchField.SetFilter("Line No.", '>%1', DataExchFieldFooter."Line No.");
        exit(DataExchField.IsEmpty);
    end;

    local procedure ExportDataExchToCSVFile(DataExchNo: Integer; var Filename: Text[1024])
    var
        DataExchField: Record "Data Exch. Field";
        FileManagement: Codeunit "File Management";
        ExportGenericCSV: XMLport "Export Generic CSV";
        ExportFile: File;
        OutStream: OutStream;
    begin
        DataExchField.SetRange("Data Exch. No.", DataExchNo);
        Filename := CopyStr(FileManagement.ServerTempFileName('csv'), 1, 1024);

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(Filename);
        ExportFile.CreateOutStream(OutStream);
        ExportGenericCSV.SetDestination(OutStream);
        ExportGenericCSV.SetTableView(DataExchField);
        ExportGenericCSV.Export();
        ExportFile.Close();
    end;

    local procedure VerifyFileContentAsRows(DataExch: Record "Data Exch."; Filename: Text[1024])
    var
        DataExchField: Record "Data Exch. Field";
        ExportFile: DotNet File;
        LinesRead: DotNet Array;
        DataExchLine: Text;
        LineNo: Integer;
        Shift: Integer;
    begin
        Assert.IsTrue(ExportFile.Exists(Filename), StrSubstNo(FileDoesNotExistErr, Filename));
        LinesRead := ExportFile.ReadAllLines(Filename);

        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        if DataExchField.FindSet() then begin
            LineNo := 1;
            repeat
                case DataExchField."Column Type" of
                    DataExchField."Column Type"::Header:
                        begin
                            DataExchLine := Format(DataExchField."Column Type");
                            if IsFirstHeader(DataExchField) then
                                Assert.AreEqual(
                                  DataExchLine, LinesRead.GetValue(LineNo - 1 - Shift), ExportedDataIsWrongErr)
                            else begin
                                Shift += 1;
                                Assert.AreNotEqual(
                                  DataExchLine, LinesRead.GetValue(LineNo - 1 - Shift), ExportedDataIsWrongErr);
                            end;
                        end;
                    DataExchField."Column Type"::Footer:
                        begin
                            DataExchLine := Format(DataExchField."Column Type");
                            if IsLastFooter(DataExchField) then
                                Assert.AreEqual(
                                  DataExchLine, LinesRead.GetValue(LineNo - 1 - Shift), ExportedDataIsWrongErr)
                            else begin
                                Shift += 1;
                                Assert.AreNotEqual(
                                  DataExchLine, LinesRead.GetValue(LineNo - 1 - Shift), ExportedDataIsWrongErr);
                            end;
                        end;
                    else begin
                        DataExchLine := StrSubstNo('%1%2', '=', DataExchField.Value);
                        Assert.AreEqual(
                          DataExchLine, LinesRead.GetValue(LineNo - 1 - Shift), ExportedDataIsWrongErr);
                    end;
                end;
                LineNo += 1;
            until DataExchField.Next() = 0;
        end;
        Assert.AreEqual(LineNo - 1 - Shift, LinesRead.Length, ExportedDataIsWrongErr)
    end;

    local procedure InsertDataExch(var DataExch: Record "Data Exch.")
    begin
        DataExch."Entry No." := 0;
        DataExch.Insert();
    end;
}

