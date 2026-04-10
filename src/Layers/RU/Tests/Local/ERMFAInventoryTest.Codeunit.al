codeunit 144716 "ERM FA Inventory Test"
{
    // // [FEATURE] [Report] [Inventory]

    TestPermissions = NonRestrictive;
    Subtype = Test;
    Permissions = tabledata "Document Print Buffer" = imd;

    var
        Assert: Codeunit Assert;
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        ValueNotExistErr: Label 'Value %1 does not exist on worksheet %2';
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('FAPhysInventoryINV1RPH')]
    [Scope('OnPrem')]
    procedure FAPhysInventoryINV1()
    var
        FAJournalBatch: Record "FA Journal Batch";
        EmployeeNo: Code[20];
        FALocationCode: Code[10];
        TotalArr: array[4] of Decimal;
        LineQty: Integer;
        i: Integer;
        InventoryDocNo: Code[20];
        InventoryDate: Date;
        DocumentNo: Code[20];
        DocumentDate: Date;
        StartingDate: Date;
        EndingDate: Date;
        Chairman: Code[20];
        Commision: array[3] of Code[20];
        WhoCheck: Code[20];
    begin
        // [FEATURE] [FA Phys. Inventory INV-1]
        // [SCENARIO 252751] Print REP 12486 "FA Phys. Inventory INV-1"
        Initialize();
        InventoryDocNo := LibraryUtility.GenerateGUID();
        EmployeeNo := CreateEmployee();
        FALocationCode := CreateFALocation(CreateEmployee());

        CreateFAJournalBatch(FAJournalBatch);
        LineQty := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to LineQty do
            CreateFAJournal(TotalArr, FAJournalBatch, InventoryDocNo, EmployeeNo, FALocationCode);

        PrepareINV1RequestValues(InventoryDate, DocumentNo, DocumentDate, StartingDate, EndingDate, Chairman, Commision, WhoCheck);
        RunFAINV1Report(FAJournalBatch, EmployeeNo, FALocationCode);

        VerifyINV1FirstPageValues(
          EmployeeNo, FALocationCode, InventoryDocNo, InventoryDate, DocumentNo, DocumentDate, StartingDate, EndingDate);
        VerifyINV1SecondPageValues(LineQty, TotalArr);
        VerifyINV1ThirdPageValues(FALocationCode, Chairman, Commision, WhoCheck);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAPhysInventoryINV1a()
    var
        FAJournalBatch: Record "FA Journal Batch";
        TotalArr: array[4] of Decimal;
        i: Integer;
    begin
        // [FEATURE] [FA Phys. Inventory INV-1a]
        // [SCENARIO] Print REP 14921 "FA Phys. Inventory INV-1a"
        Initialize();

        CreateFAJournalBatch(FAJournalBatch);
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do
            CreateFAJournal(TotalArr, FAJournalBatch, '', '', '');

        RunFAINV1aReport(FAJournalBatch);

        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, FormatAmount(TotalArr[2])),
          StrSubstNo(ValueNotExistErr, TotalArr[2], 2));
        Assert.IsTrue(
          LibraryReportValidation.CheckIfValueExistsOnSpecifiedWorksheet(2, FormatAmount(TotalArr[4])),
          StrSubstNo(ValueNotExistErr, TotalArr[4], 2));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure PrepareINV1RequestValues(var InventoryDate: Date; var DocumentNo: Code[20]; var DocumentDate: Date; var StartingDate: Date; var EndingDate: Date; var Chairman: Code[20]; var Commision: array[3] of Code[20]; var WhoCheck: Code[20])
    var
        i: Integer;
    begin
        InventoryDate := LibraryRandom.RandDate(LibraryRandom.RandInt(100));
        DocumentNo := LibraryUtility.GenerateGUID();
        DocumentDate := LibraryRandom.RandDate(LibraryRandom.RandInt(100));
        StartingDate := LibraryRandom.RandDate(LibraryRandom.RandInt(100));
        EndingDate := LibraryRandom.RandDateFrom(StartingDate, 100);
        Chairman := CreateEmployee();
        for i := 1 to ArrayLen(Commision) do
            Commision[i] := CreateEmployee();
        WhoCheck := CreateEmployee();

        LibraryVariableStorage.Enqueue(InventoryDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(DocumentDate);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(Chairman);
        LibraryVariableStorage.Enqueue(Commision[1]);
        LibraryVariableStorage.Enqueue(Commision[2]);
        LibraryVariableStorage.Enqueue(Commision[3]);
        LibraryVariableStorage.Enqueue(WhoCheck);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FA: Record "Fixed Asset";
    begin
        FA."No." := LibraryUtility.GenerateGUID();
        FA."FA Type" := FA."FA Type"::"Intangible Asset";
        FA.Insert();
        exit(FA."No.");
    end;

    local procedure CreateFAJournal(var TotalArr: array[4] of Decimal; FAJournalBatch: Record "FA Journal Batch"; DocumentNo: Code[20]; EmployeeNo: Code[20]; FALocationCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        FAJournalLine.Init();
        FAJournalLine."Journal Template Name" := FAJournalBatch."Journal Template Name";
        FAJournalLine."Journal Batch Name" := FAJournalBatch.Name;
        FAJournalLine."Line No." := LibraryUtility.GetNewRecNo(FAJournalLine, FAJournalLine.FieldNo("Line No."));
        FAJournalLine."Document No." := DocumentNo;
        FAJournalLine."FA No." := CreateFixedAsset();
        FAJournalLine."Employee No." := EmployeeNo;
        FAJournalLine."Location Code" := FALocationCode;

        FAJournalLine."Actual Quantity" := LibraryRandom.RandIntInRange(10, 2);
        FAJournalLine."Actual Amount" := LibraryRandom.RandDecInRange(10, 100, 2);
        FAJournalLine."Calc. Quantity" := LibraryRandom.RandIntInRange(10, 2);
        FAJournalLine."Calc. Amount" := LibraryRandom.RandDecInRange(10, 100, 2);
        FAJournalLine.Insert();

        TotalArr[1] += FAJournalLine."Actual Quantity";
        TotalArr[2] += FAJournalLine."Actual Amount";
        TotalArr[3] += FAJournalLine."Calc. Quantity";
        TotalArr[4] += FAJournalLine."Calc. Amount";
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
    end;

    local procedure CreateEmployee(): Code[20]
    var
        Employee: Record Employee;
    begin
        Employee.Init();
        Employee."No." := LibraryUtility.GenerateGUID();
        Employee."Org. Unit Name" := LibraryUtility.GenerateGUID();
        Employee."Job Title" := LibraryUtility.GenerateGUID();
        Employee."Last Name" := LibraryUtility.GenerateGUID();
        Employee.Initials := LibraryUtility.GenerateGUID();
        Employee.Insert();
        exit(Employee."No.");
    end;

    local procedure CreateFALocation(EmployeeNo: Code[20]): Code[10]
    var
        FALocation: Record "FA Location";
    begin
        FALocation.Init();
        FALocation.Code := LibraryUtility.GenerateGUID();
        FALocation.Name := LibraryUtility.GenerateGUID();
        FALocation.Validate("Employee No.", EmployeeNo);
        FALocation.Insert();
        exit(FALocation.Code);
    end;

    local procedure ClearPrintingData(FAJournalBatch: Record "FA Journal Batch")
    var
        DocumentPrintBuffer: Record "Document Print Buffer";
    begin
        DocumentPrintBuffer.SetRange("Table ID", DATABASE::"FA Journal Line");
        DocumentPrintBuffer.DeleteAll();
        DocumentPrintBuffer.Init();
        DocumentPrintBuffer."User ID" := UserId;
        DocumentPrintBuffer."Table ID" := DATABASE::"FA Journal Line";
        DocumentPrintBuffer."Journal Template Name" := FAJournalBatch."Journal Template Name";
        DocumentPrintBuffer."Journal Batch Name" := FAJournalBatch.Name;
        DocumentPrintBuffer.Insert();
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    var
        StdRepMgt: Codeunit "Local Report Management";
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;

    local procedure FilterFAJnlLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch")
    begin
        FAJournalLine.SetRange("Journal Template Name", FAJournalBatch."Journal Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalBatch.Name);
    end;

    local procedure RunFAINV1Report(FAJournalBatch: Record "FA Journal Batch"; EmployeeNo: Code[20]; FALocationCode: Code[10])
    var
        FAJournalLine: Record "FA Journal Line";
        FAPhysInventoryINV1: Report "FA Phys. Inventory INV-1";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FilterFAJnlLine(FAJournalLine, FAJournalBatch);
        FAJournalLine.SetRange("Employee No.", EmployeeNo);
        FAJournalLine.SetRange("Location Code", FALocationCode);

        Clear(FAPhysInventoryINV1);
        FAPhysInventoryINV1.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAPhysInventoryINV1.SetTableView(FAJournalLine);
        FAPhysInventoryINV1.UseRequestPage(true);
        Commit();
        FAPhysInventoryINV1.Run();
    end;

    local procedure RunFAINV1aReport(FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalLine: Record "FA Journal Line";
        FAPhysInventoryINV1a: Report "FA Phys. Inventory INV-1a";
    begin
        ClearPrintingData(FAJournalBatch);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        FilterFAJnlLine(FAJournalLine, FAJournalBatch);
        Clear(FAPhysInventoryINV1a);
        FAPhysInventoryINV1a.SetFileNameSilent(LibraryReportValidation.GetFileName());
        FAPhysInventoryINV1a.SetTableView(FAJournalLine);
        FAPhysInventoryINV1a.UseRequestPage(false);
        FAPhysInventoryINV1a.Run();
    end;

    local procedure VerifyINV1FirstPageValues(EmployeeNo: Code[20]; FALocationCode: Code[10]; InventoryDocNo: Code[20]; InventoryDate: Date; DocumentNo: Code[20]; DocumentDate: Date; StartingDate: Date; EndingDate: Date)
    var
        CompanyInformation: Record "Company Information";
        FALocation: Record "FA Location";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        CompanyInformation.Get();
        FALocation.Get(FALocationCode);

        LibraryReportValidation.VerifyCellValueByRef('A', 5, 1, LocalReportMgt.GetCompanyName()); // Company Name
        LibraryReportValidation.VerifyCellValueByRef('A', 7, 1, LocalReportMgt.GetEmpDepartment(EmployeeNo)); // Department Name
        LibraryReportValidation.VerifyCellValueByRef('M', 5, 1, '0317001'); // OKUD
        LibraryReportValidation.VerifyCellValueByRef('M', 6, 1, CompanyInformation."OKPO Code"); // OKPO
        LibraryReportValidation.VerifyCellValueByRef('M', 9, 1, DocumentNo); // Document No
        LibraryReportValidation.VerifyCellValueByRef('M', 10, 1, Format(DocumentDate)); // Document Date
        LibraryReportValidation.VerifyCellValueByRef('M', 11, 1, Format(StartingDate)); // Starting Date
        LibraryReportValidation.VerifyCellValueByRef('M', 12, 1, Format(EndingDate)); // Ending Date
        LibraryReportValidation.VerifyCellValueByRef('K', 16, 1, InventoryDocNo); // Inventory Document No.
        LibraryReportValidation.VerifyCellValueByRef('M', 16, 1, Format(InventoryDate)); // Inventory Document Date
        LibraryReportValidation.VerifyCellValueByRef('C', 21, 1, FALocation.Name); // Location
        LibraryReportValidation.VerifyCellValueByRef('C', 29, 1, LocalReportMgt.GetEmpPosition(EmployeeNo)); // Employee Position
        LibraryReportValidation.VerifyCellValueByRef('K', 29, 1, LocalReportMgt.GetEmpName(EmployeeNo)); // Employee Name
    end;

    local procedure VerifyINV1SecondPageValues(LinesCnt: Integer; TotalArr: array[4] of Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(TotalArr) do
            LibraryReportValidation.VerifyCellValue(42 + LinesCnt, 9 + i, FormatAmount(TotalArr[i]));
    end;

    local procedure VerifyINV1ThirdPageValues(FALocationCode: Code[10]; Chairman: Code[20]; Commision: array[3] of Code[20]; WhoCheck: Code[20])
    var
        FALocation: Record "FA Location";
        LocalReportMgt: Codeunit "Local Report Management";
        i: Integer;
    begin
        LibraryReportValidation.VerifyCellValueByRef('C', 59, 1, LocalReportMgt.GetEmpPosition(Chairman));
        LibraryReportValidation.VerifyCellValueByRef('J', 59, 1, LocalReportMgt.GetEmpName(Chairman));

        for i := 1 to ArrayLen(Commision) do begin
            LibraryReportValidation.VerifyCellValueByRef('C', 60 + i * 2, 1, LocalReportMgt.GetEmpPosition(Commision[i]));
            LibraryReportValidation.VerifyCellValueByRef('J', 60 + i * 2, 1, LocalReportMgt.GetEmpName(Commision[i]));
        end;

        FALocation.Get(FALocationCode);
        LibraryReportValidation.VerifyCellValueByRef('C', 74, 1, LocalReportMgt.GetEmpPosition(FALocation."Employee No."));
        LibraryReportValidation.VerifyCellValueByRef('J', 74, 1, LocalReportMgt.GetEmpName(FALocation."Employee No."));

        LibraryReportValidation.VerifyCellValueByRef('C', 83, 1, LocalReportMgt.GetEmpPosition(WhoCheck));
        LibraryReportValidation.VerifyCellValueByRef('J', 83, 1, LocalReportMgt.GetEmpName(WhoCheck));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FAPhysInventoryINV1RPH(var FAPhysInventoryINV1: TestRequestPage "FA Phys. Inventory INV-1")
    begin
        FAPhysInventoryINV1.InventoryDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAPhysInventoryINV1.DocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.DocumentDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAPhysInventoryINV1.StartDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAPhysInventoryINV1.EndDate.SetValue(LibraryVariableStorage.DequeueDate());
        FAPhysInventoryINV1.Chairman.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.Commission1.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.Commission2.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.Commission3.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.WhoCheck.SetValue(LibraryVariableStorage.DequeueText());
        FAPhysInventoryINV1.OK().Invoke();
    end;
}

