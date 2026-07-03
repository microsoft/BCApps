table 137093 "Asm. Availability Test Buffer"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Document No."; Code[20])
        {
        }
        field(3; "Document Line No."; Integer)
        {
        }
        field(4; "Item No."; Code[20])
        {
        }
        field(5; "Variant Code"; Code[10])
        {
        }
        field(6; "Location Code"; Code[10])
        {
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
        }
        field(8; "Quantity Per"; Decimal)
        {
            AutoFormatType = 0;
        }
        field(9; Quantity; Decimal)
        {
            AutoFormatType = 0;
        }
        field(10; Inventory; Decimal)
        {
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Inventory Is Set" := true;
            end;
        }
        field(11; "Gross Requirement"; Decimal)
        {
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Gross Requirement is Set" := true;
            end;
        }
        field(13; "Scheduled Receipts"; Decimal)
        {
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Scheduled Receipts is Set" := true;
            end;
        }
        field(14; "Expected Inventory"; Decimal)
        {
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Expected Inventory is Set" := true;
            end;
        }
        field(18; "Able To Assemble"; Decimal)
        {
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                "Able To Assemble is Set" := true;
            end;
        }
        field(19; "Earliest Availability Date"; Date)
        {

            trigger OnValidate()
            begin
                "Earliest Avail. Date is Set" := true;
            end;
        }
        field(20; "Inventory Is Set"; Boolean)
        {
        }
        field(21; "Gross Requirement is Set"; Boolean)
        {
        }
        field(23; "Scheduled Receipts is Set"; Boolean)
        {
        }
        field(24; "Expected Inventory is Set"; Boolean)
        {
        }
        field(28; "Able To Assemble is Set"; Boolean)
        {
        }
        field(29; "Earliest Avail. Date is Set"; Boolean)
        {
        }
        field(30; Description; Text[100])
        {
        }
    }

    keys
    {
        key(Key1; "Document No.", "Document Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Assert: Codeunit Assert;
        WrongValueInHeaderErr: Label 'Wrong %1 in the header on the availability page.';
        WrongValueInLineErr: Label 'Wrong %1 in the line no. %2 on the availability page.';

    [Scope('OnPrem')]
    procedure ReadDataFromPage(var AsmAvailability: TestPage "Assembly Availability")
    begin
        Reset();
        DeleteAll();

        Init();
        ReadHeaderFromPage(AsmAvailability);
        Insert();

        if AsmAvailability.AssemblyLineAvail.First() then
            repeat
                Init();
                ReadLineFromPage(AsmAvailability);
                Insert();
            until not AsmAvailability.AssemblyLineAvail.Next();
    end;

    local procedure ReadHeaderFromPage(var AsmAvailability: TestPage "Assembly Availability")
    begin
        "Document No." := AsmAvailability."No.".Value();
        "Document Line No." := 0;
        "Item No." := AsmAvailability."Item No.".Value();
        "Variant Code" := AsmAvailability."Variant Code".Value();
        "Location Code" := AsmAvailability."Location Code".Value();
        "Unit of Measure Code" := AsmAvailability."Unit of Measure Code".Value();
        Description := AsmAvailability.Description.Value();
        Quantity := AsmAvailability."Current Quantity".AsDecimal();
        Inventory := AsmAvailability.Inventory.AsDecimal();
        "Gross Requirement" := AsmAvailability.GrossRequirement.AsDecimal();
        "Scheduled Receipts" := AsmAvailability.ScheduledReceipts.AsDecimal();
        "Able To Assemble" := AsmAvailability.AbleToAssemble.AsDecimal();
        Evaluate("Earliest Availability Date", AsmAvailability.EarliestAvailableDate.Value);
    end;

    local procedure ReadLineFromPage(var AsmAvailability: TestPage "Assembly Availability")
    begin
        "Document No." := AsmAvailability."No.".Value();
        "Document Line No." += 1;
        "Item No." := AsmAvailability.AssemblyLineAvail."No.".Value();
        "Variant Code" := AsmAvailability.AssemblyLineAvail."Variant Code".Value();
        "Location Code" := AsmAvailability.AssemblyLineAvail."Location Code".Value();
        "Unit of Measure Code" := AsmAvailability.AssemblyLineAvail."Unit of Measure Code".Value();
        "Quantity Per" := AsmAvailability.AssemblyLineAvail."Quantity per".AsDecimal();
        Quantity := AsmAvailability.AssemblyLineAvail.CurrentQuantity.AsDecimal();
        "Gross Requirement" := AsmAvailability.AssemblyLineAvail.GrossRequirement.AsDecimal();
        "Scheduled Receipts" := AsmAvailability.AssemblyLineAvail.ScheduledReceipt.AsDecimal();
        "Expected Inventory" := AsmAvailability.AssemblyLineAvail.ExpectedAvailableInventory.AsDecimal();
        "Able To Assemble" := AsmAvailability.AssemblyLineAvail.AbleToAssemble.AsDecimal();
        Evaluate("Earliest Availability Date", AsmAvailability.AssemblyLineAvail.EarliestAvailableDate.Value);
    end;

    [Scope('OnPrem')]
    procedure VerifyHeader(AssemblyHeader: Record "Assembly Header"; ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer")
    begin
        Get(AssemblyHeader."No.", 0);
        VerifyCalcData(ExpAsmAvailTestBuf);
    end;

    [Scope('OnPrem')]
    procedure VerifyHeaderStatic(AssemblyHeader: Record "Assembly Header")
    begin
        Get(AssemblyHeader."No.", 0);

        Assert.AreEqual(AssemblyHeader."Item No.", "Item No.", StrSubstNo(WrongValueInHeaderErr, FieldName("Item No.")));
        Assert.AreEqual(AssemblyHeader."Variant Code", "Variant Code", StrSubstNo(WrongValueInHeaderErr, FieldName("Variant Code")));
        Assert.AreEqual(AssemblyHeader."Location Code", "Location Code", StrSubstNo(WrongValueInHeaderErr, FieldName("Location Code")));
        Assert.AreEqual(
          AssemblyHeader."Unit of Measure Code", "Unit of Measure Code",
          StrSubstNo(WrongValueInHeaderErr, FieldName("Unit of Measure Code")));
        Assert.AreEqual(AssemblyHeader.Description, Description, StrSubstNo(WrongValueInHeaderErr, FieldName(Description)));
        Assert.AreNearlyEqual(
          AssemblyHeader.Quantity - AssemblyHeader."Assembled Quantity", Quantity, 0.0001,
          StrSubstNo(WrongValueInHeaderErr, FieldName(Quantity)));
    end;

    [Scope('OnPrem')]
    procedure VerifyLine(AssemblyLine: Record "Assembly Line"; ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer")
    begin
        Get(AssemblyLine."Document No.", ExpAsmAvailTestBuf."Document Line No.");
        VerifyCalcData(ExpAsmAvailTestBuf);
    end;

    [Scope('OnPrem')]
    procedure VerifyLineStatic(AssemblyLine: Record "Assembly Line"; LineNo: Integer)
    begin
        Get(AssemblyLine."Document No.", LineNo);

        Assert.AreEqual(AssemblyLine."No.", "Item No.", StrSubstNo(WrongValueInLineErr, FieldName("Item No."), LineNo));
        Assert.AreEqual(
          AssemblyLine."Quantity per", "Quantity Per", StrSubstNo(WrongValueInLineErr, FieldName("Quantity Per"), LineNo));
        Assert.AreEqual(
          AssemblyLine."Unit of Measure Code", "Unit of Measure Code",
          StrSubstNo(WrongValueInLineErr, FieldName("Quantity Per"), LineNo));
        Assert.AreEqual(
          AssemblyLine."Location Code", "Location Code",
          StrSubstNo(WrongValueInLineErr, FieldName("Location Code"), LineNo));
        Assert.AreEqual(
          AssemblyLine."Variant Code", "Variant Code",
          StrSubstNo(WrongValueInLineErr, FieldName("Variant Code"), LineNo));
    end;

    [Scope('OnPrem')]
    procedure VerifyCalcData(ExpAsmAvailTestBuf: Record "Asm. Availability Test Buffer")
    var
        Err: Text;
    begin
        if ExpAsmAvailTestBuf."Document Line No." = 0 then
            Err := WrongValueInHeaderErr
        else
            Err := StrSubstNo(WrongValueInLineErr, '%1', ExpAsmAvailTestBuf."Document Line No.");

        if ExpAsmAvailTestBuf."Inventory Is Set" then
            Assert.AreEqual(ExpAsmAvailTestBuf.Inventory, Inventory, StrSubstNo(Err, FieldName(Inventory)));
        if ExpAsmAvailTestBuf."Gross Requirement is Set" then
            Assert.AreEqual(
              ExpAsmAvailTestBuf."Gross Requirement", "Gross Requirement",
              StrSubstNo(Err, FieldName("Gross Requirement")));
        if ExpAsmAvailTestBuf."Scheduled Receipts is Set" then
            Assert.AreEqual(
              ExpAsmAvailTestBuf."Scheduled Receipts", "Scheduled Receipts",
              StrSubstNo(Err, FieldName("Scheduled Receipts")));
        if ExpAsmAvailTestBuf."Expected Inventory is Set" then
            Assert.AreNearlyEqual(
              ExpAsmAvailTestBuf."Expected Inventory", "Expected Inventory", 0.0001,
              StrSubstNo(Err, FieldName("Expected Inventory")));
        if ExpAsmAvailTestBuf."Able To Assemble is Set" then
            Assert.AreNearlyEqual(
              ExpAsmAvailTestBuf."Able To Assemble", "Able To Assemble", 0.0001,
              StrSubstNo(Err, FieldName("Able To Assemble")));
        if ExpAsmAvailTestBuf."Earliest Avail. Date is Set" then
            Assert.AreEqual(
              ExpAsmAvailTestBuf."Earliest Availability Date", "Earliest Availability Date",
              StrSubstNo(Err, FieldName("Earliest Availability Date")));
    end;
}
