codeunit 134068 "ECSL Suggest Line Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Record Link]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLGeneratesLineInDateRange()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO] Generate report line for the vat entries within the range
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);

        // [GIVEN] 2 VAT Entries in range, 1 out of range
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, '100001', StartDate);
        InitVatEntry(VATEntry, '100002', EndDate);
        InitVatEntry(VATEntry, '100003', DMY2Date(1, 1, 1999));// out of range
        // [GIVEN] Report header with the correct date range
        InitReportHeader(VATReportHeader, StartDate, EndDate);

        // [WHEN] Generate all the report line
        CODEUNIT.Run(CODEUNIT::"EC Sales List Suggest Lines", VATReportHeader);

        // [THEN] Lines are created for the first 2 customer and total values are matching.
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetFilter("Customer VAT Reg. No.", '100001|100002');

        Assert.AreEqual(GetVATEntryTotalValue(StartDate, EndDate), GetReportTotalValue(VATReportHeader),
          'Expected that total Values are the same');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLSeperateSrvGoodsLineSameVATReg()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        StartDate: Date;
        EndDate: Date;
        VATRegNo: Text[20];
    begin
        // [SCENARIO] Goods and services are seperated correctly for the same customer

        VATRegNo := '100001';
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);

        // [GIVEN] Goods 1 line, Services 1 line, EU 3-Party Trade 1 line for the same customer
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, VATRegNo, StartDate);

        InitVatEntry(VATEntry, VATRegNo, EndDate);
        VATEntry."EU Service" := true;
        VATEntry.Modify();

        InitVatEntry(VATEntry, VATRegNo, StartDate);
        VATEntry."EU 3-Party Trade" := true;
        VATEntry.Modify();

        // [GIVEN] Report header with the correct date range
        InitReportHeader(VATReportHeader, StartDate, EndDate);

        // [WHEN] Generate all the report line
        CODEUNIT.Run(CODEUNIT::"EC Sales List Suggest Lines", VATReportHeader);

        // [THEN] 3 lines are created for the same customer.
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        Assert.AreEqual(GetVATEntryTotalValue(StartDate, EndDate), GetReportTotalValue(VATReportHeader),
          'Expected that total Values are the same');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLWontGeneratesZeroLine()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        StartDate: Date;
        EndDate: Date;
    begin
        // [SCENARIO] Does NOT Generate report line for the vat when the total amount is Zero
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);
        ECSLVATReportLineRelation.DeleteAll();

        // [GIVEN] 2 VAT Entries with oposit value
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, '100001', StartDate);
        InitVatEntry(VATEntry, '100001', EndDate);
        VATEntry.Base := -VATEntry.Base;
        VATEntry.Modify();

        // [GIVEN] Report header with the correct date range
        InitReportHeader(VATReportHeader, StartDate, EndDate);

        // [WHEN] Generate all the report line
        CODEUNIT.Run(CODEUNIT::"EC Sales List Suggest Lines", VATReportHeader);

        // [THEN] No line is generated.
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");

        Assert.AreEqual(0, ECSLVATReportLine.Count, 'Expected that there is no line');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLDeleteLinesAndRelationsWhenDeleteECSLVATReportHeader()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        StartDate: Date;
        EndDate: Date;
    begin
        // [FEATURE] [ECSL]
        // [SCENARIO 330462] When delete ECSL VAT Report Header, corresponding ECSL VAT Report Lines and ECSL VAT Report Line Relations are also deleted
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);

        // [GIVEN] Created two VAT Entries
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, '100001', StartDate);
        InitVatEntry(VATEntry, '100002', EndDate);

        // [GIVEN] Created ECSL VAT Report Header and corresponding ECSL Lines
        InitReportHeader(VATReportHeader, StartDate, EndDate);
        CODEUNIT.Run(CODEUNIT::"EC Sales List Suggest Lines", VATReportHeader);

        // [WHEN] Delete ECSL VAT Report Header
        VATReportHeader.Delete(true);

        // [THEN] ECSL VAT Report Lines and ECSL VAT Report Line Relations are also deleted
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        Assert.RecordIsEmpty(ECSLVATReportLine);
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        Assert.RecordIsEmpty(ECSLVATReportLineRelation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ECSLLeaveLinesAndRelationsWhenDeleteNonECSLVATReportHeader()
    var
        VATEntry: Record "VAT Entry";
        VATReportHeader: Record "VAT Report Header";
        VATReturnVATReportHeader: Record "VAT Report Header";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        StartDate: Date;
        EndDate: Date;
    begin
        // [FEATURE] [ECSL]
        // [SCENARIO 330462] Deleting VAT Return VAT Report Header, does not affect ECSL VAT Report Lines and ECSL VAT Report Line Relations with the same Report No.
        StartDate := DMY2Date(1, 1, 2017);
        EndDate := DMY2Date(31, 1, 2017);

        // [GIVEN] Created two VAT Entries
        VATEntry.DeleteAll();
        InitVatEntry(VATEntry, '100001', StartDate);
        InitVatEntry(VATEntry, '100002', EndDate);

        // [GIVEN] Created ECSL VAT Report Header and corresponding ECSL Lines
        InitReportHeader(VATReportHeader, StartDate, EndDate);
        CODEUNIT.Run(CODEUNIT::"EC Sales List Suggest Lines", VATReportHeader);

        // [GIVEN] Created VAT Return VAT Report Header with the same "No."
        InitVatReturnReportHeaderCopyNo(VATReturnVATReportHeader, StartDate, EndDate, VATReportHeader."No.");

        // [WHEN] Delete VAT Return VAT Report Header
        VATReturnVATReportHeader.Delete(true);

        // [THEN] ECSL VAT Report Lines and ECSL VAT Report Line Relations still exist
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        Assert.RecordIsNotEmpty(ECSLVATReportLine);
        ECSLVATReportLineRelation.SetRange("ECSL Report No.", VATReportHeader."No.");
        Assert.RecordIsNotEmpty(ECSLVATReportLineRelation);
    end;

    local procedure InitReportHeader(var VATReportHeader: Record "VAT Report Header"; StartDate: Date; EndDate: Date)
    begin
        VATReportHeader.Init();
        VATReportHeader."Start Date" := StartDate;
        VATReportHeader."End Date" := EndDate;
        VATReportHeader."No." := CopyStr(CreateGuid(), 2, 20);

        VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
        VATReportHeader."Period No." := Date2DMY(StartDate, 2);
        VATReportHeader."Period Year" := Date2DMY(StartDate, 3);

        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"EC Sales List";
        VATReportHeader.Insert();
    end;

    local procedure InitVatReturnReportHeaderCopyNo(var VATReportHeader: Record "VAT Report Header"; StartDate: Date; EndDate: Date; ReportNo: Code[20])
    begin
        VATReportHeader.Init();
        VATReportHeader."Start Date" := StartDate;
        VATReportHeader."End Date" := EndDate;
        VATReportHeader."No." := ReportNo;

        VATReportHeader."Period Type" := VATReportHeader."Period Type"::Month;
        VATReportHeader."Period No." := Date2DMY(StartDate, 2);
        VATReportHeader."Period Year" := Date2DMY(StartDate, 3);

        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert();
    end;

    local procedure InitVatEntry(var VATEntry: Record "VAT Entry"; VatRegNo: Text[20]; PostingDate: Date)
    var
        LastId: Integer;
    begin
        if VATEntry.FindLast() then
            LastId := VATEntry."Entry No.";

        VATEntry.Init();
        VATEntry."Entry No." := LastId + 1;
        VATEntry.Base := -1.7;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."EU 3-Party Trade" := false;
        VATEntry."VAT Registration No." := VatRegNo;
        VATEntry."EU Service" := false;
        VATEntry."Country/Region Code" := 'DE';
        VATEntry.Insert();
    end;

    local procedure GetVATEntryTotalValue(StartDate: Date; EndDate: Date): Integer
    var
        VATEntry: Record "VAT Entry";
        Total: Integer;
    begin
        VATEntry.SetFilter("Posting Date", '%1..%2', StartDate, EndDate);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        if not VATEntry.FindSet() then
            exit(0);

        repeat
            Total += Round(VATEntry.Base, 1);
        until VATEntry.Next() = 0;
        exit(-Total);
    end;

    local procedure GetReportTotalValue(VATReportHeader: Record "VAT Report Header"): Integer
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLine.SetRange("Report No.", VATReportHeader."No.");
        ECSLVATReportLine.SetCurrentKey("Report No.");
        ECSLVATReportLine.CalcSums("Total Value Of Supplies");
        exit(ECSLVATReportLine."Total Value Of Supplies");
    end;

    local procedure Teardown()
    var
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        ECSLVATReportLine: Record "ECSL VAT Report Line";
    begin
        ECSLVATReportLineRelation.DeleteAll();
        ECSLVATReportLine.DeleteAll();
    end;
}

