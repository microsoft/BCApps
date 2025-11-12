report 103232 "BW Create Reference Mgt"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // The intention of this report is to generate the C/AL code and include the reference data
    // necessary to have hardcoded test results in particular codeunits.
    // 
    // The report will create a *.txt file. This has to be imported and the included codeunits
    // have to be compiled.
    // 
    // Any modifications to the resulting codeunits have to be done in THIS report and not in
    // the codeunits themselves.

    ProcessingOnly = true;
    UseRequestPage = true;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                CreateTempRefData();

                CodeunitHeaderTmpl := 'OBJECT Codeunit %1 %2';

                ProcedureHeaderTmpl := '    PROCEDURE Verify@%1(NewUseCaseNo : Integer;' +
                  'NewTestCaseNo : Integer;NewIterationNo : Integer;NewOffset : Integer);';
                ProcedureCall := '                  Test(';
                Indention := '  ';

                FinishText := ');';

                if SelectWhseEntry then
                    CreateRefWhseEntry();
                if SelectWhseJnlLine then
                    CreateRefWhseJnlLine();
                if SelectItemJnlLine then
                    CreateRefItemJnlLine();
                if SelectWhseActivLine then
                    CreateRefWhseActivLine();
                if SelectBinContent then
                    CreateRefBinContent();
                if SelectItemLedgEntry then
                    CreateRefItemLedgEntry();
                if SelectWhseRcptLine then
                    CreateRefWhseRcptLine();
                if SelectPostedRcptLine then
                    CreateRefPostedRcptLine();
                if SelectWhseShptLine then
                    CreateRefWhseShptLine();
                if SelectPostedShptLine then
                    CreateRefPostedShptLine();
                if SelectWhseWkshLine then
                    CreateRefWhseWkshLine();
                if SelectWhseReq then
                    CreateRefWhseReq();
                if SelectItemReg then
                    CreateRefItemReg();
                if SelectPstdInvPutAwayLine then
                    CreateRefPstdInvPutAwayLine();
                if SelectPstdInvPickLine then
                    CreateRefPstdInvPickLine();
            end;

            trigger OnPostDataItem()
            begin
                OutFile.Close();
                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                OutFile.TextMode(true);
                OutFile.WriteMode(true);
                OutFile.Create(TemporaryPath + '\BW_ReferenceManagement.txt');

                Window.Open(
                  '#1############################\' +
                  'Use Case:             #2######\' +
                  'Test Case:            #3######\' +
                  'Iteration:            #4######');

                MaxLineLength := 120;
                MinIndention := 6;

                LF := 10;
                CR := 13;
                Comma := ',';
                Apostrophe := '''';
                LBracket := 123;
                RBracket := 125;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        SelectWhseEntry := true;
        SelectWhseActivLine := true;
        SelectWhseJnlLine := true;
        SelectItemLedgEntry := true;
        SelectBinContent := true;
        SelectItemJnlLine := true;
        SelectWhseRcptLine := true;
        SelectPostedRcptLine := true;
        SelectWhseShptLine := true;
        SelectPostedShptLine := true;
        SelectWhseWkshLine := true;
        SelectWhseReq := true;
        SelectItemReg := true;
        SelectPstdInvPutAwayLine := true;
        SelectPstdInvPickLine := true;
    end;

    var
        UseCases: Record "Whse. Use Case";
        TestCases: Record "Whse. Test Case";
        TestIteration: Record "Whse. Test Iteration";
        ItemLedgEntryRef: Record "BW Item Ledger Entry Ref";
        BinContentRef: Record "BW Bin Content Ref";
        WhseActivLineRef: Record "BW Warehouse Activity Line Ref";
        WhseEntryRef: Record "BW Warehouse Entry Ref";
        WhseJnlLineRef: Record "BW Warehouse Journal Line Ref";
        ItemJnlLineRef: Record "BW Item Journal Line Ref.";
        WhseRcptLineRef: Record "BW Warehouse Receipt Line Ref";
        PostedRcptLineRef: Record "BW Posted Whse. Rcpt Line Ref";
        WhseShptLineRef: Record "BW Warehouse Shipment Line Ref";
        PostedShptLineRef: Record "BW Posted Whse. Shpmt Line Ref";
        WhseWkshLineRef: Record "BW Whse. Worksheet Line Ref";
        WhseReqRef: Record "BW Warehouse Request Ref";
        ItemRegRef: Record "BW Item Register Ref";
        PstdInvPutAwayLineRef: Record "BW P. Invt. Put-away Line Ref";
        PstdInvPickLineRef: Record "BW P. Invt. Pick Line Ref";
        TempRefData: Record "Whse. Temp. Reference Data" temporary;
        OutFile: File;
        Window: Dialog;
        LF: Char;
        CR: Char;
        LBracket: Char;
        RBracket: Char;
        Comma: Text[30];
        Apostrophe: Text[30];
        CodeunitHeaderTmpl: Text[250];
        CodeunitHeader: Text[250];
        CodeunitName: Text[250];
        ProcedureHeaderTmpl: Text[250];
        ProcedureHeader: Text[250];
        ProcedureCall: Text[250];
        CommandString: Text[250];
        FinishText: Text[50];
        BeginText: Text[50];
        EndText: Text[50];
        ExitText: Text[50];
        TableText: Text[250];
        Indention: Text[50];
        CodeunitNo: Integer;
        RefTableID: Integer;
        EntryNo: Integer;
        MaxLineLength: Integer;
        MinIndention: Integer;
        TempRefDataCount: Integer;
        ProcedureNo: Integer;
        SelectWhseEntry: Boolean;
        SelectWhseJnlLine: Boolean;
        SelectItemJnlLine: Boolean;
        SelectWhseActivLine: Boolean;
        SelectItemLedgEntry: Boolean;
        SelectBinContent: Boolean;
        SelectWhseRcptLine: Boolean;
        SelectPostedRcptLine: Boolean;
        SelectWhseShptLine: Boolean;
        SelectPostedShptLine: Boolean;
        SelectWhseWkshLine: Boolean;
        SelectWhseReq: Boolean;
        SelectItemReg: Boolean;
        SelectPstdInvPutAwayLine: Boolean;
        SelectPstdInvPickLine: Boolean;

    [Scope('OnPrem')]
    procedure CreateRefWhseEntry()
    begin
        CodeunitNo := 103361;
        CodeunitName := 'BW Warehouse Entry Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseEntry();
        CreateTestWhseEntry();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseEntry()
    begin
        Window.Update(1, 'Warehouse Entry');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Entry"';
        RefTableID := DATABASE::"BW Warehouse Entry Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseEntry()
    begin
        // CreateTestWhseEntry()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(EntryNo : Integer;LocationCode : Code[10];' +
          'ZoneCode : Code[10];BinCode : Code[20];Descr : Text[50];ItemNo : Code[20];VariantCode : Code[10];' +
          'Quantity : Decimal;UnitofMeasure : Code[10];Cubage : Decimal;Weight : Decimal;' +
          'SerialNo : Code[20];LotNo : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseEntry : Record "Warehouse Entry";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        EntryNo := EntryNo + Offset;');
        WriteOutFile('        IF NOT WhseEntry.GET(EntryNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Location Code"),WhseEntry."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Zone Code"),WhseEntry."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Bin Code"),WhseEntry."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME(Description),WhseEntry.Description,Descr,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Item No."),WhseEntry."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Variant Code"),WhseEntry."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseEntry.FIELDNAME(Quantity),WhseEntry.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Unit of Measure Code"),' +
          'WhseEntry."Unit of Measure Code",UnitofMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseEntry.FIELDNAME(Cubage),WhseEntry.Cubage,Cubage,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseEntry.FIELDNAME(Weight),WhseEntry.Weight,Weight,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Serial No."),WhseEntry."Serial No.",SerialNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseEntry.FIELDNAME("Lot No."),WhseEntry."Lot No.",LotNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefItemLedgEntry()
    begin
        CodeunitNo := 103362;
        CodeunitName := 'BW ItemLedgEntry Ref. Mgmt';
        CreateHeader();
        CreateVerifyItemLedgEntry();
        CreateTestItemLedgEntry();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyItemLedgEntry()
    begin
        Window.Update(1, 'Item Ledger Entry');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Item Ledger Entry"';
        RefTableID := DATABASE::"BW Item Ledger Entry Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItemLedgEntry()
    begin
        // CreateTestItemLedgEntry()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(EntryNo : Integer;ItemNo : Code[20];' +
          'PostingDate : Date;LocationCode : Code[10];Quantity : Decimal;RemainingQuantity : Decimal;' +
          'InvoicedQuantity : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      ILE : Record "Item Ledger Entry";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        EntryNo := EntryNo;');
        WriteOutFile('        IF NOT ILE.GET(EntryNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(ILE.FIELDNAME("Item No."),ILE."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestDateValue(ILE.FIELDNAME("Posting Date"),ILE."Posting Date",PostingDate,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(ILE.FIELDNAME("Location Code"),ILE."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ILE.FIELDNAME(Quantity),ILE.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ILE.FIELDNAME("Remaining Quantity"),ILE."Remaining Quantity",RemainingQuantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ILE.FIELDNAME("Invoiced Quantity"),ILE."Invoiced Quantity",InvoicedQuantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefBinContent()
    begin
        CodeunitNo := 103363;
        CodeunitName := 'BW Bin Content Ref. Mgmt';
        CreateHeader();
        CreateVerifyBinContent();
        CreateTestBinContent();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyBinContent()
    begin
        Window.Update(1, 'Bin Content');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Bin Content"';
        RefTableID := DATABASE::"BW Bin Content Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestBinContent()
    begin
        // CreateTestBinContent()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(LocationCode : Code[10];ZoneCode : Code[10];BinCode : Code[20];' +
          'ItemNo : Code[20];VariantCode : Code[10];UOM : Code[10];Qty : Decimal;PickQty : Decimal;NegAdjQty : Decimal;');
        WriteOutFile('    PutQty : Decimal;PosAdjQty : Decimal;QtyPerUoM : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      BinContent : Record "Bin Content";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT BinContent.GET(LocationCode,BinCode,ItemNo,VariantCode,UOM) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,0,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Location Code"),BinContent."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Zone Code"),BinContent."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Bin Code"),BinContent."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Item No."),BinContent."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Variant Code"),BinContent."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(BinContent.FIELDNAME("Unit of Measure Code"),' +
          'BinContent."Unit of Measure Code",UOM,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          BinContent.CALCFIELDS(Quantity);');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME(Quantity),BinContent.Quantity,Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          BinContent.CALCFIELDS("Pick Qty.");');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME("Pick Qty."),BinContent."Pick Qty.",PickQty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          BinContent.CALCFIELDS("Neg. Adjmt. Qty.");');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME("Neg. Adjmt. Qty."),BinContent."Neg. Adjmt. Qty.",NegAdjQty,'
          );
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          BinContent.CALCFIELDS("Put-away Qty.");');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME("Put-away Qty."),BinContent."Put-away Qty.",PutQty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          BinContent.CALCFIELDS("Pos. Adjmt. Qty.");');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME("Pos. Adjmt. Qty."),BinContent."Pos. Adjmt. Qty.",PosAdjQty,'
          );
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(BinContent.FIELDNAME("Qty. per Unit of Measure"),' +
          'BinContent."Qty. per Unit of Measure",QtyPerUoM,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseActivLine()
    begin
        CodeunitNo := 103364;
        CodeunitName := 'BW Whse. Activity Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseActivLine();
        CreateTestWhseActivLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseActivLine()
    begin
        Window.Update(1, 'Whse. Activity Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Activity Line"';
        RefTableID := DATABASE::"BW Warehouse Activity Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseActivLine()
    begin
        // CreateTestWhseActivLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(Type@1024 : Option;No@1002 : Code[20];LineNo@1003 : Integer;' +
          'SourceType@1004 : Option;SourceNo@1006 : Code[20];WhseDocNo@1009 : Code[20];');
        WriteOutFile('    ActionType@1011 : Option;ItemNo@1012 : Code[20];VariantCode@1014 : Code[10];');
        WriteOutFile('    UnitOfMeasure@1013 : Code[10];');
        WriteOutFile('    BinCode@1017 : Code[20];Quantity@1018 : Decimal;QtyHandled@1019 : Decimal;');
        WriteOutFile('    DestinationType : Option;DestinationNo : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseActivLine@1000 : Record "Warehouse Activity Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestscriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseActivLine.GET(Type,No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME("Activity Type"),WhseActivLine."Activity Type",Type,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME("Source Type"),WhseActivLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Source No."),' +
          'WhseActivLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Whse. Document No."),' +
          'WhseActivLine."Whse. Document No.",WhseDocNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME("Action Type"),WhseActivLine."Action Type",ActionType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Item No."),WhseActivLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Variant Code"),WhseActivLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Unit of Measure Code"),' +
          'WhseActivLine."Unit of Measure Code",UnitOfMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Bin Code"),WhseActivLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME(Quantity),WhseActivLine.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME("Qty. Handled"),WhseActivLine."Qty. Handled",QtyHandled,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseActivLine.FIELDNAME("Destination Type"),' +
          'WhseActivLine."Destination Type",DestinationType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseActivLine.FIELDNAME("Destination No."),' +
          'WhseActivLine."Destination No.",DestinationNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseJnlLine()
    begin
        CodeunitNo := 103365;
        CodeunitName := 'BW WhseJnlLine Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseJnlLine();
        CreateTestWhseJnlLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseJnlLine()
    begin
        Window.Update(1, 'Whse. Journal Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Journal Line"';
        RefTableID := DATABASE::"BW Warehouse Journal Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseJnlLine()
    begin
        // CreateTestWhseJnlLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(JnlTmplteName : Code[10];JnlBatchName : Code[10];' +
          'LocCode : Code[10];LineNo : Integer;ItemNo : Code[20];' +
          'FromZoneCode : Code[10];FromBCode : Code[20];ToZoneCode : Code[10];ToBCode : Code[20];Qty : Decimal;QtyBase : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseJnlLine@1003 : Record "Warehouse Journal Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseJnlLine.GET(JnlTmplteName,JnlBatchName,LocCode,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(WhseJnlLine.FIELDNAME("Item No."),WhseJnlLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseJnlLine.FIELDNAME("From Zone Code"),WhseJnlLine."From Zone Code",FromZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseJnlLine.FIELDNAME("From Bin Code"),WhseJnlLine."From Bin Code",FromBCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseJnlLine.FIELDNAME("To Zone Code"),WhseJnlLine."To Zone Code",ToZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseJnlLine.FIELDNAME("To Bin Code"),WhseJnlLine."To Bin Code",ToBCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseJnlLine.FIELDNAME(Quantity),WhseJnlLine.Quantity,Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile(
          '          TestNumberValue(WhseJnlLine.FIELDNAME("Qty. (Absolute, Base)"),WhseJnlLine."Qty. (Absolute, Base)",QtyBase,'
          );
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefItemJnlLine()
    begin
        CodeunitNo := 103366;
        CodeunitName := 'BW ItemJnlLine Ref. Mgmt';
        CreateHeader();
        CreateVerifyItemJnlLine();
        CreateTestItemJnlLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyItemJnlLine()
    begin
        Window.Update(1, 'Item Journal Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Item Journal Line"';
        RefTableID := DATABASE::"BW Item Journal Line Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItemJnlLine()
    begin
        // CreateTestItemJnlLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(JnlTmplteName : Code[10];JnlBatchName : Code[10];' +
          'LineNo : Integer;PostingDate : Date;ItemNo : Code[20];VariantCode : Code[10];LocCode : Code[10];' +
          'QtyCalc : Decimal;QtyPhys : Decimal;Qty : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      ItemJnlLine@1003 : Record "Item Journal Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT ItemJnlLine.GET(JnlTmplteName,JnlBatchName,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestDateValue(ItemJnlLine.FIELDNAME("Posting Date"),ItemJnlLine."Posting Date",PostingDate,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(ItemJnlLine.FIELDNAME("Item No."),ItemJnlLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(ItemJnlLine.FIELDNAME("Variant Code"),ItemJnlLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(ItemJnlLine.FIELDNAME("Location Code"),ItemJnlLine."Location Code",LocCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemJnlLine.FIELDNAME("Qty. (Calculated)"),ItemJnlLine."Qty. (Calculated)",QtyCalc,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemJnlLine.FIELDNAME("Qty. (Phys. Inventory)"),');
        WriteOutFile('            ItemJnlLine."Qty. (Phys. Inventory)",QtyPhys,UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemJnlLine.FIELDNAME(Quantity),ItemJnlLine.Quantity,Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseRcptLine()
    begin
        CodeunitNo := 103367;
        CodeunitName := 'BW Whse. Rcpt. Line Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseRcptLine();
        CreateTestWhseRcptLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseRcptLine()
    begin
        Window.Update(1, 'Whse. Receipt Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Receipt Line"';
        RefTableID := DATABASE::"BW Warehouse Receipt Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseRcptLine()
    begin
        // CreateTestWhseRcptLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No@1002 : Code[20];LineNo@1003 : Integer;' +
          'SourceType@1004 : Option;SourceNo@1006 : Code[20];ItemNo@1008 : Code[20];VariantCode@1009 : Code[10];');
        WriteOutFile('    UnitOfMeasure@1010 : Code[10];ZoneCode@1012 : Code[10];BinCode@1013 : Code[10];Quantity@1018 : Decimal;'
          +
          'OutStandingQty@1014 : Decimal;QtyReceived@1016 : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseRcptLine@1000 : Record "Warehouse Receipt Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestscriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseRcptLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(WhseRcptLine.FIELDNAME("Source Type"),WhseRcptLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Source No."),' +
          'WhseRcptLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Item No."),WhseRcptLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Variant Code"),WhseRcptLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Unit of Measure Code"),' +
          'WhseRcptLine."Unit of Measure Code",UnitOfMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Zone Code"),WhseRcptLine."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseRcptLine.FIELDNAME("Bin Code"),WhseRcptLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseRcptLine.FIELDNAME(Quantity),WhseRcptLine.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseRcptLine.FIELDNAME("Qty. Outstanding"),' +
          'WhseRcptLine."Qty. Outstanding",OutstandingQty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseRcptLine.FIELDNAME("Qty. Received"),' +
          'WhseRcptLine."Qty. Received",QtyReceived,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefPostedRcptLine()
    begin
        CodeunitNo := 103368;
        CodeunitName := 'BW Pstd. Rcpt.-Line Ref. Mgmt';
        CreateHeader();
        CreateVerifyPostedRcptLine();
        CreateTestPostedRcptLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyPostedRcptLine()
    begin
        Window.Update(1, 'Posted Whse. Receipt Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Posted Whse. Receipt Line"';
        RefTableID := DATABASE::"BW Posted Whse. Rcpt Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestPostedRcptLine()
    begin
        // CreateTestPostedRcptLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No@1002 : Code[20];LineNo@1003 : Integer;' +
          'SourceType@1004 : Option;SourceSubtype@1005 : Option;SourceNo@1006 : Code[20];SourceLineNo@1007 : Integer;');
        WriteOutFile('    ItemNo@1008 : Code[20];VariantCode@1013 : Code[10];UnitOfMeasure@1009 : Code[10];' +
          'LocationCode@1010 : Code[10];ZoneCode@1011 : Code[10];BinCode@1012 : Code[10];' +
          'Quantity@1014 : Decimal;QuantityBase@1015 : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      PostedRcptLine@1000 : Record "Posted Whse. Receipt Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestscriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT PostedRcptLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(PostedRcptLine.FIELDNAME("Source Type"),PostedRcptLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile(
          '          TestNumberValue(PostedRcptLine.FIELDNAME("Source Subtype"),PostedRcptLine."Source Subtype",SourceSubtype,'
          );
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Source No."),' +
          'PostedRcptLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedRcptLine.FIELDNAME("Source Line No."),' +
          'PostedRcptLine."Source Line No.",SourceLineNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Item No."),PostedRcptLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Variant Code"),PostedRcptLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Unit of Measure Code"),' +
          'PostedRcptLine."Unit of Measure Code",UnitOfMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Location Code"),PostedRcptLine."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Zone Code"),PostedRcptLine."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedRcptLine.FIELDNAME("Bin Code"),PostedRcptLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedRcptLine.FIELDNAME(Quantity),PostedRcptLine.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedRcptLine.FIELDNAME("Qty. (Base)"),' +
          'PostedRcptLine."Qty. (Base)",QuantityBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseShptLine()
    begin
        CodeunitNo := 103369;
        CodeunitName := 'BW Whse. Shpt.-Line Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseShptLine();
        CreateTestWhseShptLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseShptLine()
    begin
        Window.Update(1, 'Whse. Shipment Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Shipment Line"';
        RefTableID := DATABASE::"BW Warehouse Shipment Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseShptLine()
    begin
        // CreateTestWhseShptLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No@1002 : Code[20];LineNo@1003 : Integer;' +
          'SourceType@1004 : Option;SourceSubtype@1005 : Option;SourceNo@1006 : Code[20];SourceLineNo@1007 : Integer;');
        WriteOutFile('    ItemNo@1008 : Code[20];VariantCode@1021 : Code[10];UnitOfMeasure@1009 : Code[10];' +
          'ZoneCode@1011 : Code[10];BinCode@1012 : Code[10];Quantity@1019 : Decimal;OutStandingQty@1013 : Decimal;');
        WriteOutFile('    QtyPicked@1015 : Decimal;QtyPickedBase@1016 : Decimal;QtyShipped@1017 : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseShptLine@1000 : Record "Warehouse Shipment Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestscriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseShptLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Source Type"),WhseShptLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Source Subtype"),WhseShptLine."Source Subtype",SourceSubtype,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Source No."),' +
          'WhseShptLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Source Line No."),' +
          'WhseShptLine."Source Line No.",SourceLineNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Item No."),WhseShptLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Variant Code"),WhseShptLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Unit of Measure Code"),' +
          'WhseShptLine."Unit of Measure Code",UnitOfMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Zone Code"),WhseShptLine."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseShptLine.FIELDNAME("Bin Code"),WhseShptLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME(Quantity),WhseShptLine.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Qty. Outstanding"),' +
          'WhseShptLine."Qty. Outstanding",OutstandingQty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Qty. Picked"),' +
          'WhseShptLine."Qty. Picked",QtyPicked,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Qty. Picked (Base)"),' +
          'WhseShptLine."Qty. Picked (Base)",QtyPickedBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseShptLine.FIELDNAME("Qty. Shipped"),' +
          'WhseShptLine."Qty. Shipped",QtyShipped,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefPostedShptLine()
    begin
        CodeunitNo := 103370;
        CodeunitName := 'BW Pstd. Shpt.-Line Ref. Mgmt';
        CreateHeader();
        CreateVerifyPostedShptLine();
        CreateTestPostedShptLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyPostedShptLine()
    begin
        Window.Update(1, 'Posted Whse. Shipment Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Posted Whse. Shipment Line"';
        RefTableID := DATABASE::"BW Posted Whse. Shpmt Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestPostedShptLine()
    begin
        // CreateTestPostedShptLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No@1002 : Code[20];LineNo@1003 : Integer;' +
          'SourceType@1004 : Option;SourceSubtype@1005 : Option;SourceNo@1006 : Code[20];SourceLineNo@1007 : Integer;');
        WriteOutFile('    ItemNo@1008 : Code[20];VariantCode@1011 : Code[10];UnitOfMeasure@1009 : Code[10];' +
          'LocationCode@1010 : Code[10];ZoneCode@1012 : Code[10];BinCode@1013 : Code[10];' +
          'Quantity@1014 : Decimal;QuantityBase@1015 : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      PostedShptLine@1000 : Record "Posted Whse. Shipment Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestscriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT PostedShptLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(PostedShptLine.FIELDNAME("Source Type"),PostedShptLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile(
          '          TestNumberValue(PostedShptLine.FIELDNAME("Source Subtype"),PostedShptLine."Source Subtype",SourceSubtype,'
          );
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Source No."),' +
          'PostedShptLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedShptLine.FIELDNAME("Source Line No."),' +
          'PostedShptLine."Source Line No.",SourceLineNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Item No."),PostedShptLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Variant Code"),PostedShptLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Unit of Measure Code"),' +
          'PostedShptLine."Unit of Measure Code",UnitOfMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Location Code"),PostedShptLine."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Zone Code"),PostedShptLine."Zone Code",ZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PostedShptLine.FIELDNAME("Bin Code"),PostedShptLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedShptLine.FIELDNAME(Quantity),PostedShptLine.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PostedShptLine.FIELDNAME("Qty. (Base)"),' +
          'PostedShptLine."Qty. (Base)",QuantityBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseWkshLine()
    begin
        CodeunitNo := 103371;
        CodeunitName := 'BW WhseWkshLine Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseWkshLine();
        CreateTestWhseWkshLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseWkshLine()
    begin
        Window.Update(1, 'Whse Worksheet Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Whse. Worksheet Line"';
        RefTableID := DATABASE::"BW Whse. Worksheet Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseWkshLine()
    begin
        // CreateTestWhseWkshLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(WkshTemplate@1001 : Code[10];LineNo@1004 : Integer;' +
          'ItemNo@1005 : Code[20];VariantCode@1006 : Code[10];UnitofMeasure@1007 : Code[10];' +
          'FromZoneCode@1012 : Code[10];FromBinCode@1013 : Code[20];ToZoneCode@1008 : Code[10];');
        WriteOutFile('    ToBinCode@1009 : Code[20];Qty@1010 : Decimal;QtyBase@1011 : Decimal;SourceType@1014 : Integer;' +
          'WhseDocType@1015 : Option;Name@1016 :Code[10];LocCode@1017 : Code[10];QtyOut@1018 : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseWkshLine@1019 : Record "Whse. Worksheet Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseWkshLine.GET(WkshTemplate,Name,LocCode,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("Item No."),WhseWkshLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("Variant Code"),WhseWkshLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("Unit of Measure Code"),' +
          'WhseWkshLine."Unit of Measure Code",UnitofMeasure,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("Location Code"),WhseWkshLine."Location Code",LocCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("From Zone Code"),WhseWkshLine."From Zone Code",FromZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("From Bin Code"),WhseWkshLine."From Bin Code",FromBinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("To Zone Code"),WhseWkshLine."To Zone Code",ToZoneCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseWkshLine.FIELDNAME("To Bin Code"),WhseWkshLine."To Bin Code",ToBinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseWkshLine.FIELDNAME(Quantity),WhseWkshLine.Quantity,Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseWkshLine.FIELDNAME("Qty. (Base)"),WhseWkshLine."Qty. (Base)",QtyBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseWkshLine.FIELDNAME("Qty. Outstanding"),WhseWkshLine."Qty. Outstanding",QtyOut,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseWkshLine.FIELDNAME("Source Type"),WhseWkshLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseWkshLine.FIELDNAME("Whse. Document Type"),' +
          'WhseWkshLine."Whse. Document Type",WhseDocType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefWhseReq()
    begin
        CodeunitNo := 103372;
        CodeunitName := 'BW Whse. Request Ref. Mgmt';
        CreateHeader();
        CreateVerifyWhseReq();
        CreateTestWhseReq();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyWhseReq()
    begin
        Window.Update(1, 'Warehouse Request');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Warehouse Request"';
        RefTableID := DATABASE::"BW Warehouse Request Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestWhseReq()
    begin
        // CreateTestWhseReq()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(Type : Option;LocationCode : Code[10];' +
          'SourceType: Integer;SourceSubtype: Option;SourceNo : Code[20];' +
          'SourceDoc: Option;DocumentStatus: Option);');
        WriteOutFile('    VAR');
        WriteOutFile('      WhseReq : Record "Warehouse Request";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT WhseReq.GET(Type,LocationCode,SourceType,SourceSubtype,SourceNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,0,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(WhseReq.FIELDNAME("Location Code"),WhseReq."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseReq.FIELDNAME("Source Type"),WhseReq."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseReq.FIELDNAME("Source Subtype"),WhseReq."Source Subtype",SourceSubtype,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(WhseReq.FIELDNAME("Source No."),WhseReq."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseReq.FIELDNAME("Source Document"),WhseReq."Source Document",SourceDoc,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(WhseReq.FIELDNAME("Document Status"),WhseReq."Document Status",DocumentStatus,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefItemReg()
    begin
        CodeunitNo := 103373;
        CodeunitName := 'BW Item Register Ref. Mgmt';
        CreateHeader();
        CreateVerifyItemReg();
        CreateTestItemReg();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyItemReg()
    begin
        Window.Update(1, 'Item Register');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Item Register"';
        RefTableID := DATABASE::"BW Item Register Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItemReg()
    begin
        // CreateTestItemReg()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No : Integer;FromEntryNo : Integer;' +
          'ToEntryNo : Integer;SourceCode : Code[10];FromPhysInvEntryNo : Integer;ToPhysInvEntryNo : Integer;' +
          'FromValEntryNo : Integer;ToValEntryNo : Integer);');
        WriteOutFile('    VAR');
        WriteOutFile('      ItemReg : Record "Item Register";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        No := No + Offset;');
        WriteOutFile('        IF NOT ItemReg.GET(No) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,No,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("From Entry No."),ItemReg."From Entry No.",FromEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("To Entry No."),ItemReg."To Entry No.",ToEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(ItemReg.FIELDNAME("Source Code"),ItemReg."Source Code",SourceCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("From Phys. Inventory Entry No."),' +
          'ItemReg."From Phys. Inventory Entry No.",FromPhysInvEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("To Phys. Inventory Entry No."),' +
          'ItemReg."To Phys. Inventory Entry No.",ToPhysInvEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("From Value Entry No."),' +
          'ItemReg."From Value Entry No.",FromValEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemReg.FIELDNAME("To Value Entry No."),' +
          'ItemReg."To Value Entry No.",ToValEntryNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,No,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefPstdInvPutAwayLine()
    begin
        CodeunitNo := 103374;
        CodeunitName := 'BW Pstd InvPutAwayLn Ref. Mgmt';
        CreateHeader();
        CreateVerifyPstdInvPutAwayLine();
        CreateTestPstdInvPutAwayLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyPstdInvPutAwayLine()
    begin
        Window.Update(1, 'Posted Invt. Put-away Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Posted Invt. Put-away Line"';
        RefTableID := DATABASE::"BW P. Invt. Put-away Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestPstdInvPutAwayLine()
    begin
        // CreateTestPstdInvPutAwayLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No : Code[20];LineNo : Integer;SourceType : Integer;' +
          'SourceSubtype : Option;SourceNo : Code[20];SourceLineNo : Integer;SourceDoc : Option;LocationCode : Code[10];');
        WriteOutFile('    ItemNo : Code[20];VariantCode : Code[10];Qty : Decimal;QtyBase : Decimal;' +
          'SerialNo : Code[20];LotNo : Code[20];BinCode : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      PstdInvPutAwayLine : Record "Posted Invt. Put-away Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT PstdInvPutAwayLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile(
          '          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Source Type"),PstdInvPutAwayLine."Source Type",SourceType,')
        ;
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Source Subtype"),' +
          'PstdInvPutAwayLine."Source Subtype",SourceSubtype,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Source No."),PstdInvPutAwayLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Source Line No."),' +
          'PstdInvPutAwayLine."Source Line No.",SourceLineNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Source Document"),' +
          'PstdInvPutAwayLine."Source Document",SourceDoc,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Location Code"),' +
          'PstdInvPutAwayLine."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Item No."),PstdInvPutAwayLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Variant Code"),' +
          'PstdInvPutAwayLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Quantity"),PstdInvPutAwayLine."Quantity",Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPutAwayLine.FIELDNAME("Qty. (Base)"),' +
          'PstdInvPutAwayLine."Qty. (Base)",QtyBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Serial No."),' +
          'PstdInvPutAwayLine."Serial No.",SerialNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Lot No."),PstdInvPutAwayLine."Lot No.",LotNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPutAwayLine.FIELDNAME("Bin Code"),PstdInvPutAwayLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefPstdInvPickLine()
    begin
        CodeunitNo := 103375;
        CodeunitName := 'BW Pstd InvPickLn Ref. Mgmt';
        CreateHeader();
        CreateVerifyPstdInvPickLine();
        CreateTestPstdInvPickLine();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyPstdInvPickLine()
    begin
        Window.Update(1, 'Posted Invt. Pick Line');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Posted Invt. Pick Line"';
        RefTableID := DATABASE::"BW P. Invt. Pick Line Ref";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestPstdInvPickLine()
    begin
        // CreateTestPstdInvPickLine()

        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(No : Code[20];LineNo : Integer;SourceType : Integer;' +
          'SourceSubtype : Option;SourceNo : Code[20];SourceLineNo : Integer;SourceDoc : Option;LocationCode : Code[10];');
        WriteOutFile('    ItemNo : Code[20];VariantCode : Code[10];Qty : Decimal;QtyBase : Decimal;' +
          'SerialNo : Code[20];LotNo : Code[20];BinCode : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      PstdInvPickLine : Record "Posted Invt. Pick Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT PstdInvPickLine.GET(No,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Source Type"),PstdInvPickLine."Source Type",SourceType,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Source Subtype"),' +
          'PstdInvPickLine."Source Subtype",SourceSubtype,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Source No."),PstdInvPickLine."Source No.",SourceNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Source Line No."),' +
          'PstdInvPickLine."Source Line No.",SourceLineNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Source Document"),' +
          'PstdInvPickLine."Source Document",SourceDoc,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Location Code"),' +
          'PstdInvPickLine."Location Code",LocationCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Item No."),PstdInvPickLine."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Variant Code"),' +
          'PstdInvPickLine."Variant Code",VariantCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Quantity"),PstdInvPickLine."Quantity",Qty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(PstdInvPickLine.FIELDNAME("Qty. (Base)"),' +
          'PstdInvPickLine."Qty. (Base)",QtyBase,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Serial No."),' +
          'PstdInvPickLine."Serial No.",SerialNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Lot No."),PstdInvPickLine."Lot No.",LotNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(PstdInvPickLine.FIELDNAME("Bin Code"),PstdInvPickLine."Bin Code",BinCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateHeader()
    begin
        ProcedureNo := 103350;
        CodeunitHeader := StrSubstNo(CodeunitHeaderTmpl, CodeunitNo, CodeunitName);
        WriteOutFile(CodeunitHeader);
        WriteOutFile('' + Format(LBracket) + '');
        WriteOutFile('  OBJECT-PROPERTIES');
        WriteOutFile('  ' + Format(LBracket) + '');
        WriteOutFile('    Date=' + Format(Today, 0, '<day,2>.<month,2>.<year>') + ';');
        WriteOutFile('    Time=[' + Format(Time, 0, '<hours24,2>:<minutes,2>:<seconds,2>') + '];');
        WriteOutFile('    Modified=No;');
        WriteOutFile('    Version List=;');
        WriteOutFile('  ' + Format(RBracket) + '');
        WriteOutFile('  PROPERTIES');
        WriteOutFile('  ' + Format(LBracket) + '');
        WriteOutFile('    OnRun=BEGIN');
        WriteOutFile('          END;');
        WriteOutFile('');
        WriteOutFile('  ' + Format(RBracket) + '');
        WriteOutFile('  CODE');
        WriteOutFile('  ' + Format(LBracket) + '');
        WriteOutFile('    VAR');
        WriteOutFile('      TestScriptMgmt : Codeunit "BW TestscriptManagement";');
        WriteOutFile('      UseCaseNo : Integer;');
        WriteOutFile('      TestCaseNo : Integer;');
        WriteOutFile('      IterationNo : Integer;');
        WriteOutFile('      Offset : Integer;');
        WriteOutFile('      TableID : Integer;');
        WriteOutFile('      NoOfRecords : Integer;');
        WriteOutFile('      NoOfFields : Integer;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure LoopIterations()
    begin
        WriteOutFile(ProcedureHeader);
        WriteOutFile('    BEGIN');
        WriteOutFile('      UseCaseNo := NewUseCaseNo;');
        WriteOutFile('      TestCaseNo := NewTestCaseNo;');
        WriteOutFile('      IterationNo := NewIterationNo;');
        WriteOutFile('      Offset := NewOffset;');
        WriteOutFile('      TableID := ' + TableText + ';');
        WriteOutFile('');

        UseCases.Reset();
        UseCases.SetRange("Project Code", 'BW');
        if UseCases.Find('-') then begin
            WriteOutFile('      CASE UseCaseNo OF');
            repeat
                TestCases.Reset();
                TestCases.SetRange("Project Code", UseCases."Project Code");
                TestCases.SetRange("Use Case No.", UseCases."Use Case No.");
                if TestCases.Find('-') then begin
                    WriteOutFile('        ' + Format(TestCases."Use Case No.") + ':');
                    WriteOutFile('          CASE TestCaseNo OF');
                    repeat
                        TestIteration.Reset();
                        TestIteration.SetRange("Project Code", TestCases."Project Code");
                        TestIteration.SetRange("Use Case No.", TestCases."Use Case No.");
                        TestIteration.SetRange("Test Case No.", TestCases."Test Case No.");
                        if TestIteration.Find('-') then begin
                            WriteOutFile('            ' + Format(TestIteration."Test Case No.") + ':');
                            WriteOutFile('              CASE IterationNo OF');
                            repeat
                                WriteOutFile('                ' + Format(TestIteration."Iteration No.") + ':   // ' +
                                  Format(TestIteration."Use Case No.") + '-' + Format(TestIteration."Test Case No.") + '-' +
                                  Format(TestIteration."Iteration No."));
                                RetrieveExpectedTestResults();
                                TestIteration.SetRange("Iteration No.", TestIteration."Iteration No.");
                                TestIteration.Find('+');
                                TestIteration.SetRange("Iteration No.");
                            until TestIteration.Next() = 0;
                            WriteOutFile('              else');
                            WriteOutFile('                EXIT;');
                            WriteOutFile('              END;');
                        end;
                        TestCases.SetRange("Test Case No.", TestCases."Test Case No.");
                        TestCases.Find('+');
                        TestCases.SetRange("Test Case No.");
                    until TestCases.Next() = 0;
                    WriteOutFile('          else');
                    WriteOutFile('            EXIT;');
                    WriteOutFile('          END;');
                end;
                UseCases.SetRange("Project Code", UseCases."Project Code");
                UseCases.SetRange("Use Case No.", UseCases."Use Case No.");
                UseCases.Find('+');
                UseCases.SetRange("Use Case No.");
            until UseCases.Next() = 0;
            WriteOutFile('      else');
            WriteOutFile('        EXIT;');
            WriteOutFile('      END;');
        end;

        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateFooter()
    begin
        WriteOutFile('    PROCEDURE SetNumbers@' + NextProcNo() + '(NewNoOfRecords : Integer;NewNoOfFields : Integer);');
        WriteOutFile('    BEGIN');
        WriteOutFile('      NoOfRecords := NewNoOfRecords;');
        WriteOutFile('      NoOfFields := NewNoOfFields;');
        WriteOutFile('    END;');
        WriteOutFile('');
        WriteOutFile('    PROCEDURE GetNumbers@' + NextProcNo() + '(VAR NewNoOfRecords : Integer;VAR NewNoOfFields : Integer);');
        WriteOutFile('    BEGIN');
        WriteOutFile('      NewNoOfRecords := NoOfRecords;');
        WriteOutFile('      NewNoOfFields := NoOfFields;');
        WriteOutFile('    END;');
        WriteOutFile('');
        WriteOutFile('    BEGIN');
        WriteOutFile('    ' + Format(LBracket) + '');
        WriteOutFile('      ******************************************************************************************');
        WriteOutFile('      *** This code has been generated by REPORT::"BW Create Reference Mgmt" to contain');
        WriteOutFile('      *** the reference data hardcoded for every iteration.');
        WriteOutFile('      *** All modifications to this codeunit have to be done in that report, not here !');
        WriteOutFile('      ***');
        WriteOutFile('      *** Source company for reference data: ' + CompanyName);
        WriteOutFile('      ***');
        WriteOutFile('      ******************************************************************************************');
        WriteOutFile('    ' + Format(RBracket) + '');
        WriteOutFile('    END.');
        WriteOutFile('  ' + Format(RBracket) + '');
        WriteOutFile('' + Format(RBracket) + '');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure RetrieveExpectedTestResults()
    begin
        BeginText := '                  BEGIN';
        EndText := '                  END;';
        ExitText := '                  EXIT;';
        Window.Update(2, TestIteration."Use Case No.");
        Window.Update(3, TestIteration."Test Case No.");
        Window.Update(4, TestIteration."Iteration No.");
        TempRefData.SetRange("Table ID", RefTableID);
        TempRefData.SetRange("Project Code", 'BW');
        TempRefData.SetRange("Use Case No.", TestIteration."Use Case No.");
        TempRefData.SetRange("Test Case No.", TestIteration."Test Case No.");
        TempRefData.SetRange("Iteration No.", TestIteration."Iteration No.");
        TempRefDataCount := TempRefData.Count();
        if TempRefDataCount > 0 then begin
            if TempRefDataCount = 1 then
                EndText := ''
            else
                WriteOutFile(BeginText);
            ExitText := '';
        end;
        if TempRefData.Find('-') then
            repeat
                if EndText = '' then
                    CommandString := ProcedureCall + TempRefData.TestString + FinishText
                else
                    CommandString := Indention + ProcedureCall + TempRefData.TestString + FinishText;
                if StrLen(CommandString) <= MaxLineLength then
                    WriteOutFile(CommandString)
                else
                    SplitCommandString();
            until TempRefData.Next() = 0;
        if ExitText <> '' then
            WriteOutFile(ExitText)
        else
            if EndText <> '' then
                WriteOutFile(EndText);
    end;

    [Scope('OnPrem')]
    procedure SplitCommandString()
    var
        NextString: Text[250];
        OutString: Text[250];
        NoOfLeadingBlanks: Integer;
        i: Integer;
        Offset: Integer;
        StringComplete: Boolean;
        LineComplete: Boolean;
    begin
        NoOfLeadingBlanks := 0;
        while (StrLen(CommandString) > 0) and (CommandString[1] = ' ') do begin
            NoOfLeadingBlanks := NoOfLeadingBlanks + 1;
            CommandString := DelStr(CommandString, 1, 1);
        end;

        Offset := 0;
        while StrLen(CommandString) > 0 do begin
            OutString := PadStr(' ', NoOfLeadingBlanks + Offset);
            LineComplete := false;
            while not LineComplete do begin
                i := 1;
                NextString := '';
                StringComplete := false;
                while not StringComplete do begin
                    NextString := NextString + CopyStr(CommandString, i, 1);
                    StringComplete := (i >= StrLen(CommandString)) or (CopyStr(CommandString, i, 1) = Comma);
                    i := i + 1;
                end;
                if StrLen(OutString) + StrLen(NextString) <= MaxLineLength + MinIndention then begin
                    OutString := OutString + NextString;
                    CommandString := DelStr(CommandString, 1, StrLen(NextString));
                    if StrLen(CommandString) = 0 then
                        LineComplete := true;
                end else
                    if DelChr(OutString) = '' then begin
                        NoOfLeadingBlanks := MinIndention;
                        OutString := PadStr(' ', NoOfLeadingBlanks + Offset);
                    end else
                        LineComplete := true;
            end;
            WriteOutFile(OutString);
            Offset := 2;
        end;
    end;

    [Scope('OnPrem')]
    procedure CreateTempRefData()
    begin
        Window.Update(1, 'Create Temp. Ref. Data...');
        if SelectWhseEntry then
            ProcessWhseEntryRef();
        if SelectWhseActivLine then
            ProcessWhseActivLineRef();
        if SelectWhseJnlLine then
            ProcessWhseJnlLineRef();
        if SelectItemJnlLine then
            ProcessItemJnlLineRef();
        if SelectItemLedgEntry then
            ProcessItemLedgEntryRef();
        if SelectBinContent then
            ProcessBinContentRef();
        if SelectWhseRcptLine then
            ProcessWhseRcptLineRef();
        if SelectPostedRcptLine then
            ProcessPostedRcptLineRef();
        if SelectWhseShptLine then
            ProcessWhseShptLineRef();
        if SelectPostedShptLine then
            ProcessPostedShptLineRef();
        if SelectWhseWkshLine then
            ProcessWhseWkshLineRef();
        if SelectWhseReq then
            ProcessWhseReqRef();
        if SelectItemReg then
            ProcessItemRegRef();
        if SelectPstdInvPutAwayLine then
            ProcessPstdInvPutAwayLineRef();
        if SelectPstdInvPickLine then
            ProcessPstdInvPickLineRef();
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseEntryRef()
    begin
        // ProcessWhseEntryRef()

        RefTableID := DATABASE::"BW Warehouse Entry Ref";
        EntryNo := 0;
        WhseEntryRef.Reset();
        if WhseEntryRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseEntryRef."Use Case No.", WhseEntryRef."Test Case No.", WhseEntryRef."Iteration No.", EntryNo,
                  FormatInteger(WhseEntryRef."Entry No.") + Comma +
                  FormatText(WhseEntryRef."Location Code") + Comma +
                  FormatText(WhseEntryRef."Zone Code") + Comma +
                  FormatText(WhseEntryRef."Bin Code") + Comma +
                  FormatText(WhseEntryRef.Description) + Comma +
                  FormatText(WhseEntryRef."Item No.") + Comma +
                  FormatText(WhseEntryRef."Variant Code") + Comma +
                  FormatDecimal(WhseEntryRef.Quantity) + Comma +
                  FormatText(WhseEntryRef."Unit of Measure Code") + Comma +
                  FormatDecimal(WhseEntryRef.Cubage) + Comma +
                  FormatDecimal(WhseEntryRef.Weight) + Comma +
                  FormatText(WhseEntryRef."Serial No.") + Comma +
                  FormatText(WhseEntryRef."Lot No.")
                  );
            until WhseEntryRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessItemLedgEntryRef()
    begin
        // ProcessItemLedgEntryRef()

        RefTableID := DATABASE::"BW Item Ledger Entry Ref";
        EntryNo := 0;
        ItemLedgEntryRef.Reset();
        if ItemLedgEntryRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, ItemLedgEntryRef."Use Case No.", ItemLedgEntryRef."Test Case No.", ItemLedgEntryRef."Iteration No.", EntryNo,
                  FormatInteger(ItemLedgEntryRef."Entry No.") + Comma +
                  FormatText(ItemLedgEntryRef."Item No.") + Comma +
                  FormatDate(ItemLedgEntryRef."Posting Date") + Comma +
                  FormatText(ItemLedgEntryRef."Location Code") + Comma +
                  FormatDecimal(ItemLedgEntryRef.Quantity) + Comma +
                  FormatDecimal(ItemLedgEntryRef."Remaining Quantity") + Comma +
                  FormatDecimal(ItemLedgEntryRef."Invoiced Quantity")
                  );
            until ItemLedgEntryRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessBinContentRef()
    begin
        // ProcessBinContentRef()

        RefTableID := DATABASE::"BW Bin Content Ref";
        EntryNo := 0;
        BinContentRef.Reset();
        if BinContentRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, BinContentRef."Use Case No.", BinContentRef."Test Case No.", BinContentRef."Iteration No.", EntryNo,
                  FormatText(BinContentRef."Location Code") + Comma +
                  FormatText(BinContentRef."Zone Code") + Comma +
                  FormatText(BinContentRef."Bin Code") + Comma +
                  FormatText(BinContentRef."Item No.") + Comma +
                  FormatText(BinContentRef."Variant Code") + Comma +
                  FormatText(BinContentRef."Unit of Measure Code") + Comma +
                  FormatDecimal(BinContentRef.Quantity) + Comma +
                  FormatDecimal(BinContentRef."Pick Qty.") + Comma +
                  FormatDecimal(BinContentRef."Neg. Adjmt. Qty.") + Comma +
                  FormatDecimal(BinContentRef."Put-away Qty.") + Comma +
                  FormatDecimal(BinContentRef."Pos. Adjmt. Qty.") + Comma +
                  FormatDecimal(BinContentRef."Qty. per Unit of Measure")
                  );
            until BinContentRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseJnlLineRef()
    begin
        // ProcessWhseJnlLineRef()

        RefTableID := DATABASE::"BW Warehouse Journal Line Ref";
        EntryNo := 0;
        WhseJnlLineRef.Reset();
        if WhseJnlLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseJnlLineRef."Use Case No.", WhseJnlLineRef."Test Case No.", WhseJnlLineRef."Iteration No.", EntryNo,
                  FormatText(WhseJnlLineRef."Journal Template Name") + Comma +
                  FormatText(WhseJnlLineRef."Journal Batch Name") + Comma +
                  FormatText(WhseJnlLineRef."Location Code") + Comma +
                  FormatInteger(WhseJnlLineRef."Line No.") + Comma +
                  FormatText(WhseJnlLineRef."Item No.") + Comma +
                  FormatText(WhseJnlLineRef."From Zone Code") + Comma +
                  FormatText(WhseJnlLineRef."From Bin Code") + Comma +
                  FormatText(WhseJnlLineRef."To Zone Code") + Comma +
                  FormatText(WhseJnlLineRef."To Bin Code") + Comma +
                  FormatDecimal(WhseJnlLineRef.Quantity) + Comma +
                  FormatDecimal(WhseJnlLineRef."Qty. (Absolute, Base)")
                  );
            until WhseJnlLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessItemJnlLineRef()
    begin
        // ProcessItemJnlLineRef()

        RefTableID := DATABASE::"BW Item Journal Line Ref.";
        EntryNo := 0;
        ItemJnlLineRef.Reset();
        if ItemJnlLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, ItemJnlLineRef."Use Case No.", ItemJnlLineRef."Test Case No.", ItemJnlLineRef."Iteration No.", EntryNo,
                  FormatText(ItemJnlLineRef."Journal Template Name") + Comma +
                  FormatText(ItemJnlLineRef."Journal Batch Name") + Comma +
                  FormatInteger(ItemJnlLineRef."Line No.") + Comma +
                  FormatDate(ItemJnlLineRef."Posting Date") + Comma +
                  FormatText(ItemJnlLineRef."Item No.") + Comma +
                  FormatText(ItemJnlLineRef."Variant Code") + Comma +
                  FormatText(ItemJnlLineRef."Location Code") + Comma +
                  FormatDecimal(ItemJnlLineRef."Qty. (Calculated)") + Comma +
                  FormatDecimal(ItemJnlLineRef."Qty. (Phys. Inventory)") + Comma +
                  FormatDecimal(ItemJnlLineRef.Quantity)
                  );
            until ItemJnlLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseActivLineRef()
    begin
        // ProcessWhseActivLineRef()

        RefTableID := DATABASE::"BW Warehouse Activity Line Ref";
        EntryNo := 0;
        WhseActivLineRef.Reset();
        if WhseActivLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseActivLineRef."Use Case No.", WhseActivLineRef."Test Case No.", WhseActivLineRef."Iteration No.", EntryNo,
                  FormatInteger(WhseActivLineRef."Activity Type") + Comma +
                  FormatText(WhseActivLineRef."No.") + Comma +
                  FormatInteger(WhseActivLineRef."Line No.") + Comma +
                  FormatInteger(WhseActivLineRef."Source Type") + Comma +
                  FormatText(WhseActivLineRef."Source No.") + Comma +
                  FormatText(WhseActivLineRef."Whse. Document No.") + Comma +
                  FormatInteger(WhseActivLineRef."Action Type") + Comma +
                  FormatText(WhseActivLineRef."Item No.") + Comma +
                  FormatText(WhseActivLineRef."Variant Code") + Comma +
                  FormatText(WhseActivLineRef."Unit of Measure Code") + Comma +
                  FormatText(WhseActivLineRef."Bin Code") + Comma +
                  FormatDecimal(WhseActivLineRef.Quantity) + Comma +
                  FormatDecimal(WhseActivLineRef."Qty. Handled") + Comma +
                  FormatInteger(WhseActivLineRef."Destination Type") + Comma +
                  FormatText(WhseActivLineRef."Destination No.")
                  );
            until WhseActivLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseRcptLineRef()
    begin
        // ProcessWhseRcptLineRef()

        RefTableID := DATABASE::"BW Warehouse Receipt Line Ref";
        EntryNo := 0;
        WhseRcptLineRef.Reset();
        if WhseRcptLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseRcptLineRef."Use Case No.", WhseRcptLineRef."Test Case No.", WhseRcptLineRef."Iteration No.", EntryNo,
                  FormatText(WhseRcptLineRef."No.") + Comma +
                  FormatInteger(WhseRcptLineRef."Line No.") + Comma +
                  FormatInteger(WhseRcptLineRef."Source Type") + Comma +
                  FormatText(WhseRcptLineRef."Source No.") + Comma +
                  FormatText(WhseRcptLineRef."Item No.") + Comma +
                  FormatText(WhseRcptLineRef."Variant Code") + Comma +
                  FormatText(WhseRcptLineRef."Unit of Measure Code") + Comma +
                  FormatText(WhseRcptLineRef."Zone Code") + Comma +
                  FormatText(WhseRcptLineRef."Bin Code") + Comma +
                  FormatDecimal(WhseRcptLineRef.Quantity) + Comma +
                  FormatDecimal(WhseRcptLineRef."Qty. Outstanding") + Comma +
                  FormatDecimal(WhseRcptLineRef."Qty. Received")
                  );
            until WhseRcptLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessPostedRcptLineRef()
    begin
        // ProcessPostedRcptLineRef()

        RefTableID := DATABASE::"BW Posted Whse. Rcpt Line Ref";
        EntryNo := 0;
        PostedRcptLineRef.Reset();
        if PostedRcptLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, PostedRcptLineRef."Use Case No.", PostedRcptLineRef."Test Case No.", PostedRcptLineRef."Iteration No.", EntryNo,
                  FormatText(PostedRcptLineRef."No.") + Comma +
                  FormatInteger(PostedRcptLineRef."Line No.") + Comma +
                  FormatInteger(PostedRcptLineRef."Source Type") + Comma +
                  FormatInteger(PostedRcptLineRef."Source Subtype") + Comma +
                  FormatText(PostedRcptLineRef."Source No.") + Comma +
                  FormatInteger(PostedRcptLineRef."Source Line No.") + Comma +
                  FormatText(PostedRcptLineRef."Item No.") + Comma +
                  FormatText(PostedRcptLineRef."Variant Code") + Comma +
                  FormatText(PostedRcptLineRef."Unit of Measure Code") + Comma +
                  FormatText(PostedRcptLineRef."Location Code") + Comma +
                  FormatText(PostedRcptLineRef."Zone Code") + Comma +
                  FormatText(PostedRcptLineRef."Bin Code") + Comma +
                  FormatDecimal(PostedRcptLineRef.Quantity) + Comma +
                  FormatDecimal(PostedRcptLineRef."Qty. (Base)")
                  );
            until PostedRcptLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseShptLineRef()
    begin
        // ProcessWhseShptLineRef()

        RefTableID := DATABASE::"BW Warehouse Shipment Line Ref";
        EntryNo := 0;
        WhseShptLineRef.Reset();
        if WhseShptLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseShptLineRef."Use Case No.", WhseShptLineRef."Test Case No.", WhseShptLineRef."Iteration No.", EntryNo,
                  FormatText(WhseShptLineRef."No.") + Comma +
                  FormatInteger(WhseShptLineRef."Line No.") + Comma +
                  FormatInteger(WhseShptLineRef."Source Type") + Comma +
                  FormatInteger(WhseShptLineRef."Source Subtype") + Comma +
                  FormatText(WhseShptLineRef."Source No.") + Comma +
                  FormatInteger(WhseShptLineRef."Source Line No.") + Comma +
                  FormatText(WhseShptLineRef."Item No.") + Comma +
                  FormatText(WhseShptLineRef."Variant Code") + Comma +
                  FormatText(WhseShptLineRef."Unit of Measure Code") + Comma +
                  FormatText(WhseShptLineRef."Zone Code") + Comma +
                  FormatText(WhseShptLineRef."Bin Code") + Comma +
                  FormatDecimal(WhseShptLineRef.Quantity) + Comma +
                  FormatDecimal(WhseShptLineRef."Qty. Outstanding") + Comma +
                  FormatDecimal(WhseShptLineRef."Qty. Picked") + Comma +
                  FormatDecimal(WhseShptLineRef."Qty. Picked (Base)") + Comma +
                  FormatDecimal(WhseShptLineRef."Qty. Shipped")
                  );
            until WhseShptLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessPostedShptLineRef()
    begin
        // ProcessPostedShptLineRef()

        RefTableID := DATABASE::"BW Posted Whse. Shpmt Line Ref";
        EntryNo := 0;
        PostedShptLineRef.Reset();
        if PostedShptLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, PostedShptLineRef."Use Case No.", PostedShptLineRef."Test Case No.", PostedShptLineRef."Iteration No.", EntryNo,
                  FormatText(PostedShptLineRef."No.") + Comma +
                  FormatInteger(PostedShptLineRef."Line No.") + Comma +
                  FormatInteger(PostedShptLineRef."Source Type") + Comma +
                  FormatInteger(PostedShptLineRef."Source Subtype") + Comma +
                  FormatText(PostedShptLineRef."Source No.") + Comma +
                  FormatInteger(PostedShptLineRef."Source Line No.") + Comma +
                  FormatText(PostedShptLineRef."Item No.") + Comma +
                  FormatText(PostedShptLineRef."Variant Code") + Comma +
                  FormatText(PostedShptLineRef."Unit of Measure Code") + Comma +
                  FormatText(PostedShptLineRef."Location Code") + Comma +
                  FormatText(PostedShptLineRef."Zone Code") + Comma +
                  FormatText(PostedShptLineRef."Bin Code") + Comma +
                  FormatDecimal(PostedShptLineRef.Quantity) + Comma +
                  FormatDecimal(PostedShptLineRef."Qty. (Base)")
                  );
            until PostedShptLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseWkshLineRef()
    begin
        // ProcessWhseWkshLineRef()

        RefTableID := DATABASE::"BW Whse. Worksheet Line Ref";
        EntryNo := 0;
        WhseWkshLineRef.Reset();
        if WhseWkshLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseWkshLineRef."Use Case No.", WhseWkshLineRef."Test Case No.", WhseWkshLineRef."Iteration No.", EntryNo,
                  FormatText(WhseWkshLineRef."Worksheet Template Name") + Comma +
                  FormatInteger(WhseWkshLineRef."Line No.") + Comma +
                  FormatText(WhseWkshLineRef."Item No.") + Comma +
                  FormatText(WhseWkshLineRef."Variant Code") + Comma +
                  FormatText(WhseWkshLineRef."Unit of Measure Code") + Comma +
                  FormatText(WhseWkshLineRef."From Zone Code") + Comma +
                  FormatText(WhseWkshLineRef."From Bin Code") + Comma +
                  FormatText(WhseWkshLineRef."To Zone Code") + Comma +
                  FormatText(WhseWkshLineRef."To Bin Code") + Comma +
                  FormatDecimal(WhseWkshLineRef.Quantity) + Comma +
                  FormatDecimal(WhseWkshLineRef."Qty. (Base)") + Comma +
                  FormatInteger(WhseWkshLineRef."Source Type") + Comma +
                  FormatInteger(WhseWkshLineRef."Whse. Document Type") + Comma +
                  FormatText(WhseWkshLineRef.Name) + Comma +
                  FormatText(WhseWkshLineRef."Location Code") + Comma +
                  FormatDecimal(WhseWkshLineRef."Qty. Outstanding")
                  );
            until WhseWkshLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessWhseReqRef()
    begin
        // ProcessWhseReqRef()

        RefTableID := DATABASE::"BW Warehouse Request Ref";
        EntryNo := 0;
        WhseReqRef.Reset();
        if WhseReqRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, WhseReqRef."Use Case No.", WhseReqRef."Test Case No.", WhseReqRef."Iteration No.", EntryNo,
                  FormatInteger(WhseReqRef.Type) + Comma +
                  FormatText(WhseReqRef."Location Code") + Comma +
                  FormatInteger(WhseReqRef."Source Type") + Comma +
                  FormatInteger(WhseReqRef."Source Subtype") + Comma +
                  FormatText(WhseReqRef."Source No.") + Comma +
                  FormatInteger(WhseReqRef."Source Document") + Comma +
                  FormatInteger(WhseReqRef."Document Status")
                  );
            until WhseReqRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessItemRegRef()
    begin
        // ProcessItemRegRef()

        RefTableID := DATABASE::"BW Item Register Ref";
        EntryNo := 0;
        ItemRegRef.Reset();
        if ItemRegRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, ItemRegRef."Use Case No.", ItemRegRef."Test Case No.", ItemRegRef."Iteration No.", EntryNo,
                  FormatInteger(ItemRegRef."No.") + Comma +
                  FormatInteger(ItemRegRef."From Entry No.") + Comma +
                  FormatInteger(ItemRegRef."To Entry No.") + Comma +
                  FormatText(ItemRegRef."Source Code") + Comma +
                  FormatInteger(ItemRegRef."From Phys. Inventory Entry No.") + Comma +
                  FormatInteger(ItemRegRef."To Phys. Inventory Entry No.") + Comma +
                  FormatInteger(ItemRegRef."From Value Entry No.") + Comma +
                  FormatInteger(ItemRegRef."To Value Entry No.")
                  );
            until ItemRegRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessPstdInvPutAwayLineRef()
    begin
        // ProcessPstdInvPutAwayLineRef()

        RefTableID := DATABASE::"BW P. Invt. Put-away Line Ref";
        EntryNo := 0;
        PstdInvPutAwayLineRef.Reset();
        if PstdInvPutAwayLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, PstdInvPutAwayLineRef."Use Case No.", PstdInvPutAwayLineRef."Test Case No.", PstdInvPutAwayLineRef."Iteration No.", EntryNo,
                  FormatText(PstdInvPutAwayLineRef."No.") + Comma +
                  FormatInteger(PstdInvPutAwayLineRef."Line No.") + Comma +
                  FormatInteger(PstdInvPutAwayLineRef."Source Type") + Comma +
                  FormatInteger(PstdInvPutAwayLineRef."Source Subtype") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Source No.") + Comma +
                  FormatInteger(PstdInvPutAwayLineRef."Source Line No.") + Comma +
                  FormatInteger(PstdInvPutAwayLineRef."Source Document") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Location Code") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Item No.") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Variant Code") + Comma +
                  FormatDecimal(PstdInvPutAwayLineRef.Quantity) + Comma +
                  FormatDecimal(PstdInvPutAwayLineRef."Qty. (Base)") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Serial No.") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Lot No.") + Comma +
                  FormatText(PstdInvPutAwayLineRef."Bin Code")
                  );
            until PstdInvPutAwayLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessPstdInvPickLineRef()
    begin
        // ProcessPstdInvPickLineRef()

        RefTableID := DATABASE::"BW P. Invt. Pick Line Ref";
        EntryNo := 0;
        PstdInvPickLineRef.Reset();
        if PstdInvPickLineRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, PstdInvPickLineRef."Use Case No.", PstdInvPickLineRef."Test Case No.", PstdInvPickLineRef."Iteration No.", EntryNo,
                  FormatText(PstdInvPickLineRef."No.") + Comma +
                  FormatInteger(PstdInvPickLineRef."Line No.") + Comma +
                  FormatInteger(PstdInvPickLineRef."Source Type") + Comma +
                  FormatInteger(PstdInvPickLineRef."Source Subtype") + Comma +
                  FormatText(PstdInvPickLineRef."Source No.") + Comma +
                  FormatInteger(PstdInvPickLineRef."Source Line No.") + Comma +
                  FormatInteger(PstdInvPickLineRef."Source Document") + Comma +
                  FormatText(PstdInvPickLineRef."Location Code") + Comma +
                  FormatText(PstdInvPickLineRef."Item No.") + Comma +
                  FormatText(PstdInvPickLineRef."Variant Code") + Comma +
                  FormatDecimal(PstdInvPickLineRef.Quantity) + Comma +
                  FormatDecimal(PstdInvPickLineRef."Qty. (Base)") + Comma +
                  FormatText(PstdInvPickLineRef."Serial No.") + Comma +
                  FormatText(PstdInvPickLineRef."Lot No.") + Comma +
                  FormatText(PstdInvPickLineRef."Bin Code")
                  );
            until PstdInvPickLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertTempRefData(NewTableID: Integer; NewUseCaseNo: Integer; NewTestCaseNo: Integer; NewIterationNo: Integer; NewEntryNo: Integer; NewTestString: Text[250])
    begin
        TempRefData."Table ID" := NewTableID;
        TempRefData."Project Code" := 'BW';
        TempRefData."Use Case No." := NewUseCaseNo;
        TempRefData."Test Case No." := NewTestCaseNo;
        TempRefData."Iteration No." := NewIterationNo;
        TempRefData."Entry No." := NewEntryNo;
        TempRefData.TestString := NewTestString;
        TempRefData.Insert();
    end;

    [Scope('OnPrem')]
    procedure FormatInteger(IntegerValue: Decimal): Text[250]
    begin
        exit(DelChr(Format(IntegerValue, 0, '<sign><integer>'), '=', '.'));
    end;

    [Scope('OnPrem')]
    procedure FormatDecimal(DecimalValue: Decimal) DecimalText: Text[250]
    begin
        DecimalText := Format(DecimalValue, 0, '<sign>');
        DecimalText := DecimalText + DelChr(Format(DecimalValue, 0, '<integer>'), '=', '.');
        DecimalText := DecimalText + ConvertStr(Format(DecimalValue, 0, '<decimals>'), ',', '.');
        exit(DecimalText);
    end;

    [Scope('OnPrem')]
    procedure FormatText(TextValue: Text[250]): Text[250]
    begin
        exit(Apostrophe + TextValue + Apostrophe);
    end;

    [Scope('OnPrem')]
    procedure FormatDate(DateValue: Date): Text[250]
    begin
        exit(Format(DateValue, 0, '<day,2><month,2><year>') + 'D');
    end;

    [Scope('OnPrem')]
    procedure WriteOutFile(OutText: Text[1024])
    begin
        OutFile.Write(OutText);
    end;

    [Scope('OnPrem')]
    procedure NextProcNo(): Text[30]
    begin
        ProcedureNo := ProcedureNo + 1;
        exit(Format(ProcedureNo));
    end;
}

