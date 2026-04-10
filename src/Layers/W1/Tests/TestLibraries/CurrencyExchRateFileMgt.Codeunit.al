codeunit 134273 "Currency Exch. Rate File Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        DummyCurrExchRate: Record "Currency Exchange Rate";
        BlobKey: Integer;
        W3OrgTxt: Label 'http://www.w3.org/2001/XMLSchema-instance', Locked = true;
        IsFirstLine: Boolean;

    [Scope('OnPrem')]
    procedure WriteDanishXMLHeader(var OutStream: OutStream; CurrencyCode: Code[10]; RelationalExchangeRate: Decimal)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="ISO-8859-1"?>');
        WriteLine(
          OutStream,
          StrSubstNo(
            '<exchangerates type="Exhange rates" author="Danmarks Nationalbank" refcur="%1" refamt="%2" xmlns:xsi="%3">',
            CurrencyCode, RelationalExchangeRate, W3OrgTxt));
    end;

    [Scope('OnPrem')]
    procedure WriteDanishXMLExchHeader(var OutStream: OutStream; Date: Date)
    begin
        WriteLine(OutStream, StrSubstNo('  <dailyrates id="%1">', Format(Date, 0, 9)));
    end;

    [Scope('OnPrem')]
    procedure WriteDanishXMLExchLine(var OutStream: OutStream; "Code": Code[10]; Name: Text; Rate: Decimal; CommaNumber: Boolean)
    var
        RateText: Text;
    begin
        if Rate = 0 then
            WriteLine(OutStream, StrSubstNo('    <currency code="%1" desc="%2" rate="-" />', Code, Name))
        else begin
            RateText := Format(Rate, 0, 9);
            if CommaNumber then
                RateText := ConvertStr(RateText, '.', ',');

            WriteLine(OutStream, StrSubstNo('    <currency code="%1" desc="%2" rate="%3" />', Code, Name, RateText));
        end;
    end;

    [Scope('OnPrem')]
    procedure WriteDanishXMLExchFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '  </dailyrates>');
    end;

    [Scope('OnPrem')]
    procedure WriteDanishXMLFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '</exchangerates>');
    end;

    [Scope('OnPrem')]
    procedure WriteDanishJsonHeader(var OutStream: OutStream; CurrencyCode: Code[10]; RelationalExchangeRate: Decimal)
    begin
        WriteLine(OutStream, '{');
        WriteLine(OutStream, '  "exchangerates" :');
        WriteLine(OutStream, '  {');
        WriteLine(OutStream, '    "@type" : "Exhange rates",');
        WriteLine(OutStream, '    "@author" : "Danmarks Nationalbank",');
        WriteLine(OutStream, StrSubstNo('    "@refcur" : "%1",', CurrencyCode));
        WriteLine(OutStream, StrSubstNo('    "@refamt" : "%1",', RelationalExchangeRate));
        WriteLine(OutStream, '    "@xmlns:xsi"  : "http://www.w3.org/2001/XMLSchema-instance",');
        IsFirstLine := true;
    end;

    [Scope('OnPrem')]
    procedure WriteDanishJsonExchHeader(var OutStream: OutStream; Date: Date)
    begin
        WriteLine(OutStream, '    "dailyrates" :');
        WriteLine(OutStream, '    {');
        WriteLine(OutStream, StrSubstNo('      "@id" : "%1",', Format(Date, 0, 9)));
        WriteLine(OutStream, '      "currency" :');
        WriteLine(OutStream, '      [');
    end;

    [Scope('OnPrem')]
    procedure WriteDanishJsonExchLine(var OutStream: OutStream; "Code": Code[10]; Name: Text; Rate: Decimal)
    begin
        if not IsFirstLine then
            WriteLine(OutStream, StrSubstNo('    ,'))
        else
            IsFirstLine := false;

        if Rate = 0 then
            WriteLine(
              OutStream,
              StrSubstNo('    { "@code" : "%1", "@desc" : "%2", "@rate" : "-" }', Code, Name))
        else
            WriteLine(
              OutStream,
              StrSubstNo('    { "@code" : "%1", "@desc" : "%2", "@rate" : "%3" }', Code, Name, Format(Rate, 0, 9)));
    end;

    [Scope('OnPrem')]
    procedure WriteDanishJsonExchFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '      ]');
        WriteLine(OutStream, '    }');
        IsFirstLine := true;
    end;

    [Scope('OnPrem')]
    procedure WriteDanishJsonFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '  }');
        WriteLine(OutStream, '}');
    end;

    [Scope('OnPrem')]
    procedure WriteXE_XMLHeader(var OutStream: OutStream; CurrencyCode: Code[10]; Date: Date)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="ISO-8859-1"?>');

        WriteLine(OutStream, '<!DOCTYPE xe-datafeed [');
        WriteLine(OutStream, '<!ELEMENT xe-datafeed (header*,currency*)>');
        WriteLine(OutStream, '<!ELEMENT header (hname,hvalue)>');
        WriteLine(OutStream, '<!ELEMENT hname (#PCDATA)>');
        WriteLine(OutStream, '<!ELEMENT hvalue (#PCDATA)>');
        WriteLine(OutStream, '<!ELEMENT currency (csymbol,cname,crate,cinverse)>');
        WriteLine(OutStream, '<!ELEMENT csymbol (#PCDATA)>');
        WriteLine(OutStream, '<!ELEMENT cname (#PCDATA)>');
        WriteLine(OutStream, '<!ELEMENT crate (#PCDATA)>');
        WriteLine(OutStream, '<!ELEMENT cinverse (#PCDATA)>');
        WriteLine(OutStream, ']>');

        WriteLine(OutStream, '<xe-datafeed>');
        WriteLine(OutStream, '<header><hname>Version</hname><hvalue>2.45</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Status</hname><hvalue>OK</hvalue></header>');

        WriteLine(OutStream, StrSubstNo('<header><hname>Current UTC Time</hname><hvalue>%1</hvalue></header>', Format(Date, 0, 9)));
        WriteLine(OutStream, '<header><hname>Licensed Company</hname><hvalue>ABC Corporation</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Designated Contact</hname><hvalue>John Doe</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Contact E-Mail</hname><hvalue>jdoe@abc-corporation.com</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Feed Expires on</hname><hvalue>March 2 2013</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Days Remaining</hname><hvalue>128</hvalue></header>');
        WriteLine(OutStream, '<header><hname>UTC Time of Your Next Update</hname><hvalue>2012.10.25 15:41:29</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Seconds Until Your Next Update</hname><hvalue>19111</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Rate Format</hname><hvalue>XML</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Rate Type</hname><hvalue>DAILY</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Permitted accesses per week</hname><hvalue>9</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Accesses so far this week</hname><hvalue>1</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Accesses remaining in this week</hname><hvalue>8</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Days until new access period begins</hname><hvalue>7</hvalue></header>');
        WriteLine(OutStream, '<header><hname>UTC Timestamp</hname><hvalue>2012.10.24 21:00:00</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Local Timezone</hname><hvalue>America/New_York</hvalue></header>');
        WriteLine(OutStream, '<header><hname>Local Timestamp</hname><hvalue>2012.10.24 17:00:00</hvalue></header>');
        WriteLine(OutStream, StrSubstNo('<header><hname>Base Currency</hname><hvalue>%1</hvalue></header>', CurrencyCode));
    end;

    [Scope('OnPrem')]
    procedure WriteXE_XMLExchLine(var OutStream: OutStream; "Code": Code[10]; Name: Text; Rate: Decimal; InverseRate: Decimal)
    begin
        WriteLine(
          OutStream,
          StrSubstNo(
            '    <currency><csymbol>%1</csymbol><cname>%2</cname><crate>%3</crate><cinverse>%4</cinverse></currency>',
            Code,
            Name,
            Format(Rate, 0, 9),
            Format(InverseRate, 0, 9)));
    end;

    [Scope('OnPrem')]
    procedure WriteXE_XMLFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '</xe-datafeed>');
    end;

    [Scope('OnPrem')]
    procedure WriteCanadianXMLHeader(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(OutStream, '<Currency xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">');
    end;

    [Scope('OnPrem')]
    procedure WriteCanadianXMLExchLine(var OutStream: OutStream; "Code": Code[10]; Name: Text; Rate: Decimal; InverseRate: Decimal; Date: Date)
    begin
        WriteLine(OutStream, '    <Observation>');
        WriteLine(OutStream, StrSubstNo('      <Currency_name>%1</Currency_name>', Name));
        WriteLine(OutStream, StrSubstNo('      <Observation_ISO4217>%1</Observation_ISO4217>', Code));
        WriteLine(OutStream, StrSubstNo('      <Observation_date>%1</Observation_date>', Format(Date, 0, 9)));
        WriteLine(OutStream, StrSubstNo('      <Observation_data>%1</Observation_data>', Format(Rate, 0, 9)));
        WriteLine(OutStream, StrSubstNo('      <Observation_data_reciprocal>%1</Observation_data_reciprocal>', Format(InverseRate, 0, 9)));
        WriteLine(OutStream, '</Observation>');
    end;

    [Scope('OnPrem')]
    procedure WriteCanadianXMLFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '</Currency>');
    end;

    [Scope('OnPrem')]
    procedure WriteECB_XMLHeader(var OutStream: OutStream; Date: Date)
    begin
        WriteLine(OutStream, '<?xml version="1.0" encoding="UTF-8"?>');
        WriteLine(
          OutStream,
          StrSubstNo(
            '<gesmes:Envelope xmlns:gesmes="%1" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">',
            'http://www.gesmes.org/xml/2002-08-01'));

        WriteLine(OutStream, '<gesmes:subject>Reference rates</gesmes:subject>');
        WriteLine(OutStream, '<gesmes:Sender>');
        WriteLine(OutStream, '  <gesmes:name>European Central Bank</gesmes:name>');
        WriteLine(OutStream, '</gesmes:Sender>');

        WriteLine(OutStream, '<Cube>');

        WriteLine(OutStream, StrSubstNo('  <Cube time=''%1''>', Format(Date, 0, 9)));
    end;

    [Scope('OnPrem')]
    procedure WriteECB_XMLExchLine(var OutStream: OutStream; "Code": Code[10]; Rate: Decimal)
    begin
        WriteLine(OutStream, StrSubstNo('      <Cube currency=''%2'' rate=''%1'' />', Format(Rate, 0, 9), Code));
    end;

    [Scope('OnPrem')]
    procedure WriteECB_XMLFooter(var OutStream: OutStream)
    begin
        WriteLine(OutStream, '  </Cube>');
        WriteLine(OutStream, '</Cube>');

        WriteLine(OutStream, '</gesmes:Envelope>');
    end;

    [Scope('OnPrem')]
    procedure SetupSourceMock(DataExchDefCode: Code[20]; var TempBlob: Codeunit "Temp Blob")
    var
        DataExchDef: Record "Data Exch. Def";
        ErmPeSourceTestMock: Codeunit "ERM PE Source Test Mock";
        TempBlobList: Codeunit "Temp Blob List";
    begin
        TempBlobList.Set(BlobKey, TempBlob);
        ErmPeSourceTestMock.SetTempBlobList(TempBlobList);
        BlobKey += 1;

        DataExchDef.Get(DataExchDefCode);
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"ERM PE Source Test Mock";
        DataExchDef.Modify();
    end;

    local procedure WriteLine(OutStream: OutStream; Text: Text)
    begin
        OutStream.WriteText(Text);
        OutStream.WriteText();
    end;

    [Scope('OnPrem')]
    procedure GetRelationalExhangeRate(): Decimal
    begin
        exit(1);
    end;

    [Scope('OnPrem')]
    procedure GetExchangeRateDate(): Date
    begin
        exit(Today)
    end;

    [Scope('OnPrem')]
    procedure GetDataExchDefCode(): Code[20]
    begin
        exit('CURRENCY');
    end;

    [Scope('OnPrem')]
    procedure GetDataExchLineDefCode(): Code[20]
    begin
        exit('NATIONALBANKEN');
    end;

    [Scope('OnPrem')]
    procedure GetReadingWritingCodeunit(): Integer
    begin
        exit(CODEUNIT::"Import XML File to Data Exch.");
    end;

    [Scope('OnPrem')]
    procedure GetYahooRepeaterPath(): Text[250]
    begin
        exit('/query/results/rate');
    end;

    [Scope('OnPrem')]
    procedure GetECBRepeaterPath(): Text[250]
    begin
        exit('/gesmes:Envelope/Cube/Cube/Cube');
    end;

    [Scope('OnPrem')]
    procedure GetDanishRepeaterPath(): Text[250]
    begin
        exit('/exchangerates/dailyrates/currency');
    end;

    [Scope('OnPrem')]
    procedure GetXE_RepeaterPath(): Text[250]
    begin
        exit('/xe-datafeed/currency');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianRepeaterPath(): Text[250]
    begin
        exit('/Currency/Observation');
    end;

    [Scope('OnPrem')]
    procedure GetMappingTable(): Integer
    begin
        exit(DATABASE::"Currency Exchange Rate")
    end;

    [Scope('OnPrem')]
    procedure GetMappingCodeunit(): Integer
    begin
        exit(CODEUNIT::"Map Currency Exchange Rate")
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        exit('DKK');
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCodeXMLElement(): Text[250]
    begin
        exit('code');
    end;

    [Scope('OnPrem')]
    procedure GetRelationalExchRateXMLElement(): Text[250]
    begin
        exit('refamt');
    end;

    [Scope('OnPrem')]
    procedure GetExchRateXMLElement(): Text[250]
    begin
        exit('rate');
    end;

    [Scope('OnPrem')]
    procedure GetAdjmtRelationalExchRateXMLElement(): Text[250]
    begin
        exit('rate');
    end;

    [Scope('OnPrem')]
    procedure GetAdjmtExchRateXMLElement(): Text[250]
    begin
        exit('refamt');
    end;

    [Scope('OnPrem')]
    procedure GetStartingDateXMLElement(): Text[250]
    begin
        exit('id');
    end;

    [Scope('OnPrem')]
    procedure GetXE_CurrencyCodeXMLElement(): Text[250]
    begin
        exit('csymbol');
    end;

    [Scope('OnPrem')]
    procedure GetXE_RelationalExchRateXMLElement(): Text[250]
    begin
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetXE_ExchRateXMLElement(): Text[250]
    begin
        exit('crate');
    end;

    [Scope('OnPrem')]
    procedure GetXE_AdjmtRelationalExchRateXMLElement(): Text[250]
    begin
        exit('crate');
    end;

    [Scope('OnPrem')]
    procedure GetXE_AdjmtExchRateXMLElement(): Text[250]
    begin
        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetXE_StartingDateXMLElement(): Text[250]
    begin
        exit('hvalue');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianCurrencyCodeXMLElement(): Text[250]
    begin
        exit('Observation_ISO4217');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianRelationalExchRateXMLElement(): Text[250]
    begin
        exit('Observation_data_reciprocal');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianExchRateXMLElement(): Text[250]
    begin
        exit('Observation_data');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianAdjmtRelationalExchRateXMLElement(): Text[250]
    begin
        exit('Observation_data');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianAdjmtExchRateXMLElement(): Text[250]
    begin
        exit('Observation_data_reciprocal');
    end;

    [Scope('OnPrem')]
    procedure GetCanadianStartingDateXMLElement(): Text[250]
    begin
        exit('Observation_date');
    end;

    [Scope('OnPrem')]
    procedure GetCurrencyCodeFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Currency Code"));
    end;

    [Scope('OnPrem')]
    procedure GetRelationalExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Relational Exch. Rate Amount"));
    end;

    [Scope('OnPrem')]
    procedure GetExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Exchange Rate Amount"));
    end;

    [Scope('OnPrem')]
    procedure GetAdjmtRelationalExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Relational Adjmt Exch Rate Amt"));
    end;

    [Scope('OnPrem')]
    procedure GetAdjmtExchRateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Adjustment Exch. Rate Amount"));
    end;

    [Scope('OnPrem')]
    procedure GetStartingDateFieldNo(): Integer
    begin
        exit(DummyCurrExchRate.FieldNo("Starting Date"));
    end;
}

