codeunit 139191 "RS Table Info Telemetry Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
        // [FEATURE] [Rapid Start]
    end;

    [Test]
    procedure PaymentTerms_TwoRecords_TenFields()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        TableNode: DotNet XmlNode;
        SampleTableRecordRef: RecordRef;
        CurrTableName: Text;
        CurrRecordCount: Integer;
        TotalTableFields: Integer;
        ImportedTableFields: Integer;
    begin
        // [Given] Sample RapidStart package containing 2 Payment Terms records with 8 fields each
        SampleTableRecordRef.Open(Database::"Payment Terms");
        GetSamplRSXmlNode(SampleTableRecordRef.Name, TableNode);

        // [When] Table statistics is obtaibed from the XML node.
        ConfigXMLExchange.GetTableStatisticsForTelemetry(TableNode, CurrTableName, CurrRecordCount, TotalTableFields, ImportedTableFields);

        // [Then] All the values correspond to data in sample XML.
        Assert.AreEqual(SampleTableRecordRef.Name, CurrTableName, 'The same table name expected.');
        Assert.AreEqual(2, CurrRecordCount, 'Expected to identify 2 imported records.');
        Assert.AreEqual(SampleTableRecordRef.FieldCount(), TotalTableFields, 'A different number of fields expected.');
        Assert.AreEqual(8, ImportedTableFields, 'Expected to identify 8 fields to be imported.');

        SampleTableRecordRef.Close();
    end;

    [Test]
    procedure Currency_ZeroRecords_ZeroFields()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        TableNode: DotNet XmlNode;
        SampleTableRecordRef: RecordRef;
        CurrTableName: Text;
        CurrRecordCount: Integer;
        TotalTableFields: Integer;
        ImportedTableFields: Integer;
    begin
        // [Given] Sample RapidStart package containing a Currency table, but with no records
        SampleTableRecordRef.Open(Database::"Currency");
        GetSamplRSXmlNode(SampleTableRecordRef.Name, TableNode);

        // [When] Table statistics is obtaibed from the XML node.
        ConfigXMLExchange.GetTableStatisticsForTelemetry(TableNode, CurrTableName, CurrRecordCount, TotalTableFields, ImportedTableFields);

        // [Then] All the values correspond to data in sample XML.
        Assert.AreEqual(SampleTableRecordRef.Name, CurrTableName, 'The same table name expected.');
        Assert.AreEqual(0, CurrRecordCount, 'Expected to identify 0 imported records.');
        Assert.AreEqual(SampleTableRecordRef.FieldCount(), TotalTableFields, 'A different number of fields expected.');
        Assert.AreEqual(0, ImportedTableFields, 'Expected to identify 0 fields to be imported.');

        SampleTableRecordRef.Close();
    end;

    [Test]
    procedure FinanceChargeTerms_OneRecord_FifteenFields()
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        TableNode: DotNet XmlNode;
        SampleTableRecordRef: RecordRef;
        CurrTableName: Text;
        CurrRecordCount: Integer;
        TotalTableFields: Integer;
        ImportedTableFields: Integer;
    begin
        // [Given] Sample RapidStart package containing 1 Payment Terms records with 15 fields
        SampleTableRecordRef.Open(Database::"Finance Charge Terms");
        GetSamplRSXmlNode(SampleTableRecordRef.Name, TableNode);

        // [When] Table statistics is obtaibed from the XML node.
        ConfigXMLExchange.GetTableStatisticsForTelemetry(TableNode, CurrTableName, CurrRecordCount, TotalTableFields, ImportedTableFields);

        // [Then] All the values correspond to data in sample XML.
        Assert.AreEqual(SampleTableRecordRef.Name, CurrTableName, 'The same table name expected.');
        Assert.AreEqual(1, CurrRecordCount, 'Expected to identify 1 imported records.');
        Assert.AreEqual(SampleTableRecordRef.FieldCount(), TotalTableFields, 'A different number of fields expected.');
        Assert.AreEqual(15, ImportedTableFields, 'Expected to identify 15 fields to be imported.');

        SampleTableRecordRef.Close();
    end;

    local procedure GetSamplRSXmlNode(NodeName: Text; var Node: DotNet XmlNode)
    var
        ConfigXMLExchange: Codeunit "Config. XML Exchange";
        XMLDoc: DotNet XmlDocument;
        DocXmlNode: DotNet XmlNode;
    begin
        XMLDoc := XMLDoc.XmlDocument();
        XMLDoc.LoadXml(GetSampleRapidStartXML());
        DocXmlNode := XMLDoc.DocumentElement();

        foreach Node in DocXmlNode.ChildNodes() do
            if Node.Name.Contains(ConfigXMLExchange.GetElementName(NodeName)) then
                break;
    end;

    local procedure GetSampleRapidStartXML(): Text
    begin
        exit(
        '<?xml version="1.0" encoding="UTF-16" standalone="yes"?>' +
        '<DataList MinCountForAsyncImport="5" ExcludeConfigTables="1" LanguageID="1033" ProductVersion="NAV16.0" PackageName="Microsoft Dynamics 365 Business Central" Code="W1.ENU.EXTENDED">' +
            '<PaymentTermsList>' +
                '<TableID>3</TableID>' +
                '<SkipTableTriggers>1</SkipTableTriggers>' +
                '<PaymentTerms>' +
                    '<Code PrimaryKey="1" ProcessingOrder="1">10 DAYS</Code>' +
                    '<DueDateCalculation ProcessingOrder="2">&lt;10D&gt;</DueDateCalculation>' +
                    '<DiscountDateCalculation ProcessingOrder="3">' +
                    '</DiscountDateCalculation>' +
                    '<Discount ProcessingOrder="4">0</Discount>' +
                    '<Description ProcessingOrder="5">Net 10 days</Description>' +
                    '<CalcPmtDisconCrMemos ProcessingOrder="6">0</CalcPmtDisconCrMemos>' +
                    '<LastModifiedDateTime ProcessingOrder="7">' +
                    '</LastModifiedDateTime>' +
                    '<Id ProcessingOrder="8">{F57A9BBE-1251-EA11-BB30-00155DF3A615}</Id>' +
                '</PaymentTerms>' +
                '<PaymentTerms>' +
                    '<Code>14 DAYS</Code>' +
                    '<DueDateCalculation>&lt;14D&gt;</DueDateCalculation>' +
                    '<DiscountDateCalculation>' +
                    '</DiscountDateCalculation>' +
                    '<Discount>0</Discount>' +
                    '<Description>Net 14 days</Description>' +
                    '<CalcPmtDisconCrMemos>0</CalcPmtDisconCrMemos>' +
                    '<LastModifiedDateTime>' +
                    '</LastModifiedDateTime>' +
                    '<Id>{ED7A9BBE-1251-EA11-BB30-00155DF3A615}</Id>' +
                '</PaymentTerms>' +
            '</PaymentTermsList>' +
            '<CurrencyList>' +
                '<TableID>4</TableID>' +
                '<DimensionsasColumns>1</DimensionsasColumns>' +
            '</CurrencyList>' +
            '<FinanceChargeTermsList>' +
                '<TableID>5</TableID>' +
                '<FinanceChargeTerms>' +
                    '<Code PrimaryKey="1" ProcessingOrder="1">1.5 DOM.</Code>' +
                    '<InterestRate ProcessingOrder="2">1.5</InterestRate>' +
                    '<MinimumAmountLCY ProcessingOrder="3">10</MinimumAmountLCY>' +
                    '<AdditionalFeeLCY ProcessingOrder="4">10</AdditionalFeeLCY>' +
                    '<Description ProcessingOrder="5">1.5 % for Domestic Customers</Description>' +
                    '<InterestCalculationMethod ProcessingOrder="6">0</InterestCalculationMethod>' +
                    '<InterestPeriodDays ProcessingOrder="7">30</InterestPeriodDays>' +
                    '<GracePeriod ProcessingOrder="8">&lt;5D&gt;</GracePeriod>' +
                    '<DueDateCalculation ProcessingOrder="9">&lt;1M&gt;</DueDateCalculation>' +
                    '<InterestCalculation ProcessingOrder="10">0</InterestCalculation>' +
                    '<PostInterest ProcessingOrder="11">1</PostInterest>' +
                    '<PostAdditionalFee ProcessingOrder="12">1</PostAdditionalFee>' +
                    '<LineDescription ProcessingOrder="13">%4% finance charge of %6</LineDescription>' +
                    '<AddLineFeeinInterest ProcessingOrder="14">0</AddLineFeeinInterest>' +
                    '<DetailedLinesDescription ProcessingOrder="15">Sum finance charge of %5</DetailedLinesDescription>' +
                '</FinanceChargeTerms>' +
            '</FinanceChargeTermsList>' +
        '</DataList>'
        )
    end;
}
