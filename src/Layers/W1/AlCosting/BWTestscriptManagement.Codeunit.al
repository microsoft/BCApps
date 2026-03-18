codeunit 103307 "BW TestscriptManagement"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    var
        TestscriptResult: Record "Whse. Testscript Result";
        QASetup: Record "Whse. QA Setup";
        OutputFile: File;
        Tab: Char;
        FormatValue: Text[250];
        FormatExpValue: Text[250];
        ILERecords: Integer;
        ILEFields: Integer;
        WJLRecords: Integer;
        WJLFields: Integer;
        IJLRecords: Integer;
        IJLFields: Integer;
        WALRecords: Integer;
        WALFields: Integer;
        WERecords: Integer;
        WEFields: Integer;
        LEDRecords: Integer;
        LEDFields: Integer;
        BCRecords: Integer;
        BCFields: Integer;
        RcptLineRecords: Integer;
        RcptLineFields: Integer;
        PostedRcptLineRecords: Integer;
        PostedRcptLineFields: Integer;
        ShptLineRecords: Integer;
        ShptLineFields: Integer;
        PostedShptLineRecords: Integer;
        PostedShptLineFields: Integer;
        WhseWkshLineRecords: Integer;
        WhseWkshLineFields: Integer;
        WhseReqRecords: Integer;
        WhseReqFields: Integer;
        ItemRegRecords: Integer;
        ItemRegFields: Integer;
        PostedInvPutAwayLineRecords: Integer;
        PostedInvPutAwayLineFields: Integer;
        PostedInvPickLineRecords: Integer;
        PostedInvPickLineFields: Integer;
        OutputToFile: Boolean;
        WithErrors: Boolean;

    [Scope('OnPrem')]
    procedure InitializeOutput(CodeunitID: Integer; FilePath: Text[250])
    begin
        if FilePath = '' then begin
            TestscriptResult.LockTable();
            if TestscriptResult.Find('+') then;
            TestscriptResult."Codeunit ID" := CodeunitID;
            OutputToFile := false;
        end else begin
            Tab := 9;
            OutputFile.TextMode := true;
            OutputFile.Create(FilePath);
            OutputFile.Write(' ');
            OutputFile.Write('Processing Codeunit ' + Format(CodeunitID));
            OutputFile.Write(
              'Name' + Format(Tab) +
              'Value' + Format(Tab) +
              'Expected Value' + Format(Tab) +
              'Is Equal');
            OutputToFile := true;
        end;
    end;

    [Scope('OnPrem')]
    procedure ShowTestscriptResult()
    begin
        Commit();
        WithErrors := false;
        TestscriptResult.SetCurrentKey("Is Equal");
        TestscriptResult.SetRange("Is Equal", false);

        if TestscriptResult.Find('-') then
            repeat
                WithErrors := WithErrors or
                  (TestscriptResult.Value <> '') or
                  (TestscriptResult."Expected Value" <> '');
            until TestscriptResult.Next() = 0;

        if WithErrors then
            Message('The test was completed with errors.')
        else
            Message('The test was completed with no errors.');

        PAGE.RunModal(0, TestscriptResult);
    end;

    [Scope('OnPrem')]
    procedure DeleteTestscriptResult()
    begin
        TestscriptResult.Reset();
        TestscriptResult.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure VerifyPostCondition(UseCaseNo: Integer; TestCaseNo: Integer; IterationNo: Integer; ILEOffset: Integer)
    var
        CodeunitID: Integer;
        ILERef: Record "BW Item Ledger Entry Ref";
        WALRef: Record "BW Warehouse Activity Line Ref";
        WERef: Record "BW Warehouse Entry Ref";
        IJLRef: Record "BW Item Journal Line Ref.";
        BCRef: Record "BW Bin Content Ref";
        RcptLineRef: Record "BW Warehouse Receipt Line Ref";
        PostedRcptLineRef: Record "BW Posted Whse. Rcpt Line Ref";
        ShptLineRef: Record "BW Warehouse Shipment Line Ref";
        PostedShptLineRef: Record "BW Posted Whse. Shpmt Line Ref";
        WhseWkshLineRef: Record "BW Whse. Worksheet Line Ref";
        WhseReqRef: Record "BW Warehouse Request Ref";
        ItemRegRef: Record "BW Item Register Ref";
        PostedInvPutAwayLineRef: Record "BW P. Invt. Put-away Line Ref";
        PostedInvPickLineRef: Record "BW P. Invt. Pick Line Ref";
        ILERefMgmt: Codeunit "BW ItemLedgEntry Ref. Mgmt";
        WERefMgmt: Codeunit "BW Warehouse Entry Ref. Mgmt";
        BCRefMgmt: Codeunit "BW Bin Content Ref. Mgmt";
        IJLRefMgmt: Codeunit "BW ItemJnlLine Ref. Mgmt";
        WALRefMgmt: Codeunit "BW Whse. Activity Ref. Mgmt";
        RcptLineRefMgmt: Codeunit "BW Whse. Rcpt. Line Ref. Mgmt";
        PostedRcptLineRefMgmt: Codeunit "BW Pstd. Rcpt.-Line Ref. Mgmt";
        ShptLineRefMgmt: Codeunit "BW Whse. Shpt.-Line Ref. Mgmt";
        PostedShptLineRefMgmt: Codeunit "BW Pstd. Shpt.-Line Ref. Mgmt";
        WhseWkshLineRefMgmt: Codeunit "BW WhseWkshLine Ref. Mgmt";
        WhseReqRefMgmt: Codeunit "BW Whse. Request Ref. Mgmt";
        ItemRegRefMgmt: Codeunit "BW Item Register Ref. Mgmt";
        PstdInvPutAwayLineRefMgmt: Codeunit "BW Pstd InvPutAwayLn Ref. Mgmt";
        PstdInvPickLineRefMgmt: Codeunit "BW Pstd InvPickLn Ref. Mgmt";
    begin
        QASetup.Get();

        if QASetup."Use Hardcoded Reference" then begin
            ILERefMgmt.SetNumbers(ILERecords, ILEFields);
            ILERefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, ILEOffset);
            ILERefMgmt.GetNumbers(ILERecords, ILEFields);

            WERefMgmt.SetNumbers(WERecords, WEFields);
            WERefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            WERefMgmt.GetNumbers(WERecords, WEFields);

            WALRefMgmt.SetNumbers(WALRecords, WALFields);
            WALRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            WALRefMgmt.GetNumbers(WALRecords, WALFields);

            BCRefMgmt.SetNumbers(BCRecords, BCFields);
            BCRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            BCRefMgmt.GetNumbers(BCRecords, BCFields);

            IJLRefMgmt.SetNumbers(IJLRecords, IJLFields);
            IJLRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            IJLRefMgmt.GetNumbers(IJLRecords, IJLFields);

            RcptLineRefMgmt.SetNumbers(RcptLineRecords, RcptLineFields);
            RcptLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            RcptLineRefMgmt.GetNumbers(RcptLineRecords, RcptLineFields);

            PostedRcptLineRefMgmt.SetNumbers(PostedRcptLineRecords, PostedRcptLineFields);
            PostedRcptLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            PostedRcptLineRefMgmt.GetNumbers(PostedRcptLineRecords, PostedRcptLineFields);

            ShptLineRefMgmt.SetNumbers(ShptLineRecords, ShptLineFields);
            ShptLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            ShptLineRefMgmt.GetNumbers(ShptLineRecords, ShptLineFields);

            PostedShptLineRefMgmt.SetNumbers(PostedShptLineRecords, PostedShptLineFields);
            PostedShptLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            PostedShptLineRefMgmt.GetNumbers(PostedShptLineRecords, PostedShptLineFields);

            WhseWkshLineRefMgmt.SetNumbers(WhseWkshLineRecords, WhseWkshLineFields);
            WhseWkshLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            WhseWkshLineRefMgmt.GetNumbers(WhseWkshLineRecords, WhseWkshLineFields);

            WhseReqRefMgmt.SetNumbers(WhseReqRecords, WhseReqFields);
            WhseReqRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            WhseReqRefMgmt.GetNumbers(WhseReqRecords, WhseReqFields);

            ItemRegRefMgmt.SetNumbers(ItemRegRecords, ItemRegFields);
            ItemRegRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            ItemRegRefMgmt.GetNumbers(ItemRegRecords, ItemRegFields);

            PstdInvPutAwayLineRefMgmt.SetNumbers(PostedInvPutAwayLineRecords, PostedInvPutAwayLineFields);
            PstdInvPutAwayLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            PstdInvPutAwayLineRefMgmt.GetNumbers(PostedInvPutAwayLineRecords, PostedInvPutAwayLineFields);

            PstdInvPickLineRefMgmt.SetNumbers(PostedInvPickLineRecords, PostedInvPickLineFields);
            PstdInvPickLineRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            PstdInvPickLineRefMgmt.GetNumbers(PostedInvPickLineRecords, PostedInvPickLineFields);
        end else begin
            // use reference tables
            ILERef.SetRange("Use Case No.", UseCaseNo);
            ILERef.SetRange("Test Case No.", TestCaseNo);
            ILERef.SetRange("Iteration No.", IterationNo);
            if ILERef.Find('-') then
                repeat
                    VerifyItemLedgEntry(ILERef, ILEOffset, IterationNo);
                until ILERef.Next() = 0;

            WERef.SetRange("Use Case No.", UseCaseNo);
            WERef.SetRange("Test Case No.", TestCaseNo);
            WERef.SetRange("Iteration No.", IterationNo);
            if WERef.Find('-') then
                repeat
                    VerifyWhseEntry(WERef, IterationNo);
                until WERef.Next() = 0;

            WALRef.SetRange("Use Case No.", UseCaseNo);
            WALRef.SetRange("Test Case No.", TestCaseNo);
            WALRef.SetRange("Iteration No.", IterationNo);
            if WALRef.Find('-') then
                repeat
                    VerifyWhseActivLine(WALRef, IterationNo);
                until WALRef.Next() = 0;

            IJLRef.SetRange("Use Case No.", UseCaseNo);
            IJLRef.SetRange("Test Case No.", TestCaseNo);
            IJLRef.SetRange("Iteration No.", IterationNo);
            if IJLRef.Find('-') then
                repeat
                    VerifyItemJnlLine(IJLRef, IterationNo);
                until IJLRef.Next() = 0;

            BCRef.SetRange("Use Case No.", UseCaseNo);
            BCRef.SetRange("Test Case No.", TestCaseNo);
            BCRef.SetRange("Iteration No.", IterationNo);
            if BCRef.Find('-') then
                repeat
                    VerifyBinContent(BCRef, IterationNo);
                until BCRef.Next() = 0;

            RcptLineRef.SetRange("Use Case No.", UseCaseNo);
            RcptLineRef.SetRange("Test Case No.", TestCaseNo);
            RcptLineRef.SetRange("Iteration No.", IterationNo);
            if RcptLineRef.Find('-') then
                repeat
                    VerifyWhseRcptLine(RcptLineRef, IterationNo);
                until RcptLineRef.Next() = 0;

            PostedRcptLineRef.SetRange("Use Case No.", UseCaseNo);
            PostedRcptLineRef.SetRange("Test Case No.", TestCaseNo);
            PostedRcptLineRef.SetRange("Iteration No.", IterationNo);
            if PostedRcptLineRef.Find('-') then
                repeat
                    VerifyPostedWhseRcptLine(PostedRcptLineRef, IterationNo);
                until PostedRcptLineRef.Next() = 0;

            ShptLineRef.SetRange("Use Case No.", UseCaseNo);
            ShptLineRef.SetRange("Test Case No.", TestCaseNo);
            ShptLineRef.SetRange("Iteration No.", IterationNo);
            if ShptLineRef.Find('-') then
                repeat
                    VerifyWhseShptLine(ShptLineRef, IterationNo);
                until ShptLineRef.Next() = 0;

            PostedShptLineRef.SetRange("Use Case No.", UseCaseNo);
            PostedShptLineRef.SetRange("Test Case No.", TestCaseNo);
            PostedShptLineRef.SetRange("Iteration No.", IterationNo);
            if PostedShptLineRef.Find('-') then
                repeat
                    VerifyPostedWhseShptLine(PostedShptLineRef, IterationNo);
                until PostedShptLineRef.Next() = 0;

            WhseWkshLineRef.SetRange("Use Case No.", UseCaseNo);
            WhseWkshLineRef.SetRange("Test Case No.", TestCaseNo);
            WhseWkshLineRef.SetRange("Iteration No.", IterationNo);
            if WhseWkshLineRef.Find('-') then
                repeat
                    VerifyWhseWkshLine(WhseWkshLineRef, IterationNo);
                until WhseWkshLineRef.Next() = 0;

            WhseReqRef.SetRange("Use Case No.", UseCaseNo);
            WhseReqRef.SetRange("Test Case No.", TestCaseNo);
            WhseReqRef.SetRange("Iteration No.", IterationNo);
            if WhseReqRef.Find('-') then
                repeat
                    VerifyWhseReq(WhseReqRef, IterationNo);
                until WhseReqRef.Next() = 0;

            ItemRegRef.SetRange("Use Case No.", UseCaseNo);
            ItemRegRef.SetRange("Test Case No.", TestCaseNo);
            ItemRegRef.SetRange("Iteration No.", IterationNo);
            if ItemRegRef.Find('-') then
                repeat
                    VerifyItemReg(ItemRegRef, IterationNo);
                until ItemRegRef.Next() = 0;

            PostedInvPutAwayLineRef.SetRange("Use Case No.", UseCaseNo);
            PostedInvPutAwayLineRef.SetRange("Test Case No.", TestCaseNo);
            PostedInvPutAwayLineRef.SetRange("Iteration No.", IterationNo);
            if PostedInvPutAwayLineRef.Find('-') then
                repeat
                    VerifyPostedInvPutAwayLine(PostedInvPutAwayLineRef, IterationNo);
                until PostedInvPutAwayLineRef.Next() = 0;

            PostedInvPickLineRef.SetRange("Use Case No.", UseCaseNo);
            PostedInvPickLineRef.SetRange("Test Case No.", TestCaseNo);
            PostedInvPickLineRef.SetRange("Iteration No.", IterationNo);
            if PostedInvPickLineRef.Find('-') then
                repeat
                    VerifyPostedInvPickLine(PostedInvPickLineRef, IterationNo);
                until PostedInvPickLineRef.Next() = 0;
        end;

        CodeunitID := TestscriptResult."Codeunit ID";
        TestscriptResult.Reset();
        TestscriptResult.SetCurrentKey("Use Case No.", "Test Case No.", "Iteration No.");
        TestscriptResult.SetRange("Project Code", 'BW');
        TestscriptResult.SetRange("Use Case No.", UseCaseNo);
        TestscriptResult.SetRange("Test Case No.", TestCaseNo);
        TestscriptResult.SetRange("Iteration No.", IterationNo);
        if not TestscriptResult.Find('-') then
            InsertTestResult(
              'Test reference data', 'EXIST', 'NOT DEFINED', false, UseCaseNo, TestCaseNo, 0, 0, IterationNo);
        TestscriptResult."Codeunit ID" := CodeunitID;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseEntry(WERef: Record "BW Warehouse Entry Ref"; IterationNo: Integer)
    var
        WE: Record "Warehouse Entry";
        TableID: Integer;
    begin
        TableID := DATABASE::"Warehouse Entry";
        if not WE.Get(WERef."Entry No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo)
        else begin
            Increase(WERecords);
            TestTextValue(WERef.FieldName("Location Code"), WE."Location Code", WERef."Location Code",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Zone Code"), WE."Zone Code", WERef."Zone Code",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Bin Code"), WE."Bin Code", WERef."Bin Code",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName(Description), WE.Description, WERef.Description,
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Item No."), WE."Item No.", WERef."Item No.",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Variant Code"), WE."Variant Code", WERef."Variant Code",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestNumberValue(WERef.FieldName(Quantity), WE.Quantity, WERef.Quantity,
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Unit of Measure Code"), WE."Unit of Measure Code", WERef."Unit of Measure Code",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestNumberValue(WERef.FieldName(Cubage), WE.Cubage, WERef.Cubage,
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestNumberValue(WERef.FieldName(Weight), WE.Weight, WERef.Weight,
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Serial No."), WE."Serial No.", WERef."Serial No.",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
            TestTextValue(WERef.FieldName("Lot No."), WE."Lot No.", WERef."Lot No.",
              WERef."Use Case No.", WERef."Test Case No.", WERef."Line No.", TableID, IterationNo);
            Increase(WEFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyItemJnlLine(IJLRef: Record "BW Item Journal Line Ref."; IterationNo: Integer)
    var
        IJL: Record "Item Journal Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Item Journal Line";
        if not IJL.Get(IJLRef."Journal Template Name", IJLRef."Journal Batch Name", IJLRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo)
        else begin
            Increase(IJLRecords);
            TestDateValue(IJLRef.FieldName("Posting Date"), IJL."Posting Date", IJLRef."Posting Date",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestTextValue(IJLRef.FieldName("Item No."), IJL."Item No.", IJLRef."Item No.",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestTextValue(IJLRef.FieldName("Variant Code"), IJL."Variant Code", IJLRef."Variant Code",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestTextValue(IJLRef.FieldName("Location Code"), IJL."Location Code", IJLRef."Location Code",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestNumberValue(IJLRef.FieldName("Qty. (Calculated)"), IJL."Qty. (Calculated)", IJLRef."Qty. (Calculated)",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestNumberValue(IJLRef.FieldName("Qty. (Phys. Inventory)"), IJL."Qty. (Phys. Inventory)", IJLRef."Qty. (Phys. Inventory)",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestNumberValue(IJLRef.FieldName(Quantity), IJL.Quantity, IJLRef.Quantity,
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyItemLedgEntry(ILERef: Record "BW Item Ledger Entry Ref"; Offset: Integer; IterationNo: Integer)
    var
        ILE: Record "Item Ledger Entry";
        TableID: Integer;
    begin
        TableID := DATABASE::"Item Ledger Entry";
        // "Entry No." := "Entry No." + Offset;
        if not ILE.Get(ILERef."Entry No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo)
        else begin
            Increase(ILERecords);
            TestTextValue(ILERef.FieldName("Item No."), ILE."Item No.", ILERef."Item No.",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
            TestDateValue(ILERef.FieldName("Posting Date"), ILE."Posting Date", ILERef."Posting Date",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
            TestTextValue(ILERef.FieldName("Location Code"), ILE."Location Code", ILERef."Location Code",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
            TestNumberValue(ILERef.FieldName(Quantity), ILE.Quantity, ILERef.Quantity,
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
            TestNumberValue(ILERef.FieldName("Remaining Quantity"), ILE."Remaining Quantity", ILERef."Remaining Quantity",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
            TestNumberValue(ILERef.FieldName("Invoiced Quantity"), ILE."Invoiced Quantity", ILERef."Invoiced Quantity",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseActivLine(WALRef: Record "BW Warehouse Activity Line Ref"; IterationNo: Integer)
    var
        WAL: Record "Warehouse Activity Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Warehouse Activity Line";
        if not WAL.Get(WALRef."Activity Type", WALRef."No.", WALRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo)
        else begin
            Increase(WALRecords);
            TestOptionValue(WALRef.FieldName("Activity Type"), WAL."Activity Type".AsInteger(), WALRef."Activity Type",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Source Type"), WAL."Source Type", WALRef."Source Type",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Source Subtype"), WAL."Source Subtype", WALRef."Source Subtype",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Source No."), WAL."Source No.", WALRef."Source No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Source Line No."), WAL."Source Line No.", WALRef."Source Line No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestOptionValue(
              WALRef.FieldName("Whse. Document Type"), WAL."Whse. Document Type".AsInteger(), WALRef."Whse. Document Type",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Whse. Document No."), WAL."Whse. Document No.", WALRef."Whse. Document No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Whse. Document Line No."), WAL."Whse. Document Line No.", WALRef."Whse. Document Line No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestOptionValue(WALRef.FieldName("Action Type"), WAL."Action Type".AsInteger(), WALRef."Action Type",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Item No."), WAL."Item No.", WALRef."Item No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Variant Code"), WAL."Variant Code", WALRef."Variant Code",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Unit of Measure Code"), WAL."Unit of Measure Code", WALRef."Unit of Measure Code",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Location Code"), WAL."Location Code", WALRef."Location Code",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Zone Code"), WAL."Zone Code", WALRef."Zone Code",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Bin Code"), WAL."Bin Code", WALRef."Bin Code",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName(Quantity), WAL.Quantity, WALRef.Quantity,
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. (Base)"), WAL."Qty. (Base)", WALRef."Qty. (Base)",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. Outstanding"), WAL."Qty. Outstanding", WALRef."Qty. Outstanding",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. Outstanding (Base)"), WAL."Qty. Outstanding (Base)", WALRef."Qty. Outstanding (Base)",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. to Handle"), WAL."Qty. to Handle", WALRef."Qty. to Handle",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. to Handle (Base)"), WAL."Qty. to Handle (Base)", WALRef."Qty. to Handle (Base)",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. Handled"), WAL."Qty. Handled", WALRef."Qty. Handled",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName("Qty. Handled (Base)"), WAL."Qty. Handled (Base)", WALRef."Qty. Handled (Base)",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestOptionValue(WALRef.FieldName("Destination Type"), WAL."Destination Type".AsInteger(), WALRef."Destination Type",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestTextValue(WALRef.FieldName("Destination No."), WAL."Destination No.", WALRef."Destination No.",
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName(Cubage), WAL.Cubage, WALRef.Cubage,
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
            TestNumberValue(WALRef.FieldName(Weight), WAL.Weight, WALRef.Weight,
              WALRef."Use Case No.", WALRef."Test Case No.", WALRef."Line No.", TableID, IterationNo);
            Increase(WALFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyBinContent(BCRef: Record "BW Bin Content Ref"; IterationNo: Integer)
    var
        BC: Record "Bin Content";
        TableID: Integer;
    begin
        TableID := DATABASE::"Bin Content";
        if not BC.Get(BCRef."Location Code", BCRef."Bin Code", BCRef."Item No.", BCRef."Variant Code", BCRef."Unit of Measure Code") then
            TestTextValue('', 'NOT FOUND', 'EXIST', BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo)
        else begin
            Increase(BCRecords);
            TestTextValue(BCRef.FieldName("Location Code"), BC."Location Code", BCRef."Location Code",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestTextValue(BCRef.FieldName("Zone Code"), BC."Zone Code", BCRef."Zone Code",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestTextValue(BCRef.FieldName("Bin Code"), BC."Bin Code", BCRef."Bin Code",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestTextValue(BCRef.FieldName("Item No."), BC."Item No.", BCRef."Item No.",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestTextValue(BCRef.FieldName("Variant Code"), BC."Variant Code", BCRef."Variant Code",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestTextValue(BCRef.FieldName("Unit of Measure Code"), BC."Unit of Measure Code", BCRef."Unit of Measure Code",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            BC.CalcFields(Quantity);
            TestNumberValue(BCRef.FieldName(Quantity), BC.Quantity, BCRef.Quantity,
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            BC.CalcFields("Pick Qty.");
            TestNumberValue(BCRef.FieldName("Pick Qty."), BC."Pick Qty.", BCRef."Pick Qty.",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            BC.CalcFields("Neg. Adjmt. Qty.");
            TestNumberValue(BCRef.FieldName("Neg. Adjmt. Qty."), BC."Neg. Adjmt. Qty.", BCRef."Neg. Adjmt. Qty.",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            BC.CalcFields("Put-away Qty.");
            TestNumberValue(BCRef.FieldName("Put-away Qty."), BC."Put-away Qty.", BCRef."Put-away Qty.",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            BC.CalcFields("Pos. Adjmt. Qty.");
            TestNumberValue(BCRef.FieldName("Pos. Adjmt. Qty."), BC."Pos. Adjmt. Qty.", BCRef."Pos. Adjmt. Qty.",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
            TestNumberValue(BCRef.FieldName("Qty. per Unit of Measure"), BC."Qty. per Unit of Measure", BCRef."Qty. per Unit of Measure",
              BCRef."Use Case No.", BCRef."Test Case No.", 0, TableID, IterationNo);
            Increase(BCFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseRcptLine(RcptLineRef: Record "BW Warehouse Receipt Line Ref"; IterationNo: Integer)
    var
        RcptLine: Record "Warehouse Receipt Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Warehouse Receipt Line";
        if not RcptLine.Get(RcptLineRef."No.", RcptLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(RcptLineRecords);
            TestNumberValue(RcptLineRef.FieldName("Source Type"), RcptLine."Source Type", RcptLineRef."Source Type",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Source Subtype"), RcptLine."Source Subtype", RcptLineRef."Source Subtype",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Source No."), RcptLine."Source No.", RcptLineRef."Source No.",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Source Line No."), RcptLine."Source Line No.", RcptLineRef."Source Line No.",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Item No."), RcptLine."Item No.", RcptLineRef."Item No.",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Variant Code"), RcptLine."Variant Code", RcptLineRef."Variant Code",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Unit of Measure Code"), RcptLine."Unit of Measure Code", RcptLineRef."Unit of Measure Code",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Location Code"), RcptLine."Location Code", RcptLineRef."Location Code",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Zone Code"), RcptLine."Zone Code", RcptLineRef."Zone Code",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(RcptLineRef.FieldName("Bin Code"), RcptLine."Bin Code", RcptLineRef."Bin Code",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName(Quantity), RcptLine.Quantity, RcptLineRef.Quantity,
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Qty. (Base)"), RcptLine."Qty. (Base)", RcptLineRef."Qty. (Base)",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Qty. Outstanding"), RcptLine."Qty. Outstanding", RcptLineRef."Qty. Outstanding",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Qty. Outstanding (Base)"), RcptLine."Qty. Outstanding (Base)", RcptLineRef."Qty. Outstanding (Base)",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Qty. Received"), RcptLine."Qty. Received", RcptLineRef."Qty. Received",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestNumberValue(RcptLineRef.FieldName("Qty. Received (Base)"), RcptLine."Qty. Received (Base)", RcptLineRef."Qty. Received (Base)",
              RcptLineRef."Use Case No.", RcptLineRef."Test Case No.", RcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyPostedWhseRcptLine(PostedRcptLineRef: Record "BW Posted Whse. Rcpt Line Ref"; IterationNo: Integer)
    var
        PostedRcptLine: Record "Posted Whse. Receipt Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Posted Whse. Receipt Line";
        if not PostedRcptLine.Get(PostedRcptLineRef."No.", PostedRcptLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(PostedRcptLineRecords);
            TestNumberValue(PostedRcptLineRef.FieldName("Source Type"), PostedRcptLine."Source Type", PostedRcptLineRef."Source Type",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestNumberValue(PostedRcptLineRef.FieldName("Source Subtype"), PostedRcptLine."Source Subtype", PostedRcptLineRef."Source Subtype",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Source No."), PostedRcptLine."Source No.", PostedRcptLineRef."Source No.",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestNumberValue(PostedRcptLineRef.FieldName("Source Line No."), PostedRcptLine."Source Line No.", PostedRcptLineRef."Source Line No.",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(RcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Item No."), PostedRcptLine."Item No.", PostedRcptLineRef."Item No.",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Variant Code"), PostedRcptLine."Variant Code", PostedRcptLineRef."Variant Code",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Unit of Measure Code"), PostedRcptLine."Unit of Measure Code", PostedRcptLineRef."Unit of Measure Code",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Location Code"), PostedRcptLine."Location Code", PostedRcptLineRef."Location Code",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Zone Code"), PostedRcptLine."Zone Code", PostedRcptLineRef."Zone Code",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestTextValue(PostedRcptLineRef.FieldName("Bin Code"), PostedRcptLine."Bin Code", PostedRcptLineRef."Bin Code",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestNumberValue(PostedRcptLineRef.FieldName(Quantity), PostedRcptLine.Quantity, PostedRcptLineRef.Quantity,
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
            TestNumberValue(PostedRcptLineRef.FieldName("Qty. (Base)"), PostedRcptLine."Qty. (Base)", PostedRcptLineRef."Qty. (Base)",
              PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedRcptLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseShptLine(ShptLineRef: Record "BW Warehouse Shipment Line Ref"; IterationNo: Integer)
    var
        ShptLine: Record "Warehouse Shipment Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Warehouse Shipment Line";
        if not ShptLine.Get(ShptLineRef."No.", ShptLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(ShptLineRecords);
            TestNumberValue(ShptLineRef.FieldName("Source Type"), ShptLine."Source Type", ShptLineRef."Source Type",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Source Subtype"), ShptLine."Source Subtype", ShptLineRef."Source Subtype",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Source No."), ShptLine."Source No.", ShptLineRef."Source No.",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Source Line No."), ShptLine."Source Line No.", ShptLineRef."Source Line No.",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Item No."), ShptLine."Item No.", ShptLineRef."Item No.",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Variant Code"), ShptLine."Variant Code", ShptLineRef."Variant Code",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Unit of Measure Code"), ShptLine."Unit of Measure Code", ShptLineRef."Unit of Measure Code",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Location Code"), ShptLine."Location Code", ShptLineRef."Location Code",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Zone Code"), ShptLine."Zone Code", ShptLineRef."Zone Code",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestTextValue(ShptLineRef.FieldName("Bin Code"), ShptLine."Bin Code", ShptLineRef."Bin Code",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName(Quantity), ShptLine.Quantity, ShptLineRef.Quantity,
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. (Base)"), ShptLine."Qty. (Base)", ShptLineRef."Qty. (Base)",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Outstanding"), ShptLine."Qty. Outstanding", ShptLineRef."Qty. Outstanding",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Outstanding (Base)"), ShptLine."Qty. Outstanding (Base)", ShptLineRef."Qty. Outstanding (Base)",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Picked"), ShptLine."Qty. Picked", ShptLineRef."Qty. Picked",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Picked (Base)"), ShptLine."Qty. Picked (Base)", ShptLineRef."Qty. Picked (Base)",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Shipped"), ShptLine."Qty. Shipped", ShptLineRef."Qty. Shipped",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
            TestNumberValue(ShptLineRef.FieldName("Qty. Shipped (Base)"), ShptLine."Qty. Shipped (Base)", ShptLineRef."Qty. Shipped (Base)",
              ShptLineRef."Use Case No.", ShptLineRef."Test Case No.", ShptLineRef."Line No.", TableID, IterationNo);
            Increase(ShptLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyPostedWhseShptLine(PostedShptLineRef: Record "BW Posted Whse. Shpmt Line Ref"; IterationNo: Integer)
    var
        PostedShptLine: Record "Posted Whse. Shipment Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Posted Whse. Shipment Line";
        if not PostedShptLine.Get(PostedShptLineRef."No.", PostedShptLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(PostedShptLineRecords);
            TestNumberValue(PostedShptLineRef.FieldName("Source Type"), PostedShptLine."Source Type", PostedShptLineRef."Source Type",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestNumberValue(PostedShptLineRef.FieldName("Source Subtype"), PostedShptLine."Source Subtype", PostedShptLineRef."Source Subtype",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Source No."), PostedShptLine."Source No.", PostedShptLineRef."Source No.",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestNumberValue(PostedShptLineRef.FieldName("Source Line No."), PostedShptLine."Source Line No.", PostedShptLineRef."Source Line No.",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Item No."), PostedShptLine."Item No.", PostedShptLineRef."Item No.",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Variant Code"), PostedShptLine."Variant Code", PostedShptLineRef."Variant Code",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Unit of Measure Code"), PostedShptLine."Unit of Measure Code", PostedShptLineRef."Unit of Measure Code",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Location Code"), PostedShptLine."Location Code", PostedShptLineRef."Location Code",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Zone Code"), PostedShptLine."Zone Code", PostedShptLineRef."Zone Code",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestTextValue(PostedShptLineRef.FieldName("Bin Code"), PostedShptLine."Bin Code", PostedShptLineRef."Bin Code",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestNumberValue(PostedShptLineRef.FieldName(Quantity), PostedShptLine.Quantity, PostedShptLineRef.Quantity,
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
            TestNumberValue(PostedShptLineRef.FieldName("Qty. (Base)"), PostedShptLine."Qty. (Base)", PostedShptLineRef."Qty. (Base)",
              PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Line No.", TableID, IterationNo);
            Increase(PostedShptLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseWkshLine(WhseWkshLineRef: Record "BW Whse. Worksheet Line Ref"; IterationNo: Integer)
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Whse. Worksheet Line";
        if not WhseWkshLine.Get(WhseWkshLineRef."Worksheet Template Name", WhseWkshLineRef.Name, WhseWkshLineRef."Location Code", WhseWkshLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(WhseWkshLineRecords);
            TestTextValue(WhseWkshLineRef.FieldName("Item No."), WhseWkshLine."Item No.", WhseWkshLineRef."Item No.",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("Variant Code"), WhseWkshLine."Variant Code", WhseWkshLineRef."Variant Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("Unit of Measure Code"), WhseWkshLine."Unit of Measure Code", WhseWkshLineRef."Unit of Measure Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("Location Code"), WhseWkshLine."Location Code", WhseWkshLineRef."Location Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("From Zone Code"), WhseWkshLine."From Zone Code", WhseWkshLineRef."From Zone Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("From Bin Code"), WhseWkshLine."From Bin Code", WhseWkshLineRef."From Bin Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("To Zone Code"), WhseWkshLine."To Zone Code", WhseWkshLineRef."To Zone Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestTextValue(WhseWkshLineRef.FieldName("To Bin Code"), WhseWkshLine."To Bin Code", WhseWkshLineRef."To Bin Code",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName(Quantity), WhseWkshLine.Quantity, WhseWkshLineRef.Quantity,
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName("Qty. (Base)"), WhseWkshLine."Qty. (Base)", WhseWkshLineRef."Qty. (Base)",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName("Qty. Outstanding"), WhseWkshLine."Qty. Outstanding", WhseWkshLineRef."Qty. Outstanding",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName("Qty. to Handle"), WhseWkshLine."Qty. to Handle", WhseWkshLineRef."Qty. to Handle",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName("Qty. Handled"), WhseWkshLine."Qty. Handled", WhseWkshLineRef."Qty. Handled",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestNumberValue(WhseWkshLineRef.FieldName("Source Type"), WhseWkshLine."Source Type", WhseWkshLineRef."Source Type",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
            TestOptionValue(
              WhseWkshLineRef.FieldName("Whse. Document Type"), WhseWkshLine."Whse. Document Type".AsInteger(), WhseWkshLineRef."Whse. Document Type",
              WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Line No.", TableID, IterationNo);
            Increase(WhseWkshLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyWhseReq(WhseReqRef: Record "BW Warehouse Request Ref"; IterationNo: Integer)
    var
        WhseReq: Record "Warehouse Request";
        TableID: Integer;
    begin
        TableID := DATABASE::"Warehouse Request";
        if not WhseReq.Get(WhseReqRef.Type, WhseReqRef."Location Code", WhseReqRef."Source Type", WhseReqRef."Source Subtype", WhseReqRef."Source No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo)
        else begin
            Increase(WhseReqRecords);
            TestTextValue(WhseReqRef.FieldName("Location Code"), WhseReq."Location Code", WhseReqRef."Location Code",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
            TestNumberValue(WhseReqRef.FieldName("Source Type"), WhseReq."Source Type", WhseReqRef."Source Type",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
            TestNumberValue(WhseReqRef.FieldName("Source Subtype"), WhseReq."Source Subtype", WhseReqRef."Source Subtype",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
            TestTextValue(WhseReqRef.FieldName("Source No."), WhseReq."Source No.", WhseReqRef."Source No.",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
            TestOptionValue(WhseReqRef.FieldName("Source Document"), WhseReq."Source Document".AsInteger(), WhseReqRef."Source Document",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
            TestNumberValue(WhseReqRef.FieldName("Document Status"), WhseReq."Document Status", WhseReqRef."Document Status",
              WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", 0, TableID, IterationNo);
            Increase(WhseReqFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyItemReg(ItemRegRef: Record "BW Item Register Ref"; IterationNo: Integer)
    var
        ItemReg: Record "Item Register";
        TableID: Integer;
    begin
        TableID := DATABASE::"Item Register";
        if not ItemReg.Get(ItemRegRef."No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo)
        else begin
            Increase(ItemRegRecords);
            TestNumberValue(ItemRegRef.FieldName("From Entry No."), ItemReg."From Entry No.", ItemRegRef."From Entry No.",
              ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestNumberValue(ItemRegRef.FieldName("To Entry No."), ItemReg."To Entry No.", ItemRegRef."To Entry No.",
              ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestTextValue(ItemRegRef.FieldName("Source Code"), ItemReg."Source Code", ItemRegRef."Source Code",
              ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestNumberValue(ItemRegRef.FieldName("From Phys. Inventory Entry No."), ItemReg."From Phys. Inventory Entry No.",
              ItemRegRef."From Phys. Inventory Entry No.", ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestNumberValue(ItemRegRef.FieldName("To Phys. Inventory Entry No."), ItemReg."To Phys. Inventory Entry No.",
              ItemRegRef."To Phys. Inventory Entry No.", ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestNumberValue(ItemRegRef.FieldName("From Value Entry No."), ItemReg."From Value Entry No.", ItemRegRef."From Value Entry No.",
              ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
            TestNumberValue(ItemRegRef.FieldName("To Value Entry No."), ItemReg."To Value Entry No.", ItemRegRef."To Value Entry No.",
              ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."No.", TableID, IterationNo);
            Increase(ItemRegFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyPostedInvPutAwayLine(PstdInvPutAwayLineRef: Record "BW P. Invt. Put-away Line Ref"; IterationNo: Integer)
    var
        PstdInvPutAwayLine: Record "Posted Invt. Put-away Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Posted Invt. Put-away Line";
        if not PstdInvPutAwayLine.Get(PstdInvPutAwayLineRef."No.", PstdInvPutAwayLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(PostedInvPutAwayLineRecords);
            TestNumberValue(PstdInvPutAwayLineRef.FieldName("Source Type"), PstdInvPutAwayLine."Source Type", PstdInvPutAwayLineRef."Source Type",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestNumberValue(PstdInvPutAwayLineRef.FieldName("Source Subtype"), PstdInvPutAwayLine."Source Subtype", PstdInvPutAwayLineRef."Source Subtype",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Source No."), PstdInvPutAwayLine."Source No.", PstdInvPutAwayLineRef."Source No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestNumberValue(PstdInvPutAwayLineRef.FieldName("Source Line No."), PstdInvPutAwayLine."Source Line No.", PstdInvPutAwayLineRef."Source Line No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestOptionValue(PstdInvPutAwayLineRef.FieldName("Source Document"), PstdInvPutAwayLine."Source Document".AsInteger(), PstdInvPutAwayLineRef."Source Document",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Location Code"), PstdInvPutAwayLine."Location Code", PstdInvPutAwayLineRef."Location Code",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Item No."), PstdInvPutAwayLine."Item No.", PstdInvPutAwayLineRef."Item No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Variant Code"), PstdInvPutAwayLine."Variant Code", PstdInvPutAwayLineRef."Variant Code",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestNumberValue(PstdInvPutAwayLineRef.FieldName(Quantity), PstdInvPutAwayLine.Quantity, PstdInvPutAwayLineRef.Quantity,
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestNumberValue(PstdInvPutAwayLineRef.FieldName("Qty. (Base)"), PstdInvPutAwayLine."Qty. (Base)", PstdInvPutAwayLineRef."Qty. (Base)",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestOptionValue(PstdInvPutAwayLineRef.FieldName("Destination Type"), PstdInvPutAwayLine."Destination Type".AsInteger(), PstdInvPutAwayLineRef."Destination Type",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Destination No."), PstdInvPutAwayLine."Destination No.", PstdInvPutAwayLineRef."Destination No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Whse. Activity No."), PstdInvPutAwayLine."Whse. Activity No.", PstdInvPutAwayLineRef."Whse. Activity No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Serial No."), PstdInvPutAwayLine."Serial No.", PstdInvPutAwayLineRef."Serial No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Lot No."), PstdInvPutAwayLine."Lot No.", PstdInvPutAwayLineRef."Lot No.",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestTextValue(PstdInvPutAwayLineRef.FieldName("Bin Code"), PstdInvPutAwayLine."Bin Code", PstdInvPutAwayLineRef."Bin Code",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
            TestOptionValue(PstdInvPutAwayLineRef.FieldName("Action Type"), PstdInvPutAwayLine."Action Type".AsInteger(), PstdInvPutAwayLineRef."Action Type",
              PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPutAwayLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyPostedInvPickLine(PstdInvPickLineRef: Record "BW P. Invt. Pick Line Ref"; IterationNo: Integer)
    var
        PstdInvPickLine: Record "Posted Invt. Pick Line";
        TableID: Integer;
    begin
        TableID := DATABASE::"Posted Invt. Pick Line";
        if not PstdInvPickLine.Get(PstdInvPickLineRef."No.", PstdInvPickLineRef."Line No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo)
        else begin
            Increase(PostedInvPickLineRecords);
            TestNumberValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Source Type"), PstdInvPickLine."Source Type", PstdInvPickLineRef."Source Type",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestNumberValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Source Subtype"), PstdInvPickLine."Source Subtype", PstdInvPickLineRef."Source Subtype",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Source No."), PstdInvPickLine."Source No.", PstdInvPickLineRef."Source No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestNumberValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Source Line No."), PstdInvPickLine."Source Line No.", PstdInvPickLineRef."Source Line No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestOptionValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Source Document"), PstdInvPickLine."Source Document".AsInteger(), PstdInvPickLineRef."Source Document",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Location Code"), PstdInvPickLine."Location Code", PstdInvPickLineRef."Location Code",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Item No."), PstdInvPickLine."Item No.", PstdInvPickLineRef."Item No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Variant Code"), PstdInvPickLine."Variant Code", PstdInvPickLineRef."Variant Code",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestNumberValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef.Quantity), PstdInvPickLine.Quantity, PstdInvPickLineRef.Quantity,
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestNumberValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Qty. (Base)"), PstdInvPickLine."Qty. (Base)", PstdInvPickLineRef."Qty. (Base)",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestOptionValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Destination Type"), PstdInvPickLine."Destination Type".AsInteger(), PstdInvPickLineRef."Destination Type".AsInteger(),
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Destination No."), PstdInvPickLine."Destination No.", PstdInvPickLineRef."Destination No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Whse. Activity No."), PstdInvPickLine."Whse. Activity No.", PstdInvPickLineRef."Whse. Activity No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Serial No."), PstdInvPickLine."Serial No.", PstdInvPickLineRef."Serial No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Lot No."), PstdInvPickLine."Lot No.", PstdInvPickLineRef."Lot No.",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestTextValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Bin Code"), PstdInvPickLine."Bin Code", PstdInvPickLineRef."Bin Code",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
            TestOptionValue(PstdInvPickLineRef.FieldName(PstdInvPickLineRef."Action Type"), PstdInvPickLine."Action Type".AsInteger(), PstdInvPickLineRef."Action Type",
              PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Line No.", TableID, IterationNo);
            Increase(PostedInvPickLineFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure TestTextValue(Name: Text[250]; Value: Text[250]; ExpectedValue: Text[250]; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        InsertTestResult(Name, Value, ExpectedValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure TestNumberValue(Name: Text[250]; Value: Decimal; ExpectedValue: Decimal; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        FormatValue := Format(Value);
        FormatExpValue := Format(ExpectedValue);
        InsertTestResult(Name, FormatValue, FormatExpValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure TestOptionValue(Name: Text[250]; Value: Integer; ExpectedValue: Integer; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        FormatValue := Format(Value);
        FormatExpValue := Format(ExpectedValue);
        InsertTestResult(Name, FormatValue, FormatExpValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure TestBooleanValue(Name: Text[250]; Value: Boolean; ExpectedValue: Boolean; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        FormatValue := Format(Value);
        FormatExpValue := Format(ExpectedValue);
        InsertTestResult(Name, FormatValue, FormatExpValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure TestDateValue(Name: Text[250]; Value: Date; ExpectedValue: Date; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        FormatValue := Format(Value);
        FormatExpValue := Format(ExpectedValue);
        InsertTestResult(Name, FormatValue, FormatExpValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure TestTimeValue(Name: Text[250]; Value: Time; ExpectedValue: Time; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        FormatValue := Format(Value);
        FormatExpValue := Format(ExpectedValue);
        InsertTestResult(Name, FormatValue, FormatExpValue, Value = ExpectedValue,
          UseCaseNo, TestCaseNo, EntryNo, TableID, IterationNo);
    end;

    [Scope('OnPrem')]
    procedure Increase(var Counter: Integer)
    begin
        Counter := Counter + 1;
    end;

    [Scope('OnPrem')]
    procedure WriteQuantities()
    var
        Name: Text[30];
    begin
        Name := 'No. of records / fields tested';
        FormatValue := Format(ILERecords);
        FormatExpValue := Format(ILEFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Item Ledger Entry", 0);
        FormatValue := Format(WALRecords);
        FormatExpValue := Format(WALFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Activity Line", 0);
        FormatValue := Format(WJLRecords);
        FormatExpValue := Format(WJLFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Journal Line", 0);
        FormatValue := Format(IJLRecords);
        FormatExpValue := Format(IJLFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Item Journal Line", 0);
        FormatValue := Format(WERecords);
        FormatExpValue := Format(WEFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Entry", 0);
        FormatValue := Format(BCRecords);
        FormatExpValue := Format(BCFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Bin Content", 0);
        FormatValue := Format(RcptLineRecords);
        FormatExpValue := Format(RcptLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Receipt Line", 0);
        FormatValue := Format(PostedRcptLineRecords);
        FormatExpValue := Format(PostedRcptLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Posted Whse. Receipt Line", 0);
        FormatValue := Format(ShptLineRecords);
        FormatExpValue := Format(ShptLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Shipment Line", 0);
        FormatValue := Format(PostedShptLineRecords);
        FormatExpValue := Format(PostedShptLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Posted Whse. Shipment Line", 0);
        FormatValue := Format(WhseWkshLineRecords);
        FormatExpValue := Format(WhseWkshLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Whse. Worksheet Line", 0);
        FormatValue := Format(WhseReqRecords);
        FormatExpValue := Format(WhseReqFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Warehouse Request", 0);
        FormatValue := Format(ItemRegRecords);
        FormatExpValue := Format(ItemRegFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Item Register", 0);
        FormatValue := Format(PostedInvPutAwayLineRecords);
        FormatExpValue := Format(PostedInvPutAwayLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Posted Invt. Put-away Line", 0);
        FormatValue := Format(PostedInvPickLineRecords);
        FormatExpValue := Format(PostedInvPickLineFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Posted Invt. Pick Line", 0);
    end;

    [Scope('OnPrem')]
    procedure InsertTestResult(Name: Text[250]; Value: Text[250]; ExpectedValue: Text[250]; IsEqual: Boolean; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    var
        TestScriptResult2: Record "Whse. Testscript Result";
        TestscriptManagement: Codeunit TestscriptManagement;
    begin
        if TableID = 0 then
            exit;

        TestscriptManagement.InsertTestResult(
          StrSubstNo('%1-%2 T%3:%4 %5', UseCaseNo, TestCaseNo, TableID, EntryNo, Name),
          Value, ExpectedValue, IsEqual);

        if OutputToFile then
            OutputFile.Write(
              Name + Format(Tab) +
              Value + Format(Tab) +
              ExpectedValue + Format(Tab) + Format(Tab) +
              Format(IsEqual))
        else begin
            TestScriptResult2.SetRange("Project Code", 'BW');
            if not TestScriptResult2.FindLast() then;
            TestscriptResult."Project Code" := 'BW';
            TestscriptResult."No." := TestScriptResult2."No." + 1;
            TestscriptResult.Name := Name;
            TestscriptResult.Value := Value;
            TestscriptResult."Expected Value" := ExpectedValue;
            TestscriptResult."Is Equal" := IsEqual;
            TestscriptResult.Date := Today;
            TestscriptResult.Time := Time;
            TestscriptResult."Use Case No." := UseCaseNo;
            TestscriptResult."Test Case No." := TestCaseNo;
            TestscriptResult."Entry No." := EntryNo;
            TestscriptResult.TableID := TableID;
            TestscriptResult."Iteration No." := IterationNo;
            TestscriptResult.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure GetNextNo(var LastNo: Integer): Integer
    begin
        LastNo := LastNo + 1;
        exit(LastNo);
    end;

    [Scope('OnPrem')]
    procedure GetLastItemLedgEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Reset();
        if not ItemLedgerEntry.FindLast() then;
        exit(ItemLedgerEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure InsertItemJnlLine(var NewItemJnlLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer; PostingDate: Date; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; NewLocationCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; UnitAmount: Decimal; AppliesToEntry: Integer; BinCode: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Journal Template Name", JournalTemplateName);
        ItemJnlLine.Validate("Journal Batch Name", JournalBatchName);
        ItemJnlLine.Validate("Line No.", LineNo);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Validate("Entry Type", EntryType);
        ItemJnlLine.Validate("Document No.", DocumentNo);
        ItemJnlLine.Validate("Item No.", ItemNo);
        ItemJnlLine.Validate("Variant Code", VariantCode);
        ItemJnlLine.Validate("Location Code", LocationCode);
        ItemJnlLine.Validate("Bin Code", BinCode);
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then
            ItemJnlLine.Validate("New Location Code", NewLocationCode);
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        if AppliesToEntry <> 0 then
            ItemJnlLine.Validate("Applies-to Entry", AppliesToEntry);
        if UnitAmount <> 0 then
            ItemJnlLine.Validate("Unit Amount", UnitAmount);
        ItemJnlLine.Insert(true);   // -> DELAYED INSERT on form
        NewItemJnlLine := ItemJnlLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyItemJnlLine(JnlTmplName: Code[10]; JnlBatchName: Code[10]; LineNo: Integer; AmountValuated: Decimal; ValidateAmountValuated: Boolean; ApplFromEntry: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.Get(JnlTmplName, JnlBatchName, LineNo);
        if ValidateAmountValuated then
            ItemJnlLine.Validate("Inventory Value (Revalued)", AmountValuated);
        if ApplFromEntry <> 0 then
            ItemJnlLine.Validate("Applies-from Entry", ApplFromEntry);
        ItemJnlLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure ItemJnlPostBatch(var ItemJnlLine: Record "Item Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJnlLine);

        ItemJnlDelete(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ItemJnlDelete(ItemJnlLine: Record "Item Journal Line")
    begin
        ItemJnlLine.SetRange("Journal Template Name", ItemJnlLine."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJnlLine."Journal Batch Name");
        ItemJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure InsertResEntry(var NewResEntry: Record "Reservation Entry"; LocationCode: Code[10]; LineNo: Integer; ResStatus: Enum "Reservation Status"; Date: Date; ItemNo: Code[20]; VariantCode: Code[10]; SerialNo: Code[20]; LotNo: Code[20]; Qty: Decimal; QtyBase: Decimal; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer; Pos: Boolean)
    var
        ResEntry: Record "Reservation Entry";
        CreateResEntry: Codeunit "Create Reserv. Entry";
    begin
        ResEntry.Init();
        ResEntry."Entry No." := 1;
        ResEntry."Item No." := ItemNo;
        ResEntry."Location Code" := LocationCode;
        ResEntry."Qty. per Unit of Measure" := 1;
        ResEntry."Reservation Status" := ResStatus;
        ResEntry."Source Type" := SourceType;
        ResEntry."Source Subtype" := SourceSubType;
        ResEntry."Source ID" := SourceID;
        ResEntry."Source Batch Name" := SourceBatchName;
        ResEntry."Source Ref. No." := SourceRefNo;
        ResEntry."Serial No." := SerialNo;
        ResEntry."Lot No." := LotNo;
        ResEntry."New Serial No." := SerialNo;
        ResEntry."New Lot No." := LotNo;
        if Pos then
            CreateResEntry.CreateRemainingReservEntry(ResEntry, Qty, QtyBase)
        else
            CreateResEntry.CreateRemainingReservEntry(ResEntry, -Qty, -QtyBase);
        NewResEntry := ResEntry;
    end;

    [Scope('OnPrem')]
    procedure InsertReclassJnlLine(var NewJnlLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer; Date: Date; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ToLocCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; UnitAmount: Decimal; ApplyToEntry: Integer; FromBinCode: Code[20]; ToBinCode: Code[20])
    var
        JnlLine: Record "Item Journal Line";
    begin
        JnlLine.Init();
        JnlLine.Validate("Journal Template Name", JournalTemplateName);
        JnlLine.Validate("Journal Batch Name", JournalBatchName);
        JnlLine.Validate("Line No.", LineNo);
        JnlLine.Validate("Posting Date", Date);
        JnlLine.Validate("Entry Type", EntryType);
        JnlLine.Validate("Document No.", DocumentNo);
        JnlLine.Validate("Item No.", ItemNo);
        JnlLine.Validate("Variant Code", VariantCode);
        JnlLine.Validate("Location Code", LocationCode);
        JnlLine.Validate("Bin Code", FromBinCode);
        JnlLine.Validate("New Location Code", ToLocCode);
        if JnlLine."Entry Type" = JnlLine."Entry Type"::Transfer then
            JnlLine.Validate("New Location Code", ToLocCode);
        JnlLine.Validate("New Bin Code", ToBinCode);
        JnlLine.Validate(Quantity, Quantity);
        JnlLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        if UnitAmount <> 0 then
            JnlLine.Validate("Unit Amount", UnitAmount);
        JnlLine.Insert(true);
        NewJnlLine := JnlLine;
    end;

    [Scope('OnPrem')]
    procedure InsertAdjmtWhseJnlLine(var NewWhseJnlLine: Record "Warehouse Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10]; LineNo: Integer; Date: Date; ItemNo: Code[20]; VariantCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.Init();
        WhseJnlLine.Validate("Journal Template Name", JournalTemplateName);
        WhseJnlLine.Validate("Journal Batch Name", JournalBatchName);
        WhseJnlLine.Validate("Location Code", LocationCode);
        WhseJnlLine.SetUpNewLine(NewWhseJnlLine);
        WhseJnlLine.Validate("Line No.", LineNo);
        WhseJnlLine.Validate("Registering Date", Date);
        WhseJnlLine.Validate("Item No.", ItemNo);
        WhseJnlLine.Validate("Variant Code", VariantCode);
        WhseJnlLine.Validate("Zone Code", ZoneCode);
        WhseJnlLine.Validate("Bin Code", BinCode);
        WhseJnlLine.Validate(Quantity, Quantity);
        WhseJnlLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WhseJnlLine.Insert(true);
        NewWhseJnlLine := WhseJnlLine;
    end;

    [Scope('OnPrem')]
    procedure WhseJnlPostBatch(var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register Batch", WhseJnlLine);

        WhseJnlDelete(WhseJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ModifyWhseJnlLine(JnlTmplName: Code[10]; JnlBatchName: Code[10]; Location: Code[10]; LineNo: Integer; NewQtyPhysInv: Decimal)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.Get(JnlTmplName, JnlBatchName, Location, LineNo);
        WhseJnlLine.Validate("Qty. (Phys. Inventory)", NewQtyPhysInv);
        WhseJnlLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure WhseJnlDelete(WhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.SetRange("Journal Template Name", WhseJnlLine."Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", WhseJnlLine."Journal Batch Name");
        WhseJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure InsertDedicatedBin(NewLocation: Code[10]; NewZone: Code[10]; NewBin: Code[20]; NewItemNo: Code[20]; NewVariant: Code[10]; NewUoM: Code[10]; MinQty: Decimal; MaxQty: Decimal)
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        Bin.Get(NewLocation, NewBin);
        BinContent."Location Code" := Bin."Location Code";
        BinContent."Bin Code" := Bin.Code;
        BinContent."Zone Code" := Bin."Zone Code";
        BinContent.SetUpNewLine();
        BinContent.Validate("Item No.", NewItemNo);
        BinContent.Validate("Variant Code", NewVariant);
        BinContent.Validate("Unit of Measure Code", NewUoM);
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure BlockBin(Location: Code[10]; Zone: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Variant: Code[10]; UoM: Code[10]; Block: Option)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(Location, BinCode, ItemNo, Variant, UoM);
        BinContent.Validate("Block Movement", Block);
        BinContent.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTransferHeader(var NewTransferHeader: Record "Transfer Header"; NewTransferFromCode: Code[10]; NewTransferToCode: Code[10]; NewInTransitCode: Code[10]; NewPostingDate: Date)
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.Init();
        TransferHeader.Insert(true);
        TransferHeader.Validate("Transfer-from Code", NewTransferFromCode);
        TransferHeader.Validate("Transfer-to Code", NewTransferToCode);
        TransferHeader.Validate("Posting Date", NewPostingDate);
        TransferHeader.Validate("Shipment Date", NewPostingDate);
        TransferHeader.Validate("Receipt Date", NewPostingDate);
        TransferHeader.Validate("In-Transit Code", NewInTransitCode);
        TransferHeader.Modify(true);
        NewTransferHeader := TransferHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyTransferHeader(var TransferHeader: Record "Transfer Header"; NewPostingDate: Date)
    begin
        TransferHeader.Validate("Posting Date", NewPostingDate);
        TransferHeader.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertTransferLine(var NewTransferLine: Record "Transfer Line"; NewTransferNo: Code[20]; NewLineNo: Integer; NewItemNo: Code[20]; NewVariantCode: Code[10]; NewUnitOfMeasureCode: Code[10]; NewQuantity: Decimal; NewQtyToReceive: Decimal; NewQtyToShip: Decimal)
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.Get(NewTransferNo);
        TransferLine.Init();
        TransferLine."Document No." := NewTransferNo;
        TransferLine."Line No." := NewLineNo;
        TransferLine.Insert(true);
        TransferLine.Validate("Item No.", NewItemNo);
        TransferLine.Validate("Variant Code", NewVariantCode);
        TransferLine.Validate("Transfer-from Code", TransferHeader."Transfer-from Code");
        TransferLine.Validate("Transfer-to Code", TransferHeader."Transfer-to Code");
        TransferLine.Validate(Quantity, NewQuantity);
        TransferLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        TransferLine.Validate("Qty. to Receive", NewQtyToReceive);
        TransferLine.Validate("Qty. to Ship", NewQtyToShip);
        TransferLine.Modify();
        NewTransferLine := TransferLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyTransferLine(NewTransHeaderNo: Code[20]; NewLineNo: Integer; NewFromBinCode: Code[20]; NewToBinCode: Code[20]; NewQtyToShip: Decimal; NewQtyToReceive: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Get(NewTransHeaderNo, NewLineNo);
        if NewFromBinCode <> TransferLine."Transfer-from Bin Code" then
            TransferLine.Validate("Transfer-from Bin Code", NewFromBinCode);
        if NewToBinCode <> TransferLine."Transfer-To Bin Code" then
            TransferLine.Validate("Transfer-To Bin Code", NewToBinCode);
        TransferLine."Qty. to Ship" := NewQtyToShip;
        TransferLine."Qty. to Ship (Base)" :=
          Round(NewQtyToShip * TransferLine."Qty. per Unit of Measure", 0.00001);
        TransferLine."Qty. to Receive" := NewQtyToReceive;
        TransferLine."Qty. to Receive (Base)" :=
          Round(NewQtyToReceive * TransferLine."Qty. per Unit of Measure", 0.00001);
        TransferLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure PostTransferOrder(var TransferHeader: Record "Transfer Header"; Ship: Boolean)
    var
        TransferPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        if Ship then begin
            TransferPostShipment.SetHideValidationDialog(true);
            TransferPostShipment.Run(TransferHeader);
        end else begin
            TransferPostReceipt.SetHideValidationDialog(true);
            TransferPostReceipt.Run(TransferHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure ReleaseTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
    begin
        ReleaseTransferDoc.Run(TransferHeader);
    end;

    [Scope('OnPrem')]
    procedure ReopenTransferOrder(var TransferHeader: Record "Transfer Header")
    var
        ReleaseTransferDoc: Codeunit "Release Transfer Document";
    begin
        ReleaseTransferDoc.Reopen(TransferHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesHeader(var NewSalesHeader: Record "Sales Header"; NewDocumentType: Enum "Sales Document Type"; NewSellToCustNo: Code[20]; NewOrderDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", NewDocumentType);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", NewSellToCustNo);
        SalesHeader.Validate("Order Date", NewOrderDate);
        SalesHeader.Modify(true);
        NewSalesHeader := SalesHeader;
    end;

    [Scope('OnPrem')]
    procedure ReleaseSalesDocument(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.Run(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure ModifySalesHeader(var NewSalesHeader: Record "Sales Header"; NewPostingDate: Date; NewLocationCode: Code[10]; ValidateLocationCode: Boolean; ReopenOrder: Boolean)
    var
        SalesHeader: Record "Sales Header";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        SalesHeader.Get(NewSalesHeader."Document Type", NewSalesHeader."No.");
        if ReopenOrder then
            ReleaseSalesDoc.Reopen(SalesHeader);
        SalesHeader."Posting Date" := NewPostingDate;
        if ValidateLocationCode then
            SalesHeader.Validate("Location Code", NewLocationCode);
        SalesHeader.Modify();
        NewSalesHeader := SalesHeader;
    end;

    [Scope('OnPrem')]
    procedure InsertSalesLine(var NewSalesLine: Record "Sales Line"; NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewType: Enum "Sales Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewUnitPrice: Decimal; NewLocationCode: Code[10]; NewReturnReasonCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := NewSalesHeader."Document Type";
        SalesLine."Document No." := NewSalesHeader."No.";
        SalesLine."Line No." := NewLineNo;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, NewType);
        SalesLine.Validate("No.", NewNo);
        SalesLine.Validate("Location Code", NewLocationCode);
        if NewType = SalesLine.Type::Item then
            SalesLine.Validate("Variant Code", NewVariantCode);
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        SalesLine.Validate("Unit Price", NewUnitPrice);
        if NewReturnReasonCode <> '' then
            SalesLine.Validate("Return Reason Code", NewReturnReasonCode);
        SalesLine.Modify();
        NewSalesLine := SalesLine;
    end;

    [Scope('OnPrem')]
    procedure ModifySalesLine(var NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewBinCode: Code[20]; NewQtyToShip: Decimal; NewQtyToInvoice: Decimal; NewUnitPrice: Decimal; NewLineDiscount: Decimal; SetLineDiscount: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
        if NewBinCode <> SalesLine."Bin Code" then
            SalesLine.Validate("Bin Code", NewBinCode);
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        if NewUnitPrice <> 0 then
            SalesLine.Validate("Unit Price", NewUnitPrice);
        if SetLineDiscount then
            SalesLine.Validate("Line Discount %", NewLineDiscount);
        SalesLine.Modify();

        SalesHeader.Get(NewSalesHeader."Document Type", NewSalesHeader."No.");
        SalesHeader.Ship := SalesHeader.Ship or (NewQtyToShip <> 0);
        SalesHeader.Invoice := SalesHeader.Invoice or (NewQtyToInvoice <> 0);
        SalesHeader.Modify();
        NewSalesHeader := SalesHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifySalesCrMemoLine(var NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewBinCode: Code[20]; NewQtyToReceive: Decimal; NewQtyToInvoice: Decimal; NewUnitPrice: Decimal; NewLineDiscount: Decimal; NewApplFromItemEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
        if NewBinCode <> SalesLine."Bin Code" then
            SalesLine.Validate("Bin Code", NewBinCode);
        SalesLine.Validate("Return Qty. to Receive", NewQtyToReceive);
        SalesLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        if NewUnitPrice <> 0 then
            SalesLine.Validate("Unit Price", NewUnitPrice);
        SalesLine.Validate("Line Discount %", NewLineDiscount);
        if NewApplFromItemEntry <> 0 then
            SalesLine.Validate("Appl.-from Item Entry", NewApplFromItemEntry);
        SalesLine.Modify();

        SalesHeader.Get(NewSalesHeader."Document Type", NewSalesHeader."No.");
        SalesHeader.Receive := SalesHeader.Receive or (NewQtyToReceive <> 0);
        SalesHeader.Invoice := SalesHeader.Invoice or (NewQtyToInvoice <> 0);
        SalesHeader.Modify();
        NewSalesHeader := SalesHeader;
    end;

    [Scope('OnPrem')]
    procedure PostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.Run(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure RetrieveSaleShipHeader(NewSalesHeader: Record "Sales Header"; var NewSaleShipHeader: Record "Sales Shipment Header"; WhichRcpt: Integer)
    var
        SaleShipHeader: Record "Sales Shipment Header";
        ActualRcpt: Integer;
    begin
        ActualRcpt := 0;
        SaleShipHeader.Reset();
        SaleShipHeader.SetCurrentKey("Order No.");
        SaleShipHeader.SetRange("Order No.", NewSalesHeader."No.");
        if SaleShipHeader.Find('-') then
            repeat
                NewSaleShipHeader := SaleShipHeader;
                ActualRcpt := ActualRcpt + 1;
            until (SaleShipHeader.Next() = 0) or (ActualRcpt = WhichRcpt);
        if ActualRcpt <> WhichRcpt then
            Clear(NewSaleShipHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchHeader(var NewPurchHeader: Record "Purchase Header"; NewDocumentType: Enum "Purchase Document Type"; NewBuyFromVendorNo: Code[20]; NewOrderDate: Date)
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Init();
        PurchHeader.Validate("Document Type", NewDocumentType);
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", NewBuyFromVendorNo);
        PurchHeader.Validate("Order Date", NewOrderDate);
        PurchHeader.Modify(true);
        NewPurchHeader := PurchHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchHeader(var NewPurchHeader: Record "Purchase Header"; NewPostingDate: Date; NewLocationCode: Code[10]; NewVendorInvoiceNo: Code[20]; ValidateNewStatus: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        PurchHeader.Get(NewPurchHeader."Document Type", NewPurchHeader."No.");
        if ValidateNewStatus then
            ReleasePurchDoc.Reopen(PurchHeader);
        if NewPostingDate <> 0D then
            PurchHeader.Validate("Posting Date", NewPostingDate);
        if NewLocationCode <> '' then
            PurchHeader.Validate("Location Code", NewLocationCode);
        if NewVendorInvoiceNo <> '' then
            PurchHeader.Validate("Vendor Invoice No.", NewVendorInvoiceNo);
        PurchHeader.Modify();
        NewPurchHeader := PurchHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchCrMemoHeader(var NewPurchHeader: Record "Purchase Header"; NewPostingDate: Date; NewLocationCode: Code[10]; NewVendorCrMemoNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.Get(NewPurchHeader."Document Type", NewPurchHeader."No.");
        if NewPostingDate <> 0D then
            PurchHeader.Validate("Posting Date", NewPostingDate);
        if NewLocationCode <> '' then
            PurchHeader.Validate("Location Code", NewLocationCode);
        if NewVendorCrMemoNo <> '' then
            PurchHeader.Validate("Vendor Cr. Memo No.", NewVendorCrMemoNo);
        PurchHeader.Modify();
        NewPurchHeader := PurchHeader;
    end;

    [Scope('OnPrem')]
    procedure PostPurchOrder(var PurchHeader: Record "Purchase Header")
    var
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.Run(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure RetrievePurchRcptHeader(NewPurchHeader: Record "Purchase Header"; var NewPurchRcptHeader: Record "Purch. Rcpt. Header"; WhichRcpt: Integer)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        ActualRcpt: Integer;
    begin
        ActualRcpt := 0;
        PurchRcptHeader.Reset();
        PurchRcptHeader.SetCurrentKey("Order No.");
        PurchRcptHeader.SetRange("Order No.", NewPurchHeader."No.");
        if PurchRcptHeader.Find('-') then
            repeat
                NewPurchRcptHeader := PurchRcptHeader;
                ActualRcpt := ActualRcpt + 1;
            until (PurchRcptHeader.Next() = 0) or (ActualRcpt = WhichRcpt);
        if ActualRcpt <> WhichRcpt then
            Clear(NewPurchRcptHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchLine(var NewPurchLine: Record "Purchase Line"; NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewType: Enum "Purchase Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewLocationCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewDirectUnitCost: Decimal; NewNonstock: Boolean)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();
        PurchLine."Document Type" := NewPurchHeader."Document Type";
        PurchLine."Document No." := NewPurchHeader."No.";
        PurchLine."Line No." := NewLineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, NewType);
        PurchLine.Validate("No.", NewNo);
        if NewType = PurchLine.Type::Item then
            PurchLine.Validate("Variant Code", NewVariantCode);
        PurchLine.Validate("Location Code", NewLocationCode);
        PurchLine.Validate(Quantity, NewQuantity);
        PurchLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        PurchLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        PurchLine.Validate(Nonstock, NewNonstock);
        PurchLine.Modify(true);
        NewPurchLine := PurchLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchLine(var NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewBinCode: Code[20]; NewQtyToReceive: Decimal; NewQtyToInvoice: Decimal; NewDirectUnitCost: Decimal; NewLineDiscount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
        if NewBinCode <> PurchLine."Bin Code" then
            PurchLine.Validate("Bin Code", NewBinCode);
        PurchLine.Validate("Qty. to Receive", NewQtyToReceive);
        PurchLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        if NewDirectUnitCost <> 0 then
            PurchLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        PurchLine.Validate("Line Discount %", NewLineDiscount);
        PurchLine.Modify();

        PurchHeader.Get(NewPurchHeader."Document Type", NewPurchHeader."No.");
        PurchHeader.Receive := PurchHeader.Receive or (NewQtyToReceive <> 0);
        PurchHeader.Invoice := PurchHeader.Invoice or (NewQtyToInvoice <> 0);
        PurchHeader.Modify();
        NewPurchHeader := PurchHeader;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchReturnLine(var NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewReturnReasonCode: Code[10])
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
        PurchLine.Validate("Return Reason Code", NewReturnReasonCode);
        PurchLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure ReleasePurchDocument(var PurchHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.Run(PurchHeader);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchCrMemoLine(var NewPurchLine: Record "Purchase Line"; NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewType: Enum "Purchase Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewDirectUnitCost: Decimal; NewAppToItemEntryNo: Integer)
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Init();
        PurchLine."Document Type" := NewPurchHeader."Document Type";
        PurchLine."Document No." := NewPurchHeader."No.";
        PurchLine."Line No." := NewLineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, NewType);
        PurchLine.Validate("No.", NewNo);
        if NewType = PurchLine.Type::Item then
            PurchLine.Validate("Variant Code", NewVariantCode);
        PurchLine.Validate(Quantity, NewQuantity);
        PurchLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        PurchLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        if NewAppToItemEntryNo <> 0 then
            PurchLine.Validate("Appl.-to Item Entry", NewAppToItemEntryNo);
        PurchLine.Modify(true);
        NewPurchLine := PurchLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchCrMemoLine(var NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewBinCode: Code[20]; NewQtyToReturn: Decimal; NewQtyToInvoice: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
        if NewBinCode <> PurchLine."Bin Code" then
            PurchLine.Validate("Bin Code", NewBinCode);
        PurchLine.Validate("Return Qty. to Ship", NewQtyToReturn);
        PurchLine.Validate("Qty. to Invoice", NewQtyToInvoice);
        PurchLine.Modify();

        PurchHeader.Get(NewPurchHeader."Document Type", NewPurchHeader."No.");
        PurchHeader.Ship := PurchHeader.Ship or (NewQtyToReturn <> 0);
        PurchHeader.Invoice := PurchHeader.Invoice or (NewQtyToInvoice <> 0);
        PurchHeader.Modify();
        NewPurchHeader := PurchHeader;
    end;

    [Scope('OnPrem')]
    procedure InsertProdOrder(var NewProdOrder: Record "Production Order"; NewStatus: Option; NewSourceType: Option; NewSourceNo: Code[20]; NewQuantity: Decimal; NewLocation: Code[10])
    var
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.Init();
        ProdOrder.Validate(Status, NewStatus);
        ProdOrder.Insert(true);
        ProdOrder.Validate("Source Type", NewSourceType);
        ProdOrder.Validate("Source No.", NewSourceNo);
        ProdOrder.Validate(Quantity, NewQuantity);
        ProdOrder.Validate("Location Code", NewLocation);
        ProdOrder.Modify(true);
        NewProdOrder := ProdOrder;
    end;

    [Scope('OnPrem')]
    procedure InsertProdOrderLine(NewProdOrder: Record "Production Order"; var NewProdOrderLine: Record "Prod. Order Line"; NewLineNo: Integer; NewItem: Code[20]; NewLocation: Code[10]; NewQuantity: Decimal; NewUoM: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Init();
        ProdOrderLine.Status := NewProdOrder.Status;
        ProdOrderLine."Prod. Order No." := NewProdOrder."No.";
        ProdOrderLine."Line No." := NewLineNo;
        ProdOrderLine.Insert(true);
        ProdOrderLine.Validate("Item No.", NewItem);
        ProdOrderLine.Validate("Location Code", NewLocation);
        ProdOrderLine.Validate(Quantity, NewQuantity);
        ProdOrderLine.Validate("Unit of Measure Code", NewUoM);
        ProdOrderLine.Modify(true);
        NewProdOrderLine := ProdOrderLine;
    end;

    [Scope('OnPrem')]
    procedure PostConsumption(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10]; NewLineNo: Integer; NewLocation: Code[10]; NewPostingDate: Date; NewProdOrderNo: Code[20]; NewNo: Code[20]; NewVariant: Code[10]; NewQuantity: Decimal; NewComponentLineNo: Integer)
    var
        ConsumpItemJnlLine: Record "Item Journal Line";
        ConsumpJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ConsumpItemJnlLine.Init();
        ConsumpItemJnlLine.Validate("Journal Template Name", NewJnlTemplName);
        ConsumpItemJnlLine.Validate("Journal Batch Name", NewJnlBatchName);
        ConsumpItemJnlLine."Entry Type" := ConsumpItemJnlLine."Entry Type"::Consumption;
        ConsumpItemJnlLine.Validate("Line No.", NewLineNo);
        ConsumpItemJnlLine.Validate("Location Code", NewLocation);
        ConsumpItemJnlLine.Validate("Posting Date", NewPostingDate);
        ConsumpItemJnlLine.Validate("Order Type", ConsumpItemJnlLine."Order Type"::Production);
        ConsumpItemJnlLine.Validate("Order No.", NewProdOrderNo);
        ConsumpItemJnlLine.Validate("Item No.", NewNo);
        ConsumpItemJnlLine.Validate(Quantity, NewQuantity);
        ConsumpItemJnlLine."Variant Code" := NewVariant;
        ConsumpItemJnlLine.Validate("Prod. Order Comp. Line No.", NewComponentLineNo);
        ConsumpItemJnlLine.Insert();
        ConsumpJnlPostBatch.Run(ConsumpItemJnlLine);

        POConsJnlDelete(ConsumpItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure POConsJnlDelete(ConsumpItemJnlLine: Record "Item Journal Line")
    begin
        ConsumpItemJnlLine.SetRange("Journal Template Name", ConsumpItemJnlLine."Journal Template Name");
        ConsumpItemJnlLine.SetRange("Journal Batch Name", ConsumpItemJnlLine."Journal Batch Name");
        ConsumpItemJnlLine.SetRange("Entry Type", ConsumpItemJnlLine."Entry Type"::Consumption);
        ConsumpItemJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure PostOutput(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10]; NewLineNo: Integer; NewPostingDate: Date; NewProdOrderNo: Code[20]; NewItemNo: Code[20]; NewOutputQuantity: Decimal; NewUoM: Code[10])
    var
        OutputJnlLine: Record "Item Journal Line";
        OutputJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        OutputJnlLine.Init();
        OutputJnlLine."Entry Type" := OutputJnlLine."Entry Type"::Output;
        OutputJnlLine.Validate("Journal Template Name", NewJnlTemplName);
        OutputJnlLine.Validate("Journal Batch Name", NewJnlBatchName);
        OutputJnlLine.Validate("Line No.", NewLineNo);
        OutputJnlLine.Validate("Posting Date", NewPostingDate);
        OutputJnlLine.Validate("Order Type", OutputJnlLine."Order Type"::Production);
        OutputJnlLine.Validate("Order No.", NewProdOrderNo);
        OutputJnlLine.Validate("Item No.", NewItemNo);
        OutputJnlLine.Validate("Output Quantity", NewOutputQuantity);
        OutputJnlLine.Validate("Unit of Measure Code", NewUoM);
        OutputJnlLine.Insert();
        OutputJnlPostBatch.Run(OutputJnlLine);

        POOutputJnlDelete(OutputJnlLine);
    end;

    [Scope('OnPrem')]
    procedure POOutputJnlDelete(OutputJnlLine: Record "Item Journal Line")
    begin
        OutputJnlLine.SetRange("Journal Template Name", OutputJnlLine."Journal Template Name");
        OutputJnlLine.SetRange("Journal Batch Name", OutputJnlLine."Journal Batch Name");
        OutputJnlLine.SetRange("Entry Type", OutputJnlLine."Entry Type"::Output);
        OutputJnlLine.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure InsertWhseActHeader(var NewWhseActHeader: Record "Warehouse Activity Header"; NewType: Option; NewLocationCode: Code[10])
    var
        WhseActHeader: Record "Warehouse Activity Header";
    begin
        WhseActHeader.Init();
        WhseActHeader.Validate(Type, NewType);
        WhseActHeader.Insert(true);
        WhseActHeader.Validate("Location Code", NewLocationCode);
        WhseActHeader.Modify(true);
        NewWhseActHeader := WhseActHeader;
    end;

    [Scope('OnPrem')]
    procedure RetrieveSourceDocs(NewWhseShipHeader: Record "Warehouse Shipment Header"; NewType: Option; NewSourceDoc: Option; WhichDoc: Integer)
    var
        WhseSetup: Record "Warehouse Setup";
        SourceDocSelection: Page "Source Documents";
        GetSourceDoc: Report "Get Source Documents";
        ActualDoc: Integer;
        WhseShipHeader: Record "Warehouse Shipment Header";
        WhseRequest: Record "Warehouse Request";
    begin
        WhseShipHeader := NewWhseShipHeader;

        WhseRequest.SetRange(Type, NewType);
        WhseRequest.SetRange("Source Document", NewSourceDoc);
        if WhseShipHeader."Location Code" <> '' then
            WhseRequest.SetRange("Location Code", WhseShipHeader."Location Code");

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WhseRequest);

        if WhseRequest.Find('-') then begin
            ActualDoc := 0;
            repeat
                ActualDoc := ActualDoc + 1;
                if ActualDoc = WhichDoc then
                    SourceDocSelection.GetResult(WhseRequest);

                GetSourceDoc.SetOneCreatedShptHeader(WhseShipHeader);

                WhseSetup.Get();
                GetSourceDoc.SetDoNotFillQtytoHandle(false);
                GetSourceDoc.UseRequestPage(false);
                GetSourceDoc.SetTableView(WhseRequest);
                GetSourceDoc.RunModal();
            until (WhseRequest.Next() = 0) or (ActualDoc = WhichDoc);

            if ActualDoc <> WhichDoc then
                Clear(WhseRequest);
        end;
    end;

    [Scope('OnPrem')]
    procedure ModifyWhseActLine(var NewWhseActivLine: Record "Warehouse Activity Line"; DocType: Option; DocNo: Code[20]; NewLineNo: Integer; NewZoneCode: Code[10]; NewBinCode: Code[20]; NewQtyToHandle: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.Get(DocType, DocNo, NewLineNo);
        if NewZoneCode <> WhseActivLine."Zone Code" then
            WhseActivLine.Validate("Zone Code", NewZoneCode);
        if NewBinCode <> WhseActivLine."Bin Code" then
            WhseActivLine.Validate("Bin Code", NewBinCode);
        if NewQtyToHandle <> WhseActivLine."Qty. to Handle" then
            WhseActivLine.Validate("Qty. to Handle", NewQtyToHandle);
        WhseActivLine.Modify(true);
        NewWhseActivLine := WhseActivLine;
    end;

    [Scope('OnPrem')]
    procedure AssignSerialNo(NewWhseActHeader: Record "Warehouse Activity Header"; NewType: Option; NewLocation: Code[10]; NewItemNo: Code[20])
    var
        WhseActHeader: Record "Warehouse Activity Header";
    begin
        WhseActHeader.SetRange(Type, NewType);
        WhseActHeader.SetRange("Location Code", NewLocation);
        WhseActHeader.FindFirst();
    end;

    [Scope('OnPrem')]
    procedure AutofillQtyToHandle(NewWhseActHeader: Record "Warehouse Activity Header"; NewType: Option; NewLocation: Code[10])
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActHeader.SetRange(Type, NewType);
        WhseActHeader.SetRange("Location Code", NewLocation);
        WhseActHeader.FindFirst();

        WhseActLine.SetRange("No.", WhseActHeader."No.");
        if WhseActLine.FindFirst() then
            WhseActLine.AutofillQtyToHandle(WhseActLine);
    end;

    [Scope('OnPrem')]
    procedure RetrieveWhseActDocs(var NewWhseActHeader: Record "Warehouse Activity Header"; var NewWhseActLine: Record "Warehouse Activity Line"; NewType: Option; NewSourceNo: Code[20])
    var
        WhseActHeader: Record "Warehouse Activity Header";
        WhseActLine: Record "Warehouse Activity Line";
    begin
        WhseActHeader.SetRange(Type, NewType);
        WhseActHeader.FindFirst();
        NewWhseActHeader := WhseActHeader;

        WhseActLine.SetRange("Activity Type", NewType);
        WhseActLine.SetRange("Source No.", NewSourceNo);
        WhseActLine.FindFirst();
        NewWhseActLine := WhseActLine;
    end;

    [Scope('OnPrem')]
    procedure InsertWhseRcptHeader(var WhseRcptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WhseRcptHeader.Init();
        WhseRcptHeader."Location Code" := LocationCode;
        WhseRcptHeader.Insert(true);

        WhseRcptHeader."Zone Code" := ZoneCode;
        WhseRcptHeader."Bin Code" := BinCode;
        WhseRcptHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure ModifyWhseRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; RcptNo: Code[20]; LineNo: Integer; ZoneCode: Code[10]; BinCode: Code[20]; QtytoReceive: Decimal)
    begin
        WhseRcptLine.Get(RcptNo, LineNo);
        if WhseRcptLine."Zone Code" <> ZoneCode then
            WhseRcptLine.Validate("Zone Code", ZoneCode);
        if WhseRcptLine."Bin Code" <> BinCode then
            WhseRcptLine.Validate("Bin Code", BinCode);
        if WhseRcptLine."Qty. to Receive" <> QtytoReceive then
            WhseRcptLine.Validate("Qty. to Receive", QtytoReceive);
        WhseRcptLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseRcptFromPurch(PurchaseHeader: Record "Purchase Header"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Purchase Line");
        WhseRqst.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WhseRqst.SetRange("Source No.", PurchaseHeader."No.");
        WhseRqst.SetRange("Location Code", LocationCode);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.FindFirst();
        if WhseReceiptHeader."No." <> '' then
            GetSourceDocuments.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        GetSourceDocuments.SetDoNotFillQtytoHandle(false);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseRcptFromSales(SalesHeader: Record "Sales Header"; var WhseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRqst.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseRqst.SetRange("Source No.", SalesHeader."No.");
        WhseRqst.SetRange("Location Code", LocationCode);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.FindFirst();
        if WhseReceiptHeader."No." <> '' then
            GetSourceDocuments.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        GetSourceDocuments.SetDoNotFillQtytoHandle(false);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseRcptFromTrans(TransferHeader: Record "Transfer Header"; var WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WhseRqst.SetRange(Type, WhseRqst.Type::Inbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRqst.SetRange("Source Subtype", 1);
        WhseRqst.SetRange("Source No.", TransferHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.FindFirst();
        if WhseReceiptHeader."No." <> '' then
            GetSourceDocuments.SetOneCreatedReceiptHeader(WhseReceiptHeader);
        GetSourceDocuments.SetDoNotFillQtytoHandle(false);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure PostWhseReceipt(var WhseRcptLine: Record "Warehouse Receipt Line")
    var
        WhsePostReceipt: Codeunit "Whse.-Post Receipt";
    begin
        WhseRcptLine.SetRange("No.", WhseRcptLine."No.");
        WhsePostReceipt.SetHideValidationDialog(true);
        WhsePostReceipt.Run(WhseRcptLine);
    end;

    [Scope('OnPrem')]
    procedure CreateWhseRcptBySourceFilter(var WhseRcptHeader: Record "Warehouse Receipt Header"; SourceFilterCode: Code[10])
    var
        WhseSourceFilter: Record "Warehouse Source Filter";
        GetSourceBatch: Report "Get Source Documents";
    begin
        WhseSourceFilter.Get(0, SourceFilterCode);
        GetSourceBatch.SetOneCreatedReceiptHeader(WhseRcptHeader);
        WhseSourceFilter.SetFilters(GetSourceBatch, WhseRcptHeader."Location Code");
        GetSourceBatch.SetHideDialog(true);
        GetSourceBatch.UseRequestPage(false);
        GetSourceBatch.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ModifyPutAwayWkshLine(WkshTemplateName: Code[10]; Name: Code[10]; LocationCode: Code[10]; LineNo: Integer; QtytoHandle: Decimal; UOMCode: Code[20])
    var
        PutAwayWkshLine: Record "Whse. Worksheet Line";
    begin
        PutAwayWkshLine.Get(WkshTemplateName, Name, LocationCode, LineNo);
        if PutAwayWkshLine."Qty. to Handle" <> QtytoHandle then
            PutAwayWkshLine.Validate("Qty. to Handle", QtytoHandle);
        if PutAwayWkshLine."Unit of Measure Code" <> UOMCode then
            PutAwayWkshLine.Validate("Unit of Measure Code", UOMCode);
        PutAwayWkshLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure PostWhseActivity(var NewWhseActivLine: Record "Warehouse Activity Line")
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Register";
    begin
        WhseActivLine.Copy(NewWhseActivLine);
        if WhseActivLine.Find() then
            WhseActivityPost.Run(WhseActivLine);
    end;

    [Scope('OnPrem')]
    procedure InsertWhseShptHeader(var WhseShptHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WhseShptHeader.Init();
        WhseShptHeader."Location Code" := LocationCode;
        WhseShptHeader.Insert(true);

        WhseShptHeader."Zone Code" := ZoneCode;
        WhseShptHeader."Bin Code" := BinCode;
        WhseShptHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseShptFromSales(SalesHeader: Record "Sales Header"; var WhseShptHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Sales Line");
        WhseRqst.SetRange("Source Subtype", SalesHeader."Document Type");
        WhseRqst.SetRange("Source No.", SalesHeader."No.");
        WhseRqst.SetRange("Location Code", LocationCode);
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.FindFirst();
        if WhseShptHeader."No." <> '' then
            GetSourceDocuments.SetOneCreatedShptHeader(WhseShptHeader);
        GetSourceDocuments.SetDoNotFillQtytoHandle(false);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseShptFromTrans(TransferHeader: Record "Transfer Header"; var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseRqst: Record "Warehouse Request";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        WhseRqst.SetRange(Type, WhseRqst.Type::Outbound);
        WhseRqst.SetRange("Source Type", DATABASE::"Transfer Line");
        WhseRqst.SetRange("Source Subtype", 0);
        WhseRqst.SetRange("Source No.", TransferHeader."No.");
        WhseRqst.SetRange("Document Status", WhseRqst."Document Status"::Released);
        WhseRqst.FindFirst();
        if WhseShptHeader."No." <> '' then
            GetSourceDocuments.SetOneCreatedShptHeader(WhseShptHeader);
        GetSourceDocuments.SetDoNotFillQtytoHandle(false);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetTableView(WhseRqst);
        GetSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CreateWhseShptBySourceFilter(var WhseShptHeader: Record "Warehouse Shipment Header"; SourceFilterCode: Code[10])
    var
        WhseSourceFilter: Record "Warehouse Source Filter";
        GetSourceBatch: Report "Get Source Documents";
    begin
        WhseSourceFilter.Get(1, SourceFilterCode);
        GetSourceBatch.SetOneCreatedShptHeader(WhseShptHeader);
        WhseSourceFilter.SetFilters(GetSourceBatch, WhseShptHeader."Location Code");
        GetSourceBatch.SetHideDialog(true);
        GetSourceBatch.UseRequestPage(false);
        GetSourceBatch.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ModifyWhseShptLine(var WhseShptLine: Record "Warehouse Shipment Line"; ShptNo: Code[20]; LineNo: Integer; ZoneCode: Code[10]; BinCode: Code[20]; QtytoShip: Decimal)
    begin
        WhseShptLine.Get(ShptNo, LineNo);
        if WhseShptLine."Zone Code" <> ZoneCode then
            WhseShptLine.Validate("Zone Code", ZoneCode);
        if WhseShptLine."Bin Code" <> BinCode then
            WhseShptLine.Validate("Bin Code", BinCode);
        if WhseShptLine."Qty. to Ship" <> QtytoShip then
            WhseShptLine.Validate("Qty. to Ship", QtytoShip);
        WhseShptLine.Modify();
    end;

    [Scope('OnPrem')]
    procedure ReleaseWhseShipment(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        ReleaseWhseShpt: Codeunit "Whse.-Shipment Release";
    begin
        ReleaseWhseShpt.Release(WhseShptHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePickFromWhseShipment(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        if WhseShptHeader.Status = WhseShptHeader.Status::Open then
            ReleaseWhseShipment(WhseShptHeader);
        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        if WhseShptLine.FindFirst() then begin
            WhseShptLine.SetHideValidationDialog(true);
            WhseShptLine.CreatePickDoc(WhseShptLine, WhseShptHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure PostWhseShipment(var WhseShptLine: Record "Warehouse Shipment Line"; Invoice: Boolean)
    var
        WhsePostShipment: Codeunit "Whse.-Post Shipment";
    begin
        WhseShptLine.SetRange("No.", WhseShptLine."No.");
        WhsePostShipment.SetPostingSettings(Invoice);
        WhsePostShipment.SetPrint(false);
        WhsePostShipment.Run(WhseShptLine);
    end;

    [Scope('OnPrem')]
    procedure InsertWhsePickOrderHeader(var WhsePickOrderHeader: Record "Whse. Internal Pick Header"; LocationCode: Code[10]; ToZoneCode: Code[10]; ToBinCode: Code[20])
    begin
        WhsePickOrderHeader.Init();
        WhsePickOrderHeader."Location Code" := LocationCode;
        WhsePickOrderHeader."To Zone Code" := ToZoneCode;
        WhsePickOrderHeader."To Bin Code" := ToBinCode;
        WhsePickOrderHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertWhsePickOrderLines(var NewWhsePickOrderLine: Record "Whse. Internal Pick Line"; WhsePickOrderHeader: Record "Whse. Internal Pick Header"; NewLineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ToZoneCode: Code[10]; ToBinCode: Code[20]; Quantity: Decimal; UoM: Code[10])
    var
        WhsePickOrderLine: Record "Whse. Internal Pick Line";
    begin
        WhsePickOrderLine.Init();
        WhsePickOrderLine."No." := WhsePickOrderHeader."No.";
        WhsePickOrderLine."Line No." := NewLineNo;
        WhsePickOrderLine.Insert(true);
        WhsePickOrderLine."Location Code" := LocationCode;
        WhsePickOrderLine."Item No." := ItemNo;
        WhsePickOrderLine."Variant Code" := VariantCode;
        WhsePickOrderLine."To Zone Code" := ToZoneCode;
        WhsePickOrderLine."To Bin Code" := ToBinCode;
        WhsePickOrderLine.Validate("Unit of Measure Code", UoM);
        WhsePickOrderLine.Validate(Quantity, Quantity);
        WhsePickOrderLine.Modify(true);
        NewWhsePickOrderLine := WhsePickOrderLine;
    end;

    [Scope('OnPrem')]
    procedure ReleaseWhsePickOrder(var WhsePickOrderHeader: Record "Whse. Internal Pick Header")
    var
        WhsePickOrderRelease: Codeunit "Whse. Internal Pick Release";
    begin
        WhsePickOrderRelease.Release(WhsePickOrderHeader);
    end;

    [Scope('OnPrem')]
    procedure CreatePickFromPickOrder(var WhsePickOrderHeader: Record "Whse. Internal Pick Header")
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        if WhsePickOrderHeader.Status = WhsePickOrderHeader.Status::Open then
            ReleaseWhsePickOrder(WhsePickOrderHeader);
        WhseInternalPickLine.SetRange("No.", WhsePickOrderHeader."No.");
        if WhseInternalPickLine.FindFirst() then begin
            WhseInternalPickLine.SetHideValidationDialog(true);
            WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhsePickOrderHeader);
        end;
    end;

    [Scope('OnPrem')]
    procedure CreatePickWorksheet(var PickWkshLine: Record "Whse. Worksheet Line"; WkshTemplateName: Code[10]; Name: Code[10]; LocationCode: Code[10]; DocType: Option; DocNo: Code[20])
    var
        WhsePickRqst: Record "Whse. Pick Request";
        GetWhseSourceDocuments: Report "Get Outbound Source Documents";
    begin
        GetWhseSourceDocuments.SetPickWkshName(WkshTemplateName, Name, LocationCode);
        WhsePickRqst.SetRange("Document Type", DocType);
        WhsePickRqst.SetRange("Document No.", DocNo);
        GetWhseSourceDocuments.SetHideDialog(true);
        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePickRqst);
        GetWhseSourceDocuments.RunModal();
    end;

    [Scope('OnPrem')]
    procedure CreatePickFromWksh(var NewPickWkshLine: Record "Whse. Worksheet Line"; AssignedID: Code[10]; MaxNoOfLines: Integer; MaxNoOfSourceDoc: Integer; SortPick: Enum "Whse. Activity Sorting Method"; PerShipTo: Boolean; PerItem: Boolean; PerZone: Boolean; PerBin: Boolean; PerWhseDoc: Boolean; PerDate: Boolean; PrintPick: Boolean)
    var
        PickWkshLine: Record "Whse. Worksheet Line";
        CreatePick: Report "Create Pick";
    begin
        PickWkshLine := NewPickWkshLine;
        PickWkshLine.SetRange("Worksheet Template Name", PickWkshLine."Worksheet Template Name");
        PickWkshLine.SetRange(Name, PickWkshLine.Name);
        PickWkshLine.SetRange("Location Code", PickWkshLine."Location Code");

        CreatePick.InitializeReport(
          AssignedID, MaxNoOfLines, MaxNoOfSourceDoc, SortPick, PerShipTo, PerItem,
          PerZone, PerBin, PerWhseDoc, PerDate, PrintPick, false, false);
        CreatePick.UseRequestPage(false);
        CreatePick.SetWkshPickLine(PickWkshLine);
        CreatePick.RunModal();
        Clear(CreatePick);

        NewPickWkshLine := PickWkshLine;
    end;

    [Scope('OnPrem')]
    procedure CreateInvPutAwayPickBySrcFilt(SourceDoc: Enum "Warehouse Request Source Document"; SourceNo: Code[20])
    var
        WhseRequest: Record "Warehouse Request";
        WhseActivHeader: Record "Warehouse Activity Header";
        CreateInvtPick: Codeunit "Create Inventory Pick/Movement";
        CreateInvtPutAway: Codeunit "Create Inventory Put-away";
    begin
        WhseRequest.Reset();
        WhseRequest.SetCurrentKey("Source Document", "Source No.");
        WhseRequest.SetRange("Source Document", SourceDoc);
        WhseRequest.SetRange("Source No.", SourceNo);
        if WhseRequest.Find('-') then
            repeat
                Clear(WhseActivHeader);
                case WhseRequest.Type of
                    WhseRequest.Type::Inbound:
                        begin
                            CreateInvtPutAway.CheckSourceDoc(WhseRequest);
                            CreateInvtPutAway.SetWhseRequest(WhseRequest, true);
                            WhseActivHeader.Init();
                            WhseActivHeader.Type := WhseActivHeader.Type::"Invt. Put-away";
                            WhseActivHeader."No." := '';
                            WhseActivHeader."Location Code" := WhseRequest."Location Code";
                            CreateInvtPutAway.AutoCreatePutAway(WhseActivHeader);
                        end;
                    WhseRequest.Type::Outbound:
                        begin
                            CreateInvtPick.CheckSourceDoc(WhseRequest);
                            CreateInvtPick.SetWhseRequest(WhseRequest, true);
                            WhseActivHeader.Init();
                            WhseActivHeader.Type := WhseActivHeader.Type::"Invt. Pick";
                            WhseActivHeader."No." := '';
                            WhseActivHeader."Location Code" := WhseRequest."Location Code";
                            CreateInvtPick.AutoCreatePickOrMove(WhseActivHeader);
                        end;
                end;
            until WhseRequest.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure CreateInvPick(var WhseActHeader: Record "Warehouse Activity Header")
    var
        WhseReq: Record "Warehouse Request";
        CreateInvPick: Codeunit "Create Inventory Pick/Movement";
    begin
        Commit();
        WhseReq.Init();
        WhseReq.FindLast();
        CreateInvPick.SetWhseRequest(WhseReq, true);
        CreateInvPick.Run(WhseActHeader);
    end;

    [Scope('OnPrem')]
    procedure CreateInvPutAway(var WhseActHeader: Record "Warehouse Activity Header")
    var
        WhseReq: Record "Warehouse Request";
        CreateInvPutAway: Codeunit "Create Inventory Put-away";
    begin
        Commit();
        WhseReq.Init();
        WhseReq.FindFirst();
        CreateInvPutAway.SetWhseRequest(WhseReq, true);
        CreateInvPutAway.Run(WhseActHeader);
    end;

    [Scope('OnPrem')]
    procedure PostInvWhseActLine(WhseActivLine: Record "Warehouse Activity Line"; PostInvoice: Boolean)
    var
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
    begin
        Clear(WhseActivityPost);
        WhseActivityPost.SetInvoiceSourceDoc(PostInvoice);
        WhseActivityPost.ShowHideDialog(true);
        WhseActivityPost.Run(WhseActivLine);
    end;

    [Scope('OnPrem')]
    procedure InsertMovWkshLine(var NewWhseWkshLine: Record "Whse. Worksheet Line"; WkshTemplateName: Code[10]; WkshName: Code[10]; LocationCode: Code[10]; LineNo: Integer; Date: Date; ItemNo: Code[20]; VariantCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.Init();
        WhseWkshLine.Validate("Worksheet Template Name", WkshTemplateName);
        WhseWkshLine.Validate(Name, WkshName);
        WhseWkshLine.Validate("Location Code", LocationCode);
        WhseWkshLine.Validate("Line No.", LineNo);
        WhseWkshLine.Validate("Due Date", Date);
        WhseWkshLine.Validate("Item No.", ItemNo);
        WhseWkshLine.Validate("Variant Code", VariantCode);
        WhseWkshLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WhseWkshLine.Validate("From Bin Code", FromBinCode);
        WhseWkshLine.Validate("To Bin Code", ToBinCode);
        WhseWkshLine.Validate(Quantity, Quantity);
        WhseWkshLine.Validate("Qty. to Handle", Quantity);
        WhseWkshLine.Insert(true);
        NewWhseWkshLine := WhseWkshLine;
    end;

    [Scope('OnPrem')]
    procedure InsertWhseIntPutAwayOrderHead(var WhseIntPutAwayHeader: Record "Whse. Internal Put-away Header"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WhseIntPutAwayHeader.Init();
        WhseIntPutAwayHeader."Location Code" := LocationCode;
        WhseIntPutAwayHeader."From Zone Code" := ZoneCode;
        WhseIntPutAwayHeader."From Bin Code" := BinCode;
        WhseIntPutAwayHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertWhseIntPutAwayOrderLines(var NewIntPutAwayOrderLine: Record "Whse. Internal Put-away Line"; IntPutAwayOrderHeader: Record "Whse. Internal Put-away Header"; NewLineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Qty: Decimal; UoM: Code[10])
    var
        WhseIntPutAwayOrderLine: Record "Whse. Internal Put-away Line";
    begin
        WhseIntPutAwayOrderLine.Init();
        WhseIntPutAwayOrderLine."No." := IntPutAwayOrderHeader."No.";
        WhseIntPutAwayOrderLine."Line No." := NewLineNo;
        WhseIntPutAwayOrderLine.Insert(true);
        WhseIntPutAwayOrderLine.Validate("Location Code", LocationCode);
        WhseIntPutAwayOrderLine."From Zone Code" := ZoneCode;
        WhseIntPutAwayOrderLine.Validate("From Bin Code", BinCode);
        WhseIntPutAwayOrderLine.Validate("Item No.", ItemNo);
        WhseIntPutAwayOrderLine.Validate("Variant Code", VariantCode);
        WhseIntPutAwayOrderLine.Validate("Unit of Measure Code", UoM);
        WhseIntPutAwayOrderLine.Validate(Quantity, Qty);
        WhseIntPutAwayOrderLine.Modify(true);
        NewIntPutAwayOrderLine := WhseIntPutAwayOrderLine;
    end;

    [Scope('OnPrem')]
    procedure CreaPutAwayFromIntPutAwayOrder(var WhseIntPutAwayOrderHead: Record "Whse. Internal Put-away Header")
    var
        WhseIntPutAwayLine: Record "Whse. Internal Put-away Line";
        ReleaseWhseInternalPutAway: Codeunit "Whse. Int. Put-away Release";
    begin
        if WhseIntPutAwayOrderHead.Status = WhseIntPutAwayOrderHead.Status::Open then
            ReleaseWhseInternalPutAway.Release(WhseIntPutAwayOrderHead);
        WhseIntPutAwayLine.SetRange("No.", WhseIntPutAwayOrderHead."No.");
        if WhseIntPutAwayLine.FindFirst() then begin
            WhseIntPutAwayLine.SetHideValidationDialog(true);
            WhseIntPutAwayLine.CreatePutAwayDoc(WhseIntPutAwayLine);
        end;
    end;

    [Scope('OnPrem')]
    procedure AutofillQtyToShip(WhseShptLine: Record "Warehouse Shipment Line")
    begin
        WhseShptLine.SetRange("No.", WhseShptLine."No.");
        WhseShptLine.SetRange("Location Code", WhseShptLine."Location Code");

        if WhseShptLine.FindFirst() then
            WhseShptLine.AutofillQtyToHandle(WhseShptLine);
    end;

    [Scope('OnPrem')]
    procedure ModifyItem(ItemNo: Code[20]; PutAwayUOMCode: Code[10]; PutAwayTemplCode: Code[10])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        if Item."Put-away Unit of Measure Code" <> PutAwayUOMCode then
            Item.Validate("Put-away Unit of Measure Code", PutAwayUOMCode);
        if Item."Put-away Template Code" <> PutAwayTemplCode then
            Item.Validate("Put-away Template Code", PutAwayTemplCode);
        Item.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetGlobalPreconditions()
    var
        SetGlobalPrecond: Codeunit "WMS Set Global Preconditions";
    begin
        SetGlobalPrecond.SetAutoDeleteOldData();
        SetGlobalPrecond.Run();
    end;

    [Scope('OnPrem')]
    procedure GetTestResultsPath(): Text[250]
    var
        SetGlobalPrecond: Codeunit "WMS Set Global Preconditions";
    begin
        if not QASetup.Get() then begin
            SetGlobalPrecond.MaintQASetup();
            QASetup.Get();
        end;
        exit(QASetup."Test Results Path");
    end;

    [Scope('OnPrem')]
    procedure SetNumbers(NoOfRecords: array[20] of Integer; NoOfFields: array[20] of Integer)
    begin
        ILERecords := NoOfRecords[1];
        ILEFields := NoOfFields[1];
        WJLRecords := NoOfRecords[2];
        WJLFields := NoOfFields[2];
        WALRecords := NoOfRecords[3];
        WALFields := NoOfFields[3];
        WERecords := NoOfRecords[4];
        WEFields := NoOfFields[4];
        LEDRecords := NoOfRecords[5];
        LEDFields := NoOfFields[5];
        RcptLineRecords := NoOfRecords[6];
        RcptLineFields := NoOfFields[6];
        PostedRcptLineRecords := NoOfRecords[7];
        PostedRcptLineFields := NoOfFields[7];
        ShptLineRecords := NoOfRecords[8];
        ShptLineFields := NoOfFields[8];
        PostedShptLineRecords := NoOfRecords[9];
        PostedShptLineFields := NoOfFields[9];
        WhseWkshLineRecords := NoOfRecords[11];
        WhseWkshLineFields := NoOfFields[11];
        IJLRecords := NoOfRecords[12];
        IJLFields := NoOfFields[12];
        BCRecords := NoOfRecords[13];
        BCFields := NoOfFields[13];
        WhseReqRecords := NoOfRecords[14];
        WhseReqFields := NoOfFields[14];
        ItemRegRecords := NoOfRecords[15];
        ItemRegFields := NoOfFields[15];
        PostedInvPutAwayLineRecords := NoOfRecords[16];
        PostedInvPutAwayLineFields := NoOfFields[16];
        PostedInvPickLineRecords := NoOfRecords[17];
        PostedInvPickLineFields := NoOfFields[17];
    end;

    [Scope('OnPrem')]
    procedure GetNumbers(var NoOfRecords: array[20] of Integer; var NoOfFields: array[20] of Integer)
    begin
        NoOfRecords[1] := ILERecords;
        NoOfFields[1] := ILEFields;
        NoOfRecords[2] := WJLRecords;
        NoOfFields[2] := WJLFields;
        NoOfRecords[3] := WALRecords;
        NoOfFields[3] := WALFields;
        NoOfRecords[4] := WERecords;
        NoOfFields[4] := WEFields;
        NoOfRecords[5] := LEDRecords;
        NoOfFields[5] := LEDFields;
        NoOfRecords[6] := RcptLineRecords;
        NoOfFields[6] := RcptLineFields;
        NoOfRecords[7] := PostedRcptLineRecords;
        NoOfFields[7] := PostedRcptLineFields;
        NoOfRecords[8] := ShptLineRecords;
        NoOfFields[8] := ShptLineFields;
        NoOfRecords[9] := PostedShptLineRecords;
        NoOfFields[9] := PostedShptLineFields;
        NoOfRecords[11] := WhseWkshLineRecords;
        NoOfFields[11] := WhseWkshLineFields;
        NoOfRecords[12] := IJLRecords;
        NoOfFields[12] := IJLFields;
        NoOfRecords[13] := BCRecords;
        NoOfFields[13] := BCFields;
        NoOfRecords[14] := WhseReqRecords;
        NoOfFields[14] := WhseReqFields;
        NoOfRecords[15] := ItemRegRecords;
        NoOfFields[15] := ItemRegFields;
        NoOfRecords[16] := PostedInvPutAwayLineRecords;
        NoOfFields[16] := PostedInvPutAwayLineFields;
        NoOfRecords[17] := PostedInvPickLineRecords;
        NoOfFields[17] := PostedInvPickLineFields;
    end;

    [Scope('OnPrem')]
    procedure DeleteQATables(ConfirmDelete: Boolean)
    var
        UseCase: Record "Whse. Use Case";
        TestCase: Record "Whse. Test Case";
        TestscriptResult: Record "Whse. Testscript Result";
        TestIteration: Record "Whse. Test Iteration";
        QASetup: Record "Whse. QA Setup";
        WhseEntryRef: Record "BW Warehouse Entry Ref";
        ItemLedgEntryRef: Record "BW Item Ledger Entry Ref";
        WhseJnlLineRef: Record "BW Warehouse Journal Line Ref";
        WhseActivLineRef: Record "BW Warehouse Activity Line Ref";
        WhseRcptLineRef: Record "BW Warehouse Receipt Line Ref";
        PostedRcptLineRef: Record "BW Posted Whse. Rcpt Line Ref";
        WhseShptLineRef: Record "BW Warehouse Shipment Line Ref";
        PostedShptLineRef: Record "BW Posted Whse. Shpmt Line Ref";
        PickWkshLineRef: Record "BW Whse. Worksheet Line Ref";
        BinContentRef: Record "BW Bin Content Ref";
        WhseReqRef: Record "BW Warehouse Request Ref";
        ItemRegRef: Record "BW Item Register Ref";
        PstdInvPutAwayLineRef: Record "BW P. Invt. Put-away Line Ref";
        PstdInvPickLineRef: Record "BW P. Invt. Pick Line Ref";
    begin
        if ConfirmDelete then
            if not Confirm('You are about to delete the QA tables. Proceed ?', false) then
                exit
            else
                if not Confirm('Are you absolutely sure to delete the QA tables ?', false) then
                    Error('Cancelled.');

        UseCase.DeleteAll();
        TestCase.DeleteAll();
        TestscriptResult.DeleteAll();
        TestIteration.DeleteAll();
        ItemLedgEntryRef.DeleteAll();
        WhseJnlLineRef.DeleteAll();
        WhseEntryRef.DeleteAll();
        WhseActivLineRef.DeleteAll();
        WhseRcptLineRef.DeleteAll();
        PostedRcptLineRef.DeleteAll();
        WhseShptLineRef.DeleteAll();
        PostedShptLineRef.DeleteAll();
        PickWkshLineRef.DeleteAll();
        WhseReqRef.DeleteAll();
        ItemRegRef.DeleteAll();
        BinContentRef.DeleteAll();
        PstdInvPutAwayLineRef.DeleteAll();
        PstdInvPickLineRef.DeleteAll();
        QASetup.DeleteAll();
    end;
}

