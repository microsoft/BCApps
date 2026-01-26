codeunit 144128 "DocumentTools Codeunit UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Banking] [UT]
    end;

    var
        DocumentTools: Codeunit DocumentTools;
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroNoPrint()
    var
        PrintGiro: Boolean;
        DocumentType: Integer;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        GiroAmount: Decimal;
        GiroCurrencyCode: Code[10];
        GiroAmountKr: Text[20];
        GiroAmountkre: Text[2];
        CheckDigit: Text[1];
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        // [SCENARIO] Method SetupGiro if PrintGiro = FALSE

        // Setup
        PrintGiro := false;
        DocumentType := 1;
        DocumentNo := '';
        CustomerNo := '';
        GiroAmount := 0;
        GiroCurrencyCode := '';

        // Execute
        DocumentTools.SetupGiro(
          PrintGiro, DocumentType, DocumentNo, CustomerNo, GiroAmount, GiroCurrencyCode,
          GiroAmountKr, GiroAmountkre, CheckDigit, GiroKID, KIDError);

        // Verify
        Assert.AreEqual('***', GiroAmountKr, 'GiroAmountKr not set correctly.');
        Assert.AreEqual('**', GiroAmountkre, 'GiroAmountkre not set correctly.');
        Assert.AreEqual(' ', CheckDigit, 'CheckDigit not set correctly.');
        Assert.AreEqual('', GiroKID, 'GiroKID not set correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroNoGiroCurrency()
    var
        PrintGiro: Boolean;
        DocumentType: Integer;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        GiroAmount: Decimal;
        GiroCurrencyCode: Code[10];
        GiroAmountKr: Text[20];
        GiroAmountkre: Text[2];
        CheckDigit: Text[1];
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        // [SCENARIO] Method SetupGiro if PrintGiro = TRUE, GiroCurrencyCode <> ''

        // Setup
        PrintGiro := true;
        DocumentType := 1;
        DocumentNo := '';
        CustomerNo := '';
        GiroAmount := 0;
        GiroCurrencyCode := 'NON-EMPTY'; // Any value.

        // Execute
        DocumentTools.SetupGiro(
          PrintGiro, DocumentType, DocumentNo, CustomerNo, GiroAmount, GiroCurrencyCode,
          GiroAmountKr, GiroAmountkre, CheckDigit, GiroKID, KIDError);

        // [THEN] Currency is not support and GiroAmount output values should be blanked out.
        Assert.AreEqual('', GiroAmountKr, 'GiroAmountKr not set correctly.');
        Assert.AreEqual('', GiroAmountkre, 'GiroAmountkre not set correctly.');
        Assert.AreEqual(' ', CheckDigit, 'CheckDigit not set correctly.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroCheckGiroAmountValues()
    begin
        // [SCENARIO] Method SetupGiro if PrintGiro = TRUE and GiroCurrencyCode = ''
        // [THEN] GiroAmountKr is returned as string value of Integer part of GiroAmount
        // [THEN] GiroAmountkre is returned as 0-padded (2 digits) of decimal part of GiroAmount
        // [THEN] CheckDigit is then Modulus10() of the concatenation of GiroAmountKr + GiroAmountkre
        SetupGiroCheckGiroAndVerifyAmountValues(10.0);  // Check for GiroAmount = '00'
        SetupGiroCheckGiroAndVerifyAmountValues(10.01); // Check for GiroAmount = '01'
        SetupGiroCheckGiroAndVerifyAmountValues(10.1);  // Check for GiroAmount = '10'
        SetupGiroCheckGiroAndVerifyAmountValues(LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroKIDNotUsed()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID]
        // [SCENARIO] validate Method SetupGiro if PrintGiro = TRUE and GiroCurrencyCode = '' and SalesSetup."KID Setup" = "Dot not use"

        // Setup
        SalesSetup.Get();
        SalesSetup."KID Setup" := SalesSetup."KID Setup"::"Do not use";
        SalesSetup.Modify();

        // Execute and Verify (for the 3 different document types - product also reference by number. Sigh.)
        SetupGiroAndVerifyGiroKID(1, '', '', '');
        SetupGiroAndVerifyGiroKID(2, '', '', '');
        SetupGiroAndVerifyGiroKID(3, '', '', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroKIDConfiguration()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
        ExpectedGiroKID: Code[25];
    begin
        // [FEATURE] [KID]
        // [SCENARIO] Method SetupGiro generates GiroKID for different combinations of setup and document-types.

        // Setup
        DocumentNo := '12345'; // Any number as a string.
        ExpectedGiroKID := Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length")) +
          DocumentTools.Modulus10(DocumentNo); // Calculated GiroKID

        SalesSetup.Get();
        SalesSetup."KID Setup" := SalesSetup."KID Setup"::"Document No.";
        SalesSetup."Use KID on Fin. Charge Memo" := false;     // DocumentType = 2 in the SetupGiro()
        SalesSetup."Use KID on Reminder" := false;             // DocumentType = 3 in the SetupGiro()
        SalesSetup.Modify();

        // Execute and Verify (for the 3 different document types - product also reference by number. Sigh.)
        SetupGiroAndVerifyGiroKID(1, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(2, DocumentNo, '', '');
        SetupGiroAndVerifyGiroKID(3, DocumentNo, '', '');

        // Setup
        SalesSetup."Use KID on Fin. Charge Memo" := true;      // DocumentType = 2 in the SetupGiro()
        SalesSetup."Use KID on Reminder" := false;             // DocumentType = 3 in the SetupGiro()
        SalesSetup.Modify();

        // Execute and Verify (for the 3 different document types - product also reference by number. Sigh.)
        SetupGiroAndVerifyGiroKID(1, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(2, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(3, DocumentNo, '', '');

        // Setup
        SalesSetup."Use KID on Fin. Charge Memo" := false;     // DocumentType = 2 in the SetupGiro()
        SalesSetup."Use KID on Reminder" := true;              // DocumentType = 3 in the SetupGiro()
        SalesSetup.Modify();

        // Execute and Verify (for the 3 different document types - product also reference by number. Sigh.)
        SetupGiroAndVerifyGiroKID(1, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(2, DocumentNo, '', '');
        SetupGiroAndVerifyGiroKID(3, DocumentNo, '', ExpectedGiroKID);

        // Setup
        SalesSetup."Use KID on Fin. Charge Memo" := true;      // DocumentType = 2 in the SetupGiro()
        SalesSetup."Use KID on Reminder" := true;              // DocumentType = 3 in the SetupGiro()
        SalesSetup.Modify();

        // Execute and Verify (for the 3 different document types - product also reference by number. Sigh.)
        SetupGiroAndVerifyGiroKID(1, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(2, DocumentNo, '', ExpectedGiroKID);
        SetupGiroAndVerifyGiroKID(3, DocumentNo, '', ExpectedGiroKID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetupGiroKIDSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [KID]
        // [SCENARIO] Method SetupGiro geneartes different GiroKID formats correctly based on the setup.

        // Setup
        DocumentNo := '12345'; // Any number as a string.
        CustomerNo := '67890'; // Any number as a string.

        SalesSetup.Get();
        SalesSetup."KID Setup" := SalesSetup."KID Setup"::"Document No.";
        SalesSetup."Document No. length" := LibraryRandom.RandIntInRange(5, 10); // GreaterThan/Equal to STRLEN(DocumentNo).
        SalesSetup."Customer No. length" := LibraryRandom.RandIntInRange(5, 10); // GreaterThan/Equal to STRLEN(CustomerNo).
        SalesSetup.Modify();

        // Execute and Verify
        SetupKIDExecuteSetupGiroAndVerifyGiroKID(
          SalesSetup."KID Setup"::"Document No.",
          1, DocumentNo, CustomerNo,
          AddModulus(Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length"))));

        SetupKIDExecuteSetupGiroAndVerifyGiroKID(
          SalesSetup."KID Setup"::"Document No.+Customer No.",
          1, DocumentNo, CustomerNo,
          AddModulus(
            Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length")) +
            Format(CustomerNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Customer No. length"))));

        SetupKIDExecuteSetupGiroAndVerifyGiroKID(
          SalesSetup."KID Setup"::"Customer No.+Document No.",
          1, DocumentNo, CustomerNo,
          AddModulus(
            Format(CustomerNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Customer No. length")) +
            Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length"))));

        SetupKIDExecuteSetupGiroAndVerifyGiroKID(
          SalesSetup."KID Setup"::"Document Type+Document No.",
          1, DocumentNo, CustomerNo,
          AddModulus(
            Format(1) + // DocumentType
            Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length"))));

        SetupKIDExecuteSetupGiroAndVerifyGiroKID(
          SalesSetup."KID Setup"::"Document No.+Document Type",
          1, DocumentNo, CustomerNo,
          AddModulus(
            Format(DocumentNo, 0, StrSubstNo('<text,%1><Filler,0>', SalesSetup."Document No. length")) +
            Format(1))); // DocumentType
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestKIDSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [KID]
        // [SCENARIO] Method TestKIDSetup validates that the Setup is done correctly.
        // [SCENARIO] If you are generating GiroKID on Reminders or on Fin Charge Memos you must include DocumentType in the GiroKID.

        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Do not use", false, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Do not use", true, false, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Do not use", false, true, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Do not use", true, true, true);

        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.", false, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.", true, false, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.", false, true, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.", true, true, true);

        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Customer No.", false, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Customer No.", true, false, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Customer No.", false, true, true);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Customer No.", true, true, true);

        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document Type+Document No.", false, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document Type+Document No.", true, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document Type+Document No.", false, true, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document Type+Document No.", true, true, false);

        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Document Type", false, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Document Type", true, false, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Document Type", false, true, false);
        SetupKIDAndVerifyTestKIDSetup(SalesSetup."KID Setup"::"Document No.+Document Type", true, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Modulus10()
    begin
        // [SCENARIO] validate Method Modulus10
        // [WHEN] The Modulus10 algorithm is:
        // [THEN] 1. Prefix with '0' to length 24 and postfixes with a single '0'
        // [THEN] 2. multiplies every other digit by 2, strchecksum it and assign it back to the same position
        // [THEN] 3. before doing a StrCheckSum() with weight '1' on all digits and modulus 10.

        // The expected value is grabbed from the implementation
        VerifyModulus10('1', '8');
        VerifyModulus10('01', '8');
        VerifyModulus10('10', '9');
        VerifyModulus10('6', '7');
    end;

    local procedure SetupGiroCheckGiroAndVerifyAmountValues(GiroAmount: Decimal)
    var
        PrintGiro: Boolean;
        DocumentType: Integer;
        DocumentNo: Code[20];
        CustomerNo: Code[20];
        GiroCurrencyCode: Code[10];
        GiroAmountKr: Text[20];
        GiroAmountkre: Text[2];
        CheckDigit: Text[1];
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        // Setup
        PrintGiro := true;
        DocumentType := 1;
        DocumentNo := '';
        CustomerNo := '';
        GiroCurrencyCode := '';

        // Execute
        DocumentTools.SetupGiro(
          PrintGiro, DocumentType, DocumentNo, CustomerNo, GiroAmount, GiroCurrencyCode,
          GiroAmountKr, GiroAmountkre, CheckDigit, GiroKID, KIDError);

        // Verify
        Assert.AreEqual(
          Format(Round(GiroAmount, 1, '<')),
          GiroAmountKr,
          'GiroAmountKr not assigned correctly');
        Assert.AreEqual(
          Format((GiroAmount - Round(GiroAmount, 1, '<')) * 100, 0, '<Integer,2><Filler,0>'),
          GiroAmountkre,
          'GiroAmountkre not assigned correctly');
        Assert.AreEqual(
          DocumentTools.Modulus10(GiroAmountKr + GiroAmountkre),
          CheckDigit,
          'CheckDigit not assigned correctly');
    end;

    [Normal]
    local procedure SetupKIDExecuteSetupGiroAndVerifyGiroKID(KIDSetup: Option "Do not use","Document No.","Document No.+Customer No.","Customer No.+Document No.","Document Type+Document No.","Document No.+Document Type"; DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; ExpectedGiroKID: Text[25])
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."KID Setup" := KIDSetup;
        SalesSetup.Modify();

        SetupGiroAndVerifyGiroKID(DocumentType, DocumentNo, CustomerNo, ExpectedGiroKID);
    end;

    [Normal]
    local procedure SetupGiroAndVerifyGiroKID(DocumentType: Integer; DocumentNo: Code[20]; CustomerNo: Code[20]; ExpectedGiroKID: Text[25])
    var
        PrintGiro: Boolean;
        GiroAmount: Decimal;
        GiroCurrencyCode: Code[10];
        GiroAmountKr: Text[20];
        GiroAmountkre: Text[2];
        CheckDigit: Text[1];
        GiroKID: Text[25];
        KIDError: Boolean;
    begin
        // Setup
        PrintGiro := true;
        GiroAmount := LibraryRandom.RandDec(10, 2);
        GiroCurrencyCode := '';
        GiroKID := 'INITVALUE'; // Just set to a dummy string to make sure that it is assigned in SetupGiro.

        // Execute
        DocumentTools.SetupGiro(
          PrintGiro, DocumentType, DocumentNo, CustomerNo, GiroAmount, GiroCurrencyCode,
          GiroAmountKr, GiroAmountkre, CheckDigit, GiroKID, KIDError);

        // Verify
        Assert.AreEqual(ExpectedGiroKID, GiroKID, 'GiroKID has wrong value.')
    end;

    [Normal]
    local procedure SetupKIDAndVerifyTestKIDSetup(KIDSetup: Option "Do not use","Document No.","Document No.+Customer No.","Customer No.+Document No.","Document Type+Document No.","Document No.+Document Type"; UseOnReminder: Boolean; UseOnFinChargeMemo: Boolean; ShouldFail: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // [SCENARIO] validate Method TestKIDSetup
        // The method validates that the Setup is done correctly. If you
        // are generating GiroKID on Reminders or on Fin Charge Memos you must include
        // DocumentType in the GiroKID.

        // Setup
        SalesSetup.Init();
        SalesSetup."KID Setup" := KIDSetup;
        SalesSetup."Use KID on Fin. Charge Memo" := UseOnFinChargeMemo;
        SalesSetup."Use KID on Reminder" := UseOnReminder;

        // Execute
        if not ShouldFail then
            DocumentTools.TestKIDSetup(SalesSetup)
        else
            asserterror DocumentTools.TestKIDSetup(SalesSetup);
    end;

    [Normal]
    local procedure VerifyModulus10(KIDText: Text[25]; ExpectedModulus10: Text[1])
    var
        Modulus10: Text[1];
    begin
        // [SCENARIO] validate Method Modulus10
        // The Modulus10 algorithm is:
        // 1. Prefix with '0' to length 24 and postfixes with a single '0'
        // 2. multiplies every other digit by 2, strchecksum it and assign it back to the same position
        // 3. before doing a StrCheckSum() with weight '1' on all digits and modulus 10.

        // Execute
        Modulus10 := DocumentTools.Modulus10(KIDText);

        // Verify
        Assert.AreEqual(ExpectedModulus10, Modulus10, 'Modulus10(''' + KIDText + ''') result is wrong');
    end;

    [Normal]
    local procedure AddModulus(Value: Text[24]): Text[25]
    begin
        exit(Value + DocumentTools.Modulus10(Value));
    end;
}

