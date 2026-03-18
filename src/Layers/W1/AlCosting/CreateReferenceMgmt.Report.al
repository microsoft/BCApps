report 103402 "Create Reference Mgmt"
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

                if SelectItemLedgEntry then
                    CreateRefItemLedgEntry();
                if SelectValuEntry then
                    CreateRefValuEntry();
                if SelectGLEntry then
                    CreateRefGLEntry();
                if SelectItemJnlLine then
                    CreateRefItemJnlLine();
                if SelectLedgEntryDim then
                    CreateRefLedgEntryDim();
                if SelectItem then
                    CreateRefItem();
                if SelectSKU then
                    CreateRefSKU();
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
                OutFile.Create(TemporaryPath + '\CETAF_ReferenceManagement.txt');

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
        SelectItemLedgEntry := true;
        SelectValuEntry := true;
        SelectGLEntry := true;
        SelectItemJnlLine := true;
        SelectLedgEntryDim := true;
        SelectPurchHdr := true;
        SelectItem := true;
        SelectSKU := true;
    end;

    var
        UseCases: Record "Test Iteration";
        TestCases: Record "Test Iteration";
        TestIteration: Record "Test Iteration";
        ItemLedgEntryRef: Record "Item Ledger Entry Ref.";
        ValuEntryRef: Record "Value Entry Ref.";
        GLEntryRef: Record "G/L Entry Ref.";
        ItemJnlLineRef: Record "Item Journal Line Ref.";
        LedgEntryDimRef: Record "Ledger Entry Dim. Ref.";
        ItemRef: Record "Item Ref.";
        SKURef: Record "SKU Ref.";
        TempRefData: Record "Temp. Reference Data" temporary;
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
        CodeunitNo: Integer;
        ProcedureHeaderTmpl: Text[250];
        ProcedureHeader: Text[250];
        ProcedureNo: Integer;
        ProcedureCall: Text[250];
        CommandString: Text[250];
        FinishText: Text[50];
        BeginText: Text[50];
        EndText: Text[50];
        ExitText: Text[50];
        TableText: Text[250];
        RefTableID: Integer;
        EntryNo: Integer;
        MaxLineLength: Integer;
        MinIndention: Integer;
        Indention: Text[50];
        TempRefDataCount: Integer;
        SelectItemLedgEntry: Boolean;
        SelectValuEntry: Boolean;
        SelectGLEntry: Boolean;
        SelectItemJnlLine: Boolean;
        SelectLedgEntryDim: Boolean;
        SelectPurchHdr: Boolean;
        SelectItem: Boolean;
        SelectSKU: Boolean;

    [Scope('OnPrem')]
    procedure CreateRefItemLedgEntry()
    begin
        CodeunitNo := 103451;
        CodeunitName := 'ItemLedgEntry Ref. Mgmt';
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
        RefTableID := DATABASE::"Item Ledger Entry Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItemLedgEntry()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(EntryNo : Integer;ItemNo : Code[20];' +
          'PostingDate : Date;LocationCode : Code[10];Quantity : Decimal;RemainingQuantity : Decimal;' +
          'InvoicedQuantity : Decimal;GlobalDimension1Code : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      ILE : Record "Item Ledger Entry";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        EntryNo := EntryNo + Offset;');
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
        WriteOutFile('          TestTextValue(ILE.FIELDNAME("Global Dimension 1 Code"),ILE."Global Dimension 1 Code",' +
          'GlobalDimension1Code,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefValuEntry()
    begin
        CodeunitNo := 103452;
        CodeunitName := 'ValuEntry Ref. Mgmt';
        CreateHeader();
        CreateVerifyValuEntry();
        CreateTestValuEntry();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyValuEntry()
    begin
        Window.Update(1, 'Value Entry');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Value Entry"';
        RefTableID := DATABASE::"Value Entry Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestValuEntry()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(EntryNo : Integer;ValuedQuantity : Decimal;' +
          'CostPerUnit : Decimal;AdjustedCost : Decimal;CostPostedToGL : Decimal;GlobalDimension1Code : Code[20];' +
          'AdjustedCostACY : Decimal;AdjustedSalesCost : Decimal;Descr : Text[30];ValDate : Date;' +
          'ILEQty : Decimal;ExpCostPostedToGL : Decimal;ExpCostPostedToGLACY : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      VE : Record "Value Entry";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        EntryNo := EntryNo + Offset;');
        WriteOutFile('        IF NOT VE.GET(EntryNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Valued Quantity"),VE."Valued Quantity",ValuedQuantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Cost Per Unit"),VE."Cost Per Unit",CostPerUnit,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          IF VE."Expected Cost" THEN BEGIN');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Cost Amount (Expected)"),');
        WriteOutFile('              VE."Cost Amount (Expected)",AdjustedCost,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Cost Amount (Expected) (ACY)"),');
        WriteOutFile('              VE."Cost Amount (Expected) (ACY)",AdjustedCostACY,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Sales Amount (Expected)"),');
        WriteOutFile('              VE."Sales Amount (Expected)",AdjustedSalesCost,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('          END else BEGIN');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Cost Amount (Actual)"),');
        WriteOutFile('              VE."Cost Amount (Actual)",AdjustedCost,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Cost Amount (Actual) (ACY)"),');
        WriteOutFile('              VE."Cost Amount (Actual) (ACY)",AdjustedCostACY,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('            TestNumberValue(');
        WriteOutFile('              VE.FIELDNAME("Sales Amount (Actual)"),');
        WriteOutFile('              VE."Sales Amount (Actual)",AdjustedSalesCost,');
        WriteOutFile('              UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('            Increase(NoOfFields);');
        WriteOutFile('          END;');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Cost Posted to G/L"),VE."Cost Posted to G/L",CostPostedToGL,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(VE.FIELDNAME("Global Dimension 1 Code"),VE."Global Dimension 1 Code",' +
          'GlobalDimension1Code,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(VE.FIELDNAME(Description),VE.Description,Descr,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestDateValue(VE.FIELDNAME("Valuation Date"),VE."Valuation Date",ValDate,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Item Ledger Entry Quantity"),VE."Item Ledger Entry Quantity",ILEQty,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Expected Cost Posted to G/L"),VE."Expected Cost Posted to G/L",' +
          'ExpCostPostedToGL,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(VE.FIELDNAME("Exp. Cost Posted to G/L (ACY)"),VE."Exp. Cost Posted to G/L (ACY)",' +
          'ExpCostPostedToGLACY,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefGLEntry()
    begin
        CodeunitNo := 103453;
        CodeunitName := 'GLEntry Ref. Mgmt';
        CreateHeader();
        CreateVerifyGLEntry();
        CreateTestGLEntry();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyGLEntry()
    begin
        Window.Update(1, 'G/L Entry');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"G/L Entry"';
        RefTableID := DATABASE::"G/L Entry Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestGLEntry()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(EntryNo : Integer;GLAccountNo : Code[20];Amount : Decimal;' +
          'GlobalDimension1Code : Code[20];AdditionalCurrencyAmount : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      GLE : Record "G/L Entry";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        EntryNo := EntryNo + Offset;');
        WriteOutFile('        IF NOT GLE.GET(EntryNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(GLE.FIELDNAME("G/L Account No."),GLE."G/L Account No.",GLAccountNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(GLE.FIELDNAME(Amount),GLE.Amount,Amount,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(GLE.FIELDNAME("Global Dimension 1 Code"),GLE."Global Dimension 1 Code",' +
          'GlobalDimension1Code,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(GLE.FIELDNAME("Additional-Currency Amount"),GLE."Additional-Currency Amount",' +
          'AdditionalCurrencyAmount,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefItemJnlLine()
    begin
        CodeunitNo := 103454;
        CodeunitName := 'ItemJnlLine Ref. Mgmt';
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
        RefTableID := DATABASE::"Item Journal Line Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItemJnlLine()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(JnlTemplName : Code[10];JnlBatchName : Code[10];LineNo : Integer;' +
          'PostingDate : Date;ItemNo : Code[20];Quantity : Decimal;AmountCalculated : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      IJL : Record "Item Journal Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT IJL.GET(JnlTemplName,JnlBatchName,LineNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestDateValue(IJL.FIELDNAME("Posting Date"),IJL."Posting Date",PostingDate,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestTextValue(IJL.FIELDNAME("Item No."),IJL."Item No.",ItemNo,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(IJL.FIELDNAME(Quantity),IJL.Quantity,Quantity,');
        WriteOutFile('            UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(IJL.FIELDNAME("Inventory Value (Calculated)"),IJL."Inventory Value (Calculated)",');
        WriteOutFile('            amountCalculated,UseCaseNo,TestCaseNo,LineNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefLedgEntryDim()
    begin
        CodeunitNo := 103455;
        CodeunitName := 'LedgEntryDim Ref. Mgmt';
        CreateHeader();
        CreateVerifyLedgEntryDim();
        CreateTestLedgEntryDim();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyLedgEntryDim()
    begin
        Window.Update(1, 'Ledger Entry Dimension');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Ledger Entry Dimension"';
        RefTableID := DATABASE::"Ledger Entry Dim. Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestLedgEntryDim()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '("Table ID" : Integer;EntryNo : Integer;DimensionCode : Code[20];' +
          'DimensionValueCode : Code[20]);');
        WriteOutFile('    VAR');
        WriteOutFile('      LED : Record "Dimension Set ID Filter Line";');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT LED.GET("Table ID",EntryNo,DimensionCode) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestTextValue(LED.FIELDNAME("Dimension Value Code") + '' '' + DimensionCode,');
        WriteOutFile('            LED."Dimension Value Code",DimensionValueCode,');
        WriteOutFile('            UseCaseNo,TestCaseNo,EntryNo,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefItem()
    begin
        CodeunitNo := 103457;
        CodeunitName := 'Item Ref. Mgmt';
        CreateHeader();
        CreateVerifyItem();
        CreateTestItem();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifyItem()
    begin
        Window.Update(1, 'Item');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::Item';
        RefTableID := DATABASE::"Item Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestItem()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(ItemNo : Code[20];UnitCost : Decimal;NewAverageCostLCY : Decimal;' +
          'NewAverageCostACY : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      Item : Record "Item";');
        WriteOutFile('      ItemRef : Record "Item Ref.";');
        WriteOutFile('      ItemCostMgmt : Codeunit "ItemCostManagement";');
        WriteOutFile('      AverageCostLCY : Decimal;');
        WriteOutFile('      AverageCostACY : Decimal;');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        IF NOT Item.GET(ItemNo) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,0,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(Item.FIELDNAME("Unit Cost"),Item."Unit Cost",UnitCost,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('');
        WriteOutFile('          ItemCostMgmt.CalculateAverageCost(Item,AverageCostLCY,AverageCostACY);');
        WriteOutFile('          AverageCostLCY := ROUND(AverageCostLCY,0.00001);');
        WriteOutFile('          AverageCostACY := ROUND(AverageCostACY,0.00001);');
        WriteOutFile('          TestNumberValue(ItemRef.FIELDNAME("Average Cost (LCY)"),AverageCostLCY,NewAverageCostLCY,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('          TestNumberValue(ItemRef.FIELDNAME("Average Cost (ACY)"),AverageCostACY,NewAverageCostACY,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateRefSKU()
    begin
        CodeunitNo := 103458;
        CodeunitName := 'SKU Ref. Mgmt';
        CreateHeader();
        CreateVerifySKU();
        CreateTestSKU();
        CreateFooter();
    end;

    [Scope('OnPrem')]
    procedure CreateVerifySKU()
    begin
        Window.Update(1, 'Stockkeeping Unit');
        ProcedureHeader := StrSubstNo(ProcedureHeaderTmpl, NextProcNo());
        TableText := 'DATABASE::"Stockkeeping Unit"';
        RefTableID := DATABASE::"SKU Ref.";
        LoopIterations();
    end;

    [Scope('OnPrem')]
    procedure CreateTestSKU()
    begin
        WriteOutFile('    PROCEDURE Test@' + NextProcNo() + '(LocationCode : Code[10];ItemNo : Code[20];VariantCode : Code[10];' +
          'UnitCost : Decimal;NewAverageCostLCY : Decimal;NewAverageCostACY : Decimal);');
        WriteOutFile('    VAR');
        WriteOutFile('      SKU : Record "Stockkeeping Unit";');
        WriteOutFile('      SKURef : Record "SKU Ref.";');
        WriteOutFile('      Item : Record "Item";');
        WriteOutFile('      InvtSetup : Record "Inventory Setup";');
        WriteOutFile('      ItemCostMgmt : Codeunit "ItemCostManagement";');
        WriteOutFile('      AverageCostLCY : Decimal;');
        WriteOutFile('      AverageCostACY : Decimal;');
        WriteOutFile('    BEGIN');
        WriteOutFile('      WITH TestScriptMgmt DO BEGIN');
        WriteOutFile('        TableID := DATABASE::"Stockkeeping Unit";');
        WriteOutFile('        IF NOT SKU.GET(LocationCode,ItemNo,VariantCode) THEN');
        WriteOutFile('          TestTextValue('''',''NOT FOUND'',''EXIST'',UseCaseNo,TestCaseNo,0,TableID,IterationNo)');
        WriteOutFile('        else BEGIN');
        WriteOutFile('          Increase(NoOfRecords);');
        WriteOutFile('          TestNumberValue(SKU.FIELDNAME("Unit Cost"),SKU."Unit Cost",UnitCost,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('');
        WriteOutFile('          Item.Reset();');
        WriteOutFile('          IF Item.GET(ItemNo) THEN BEGIN');
        WriteOutFile('            InvtSetup.Get();');
        WriteOutFile('            IF InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::"Item & Location' +
          ' & Variant" THEN BEGIN');
        WriteOutFile('              Item.SETRANGE("Location Filter",LocationCode);');
        WriteOutFile('              Item.SETRANGE("Variant Filter",VariantCode);');
        WriteOutFile('            END;');
        WriteOutFile('          END;');
        WriteOutFile('          ItemCostMgmt.CalculateAverageCost(Item,AverageCostLCY,AverageCostACY);');
        WriteOutFile('          AverageCostLCY := ROUND(AverageCostLCY,0.00001);');
        WriteOutFile('          AverageCostACY := ROUND(AverageCostACY,0.00001);');
        WriteOutFile('          TestNumberValue(SKURef.FIELDNAME("Average Cost (LCY)"),AverageCostLCY,NewAverageCostLCY,');
        WriteOutFile('            UseCaseNo,TestCaseNo,0,TableID,IterationNo);');
        WriteOutFile('          Increase(NoOfFields);');
        WriteOutFile('        END;');
        WriteOutFile('      END;');
        WriteOutFile('    END;');
        WriteOutFile('');
    end;

    [Scope('OnPrem')]
    procedure CreateHeader()
    begin
        ProcedureNo := 103400;
        CodeunitHeader := StrSubstNo(CodeunitHeaderTmpl, CodeunitNo, CodeunitName);
        WriteOutFile(CodeunitHeader);
        WriteOutFile('' + Format(LBracket) + '');
        WriteOutFile('  OBJECT-PROPERTIES');
        WriteOutFile('  ' + Format(LBracket) + '');
        WriteOutFile('    Date=' + Format(Today, 0, '<day,2>.<month,2>.<year>') + ';');
        WriteOutFile('    Time=[' + Format(Time, 0, '<hours24,2>:<minutes,2>:<seconds,2>') + '];');
        WriteOutFile('    Modified=No;');
        WriteOutFile('    Version List=TEST;');
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
        WriteOutFile('      TestScriptMgmt : Codeunit "_TestscriptManagement";');
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
        if UseCases.Find('-') then begin
            WriteOutFile('      CASE UseCaseNo OF');
            repeat
                TestCases.Reset();
                TestCases.SetRange("Use Case No.", UseCases."Use Case No.");
                if TestCases.Find('-') then begin
                    WriteOutFile('        ' + Format(TestCases."Use Case No.") + ':');
                    WriteOutFile('          CASE TestCaseNo OF');
                    repeat
                        TestIteration.Reset();
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
        WriteOutFile('      *** This code has been generated by REPORT::"Create Reference Mgmt" to contain');
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
        if SelectItemLedgEntry then
            ProcessItemLedgEntryRef();
        if SelectValuEntry then
            ProcessValuEntryRef();
        if SelectGLEntry then
            ProcessGLEntryRef();
        if SelectItemJnlLine then
            ProcessItemJnlLineRef();
        if SelectLedgEntryDim then
            ProcessLedgEntryDimRef();
        if SelectItem then
            ProcessItemRef();
        if SelectSKU then
            ProcessSKURef();
    end;

    [Scope('OnPrem')]
    procedure ProcessItemLedgEntryRef()
    begin
        RefTableID := DATABASE::"Item Ledger Entry Ref.";
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
                  FormatDecimal(ItemLedgEntryRef."Invoiced Quantity") + Comma +
                  FormatText(ItemLedgEntryRef."Global Dimension 1 Code")
                  );
            until ItemLedgEntryRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessValuEntryRef()
    var
        TestString: Text[200];
    begin
        RefTableID := DATABASE::"Value Entry Ref.";
        EntryNo := 0;
        ValuEntryRef.Reset();
        if ValuEntryRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                TestString :=
                  FormatInteger(ValuEntryRef."Entry No.") + Comma +
                  FormatDecimal(ValuEntryRef."Valued Quantity") + Comma +
                  FormatDecimal(ValuEntryRef."Cost per Unit") + Comma;
                if ValuEntryRef."Expected Cost" then
                    TestString := TestString + FormatDecimal(ValuEntryRef."Cost Amount (Expected)") + Comma
                else
                    TestString := TestString + FormatDecimal(ValuEntryRef."Cost Amount (Actual)") + Comma;
                TestString :=
                  TestString +
                  FormatDecimal(ValuEntryRef."Cost Posted to G/L") + Comma +
                  FormatText(ValuEntryRef."Global Dimension 1 Code") + Comma;
                if ValuEntryRef."Expected Cost" then begin
                    TestString := TestString + FormatDecimal(ValuEntryRef."Cost Amount (Expected) (ACY)") + Comma;
                    TestString := TestString + FormatDecimal(ValuEntryRef."Sales Amount (Expected)") + Comma;
                end else begin
                    TestString := TestString + FormatDecimal(ValuEntryRef."Cost Amount (Actual) (ACY)") + Comma;
                    TestString := TestString + FormatDecimal(ValuEntryRef."Sales Amount (Actual)") + Comma;
                end;
                TestString :=
                  TestString +
                  FormatText(ValuEntryRef.Description) + Comma +
                  FormatDate(ValuEntryRef."Valuation Date") + Comma +
                  FormatDecimal(ValuEntryRef."Item Ledger Entry Quantity") + Comma +
                  FormatDecimal(ValuEntryRef."Expected Cost Posted to G/L") + Comma +
                  FormatDecimal(ValuEntryRef."Exp. Cost Posted to G/L (ACY)");
                InsertTempRefData(
                  RefTableID, ValuEntryRef."Use Case No.", ValuEntryRef."Test Case No.", ValuEntryRef."Iteration No.", EntryNo,
                  TestString);
            until ValuEntryRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessGLEntryRef()
    begin
        RefTableID := DATABASE::"G/L Entry Ref.";
        EntryNo := 0;
        GLEntryRef.Reset();
        if GLEntryRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, GLEntryRef."Use Case No.", GLEntryRef."Test Case No.", GLEntryRef."Iteration No.", EntryNo,
                  FormatInteger(GLEntryRef."Entry No.") + Comma +
                  FormatText(GLEntryRef."G/L Account No.") + Comma +
                  FormatDecimal(GLEntryRef.Amount) + Comma +
                  FormatText(GLEntryRef."Global Dimension 1 Code") + Comma +
                  FormatDecimal(GLEntryRef."Additional-Currency Amount")
                  );
            until GLEntryRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessItemJnlLineRef()
    begin
        RefTableID := DATABASE::"Item Journal Line Ref.";
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
                  FormatDecimal(ItemJnlLineRef.Quantity) + Comma +
                  FormatDecimal(ItemJnlLineRef."Inventory Value (Calculated)")
                  );
            until ItemJnlLineRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessLedgEntryDimRef()
    begin
        RefTableID := DATABASE::"Ledger Entry Dim. Ref.";
        EntryNo := 0;
        LedgEntryDimRef.Reset();
        if LedgEntryDimRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, LedgEntryDimRef."Use Case No.", LedgEntryDimRef."Test Case No.", LedgEntryDimRef."Iteration No.", EntryNo,
                  FormatDecimal(LedgEntryDimRef."Table ID") + Comma +
                  FormatInteger(LedgEntryDimRef."Entry No.") + Comma +
                  FormatInteger(LedgEntryDimRef."Dimension Set ID")
                  );
            until LedgEntryDimRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessItemRef()
    begin
        RefTableID := DATABASE::"Item Ref.";
        EntryNo := 0;
        ItemRef.Reset();
        if ItemRef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, ItemRef."Use Case No.", ItemRef."Test Case No.", ItemRef."Iteration No.", EntryNo,
                  FormatText(ItemRef."No.") + Comma +
                  FormatDecimal(ItemRef."Unit Cost") + Comma +
                  FormatDecimal(ItemRef."Average Cost (LCY)") + Comma +
                  FormatDecimal(ItemRef."Average Cost (ACY)")
                  );
            until ItemRef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ProcessSKURef()
    begin
        RefTableID := DATABASE::"SKU Ref.";
        EntryNo := 0;
        SKURef.Reset();
        if SKURef.Find('-') then
            repeat
                EntryNo := EntryNo + 1;
                InsertTempRefData(
                  RefTableID, SKURef."Use Case No.", SKURef."Test Case No.", SKURef."Iteration No.", EntryNo,
                  FormatText(SKURef."Location Code") + Comma +
                  FormatText(SKURef."Item No.") + Comma +
                  FormatText(SKURef."Variant Code") + Comma +
                  FormatDecimal(SKURef."Unit Cost") + Comma +
                  FormatDecimal(SKURef."Average Cost (LCY)") + Comma +
                  FormatDecimal(SKURef."Average Cost (ACY)")
                  );
            until SKURef.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure InsertTempRefData(NewTableID: Integer; NewUseCaseNo: Integer; NewTestCaseNo: Integer; NewIterationNo: Integer; NewEntryNo: Integer; NewTestString: Text[200])
    begin
        TempRefData."Table ID" := NewTableID;
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
        // EXIT(
        // FORMAT(DecimalValue,0,'<sign>') +
        // DELCHR(FORMAT(DecimalValue,0,'<integer>'),'=','.') +
        // CONVERTSTR(FORMAT(DecimalValue,0,'<decimals>'),',','.'));

        // Workaround due to FORMAT problem
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

