codeunit 132583 "Amount Auto Format Test"
{
    SingleInstance = true;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit Assert;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestAutoFormatCase1()
    var
        AmountAutoFormatPage: Page "Amount Auto Format Test Page";
        AmountAutoFormatTestPage: TestPage "Amount Auto Format Test Page";
    begin
        // [GIVEN] A page with fields with AutoFormatType=1
        // [GIVEN] The Amount Decimal Places from the table "General Ledger Setup"
        // [GIVEN] The Amount Decimal Places from the table "Currency"
        InitializeGLSetup('1:2', '1:1', '€', 'EUR');
        InitializeCurrency('0:0', '3:4', '$', 'USD');

        AmountAutoFormatPage.InitializeExpression('case_1');
        AmountAutoFormatPage.setAutoFormatExpressionCase1('', 'InvalidCurrency', 'USD');
        AmountAutoFormatTestPage.Trap();
        AmountAutoFormatPage.Run();

        // [WHEN] AutoFormatExpression = ''
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case1GLSetup1.SetValue(1234);
        // [THEN] The inserted value is formatted using the Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('1,234.0', AmountAutoFormatTestPage.Case1GLSetup1.Value, 'The return value should be "1,234.0"');

        // [WHEN] AutoFormatExpression = 'InvalidCurrency'
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case1GLSetup2.SetValue(1234.012);
        // [THEN] The inserted value is formatted using the Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('1,234.01', AmountAutoFormatTestPage.Case1GLSetup2.Value, 'The return value should be "1,234.01"');

        // [WHEN] AutoFormatExpression = 'USD'
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case1Currency.SetValue(1234.56789);
        // [THEN] The inserted value is formatted using the Amount Decimal Places from the table "Currency"
        LibraryAssert.AreEqual('1,235', AmountAutoFormatTestPage.Case1Currency.Value, 'The return value should be "1,235"');

        AmountAutoFormatTestPage.Close();
        AmountAutoFormatPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestAutoFormatCase2()
    var
        AmountAutoFormatPage: Page "Amount Auto Format Test Page";
        AmountAutoFormatTestPage: TestPage "Amount Auto Format Test Page";
    begin
        // [GIVEN] A page with fields with AutoFormatType=2
        // [GIVEN] The Unit-Amount Decimal Places from the table "General Ledger Setup"
        // [GIVEN] The Unit-Amount Decimal Places from the table "Currency"
        InitializeGLSetup('3:3', '4:5', '£', 'GBP');
        InitializeCurrency('1:1', '2:2', '€', 'EUR');

        AmountAutoFormatPage.InitializeExpression('case_2');
        AmountAutoFormatPage.setAutoFormatExpressionCase2('', 'InvalidCurrency', 'EUR');
        AmountAutoFormatTestPage.Trap();
        AmountAutoFormatPage.Run();

        // [WHEN] AutoFormatExpression = ''
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case2GLSetup1.SetValue(15);
        // [THEN] The inserted value is formatted using the Unit-Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('15.0000', AmountAutoFormatTestPage.Case2GLSetup1.Value, 'The return value should be "15.0000"');

        // [WHEN] AutoFormatExpression = 'InvalidCurrency'
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case2GLSetup2.SetValue(15.0123456);
        // [THEN] The inserted value is formatted using the Unit-Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('15.01235', AmountAutoFormatTestPage.Case2GLSetup2.Value, 'The return value should be "15.01235"');

        // [WHEN] AutoFormatExpression = 'EUR'
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case2Currency.SetValue(15.56);
        // [THEN] The inserted value is formatted using the Unit-Amount Decimal Places from the table "Currency"
        LibraryAssert.AreEqual('15.56', AmountAutoFormatTestPage.Case2Currency.Value, 'The return value should be "15.56"');

        AmountAutoFormatTestPage.Close();
        AmountAutoFormatPage.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestAutoFormatCase10()
    begin
        // [GIVEN] A page with fields with AutoFormatType=10
        // [GIVEN] The Amount Decimal Places and the Unit-Amount Decimal Places from the table "General Ledger Setup"
        // [GIVEN] The Amount Decimal Places and the Unit-Amount Decimal Places from the table "Currency"
        InitializeGLSetup('1:1', '2:2', '€', 'EUR');
        InitializeCurrency('3:3', '0:1', '$', 'USD');

        // [GIVEN] A test table with the values to format
        // In this case the values need to be in a table because they are declared as Decimal but they will be converted in text if
        // there are symbols (e.g: $) in the final formatted result
        InitializeTestTable();

        TestCaseNoSubtype();
        TestCaseSubtype1();
        TestCaseSubtype2();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestReadRounding()
    var
        AutoFormat: Codeunit "Auto Format";
    begin
        // [GIVEN] The Amount Rounding Precision value from the table "General Ledger Setup"
        InitializeGLSetup('2:2', '3:3', '€', 'EUR');

        // [WHEN] The procedure ReadRounding is called
        // [THEN] The Rounding Precision value is returned
        LibraryAssert.AreEqual(0.00001, AutoFormat.ReadRounding(), 'The return value should be "0.00001"');
    end;

    local procedure TestCaseNoSubtype()
    var
        AmountAutoFormatPage: Page "Amount Auto Format Test Page";
        AmountAutoFormatTestPage: TestPage "Amount Auto Format Test Page";
    begin
        AmountAutoFormatPage.InitializeExpression('case_10_NoSubtype');
        AmountAutoFormatPage.setAutoFormatExpressionCase10('<Precision,0:0><Standard Format,0>', '', '', '', '');
        AmountAutoFormatTestPage.Trap();
        AmountAutoFormatPage.Run();

        // [WHEN] AutoFormatExpression doesn't match any FormatSubtype
        // [WHEN] A value is inserted in the field
        AmountAutoFormatTestPage.Case10NoFormatSubtype.SetValue(34.4903);
        // [THEN] The inserted value is formatted using the provided AutoFormatExpression ('<Precision,0:0><Standard Format,0>' in this case)
        LibraryAssert.AreEqual('34', AmountAutoFormatTestPage.Case10NoFormatSubtype.Value, 'The return value should be "34"');

        AmountAutoFormatTestPage.Close();
        AmountAutoFormatPage.Close();
    end;

    local procedure TestCaseSubtype1()
    var
        AmountAutoFormatPage: Page "Amount Auto Format Test Page";
        AmountAutoFormatTestPage: TestPage "Amount Auto Format Test Page";
    begin
        AmountAutoFormatPage.InitializeExpression('case_10_1');
        AmountAutoFormatPage.setAutoFormatExpressionCase10('', '1', '1,InvalidCurrency,Prefix', '1,USD', '1,USD,Prefix');
        AmountAutoFormatTestPage.Trap();
        AmountAutoFormatPage.Run();

        // [WHEN] AutoFormatExpression = '1'
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using the Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('€ 34.6', AmountAutoFormatTestPage.Case10GLSetup1.Value, 'The return value should be "€ 34.6"');

        // [WHEN] AutoFormatExpression = '1,InvalidCurrency,Prefix';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Amount Decimal Places from the table "General Ledger Setup", the given Prefix and the default currency symbol
        LibraryAssert.AreEqual('Prefix € 37.0', AmountAutoFormatTestPage.Case10GLSetup2.Value, 'The return value should be "Prefix € 37.0"');

        // [WHEN] AutoFormatExpression = '1,USD';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Amount Decimal Places from the table "Currency" and the currency associated to the 3 letter code
        LibraryAssert.AreEqual('$ 144.490', AmountAutoFormatTestPage.Case10Currency1.Value, 'The return value should be "$ 144.490"');

        // [WHEN] AutoFormatExpression = '1,USD,Prefix';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Amount Decimal Places from the table "Currency", the given Prefix and the currency associated to the 3 letter code
        LibraryAssert.AreEqual('Prefix $ 320.400', AmountAutoFormatTestPage.Case10Currency2.Value, 'The return value should be "Prefix $ 320.400"');

        AmountAutoFormatTestPage.Close();
        AmountAutoFormatPage.Close();
    end;

    local procedure TestCaseSubtype2()
    var
        AmountAutoFormatPage: Page "Amount Auto Format Test Page";
        AmountAutoFormatTestPage: TestPage "Amount Auto Format Test Page";
    begin
        AmountAutoFormatPage.InitializeExpression('case_10_2');
        AmountAutoFormatPage.setAutoFormatExpressionCase10('', '2', '2,InvalidCurrency,Prefix', '2,USD', '2,USD,Prefix');
        AmountAutoFormatTestPage.Trap();
        AmountAutoFormatPage.Run();

        // [WHEN] AutoFormatExpression = '2'
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using the Unit-Amount Decimal Places from the table "General Ledger Setup"
        LibraryAssert.AreEqual('€ 34.56', AmountAutoFormatTestPage.Case10GLSetup1.Value, 'The return value should be "€ 34.56"');

        // [WHEN] AutoFormatExpression = '2,InvalidCurrency,Prefix';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Unit-Amount Decimal Places from the table "General Ledger Setup", the given Prefix and the default currency symbol
        LibraryAssert.AreEqual('Prefix € 37.00', AmountAutoFormatTestPage.Case10GLSetup2.Value, 'The return value should be "Prefix € 37.00"');

        // [WHEN] AutoFormatExpression = '2,USD';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Unit-Amount Decimal Places from the table "Currency" and the currency associated to the 3 letter code
        LibraryAssert.AreEqual('$ 144.5', AmountAutoFormatTestPage.Case10Currency1.Value, 'The return value should be "$ 144.5"');

        // [WHEN] AutoFormatExpression = '2,USD,Prefix';
        // [WHEN] A value is inserted in the field from the table when the page loads
        // [THEN] The inserted value is formatted using Unit-Amount Decimal Places from the table "Currency", the given Prefix and the currency associated to the 3 letter code
        LibraryAssert.AreEqual('Prefix $ 320.4', AmountAutoFormatTestPage.Case10Currency2.Value, 'The return value should be "Prefix $ 320.4"');

        AmountAutoFormatTestPage.Close();
        AmountAutoFormatPage.Close();
    end;

    local procedure InitializeGLSetup(DecimalPlaces: Text[5]; UnitDecimalPlaces: Text[5]; CurrencySymbol: Text[1]; LCYCode: Text[3])
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.DeleteAll();
        GLSetup."Amount Decimal Places" := DecimalPlaces;
        GLSetup."Unit-Amount Decimal Places" := UnitDecimalPlaces;
        GLSetup."Local Currency Symbol" := CurrencySymbol;
        GLSetup."LCY Code" := LCYCode;
        GLSetup."Amount Rounding Precision" := 0.00001;
        GLSetup."Show Currency" := enum::"Show Currency"::Never;
        GLSetup."Currency Symbol Position" := enum::"Currency Symbol Position"::"Before Amount";
        GLSetup.Insert(true);
    end;

    local procedure InitializeCurrency(DecimalPlaces: Text[5]; UnitDecimalPlaces: Text[5]; CurrencySymbol: Text[1]; CurrencyCode: Text[3])
    var
        Currency: Record "Currency";
    begin
        Currency.DeleteAll();
        Currency."Code" := CurrencyCode;
        Currency."Amount Decimal Places" := DecimalPlaces;
        Currency."Unit-Amount Decimal Places" := UnitDecimalPlaces;
        Currency."Symbol" := CurrencySymbol;
        Currency."Currency Symbol Position" := enum::"Currency Symbol Position"::"Before Amount";
        Currency.Insert(true);
    end;

    local procedure InitializeTestTable()
    var
        AutoFormatTestTable: Record "Amount Auto Format Test Table";
    begin
        AutoFormatTestTable.DeleteAll();
        AutoFormatTestTable.Case10GLSetup1 := 34.56;
        AutoFormatTestTable.Case10GLSetup2 := 37;
        AutoFormatTestTable.Case10Currency1 := 144.490367;
        AutoFormatTestTable.Case10Currency2 := 320.4;
        AutoFormatTestTable.Insert();
    end;
}