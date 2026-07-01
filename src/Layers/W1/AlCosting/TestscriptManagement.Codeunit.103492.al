#pragma warning disable AA0215
codeunit 103492 _TestscriptManagement
#pragma warning restore AA0215
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
        DeleteQATables(true);
    end;

    var
        TestscriptResult: Record "Testscript Result";
        QASetup: Record "QA Setup";
        TestscriptManagement: Codeunit TestscriptManagement;
        ILERefMgmt: Codeunit "ItemLedgEntry Ref. Mgmt";
        VERefMgmt: Codeunit "ValuEntry Ref. Mgmt";
        GLERefMgmt: Codeunit "GLEntry Ref. Mgmt";
        IJLRefMgmt: Codeunit "ItemJnlLine Ref. Mgmt";
        LEDRefMgmt: Codeunit "LedgEntryDim Ref. Mgmt";
        ItemRefMgmt: Codeunit "Item Ref. Mgmt";
        SKURefMgmt: Codeunit "SKU Ref. Mgmt";
        ItemCostMgmt: Codeunit ItemCostManagement;
        OutputFile: File;
        OutputToFile: Boolean;
        Tab: Char;
        iD: Integer;
        DimensionCode: array[50] of Code[20];
        DimensionValueCode: array[50] of Code[20];
        NewDimensionValueCode: array[50] of Code[20];
        WithErrors: Boolean;
        ILERecords: Integer;
        ILEFields: Integer;
        VERecords: Integer;
        VEFields: Integer;
        GLERecords: Integer;
        GLEFields: Integer;
        IJLRecords: Integer;
        IJLFields: Integer;
        LEDRecords: Integer;
        LEDFields: Integer;
        ItemRecords: Integer;
        ItemFields: Integer;
        SKURecords: Integer;
        SKUFields: Integer;
        FormatValue: Text[250];
        FormatExpValue: Text[250];
        DimMgt: Codeunit DimensionManagement;

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
        WithErrors := false;
        TestscriptResult.SetRange("Is Equal", false);

        if TestscriptResult.Find('-') then
            repeat
                WithErrors := WithErrors or
                  (TestscriptResult.Value <> '') or
                  (TestscriptResult."Expected Value" <> '');
            until TestscriptResult.Next() = 0;

        if WithErrors then
            Message('The test has completed with errors.')
        else
            Message('The test has completed with no errors.');

        PAGE.RunModal(0, TestscriptResult);
    end;

    [Scope('OnPrem')]
    procedure DeleteTestscriptResult()
    begin
        TestscriptResult.Reset();
        TestscriptResult.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure VerifyPostCondition(UseCaseNo: Integer; TestCaseNo: Integer; IterationNo: Integer; ILEOffset: Integer; VEOffset: Integer; GLEOffset: Integer)
    var
        ILERef: Record "Item Ledger Entry Ref.";
        VERef: Record "Value Entry Ref.";
        GLERef: Record "G/L Entry Ref.";
        IJLRef: Record "Item Journal Line Ref.";
        LEDRef: Record "Ledger Entry Dim. Ref.";
        ItemRef: Record "Item Ref.";
        SKURef: Record "SKU Ref.";
        CodeunitID: Integer;
    begin
        //SaveRefEntries(UseCaseNo,TestCaseNo,IterationNo);

        QASetup.Get();
        if QASetup."Use Hardcoded Reference" then begin

            ILERefMgmt.SetNumbers(ILERecords, ILEFields);
            ILERefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, ILEOffset);
            ILERefMgmt.GetNumbers(ILERecords, ILEFields);

            VERefMgmt.SetNumbers(VERecords, VEFields);
            VERefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, VEOffset);
            VERefMgmt.GetNumbers(VERecords, VEFields);

            GLERefMgmt.SetNumbers(GLERecords, GLEFields);
            GLERefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, GLEOffset);
            GLERefMgmt.GetNumbers(GLERecords, GLEFields);

            IJLRefMgmt.SetNumbers(IJLRecords, IJLFields);
            IJLRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            IJLRefMgmt.GetNumbers(IJLRecords, IJLFields);

            LEDRefMgmt.SetNumbers(LEDRecords, LEDFields);
            LEDRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            LEDRefMgmt.GetNumbers(LEDRecords, LEDFields);

            ItemRefMgmt.SetNumbers(ItemRecords, ItemFields);
            ItemRefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            ItemRefMgmt.GetNumbers(ItemRecords, ItemFields);

            SKURefMgmt.SetNumbers(SKURecords, SKUFields);
            SKURefMgmt.Verify(UseCaseNo, TestCaseNo, IterationNo, 0);
            SKURefMgmt.GetNumbers(SKURecords, SKUFields);

        end else begin
            // use reference tables
            ILERef.SetRange("Use Case No.", UseCaseNo);
            ILERef.SetRange("Test Case No.", TestCaseNo);
            ILERef.SetRange("Iteration No.", IterationNo);
            if ILERef.Find('-') then
                repeat
                    VerifyItemLedgEntry(ILERef, ILEOffset, IterationNo);
                until ILERef.Next() = 0;

            VERef.SetRange("Use Case No.", UseCaseNo);
            VERef.SetRange("Test Case No.", TestCaseNo);
            VERef.SetRange("Iteration No.", IterationNo);
            if VERef.Find('-') then
                repeat
                    VerifyValuEntry(VERef, VEOffset, IterationNo);
                until VERef.Next() = 0;

            GLERef.SetRange("Use Case No.", UseCaseNo);
            GLERef.SetRange("Test Case No.", TestCaseNo);
            GLERef.SetRange("Iteration No.", IterationNo);
            if GLERef.Find('-') then
                repeat
                    VerifyGLEntry(GLERef, GLEOffset, IterationNo);
                until GLERef.Next() = 0;

            IJLRef.SetRange("Use Case No.", UseCaseNo);
            IJLRef.SetRange("Test Case No.", TestCaseNo);
            IJLRef.SetRange("Iteration No.", IterationNo);
            if IJLRef.Find('-') then
                repeat
                    VerifyItemJnlLine(IJLRef, IterationNo);
                until IJLRef.Next() = 0;

            LEDRef.SetRange("Use Case No.", UseCaseNo);
            LEDRef.SetRange("Test Case No.", TestCaseNo);
            LEDRef.SetRange("Iteration No.", IterationNo);
            if LEDRef.Find('-') then
                repeat
                    VerifyLedgEntryDim(LEDRef, IterationNo);
                until LEDRef.Next() = 0;

            ItemRef.SetRange("Use Case No.", UseCaseNo);
            ItemRef.SetRange("Test Case No.", TestCaseNo);
            ItemRef.SetRange("Iteration No.", IterationNo);
            if ItemRef.Find('-') then
                repeat
                    VerifyItem(ItemRef, IterationNo);
                until ItemRef.Next() = 0;

            SKURef.SetRange("Use Case No.", UseCaseNo);
            SKURef.SetRange("Test Case No.", TestCaseNo);
            SKURef.SetRange("Iteration No.", IterationNo);
            if SKURef.Find('-') then
                repeat
                    VerifySKU(SKURef, IterationNo);
                until SKURef.Next() = 0;
        end;

        CodeunitID := TestscriptResult."Codeunit ID";
        TestscriptResult."Codeunit ID" := CodeunitID;
    end;

    [Scope('OnPrem')]
    procedure VerifyItemLedgEntry(ILERef: Record "Item Ledger Entry Ref."; Offset: Integer; IterationNo: Integer)
    var
        ILE: Record "Item Ledger Entry";
        TableID: Integer;
    begin
        TableID := DATABASE::"Item Ledger Entry";
        ILERef."Entry No." := ILERef."Entry No." + Offset;
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
            TestTextValue(ILERef.FieldName("Global Dimension 1 Code"), ILE."Global Dimension 1 Code", ILERef."Global Dimension 1 Code",
              ILERef."Use Case No.", ILERef."Test Case No.", ILERef."Entry No.", TableID, IterationNo);
            Increase(ILEFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyValuEntry(VERef: Record "Value Entry Ref."; Offset: Integer; IterationNo: Integer)
    var
        VE: Record "Value Entry";
        TableID: Integer;
    begin
        TableID := DATABASE::"Value Entry";
        VERef."Entry No." := VERef."Entry No." + Offset;
        if not VE.Get(VERef."Entry No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo)
        else begin
            Increase(VERecords);
            TestNumberValue(VERef.FieldName("Valued Quantity"), VE."Valued Quantity", VERef."Valued Quantity",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestNumberValue(VERef.FieldName("Cost per Unit"), VE."Cost per Unit", VERef."Cost per Unit",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            if VE."Expected Cost" then begin
                TestNumberValue(
                  VE.FieldName("Cost Amount (Expected)"),
                  VE."Cost Amount (Expected)", VERef."Cost Amount (Expected)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
                TestNumberValue(
                  VE.FieldName("Cost Amount (Expected) (ACY)"),
                  VE."Cost Amount (Expected) (ACY)", VERef."Cost Amount (Expected) (ACY)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
                TestNumberValue(
                  VE.FieldName("Sales Amount (Expected)"),
                  VE."Sales Amount (Expected)", VERef."Sales Amount (Expected)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
            end else begin
                TestNumberValue(
                  VE.FieldName("Cost Amount (Actual)"),
                  VE."Cost Amount (Actual)", VERef."Cost Amount (Actual)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
                TestNumberValue(
                  VE.FieldName("Cost Amount (Actual) (ACY)"),
                  VE."Cost Amount (Actual) (ACY)", VERef."Cost Amount (Actual) (ACY)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
                TestNumberValue(
                  VE.FieldName("Sales Amount (Actual)"),
                  VE."Sales Amount (Actual)", VERef."Sales Amount (Actual)",
                  VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
                Increase(VEFields);
            end;
            TestNumberValue(VERef.FieldName("Cost Posted to G/L"), VE."Cost Posted to G/L", VERef."Cost Posted to G/L",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestTextValue(VERef.FieldName("Global Dimension 1 Code"), VE."Global Dimension 1 Code", VERef."Global Dimension 1 Code",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestTextValue(VE.FieldName(Description), VE.Description, VERef.Description,
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestDateValue(VE.FieldName("Valuation Date"), VE."Valuation Date", VERef."Valuation Date",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestNumberValue(VE.FieldName("Item Ledger Entry Quantity"), VE."Item Ledger Entry Quantity", VERef."Item Ledger Entry Quantity",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestNumberValue(VE.FieldName("Expected Cost Posted to G/L"), VE."Expected Cost Posted to G/L", VERef."Expected Cost Posted to G/L",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
            TestNumberValue(
              VE.FieldName("Exp. Cost Posted to G/L (ACY)"),
              VE."Exp. Cost Posted to G/L (ACY)", VERef."Exp. Cost Posted to G/L (ACY)",
              VERef."Use Case No.", VERef."Test Case No.", VERef."Entry No.", TableID, IterationNo);
            Increase(VEFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyGLEntry(GLERef: Record "G/L Entry Ref."; Offset: Integer; IterationNo: Integer)
    var
        GLE: Record "G/L Entry";
        TableID: Integer;
    begin
        TableID := DATABASE::"G/L Entry";
        GLERef."Entry No." := GLERef."Entry No." + Offset;
        if not GLE.Get(GLERef."Entry No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', GLERef."Use Case No.", GLERef."Test Case No.", GLERef."Entry No.", TableID, IterationNo)
        else begin
            Increase(GLERecords);
            TestTextValue(GLERef.FieldName("G/L Account No."), GLE."G/L Account No.", GLERef."G/L Account No.",
              GLERef."Use Case No.", GLERef."Test Case No.", GLERef."Entry No.", TableID, IterationNo);
            Increase(GLEFields);
            TestNumberValue(GLERef.FieldName(Amount), GLE.Amount, GLERef.Amount,
              GLERef."Use Case No.", GLERef."Test Case No.", GLERef."Entry No.", TableID, IterationNo);
            Increase(GLEFields);
            TestTextValue(GLERef.FieldName("Global Dimension 1 Code"), GLE."Global Dimension 1 Code", GLERef."Global Dimension 1 Code",
              GLERef."Use Case No.", GLERef."Test Case No.", GLERef."Entry No.", TableID, IterationNo);
            Increase(GLEFields);
            TestNumberValue(GLERef.FieldName("Additional-Currency Amount"), GLE."Additional-Currency Amount", GLERef."Additional-Currency Amount",
              GLERef."Use Case No.", GLERef."Test Case No.", GLERef."Entry No.", TableID, IterationNo);
            Increase(GLEFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyItemJnlLine(IJLRef: Record "Item Journal Line Ref."; IterationNo: Integer)
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
            TestNumberValue(IJLRef.FieldName(Quantity), IJL.Quantity, IJLRef.Quantity,
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
            TestNumberValue(IJLRef.FieldName("Inventory Value (Calculated)"), IJL."Inventory Value (Calculated)", IJLRef."Inventory Value (Calculated)",
              IJLRef."Use Case No.", IJLRef."Test Case No.", IJLRef."Line No.", TableID, IterationNo);
            Increase(IJLFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyLedgEntryDim(LEDRef: Record "Ledger Entry Dim. Ref."; IterationNo: Integer)
    var
        TableID: Integer;
        GLEntry: Record "G/L Entry";
        ItemLdgEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
        EntryNo: Integer;
    begin
        TableID := LEDRef."Table ID";
        EntryNo := LEDRef."Entry No.";
        if (TableID <> 17) and (TableID <> 32) and (TableID <> 5802) then
            Error('103492 More table need to be verified. Table ID: %1', TableID);

        if TableID = 17 then begin
            GLEntry.SetRange("Entry No.", EntryNo);
            GLEntry.FindFirst();
            TestNumberValue(LEDRef.FieldName("Dimension Set ID"), GLEntry."Dimension Set ID", LEDRef."Dimension Set ID",
              LEDRef."Use Case No.", LEDRef."Test Case No.", LEDRef."Entry No.", TableID, IterationNo);
        end;

        if TableID = 32 then begin
            ItemLdgEntry.SetRange("Entry No.", EntryNo);
            ItemLdgEntry.FindFirst();
            TestNumberValue(LEDRef.FieldName("Dimension Set ID"), ItemLdgEntry."Dimension Set ID", LEDRef."Dimension Set ID",
              LEDRef."Use Case No.", LEDRef."Test Case No.", LEDRef."Entry No.", TableID, IterationNo);
        end;

        if TableID = 5802 then begin
            ValueEntry.SetRange("Entry No.", EntryNo);
            ValueEntry.FindFirst();
            TestNumberValue(LEDRef.FieldName("Dimension Set ID"), ValueEntry."Dimension Set ID", LEDRef."Dimension Set ID",
              LEDRef."Use Case No.", LEDRef."Test Case No.", LEDRef."Entry No.", TableID, IterationNo);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifyItem(ItemRef: Record "Item Ref."; IterationNo: Integer)
    var
        Item: Record Item;
        TableID: Integer;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        TableID := DATABASE::Item;
        if not Item.Get(ItemRef."No.") then
            TestTextValue('', 'NOT FOUND', 'EXIST', ItemRef."Use Case No.", ItemRef."Test Case No.", 0, TableID, IterationNo)
        else begin
            Increase(ItemRecords);
            TestNumberValue(ItemRef.FieldName("Unit Cost"), Item."Unit Cost", ItemRef."Unit Cost",
              ItemRef."Use Case No.", ItemRef."Test Case No.", 0, TableID, IterationNo);
            Increase(ItemFields);

            ItemCostMgmt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
            AverageCostLCY := Round(AverageCostLCY, 0.00001);
            AverageCostACY := Round(AverageCostACY, 0.00001);
            TestNumberValue(ItemRef.FieldName("Average Cost (LCY)"), AverageCostLCY, ItemRef."Average Cost (LCY)",
              ItemRef."Use Case No.", ItemRef."Test Case No.", 0, TableID, IterationNo);
            Increase(ItemFields);
            TestNumberValue(ItemRef.FieldName("Average Cost (ACY)"), AverageCostACY, ItemRef."Average Cost (ACY)",
              ItemRef."Use Case No.", ItemRef."Test Case No.", 0, TableID, IterationNo);
            Increase(ItemFields);
        end;
    end;

    [Scope('OnPrem')]
    procedure VerifySKU(SKURef: Record "SKU Ref."; IterationNo: Integer)
    var
        SKU: Record "Stockkeeping Unit";
        Item: Record Item;
        InvtSetup: Record "Inventory Setup";
        TableID: Integer;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        TableID := DATABASE::"Stockkeeping Unit";
        if not SKU.Get(SKURef."Location Code", SKURef."Item No.", SKURef."Variant Code") then
            TestTextValue('', 'NOT FOUND', 'EXIST', SKURef."Use Case No.", SKURef."Test Case No.", 0, TableID, IterationNo)
        else begin
            Increase(SKURecords);
            TestNumberValue(SKURef.FieldName("Unit Cost"), SKU."Unit Cost", SKURef."Unit Cost",
              SKURef."Use Case No.", SKURef."Test Case No.", 0, TableID, IterationNo);
            Increase(SKUFields);

            Item.Reset();
            if Item.Get(SKURef."Item No.") then begin
                InvtSetup.Get();
                if InvtSetup."Average Cost Calc. Type" = InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant" then begin
                    Item.SetRange("Location Filter", SKURef."Location Code");
                    Item.SetRange("Variant Filter", SKURef."Variant Code");
                end;
            end;
            ItemCostMgmt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
            AverageCostLCY := Round(AverageCostLCY, 0.00001);
            AverageCostACY := Round(AverageCostACY, 0.00001);
            TestNumberValue(SKURef.FieldName("Average Cost (LCY)"), AverageCostLCY, SKURef."Average Cost (LCY)",
              SKURef."Use Case No.", SKURef."Test Case No.", 0, TableID, IterationNo);
            Increase(SKUFields);
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
        FormatValue := Format(GLERecords);
        FormatExpValue := Format(GLEFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"G/L Entry", 0);
        FormatValue := Format(VERecords);
        FormatExpValue := Format(VEFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Value Entry", 0);
        FormatValue := Format(IJLRecords);
        FormatExpValue := Format(IJLFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Item Journal Line", 0);
        FormatValue := Format(LEDRecords);
        FormatExpValue := Format(LEDFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Dimension Set Entry", 0);
        FormatValue := Format(ItemRecords);
        FormatExpValue := Format(ItemFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::Item, 0);
        FormatValue := Format(SKURecords);
        FormatExpValue := Format(SKUFields);
        InsertTestResult(Name, FormatValue, FormatExpValue, true, 0, 0, 0,
          DATABASE::"Stockkeeping Unit", 0);
    end;

    [Scope('OnPrem')]
    procedure InsertTestResult(Name: Text[250]; Value: Text[250]; ExpectedValue: Text[250]; IsEqual: Boolean; UseCaseNo: Integer; TestCaseNo: Integer; EntryNo: Integer; TableID: Integer; IterationNo: Integer)
    begin
        if TableID = 0 then
            exit;

        TestscriptManagement.InsertTestResult(
          StrSubstNo('%1-%2 T%3:%4 %5', UseCaseNo, TestCaseNo, TableID, EntryNo, Name),
          Value, ExpectedValue, IsEqual);

        /*
        IF OutputToFile THEN BEGIN
          OutputFile.WRITE(
            Name + FORMAT(Tab) +
            Value + FORMAT(Tab) +
            ExpectedValue + FORMAT(Tab) + FORMAT(Tab) +
            FORMAT(IsEqual));
        END else BEGIN
          IF NOT TestScriptResult2.FIND('+') THEN;
          TestscriptResult."No." := TestScriptResult2."No." + 1;
          TestscriptResult.Name := Name;
          TestscriptResult.Value := Value;
          TestscriptResult."Expected Value" := ExpectedValue;
          TestscriptResult."Is Equal" := IsEqual;
          TestscriptResult.Date := TODAY;
          TestscriptResult.Time := TIME;
          TestscriptResult."Use Case No." := UseCaseNo;
          TestscriptResult."Test Case No." := TestCaseNo;
          TestscriptResult."Entry No." := EntryNo;
          TestscriptResult.TableID := TableID;
          TestscriptResult."Iteration No." := IterationNo;
          TestscriptResult.Insert();
        END;
        */

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
    procedure GetLastValuEntryNo(): Integer
    var
        ValuEntry: Record "Value Entry";
    begin
        ValuEntry.Reset();
        if not ValuEntry.FindLast() then;
        exit(ValuEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure GetLastGLEntryNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.Reset();
        if not GLEntry.FindLast() then;
        exit(GLEntry."Entry No.");
    end;

    [Scope('OnPrem')]
    procedure SetAddRepCurr(NewAddRepCurr: Code[10])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Additional Reporting Currency" <> NewAddRepCurr then begin
            GLSetup.Validate("Additional Reporting Currency", NewAddRepCurr);
            GLSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAutoCostPost(NewAutoCostPost: Boolean)
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Posting" <> NewAutoCostPost then begin
            InvtSetup.Validate("Automatic Cost Posting", NewAutoCostPost);
            InvtSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAverageCostCalcType(NewAverageCostCalcType: Enum "Average Cost Calculation Type")
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        if InvtSetup."Average Cost Calc. Type" <> NewAverageCostCalcType then begin
            InvtSetup."Average Cost Calc. Type" := NewAverageCostCalcType;
            InvtSetup.Modify();
            CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InvtSetup);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAverageCostPeriod(NewAverageCostPeriod: Enum "Average Cost Period Type")
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        if InvtSetup."Average Cost Period" <> NewAverageCostPeriod then begin
            InvtSetup."Average Cost Period" := NewAverageCostPeriod;
            InvtSetup.Modify();
            CODEUNIT.Run(CODEUNIT::"Change Average Cost Setting", InvtSetup);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetAutoCostAdjmt(NewAutoCostAdjmt: Enum "Automatic Cost Adjustment Type")
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        if InvtSetup."Automatic Cost Adjustment" <> NewAutoCostAdjmt then begin
            InvtSetup.Validate("Automatic Cost Adjustment", NewAutoCostAdjmt);
            InvtSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetExpCostPost(NewExpCostPost: Boolean)
    var
        InvtSetup: Record "Inventory Setup";
    begin
        InvtSetup.Get();
        if InvtSetup."Expected Cost Posting to G/L" <> NewExpCostPost then begin
            InvtSetup.Validate("Expected Cost Posting to G/L", NewExpCostPost);
            InvtSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetPurchCalcInvDisc(NewCalcInvDiscount: Boolean)
    var
        PurchPayableSetup: Record "Purchases & Payables Setup";
    begin
        PurchPayableSetup.Get();
        if PurchPayableSetup."Calc. Inv. Discount" <> NewCalcInvDiscount then begin
            PurchPayableSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
            PurchPayableSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure SetSalesCalcInvDisc(NewCalcInvDiscount: Boolean)
    var
        SalesReceiveSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceiveSetup.Get();
        if SalesReceiveSetup."Calc. Inv. Discount" <> NewCalcInvDiscount then begin
            SalesReceiveSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
            SalesReceiveSetup.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertItemJnlLine(var NewItemJnlLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LineNo: Integer; PostingDate: Date; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; NewLocationCode: Code[10]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; UnitAmount: Decimal; AppliesToEntry: Integer)
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
        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then
            ItemJnlLine.Validate("New Location Code", NewLocationCode);
        ItemJnlLine.Validate(Quantity, Quantity);
        ItemJnlLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        if AppliesToEntry <> 0 then
            ItemJnlLine.Validate("Applies-to Entry", AppliesToEntry);
        if UnitAmount <> 0 then
            ItemJnlLine.Validate("Unit Amount", UnitAmount);
        ItemJnlLine.Insert(true);   // -> DELAYED INSERT on form
        Clear(NewItemJnlLine);
        NewItemJnlLine := ItemJnlLine;
        InsertJnlLineDim(ItemJnlLine);
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
        InsertJnlLineDim(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure ClearDimensions()
    begin
        iD := 0;
        Clear(DimensionCode);
        Clear(DimensionValueCode);
        Clear(NewDimensionValueCode);
    end;

    [Scope('OnPrem')]
    procedure InsertDimension(DimCode: Code[20]; DimValueCode: Code[20]; NewDimValueCode: Code[20])
    begin
        iD := iD + 1;
        if iD > ArrayLen(DimensionCode) then
            exit;
        DimensionCode[iD] := DimCode;
        DimensionValueCode[iD] := DimValueCode;
        NewDimensionValueCode[iD] := NewDimValueCode;
    end;

    [Scope('OnPrem')]
    procedure InsertJnlLineDim(ItemJnlLine: Record "Item Journal Line")
    var
        DimSetEntry: Record "Dimension Set Entry";
        DimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
        NewDimSetID: Integer;
        NewShortcutDimVal1: Code[20];
        NewShortcutDimVal2: Code[20];
    begin
        DimSetID := ItemJnlLine."Dimension Set ID";
        NewDimSetID := ItemJnlLine."New Dimension Set ID";
        for iD := 1 to ArrayLen(DimensionCode) do
            if DimensionCode[iD] <> '' then begin
                DimSetEntry.SetRange("Dimension Set ID", DimSetID);
                DimSetEntry.SetRange("Dimension Code", DimensionCode[iD]);
                if DimSetEntry.FindFirst() then
                    DimSetID := EditDimSet(DimSetID, DimensionCode[iD], DimensionValueCode[iD])
                else
                    DimSetID := CreateDimSet(DimSetID, DimensionCode[iD], DimensionValueCode[iD]);
            end;
        ItemJnlLine.Validate("Dimension Set ID", DimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(DimSetID, ShortcutDimVal1, ShortcutDimVal2);
        ItemJnlLine.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        ItemJnlLine.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);
        ItemJnlLine.Modify(true);

        if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::Transfer then begin
            DimSetEntry.Reset();
            for iD := 1 to ArrayLen(DimensionCode) do
                if DimensionCode[iD] <> '' then begin
                    DimSetEntry.SetRange("Dimension Set ID", NewDimSetID);
                    DimSetEntry.SetRange("Dimension Code", DimensionCode[iD]);
                    if DimSetEntry.FindFirst() then
                        NewDimSetID := EditDimSet(NewDimSetID, DimensionCode[iD], NewDimensionValueCode[iD])
                    else
                        NewDimSetID := CreateDimSet(NewDimSetID, DimensionCode[iD], NewDimensionValueCode[iD]);
                end;
            ItemJnlLine.Validate("New Dimension Set ID", NewDimSetID);
            DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, NewShortcutDimVal1, NewShortcutDimVal2);
            ItemJnlLine.Validate("New Shortcut Dimension 1 Code", NewShortcutDimVal1);
            ItemJnlLine.Validate("New Shortcut Dimension 2 Code", NewShortcutDimVal2);
            ItemJnlLine.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure InsertDocumDim(DimSetID: Integer): Integer
    var
        DimSetEntry: Record "Dimension Set Entry";
        NewDimSetID: Integer;
    begin
        NewDimSetID := DimSetID;
        for iD := 1 to ArrayLen(DimensionCode) do
            if DimensionCode[iD] <> '' then begin
                DimSetEntry.SetRange("Dimension Set ID", NewDimSetID);
                DimSetEntry.SetRange("Dimension Code", DimensionCode[iD]);
                if DimSetEntry.FindFirst() then
                    NewDimSetID := EditDimSet(NewDimSetID, DimensionCode[iD], DimensionValueCode[iD])
                else
                    NewDimSetID := CreateDimSet(NewDimSetID, DimensionCode[iD], DimensionValueCode[iD]);
            end;
        exit(NewDimSetID);
    end;

    [Scope('OnPrem')]
    procedure InsertSalesHeader(var NewSalesHeader: Record "Sales Header"; NewDocumentType: Enum "Sales Document Type"; NewSellToCustNo: Code[20]; NewOrderDate: Date)
    var
        SalesHeader: Record "Sales Header";
        DimSetID: Integer;
        NewDimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", NewDocumentType);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", NewSellToCustNo);
        SalesHeader.Validate("Order Date", NewOrderDate);
        DimSetID := SalesHeader."Dimension Set ID";
        NewDimSetID := InsertDocumDim(DimSetID);
        SalesHeader.Validate("Dimension Set ID", NewDimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, ShortcutDimVal1, ShortcutDimVal2);
        SalesHeader.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        SalesHeader.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);
        SalesHeader.Modify(true);

        NewSalesHeader := SalesHeader;
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
    procedure InsertSalesLine(var NewSalesLine: Record "Sales Line"; NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewType: Enum "Sales Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewUnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
    begin
        SalesLine.Init();
        SalesLine."Document Type" := NewSalesHeader."Document Type";
        SalesLine."Document No." := NewSalesHeader."No.";
        SalesLine."Line No." := NewLineNo;
        SalesLine.Insert(true);
        SalesLine.Validate(Type, NewType);
        SalesLine.Validate("No.", NewNo);
        if NewType = SalesLine.Type::Item then
            SalesLine.Validate("Variant Code", NewVariantCode);
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        SalesLine.Validate("Unit Price", NewUnitPrice);
        DimSetID := SalesLine."Dimension Set ID";
        NewDimSetID := InsertDocumDim(DimSetID);
        SalesLine.Validate("Dimension Set ID", NewDimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, ShortcutDimVal1, ShortcutDimVal2);
        SalesLine.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        SalesLine.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);
        SalesLine.Modify(true);
        NewSalesLine := SalesLine;
    end;

    [Scope('OnPrem')]
    procedure ModifySalesLine(var NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewQtyToShip: Decimal; NewQtyToInvoice: Decimal; NewUnitPrice: Decimal; NewLineDiscount: Decimal; SetLineDiscount: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
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
    procedure ModifySalesReturnLine(var NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewQtyToReceive: Decimal; NewQtyToInvoice: Decimal; NewUnitPrice: Decimal; NewLineDiscount: Decimal; NewApplFromItemEntry: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo);
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
    procedure InsertSalesChargeAssignLine(NewSalesLine: Record "Sales Line"; NewLineNo: Integer; NewApplToDocType: Enum "Sales Applies-to Document Type"; NewApplToDocNo: Code[20]; NewApplToDocLineNo: Integer; NewItemNo: Code[20])
    var
        SalesChargeAssignLine: Record "Item Charge Assignment (Sales)";
    begin
        SalesChargeAssignLine.Init();
        SalesChargeAssignLine."Document Type" := NewSalesLine."Document Type";
        SalesChargeAssignLine."Document No." := NewSalesLine."Document No.";
        SalesChargeAssignLine."Document Line No." := NewSalesLine."Line No.";
        SalesChargeAssignLine."Line No." := NewLineNo;
        SalesChargeAssignLine."Item Charge No." := NewSalesLine."No.";
        SalesChargeAssignLine."Applies-to Doc. Type" := NewApplToDocType;
        SalesChargeAssignLine."Applies-to Doc. No." := NewApplToDocNo;
        SalesChargeAssignLine."Applies-to Doc. Line No." := NewApplToDocLineNo;
        SalesChargeAssignLine."Unit Cost" := NewSalesLine."Unit Price";
        SalesChargeAssignLine."Item No." := NewItemNo;
        SalesChargeAssignLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ModifySalesChargeAssignLine(NewSalesHeader: Record "Sales Header"; NewLineNo: Integer; NewDistLineNo: Integer; NewQtyToAssign: Decimal)
    var
        SalesChargeAssignLine: Record "Item Charge Assignment (Sales)";
    begin
        SalesChargeAssignLine.Get(NewSalesHeader."Document Type", NewSalesHeader."No.", NewLineNo, NewDistLineNo);
        if NewQtyToAssign <> 0 then
            SalesChargeAssignLine.Validate("Qty. to Assign", NewQtyToAssign);
        SalesChargeAssignLine.Modify(true);
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
        DimSetID: Integer;
        NewDimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
    begin
        PurchHeader.Init();
        PurchHeader.Validate("Document Type", NewDocumentType);
        PurchHeader.Insert(true);
        PurchHeader.Validate("Buy-from Vendor No.", NewBuyFromVendorNo);
        PurchHeader.Validate("Order Date", NewOrderDate);
        PurchHeader.Modify(true);
        DimSetID := PurchHeader."Dimension Set ID";
        NewDimSetID := InsertDocumDim(DimSetID);
        PurchHeader.Validate("Dimension Set ID", NewDimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, ShortcutDimVal1, ShortcutDimVal2);
        PurchHeader.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        PurchHeader.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);
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
    procedure ModifyPurchReturnHeader(var NewPurchHeader: Record "Purchase Header"; NewPostingDate: Date; NewLocationCode: Code[10]; NewVendorCrMemoNo: Code[20])
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
    procedure InsertPurchLine(var NewPurchLine: Record "Purchase Line"; NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewType: Enum "Purchase Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewDirectUnitCost: Decimal)
    var
        PurchLine: Record "Purchase Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
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
        PurchLine.Modify(true);
        DimSetID := PurchLine."Dimension Set ID";
        NewDimSetID := InsertDocumDim(DimSetID);
        PurchLine.Validate("Dimension Set ID", NewDimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, ShortcutDimVal1, ShortcutDimVal2);
        PurchLine.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        PurchLine.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);

        PurchLine.Modify(true);

        NewPurchLine := PurchLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchLine(var NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewQtyToReceive: Decimal; NewQtyToInvoice: Decimal; NewDirectUnitCost: Decimal; NewLineDiscount: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
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
    procedure InsertPurchChargeAssignLine(NewPurchLine: Record "Purchase Line"; NewLineNo: Integer; NewApplToDocType: Enum "Purchase Applies-to Document Type"; NewApplToDocNo: Code[20]; NewApplToDocLineNo: Integer; NewItemNo: Code[20])
    var
        PurchChargeAssignLine: Record "Item Charge Assignment (Purch)";
    begin
        PurchChargeAssignLine.Init();
        PurchChargeAssignLine."Document Type" := NewPurchLine."Document Type";
        PurchChargeAssignLine."Document No." := NewPurchLine."Document No.";
        PurchChargeAssignLine."Document Line No." := NewPurchLine."Line No.";
        PurchChargeAssignLine."Line No." := NewLineNo;
        PurchChargeAssignLine."Item Charge No." := NewPurchLine."No.";
        PurchChargeAssignLine."Applies-to Doc. Type" := NewApplToDocType;
        PurchChargeAssignLine."Applies-to Doc. No." := NewApplToDocNo;
        PurchChargeAssignLine."Applies-to Doc. Line No." := NewApplToDocLineNo;
        PurchChargeAssignLine."Unit Cost" := NewPurchLine."Unit Cost";
        PurchChargeAssignLine."Item No." := NewItemNo;
        PurchChargeAssignLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchChargeAssignLine(NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewDistLineNo: Integer; NewQtyToAssign: Decimal)
    var
        PurchChargeAssignLine: Record "Item Charge Assignment (Purch)";
    begin
        PurchChargeAssignLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo, NewDistLineNo);
        if NewQtyToAssign <> 0 then
            PurchChargeAssignLine.Validate("Qty. to Assign", NewQtyToAssign);
        PurchChargeAssignLine.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertPurchReturnLine(var NewPurchLine: Record "Purchase Line"; NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewType: Enum "Purchase Line Type"; NewNo: Code[20]; NewVariantCode: Code[10]; NewQuantity: Decimal; NewUnitOfMeasureCode: Code[10]; NewDirectUnitCost: Decimal; NewAppToItemEntryNo: Integer)
    var
        PurchLine: Record "Purchase Line";
        DimSetID: Integer;
        NewDimSetID: Integer;
        ShortcutDimVal1: Code[20];
        ShortcutDimVal2: Code[20];
    begin
        PurchLine.Init();
        PurchLine."Document Type" := NewPurchHeader."Document Type";
        PurchLine."Document No." := NewPurchHeader."No.";
        PurchLine."Line No." := NewLineNo;
        PurchLine.Insert(true);
        PurchLine.Validate(Type, NewType);
        PurchLine.Validate("No.", NewNo);
        PurchLine.Validate("Variant Code", NewVariantCode);
        PurchLine.Validate(Quantity, NewQuantity);
        PurchLine.Validate("Unit of Measure Code", NewUnitOfMeasureCode);
        PurchLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        if NewAppToItemEntryNo <> 0 then
            PurchLine.Validate("Appl.-to Item Entry", NewAppToItemEntryNo);
        PurchLine.Modify(true);
        DimSetID := PurchLine."Dimension Set ID";
        NewDimSetID := InsertDocumDim(DimSetID);
        PurchLine.Validate("Dimension Set ID", NewDimSetID);
        DimMgt.UpdateGlobalDimFromDimSetID(NewDimSetID, ShortcutDimVal1, ShortcutDimVal2);
        PurchLine.Validate("Shortcut Dimension 1 Code", ShortcutDimVal1);
        PurchLine.Validate("Shortcut Dimension 2 Code", ShortcutDimVal2);
        PurchLine.Modify(true);

        NewPurchLine := PurchLine;
    end;

    [Scope('OnPrem')]
    procedure ModifyPurchReturnLine(var NewPurchHeader: Record "Purchase Header"; NewLineNo: Integer; NewQtyToReturn: Decimal; NewQtyToInvoice: Decimal)
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.Get(NewPurchHeader."Document Type", NewPurchHeader."No.", NewLineNo);
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
    procedure InsertProdOrder(var NewProdOrder: Record "Production Order"; NewStatus: Enum "Production Order Status"; NewSourceType: Enum "Prod. Order Source Type"; NewSourceNo: Code[20]; NewQuantity: Decimal)
    var
        ProdOrder: Record "Production Order";
        RefreshProdOrder: Report "Refresh Production Order";
    begin
        Clear(NewProdOrder);
        ProdOrder.Init();
        ProdOrder.Validate(Status, NewStatus);
        ProdOrder.Insert(true);
        ProdOrder.Validate("Source Type", NewSourceType);
        ProdOrder.Validate("Source No.", NewSourceNo);
        ProdOrder.Validate(Quantity, NewQuantity);
        ProdOrder.Modify(true);

        ProdOrder.SetRange(Status, ProdOrder.Status);
        ProdOrder.SetRange("No.", ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::Update;
        RefreshProdOrder.SetTableView(ProdOrder);
        RefreshProdOrder.UseRequestPage(false);
        RefreshProdOrder.RunModal();
        NewProdOrder.Get(ProdOrder.Status, ProdOrder."No.");
        Commit();
        CurrentTransactionType := TRANSACTIONTYPE::UpdateNoLocks;
    end;

    [Scope('OnPrem')]
    procedure PostConsumption(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10]; NewLineNo: Integer; NewPostingDate: Date; NewProdOrderNo: Code[20]; NewItemNo: Code[20]; NewQuantity: Decimal; NewAppliesToEntry: Integer)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Journal Template Name", NewJnlTemplName);
        ItemJnlLine.Validate("Journal Batch Name", NewJnlBatchName);
        ItemJnlLine.Validate("Line No.", NewLineNo);
        ItemJnlLine.Validate("Posting Date", NewPostingDate);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", NewProdOrderNo);
        ItemJnlLine.Validate("Item No.", NewItemNo);
        ItemJnlLine.Validate(Quantity, NewQuantity);
        if NewAppliesToEntry <> 0 then
            ItemJnlLine."Applies-from Entry" := NewAppliesToEntry;
        ItemJnlLine.Insert();
        ItemJnlPostBatch.Run(ItemJnlLine);

        ItemJnlDelete(ItemJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostOutput(NewJnlTemplName: Code[10]; NewJnlBatchName: Code[10]; NewLineNo: Integer; NewPostingDate: Date; NewProdOrderNo: Code[20]; NewItemNo: Code[20]; NewOutputQuantity: Decimal)
    var
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
    begin
        ItemJnlLine.Init();
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Journal Template Name", NewJnlTemplName);
        ItemJnlLine.Validate("Journal Batch Name", NewJnlBatchName);
        ItemJnlLine.Validate("Line No.", NewLineNo);
        ItemJnlLine.Validate("Posting Date", NewPostingDate);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", NewProdOrderNo);
        ItemJnlLine.Validate("Item No.", NewItemNo);
        ItemJnlLine.Validate("Output Quantity", NewOutputQuantity);
        ItemJnlLine.Insert();
        ItemJnlPostBatch.Run(ItemJnlLine);

        ItemJnlDelete(ItemJnlLine);
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
    procedure InsertReqInputData(ObjectName: Text[30]; TabName: Text[30]; FieldName: Text[30]; FieldValue: Text[30]; ControlName: Text[30]; ControlType: Text[30]; Shortcut: Text[30])
    var
        ReqInputData: Record "Required Input Data";
    begin
        ReqInputData."Object Name" := ObjectName;
        ReqInputData."Tab Name" := TabName;
        ReqInputData."No." := GetNextNoReqInputData(ReqInputData);
        ReqInputData."Field Name" := FieldName;
        ReqInputData."Field Value" := FieldValue;
        ReqInputData."Control Name" := ControlName;
        ReqInputData."Control Type" := ControlType;
        ReqInputData.Shortcut := Shortcut;
        ReqInputData.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetNextNoReqInputData(ReqInputData: Record "Required Input Data"): Integer
    begin
        ReqInputData.SetRange("Object Name", ReqInputData."Object Name");
        if not ReqInputData.FindLast() then;
        exit(ReqInputData."No." + 1);
    end;

    [Scope('OnPrem')]
    procedure DeleteAllReqInputData()
    var
        ReqInputData: Record "Required Input Data";
    begin
        ReqInputData.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SetGlobalPreconditions()
    var
        SetGlobalPrecond: Codeunit "_Set Global Preconditions";
    begin
        SetGlobalPrecond.SetAutoDeleteOldData();
        SetGlobalPrecond.Run();
    end;

    [Scope('OnPrem')]
    procedure RenameItem(OldItemNo: Code[20]; NewItemNo: Code[20])
    var
        SetGlobalPrecond: Codeunit "_Set Global Preconditions";
    begin
        SetGlobalPrecond.RenameItem(OldItemNo, NewItemNo);
    end;

    [Scope('OnPrem')]
    procedure GetTestResultsPath(): Text[250]
    var
        SetGlobalPrecond: Codeunit "_Set Global Preconditions";
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
        VERecords := NoOfRecords[2];
        VEFields := NoOfFields[2];
        GLERecords := NoOfRecords[3];
        GLEFields := NoOfFields[3];
        IJLRecords := NoOfRecords[4];
        IJLFields := NoOfFields[4];
        LEDRecords := NoOfRecords[5];
        LEDFields := NoOfFields[5];
        ItemRecords := NoOfRecords[7];
        ItemFields := NoOfFields[7];
        SKURecords := NoOfRecords[8];
        SKUFields := NoOfFields[8];
    end;

    [Scope('OnPrem')]
    procedure GetNumbers(var NoOfRecords: array[20] of Integer; var NoOfFields: array[20] of Integer)
    begin
        NoOfRecords[1] := ILERecords;
        NoOfFields[1] := ILEFields;
        NoOfRecords[2] := VERecords;
        NoOfFields[2] := VEFields;
        NoOfRecords[3] := GLERecords;
        NoOfFields[3] := GLEFields;
        NoOfRecords[4] := IJLRecords;
        NoOfFields[4] := IJLFields;
        NoOfRecords[5] := LEDRecords;
        NoOfFields[5] := LEDFields;
        NoOfRecords[7] := ItemRecords;
        NoOfFields[7] := ItemFields;
        NoOfRecords[8] := SKURecords;
        NoOfFields[8] := SKUFields;
    end;

    [Scope('OnPrem')]
    procedure DeleteQATables(ConfirmDelete: Boolean)
    var
        UseCase: Record "Use Case";
        TestCase: Record "Test Case";
        TestscriptResult: Record "_Testscript Result";
        TestIteration: Record "Test Iteration";
        ReqInputData: Record "Required Input Data";
        ItemLedgEntryRef: Record "Item Ledger Entry Ref.";
        ValuEntryRef: Record "Value Entry Ref.";
        GLEntryRef: Record "G/L Entry Ref.";
        ItemJnlLineRef: Record "Item Journal Line Ref.";
        LedgEntryDimRef: Record "Ledger Entry Dim. Ref.";
        ItemRef: Record "Item Ref.";
        SKURef: Record "SKU Ref.";
        QASetup: Record "QA Setup";
    begin
        if ConfirmDelete then
            if not Confirm('You are about to delete the QA tables. Proceed ?', false) then
                exit;

        UseCase.DeleteAll();
        TestCase.DeleteAll();
        TestscriptResult.DeleteAll();
        TestIteration.DeleteAll();
        ReqInputData.DeleteAll();
        ItemLedgEntryRef.DeleteAll();
        ValuEntryRef.DeleteAll();
        GLEntryRef.DeleteAll();
        ItemJnlLineRef.DeleteAll();
        LedgEntryDimRef.DeleteAll();
        ItemRef.DeleteAll();
        SKURef.DeleteAll();
        QASetup.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure SaveRefEntries(UseCaseNo: Integer; TestCaseNo: Integer; IterationNo: Integer)
    var
        InvtSetup: Record "Inventory Setup";
        GLEntry: Record "G/L Entry";
        GLEntryRef: Record "G/L Entry Ref.";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemLedgEntryRef: Record "Item Ledger Entry Ref.";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLineRef: Record "Item Journal Line Ref.";
        ValueEntry: Record "Value Entry";
        ValueEntryRef: Record "Value Entry Ref.";
        Item: Record Item;
        ItemRef: Record "Item Ref.";
        SKU: Record "Stockkeeping Unit";
        SKURef: Record "SKU Ref.";
        ItemCostMgt: Codeunit ItemCostManagement;
        AverageCostLCY: Decimal;
        AverageCostACY: Decimal;
    begin
        GLEntryRef.SetRange("Use Case No.", UseCaseNo);
        GLEntryRef.SetRange("Test Case No.", TestCaseNo);
        if GLEntryRef.FindLast() then;
        GLEntry."Entry No." := GLEntryRef."Entry No.";
        GLEntryRef."Use Case No." := UseCaseNo;
        GLEntryRef."Test Case No." := TestCaseNo;
        GLEntryRef."Iteration No." := IterationNo;
        if GLEntry.Next() <> 0 then
            repeat
                GLEntryRef.TransferFields(GLEntry);
                GLEntryRef.Insert();
                SaveRefEntryDims(UseCaseNo, TestCaseNo, IterationNo, DATABASE::"G/L Entry", GLEntry."Entry No.", GLEntry."Dimension Set ID");
            until GLEntry.Next() = 0;

        ValueEntryRef.SetRange("Use Case No.", UseCaseNo);
        ValueEntryRef.SetRange("Test Case No.", TestCaseNo);
        if ValueEntryRef.FindLast() then;
        ValueEntry."Entry No." := ValueEntryRef."Entry No.";
        ValueEntryRef."Use Case No." := UseCaseNo;
        ValueEntryRef."Test Case No." := TestCaseNo;
        ValueEntryRef."Iteration No." := IterationNo;
        if ValueEntry.Next() <> 0 then
            repeat
                ValueEntryRef.TransferFields(ValueEntry);
                ValueEntryRef.Insert();
                SaveRefEntryDims(UseCaseNo, TestCaseNo, IterationNo, DATABASE::"Value Entry", ValueEntry."Entry No.", ValueEntry."Dimension Set ID"
            );
            until ValueEntry.Next() = 0;

        ItemLedgEntryRef.SetRange("Use Case No.", UseCaseNo);
        ItemLedgEntryRef.SetRange("Test Case No.", TestCaseNo);
        if ItemLedgEntryRef.FindLast() then;
        ItemLedgEntry."Entry No." := ItemLedgEntryRef."Entry No.";
        ItemLedgEntryRef."Use Case No." := UseCaseNo;
        ItemLedgEntryRef."Test Case No." := TestCaseNo;
        ItemLedgEntryRef."Iteration No." := IterationNo;
        if ItemLedgEntry.Next() <> 0 then
            repeat
                ItemLedgEntryRef.TransferFields(ItemLedgEntry);
                ItemLedgEntryRef.Insert();
                SaveRefEntryDims(UseCaseNo, TestCaseNo, IterationNo, DATABASE::"Item Ledger Entry", ItemLedgEntry."Entry No.",
                  ItemLedgEntry."Dimension Set ID");
            until ItemLedgEntry.Next() = 0;

        ItemJnlLineRef.SetRange("Use Case No.", UseCaseNo);
        ItemJnlLineRef.SetRange("Test Case No.", TestCaseNo);
        if ItemJnlLineRef.FindLast() then;
        ItemJnlLine."Line No." := ItemJnlLineRef."Line No.";
        ItemJnlLineRef."Use Case No." := UseCaseNo;
        ItemJnlLineRef."Test Case No." := TestCaseNo;
        ItemJnlLineRef."Iteration No." := IterationNo;
        if ItemJnlLine.Next() <> 0 then
            repeat
                ItemJnlLineRef.TransferFields(ItemJnlLine);
                ItemJnlLineRef.Insert();
                SaveRefEntryDims(UseCaseNo, TestCaseNo, IterationNo, DATABASE::"Item Journal Line", ItemJnlLine."Line No.",
                ItemJnlLine."Dimension Set ID");
            until ItemJnlLine.Next() = 0;

        ItemRef.SetRange("Use Case No.", UseCaseNo);
        ItemRef.SetRange("Test Case No.", TestCaseNo);
        if ItemRef.FindLast() then;
        Item."No." := Item."No.";
        ItemRef."Use Case No." := UseCaseNo;
        ItemRef."Test Case No." := TestCaseNo;
        ItemRef."Iteration No." := IterationNo;
        if Item.Next() <> 0 then
            repeat
                ItemRef.TransferFields(Item);
                ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
                ItemRef."Average Cost (LCY)" := Round(AverageCostLCY, 0.00001);
                ItemRef."Average Cost (ACY)" := Round(AverageCostACY, 0.00001);
                ItemRef.Insert();
            until Item.Next() = 0;

        InvtSetup.Get();
        SKURef.SetRange("Use Case No.", UseCaseNo);
        SKURef.SetRange("Test Case No.", TestCaseNo);
        if SKURef.FindLast() then;
        Item."No." := Item."No.";
        SKURef."Use Case No." := UseCaseNo;
        SKURef."Test Case No." := TestCaseNo;
        SKURef."Iteration No." := IterationNo;
        if SKU.Next() <> 0 then
            repeat
                SKURef.TransferFields(SKU);
                Item.Reset();
                if Item.Get(SKU."Item No.") then begin
                    if InvtSetup."Average Cost Calc. Type" =
                       InvtSetup."Average Cost Calc. Type"::"Item & Location & Variant"
                    then begin
                        Item.SetRange("Location Filter", SKU."Location Code");
                        Item.SetRange("Variant Filter", SKU."Variant Code");
                    end;
                    ItemCostMgt.CalculateAverageCost(Item, AverageCostLCY, AverageCostACY);
                    SKURef."Average Cost (LCY)" := Round(AverageCostLCY, 0.00001);
                    SKURef."Average Cost (ACY)" := Round(AverageCostACY, 0.00001);
                end;
                SKURef.Insert();
            until SKU.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SaveRefEntryDims(UseCaseNo: Integer; TestCaseNo: Integer; IterationNo: Integer; TableID: Integer; EntryNo: Integer; DimSetID: Integer)
    var
        LedgEntryDimRef: Record "Ledger Entry Dim. Ref.";
    begin
        LedgEntryDimRef."Use Case No." := UseCaseNo;
        LedgEntryDimRef."Test Case No." := TestCaseNo;
        LedgEntryDimRef."Iteration No." := IterationNo;
        LedgEntryDimRef."Dimension Set ID" := DimSetID;
        LedgEntryDimRef.Insert();
    end;

    [Scope('OnPrem')]
    procedure AdjustItem(ItemNoFilter: Text[250]; ItemCategoryFilter: Text[250]; OverrideCostPost: Boolean)
    var
        Item: Record Item;
        InvSetup: Record "Inventory Setup";
        InvtAdjmt: Codeunit "Inventory Adjustment";
        PostToGL: Boolean;
    begin
        if ItemNoFilter <> '' then
            Item.SetFilter("No.", ItemNoFilter);
        if ItemCategoryFilter <> '' then
            Item.SetFilter("Item Category Code", ItemCategoryFilter);

        if not OverrideCostPost then begin
            InvSetup.FindFirst();
            PostToGL := InvSetup."Automatic Cost Posting";
        end else
            PostToGL := false;

        Clear(InvtAdjmt);
        InvtAdjmt.SetProperties(false, PostToGL);
        InvtAdjmt.SetFilterItem(Item);
        InvtAdjmt.MakeMultiLevelAdjmt();
    end;

    [Scope('OnPrem')]
    procedure EditDimSet(DimSetID: Integer; DimCode: Code[20]; DimValCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        NewDimSetID: Integer;
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        // Edit existing dimension value for the given dimension on document, document line and journal
        // DimSetID: existing dimension set ID on document, document line and journal
        // Return new Dimension Set ID.

        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);

        DimVal.Get(DimCode, DimValCode);
        TempDimSetEntry.SetRange("Dimension Code", DimVal."Dimension Code");
        TempDimSetEntry.FindFirst();
        TempDimSetEntry.Validate("Dimension Value Code", DimVal.Code);
        TempDimSetEntry.Validate("Dimension Value ID", DimVal."Dimension Value ID");
        TempDimSetEntry.Modify(true);

        //TempDimSetEntry.Reset();
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        exit(NewDimSetID);
    end;

    [Scope('OnPrem')]
    procedure DeleteDimSet(DimSetID: Integer; DimCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        NewDimSetID: Integer;
        DimMgt: Codeunit DimensionManagement;
    begin
        // Delete existing dimension and dimension value on document, document line and journal
        // DimSetID: existing dimension set ID on document, document line and journal
        // Return new Dimension Set ID.

        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);

        TempDimSetEntry.SetRange("Dimension Code", DimCode);
        TempDimSetEntry.FindFirst();
        TempDimSetEntry.Delete(true);

        TempDimSetEntry.Reset();
        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        exit(NewDimSetID);
    end;

    [Scope('OnPrem')]
    procedure CreateDimSet(DimSetID: Integer; DimCode: Code[20]; DimValCode: Code[20]): Integer
    var
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        NewDimSetID: Integer;
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        // Insert new dimension and dimension value on document, document line and journal
        // DimSetID: existing dimension set ID on document, document line and journal
        // Return new Dimension Set ID.

        DimMgt.GetDimensionSet(TempDimSetEntry, DimSetID);
        DimVal.Get(DimCode, DimValCode);

        TempDimSetEntry.Validate("Dimension Code", DimVal."Dimension Code");
        TempDimSetEntry.Validate("Dimension Value Code", DimValCode);
        TempDimSetEntry.Validate("Dimension Value ID", DimVal."Dimension Value ID");
        TempDimSetEntry.Insert(true);

        NewDimSetID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        TempDimSetEntry.DeleteAll();
        exit(NewDimSetID);
    end;
}

