#pragma warning disable AA0247
report 14900 "Import Currency Exch. Rate"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Import Currency Exch. Rate';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem(Date; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Date));

            trigger OnAfterGetRecord()
            begin
                DaysCounter += 1;
                Window.Update(1, Format("Period Start"));
                Window.Update(2, Round(DaysCounter / ProcessingDaysQty * 10000, 1));

                LoadXML("Period Start", XMLRootNode, DateLoaded, false);
                if DateLoaded <> "Period Start" then
                    CurrReport.Skip();

                ImportExchRates();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Period Start", StartDate, EndDate);

                ProcessingDaysQty := EndDate - StartDate + 1;
                Window.Open(Text000);
            end;
        }
        dataitem(MonthlyRates; Date)
        {
            DataItemTableView = sorting("Period Type", "Period Start") where("Period Type" = const(Month));

            trigger OnAfterGetRecord()
            begin
                MonthesCounter += 1;
                Window.Update(1, Format("Period Start"));
                Window.Update(3, Round(MonthesCounter / ProcessingMonthesQty * 10000, 1));

                LoadXML("Period Start", XMLRootNode, DateLoaded, true);

                ImportExchRates();
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Period Start", CalcDate('<-CM>', StartDate), EndDate);

                ProcessingMonthesQty := Count;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'End Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            StartDate := Today;
            EndDate := Today;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if StartDate = 0D then
            Error(Text008);

        if EndDate = 0D then
            Error(Text009);

        if EndDate < StartDate then
            Error(Text007);
    end;

    var
        Currency: Record Currency;
        CompanyInformation: Record "Company Information";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Company: Record Company;
        XMLRootNode: DotNet XmlNode;
        Window: Dialog;
        StartDate: Date;
        EndDate: Date;
        DateLoaded: Date;
        ExchRateAmount: Decimal;
        RelationalExchRateAmount: Decimal;
        ProcessingDaysQty: Integer;
        DaysCounter: Integer;
        ProcessingMonthesQty: Integer;
        MonthesCounter: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Importing Currency Exchange Rates #1######\Daily Exchange Rates    @2@@@@@@@@@@@@@@@@\Monthly Exchange Rates  @3@@@@@@@@@@@@@@@@';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text002: Label 'Unexpected XML structure.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'Unable to find %1 attribute.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text005: Label 'Unexpected %1 attribute format.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label 'Unexpected %1 node value.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text007: Label 'Start Date cannot be greater than End Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text008: Label 'You must specify the Start Date.';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text009: Label 'You must specify the End Date.';
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure LoadXML(DateReq: Date; var XMLNode: DotNet XmlNode; var DateLoaded: Date; MonthlyRates: Boolean)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLNamedNodeMap: DotNet XmlNamedNodeMap;
        XMLNodeDate: DotNet XmlNode;
        MonthlyURLAppendix: Text[30];
    begin
        if MonthlyRates then
            MonthlyURLAppendix := '&d=1';

        XMLDOMManagement.LoadXMLNodeFromUri(
          'http://www.cbr.ru/scripts/XML_daily.asp?date_req=' + Format(DateReq, 0, '<Day,2>.<Month,2>.<Year4>') + MonthlyURLAppendix,
          XMLNode);

        if XMLNode.Name <> 'ValCurs' then
            Error(Text002);

        XMLNamedNodeMap := XMLNode.Attributes;
        XMLNodeDate := XMLNamedNodeMap.GetNamedItem('Date');
        if IsNull(XMLNodeDate) then
            Error(Text004, 'Date');

        if not EvaluateDate(DateLoaded, Format(XMLNodeDate.Value)) then
            Error(Text005, 'Date');
    end;

    [Scope('OnPrem')]
    procedure GetExchRateParameters(CurrencyCode: Code[10]; var ExchRateAmount: Decimal; var RelationalExchRateAmount: Decimal; var XMLNode: DotNet XmlNode): Boolean
    var
        XMLNodeList: DotNet XmlNodeList;
        XMLNodeExchRate: DotNet XmlNode;
        XMLNodeCurrencyCode: DotNet XmlNode;
        XMLNodeExchRateAmount: DotNet XmlNode;
        XMLNodeRelExchRateAmount: DotNet XmlNode;
        i: Integer;
    begin
        XMLNodeList := XMLNode.ChildNodes;
        if not IsNull(XMLNodeList) then
            for i := 0 to XMLNodeList.Count - 1 do begin
                XMLNodeExchRate := XMLNodeList.Item(i);
                if FindNode(XMLNodeExchRate, 'CharCode', XMLNodeCurrencyCode) then
                    if Format(XMLNodeCurrencyCode.InnerText) = CurrencyCode then begin
                        if FindNode(XMLNodeExchRate, 'Nominal', XMLNodeExchRateAmount) then
                            if not Evaluate(ExchRateAmount,
                                 ConvertToXMLFormat(Format(XMLNodeExchRateAmount.InnerText)), 9) then
                                Error(Text006, 'Nominal');

                        if FindNode(XMLNodeExchRate, 'Value', XMLNodeRelExchRateAmount) then
                            if not Evaluate(RelationalExchRateAmount,
                                 ConvertToXMLFormat(Format(XMLNodeRelExchRateAmount.InnerText)), 9) then
                                Error(Text006, 'Value');
                        exit(true);
                    end;
            end;

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure ConvertToXMLFormat(Str: Text[1024]): Text[1024]
    begin
        exit(ConvertStr(Str, ',', '.'));
    end;

    [Scope('OnPrem')]
    procedure FindNode(var XMLRootNode: DotNet XmlNode; NodePath: Text[250]; var FoundXMLNode: DotNet XmlNode): Boolean
    begin
        if IsNull(XMLRootNode) then
            exit(false);

        FoundXMLNode := XMLRootNode.SelectSingleNode(NodePath);

        if IsNull(FoundXMLNode) then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure EvaluateDate(var DateLoaded: Date; Str: Text[30]): Boolean
    var
        Day: Integer;
        Month: Integer;
        Year: Integer;
    begin
        if not Evaluate(Day, CopyStr(Str, 1, 2)) then
            exit(false);

        if not Evaluate(Month, CopyStr(Str, 4, 2)) then
            exit(false);

        if not Evaluate(Year, CopyStr(Str, 7)) then
            exit(false);

        DateLoaded := DMY2Date(Day, Month, Year);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure ImportExchRates()
    begin
        if Company.FindSet() then
            repeat
                CompanyInformation.ChangeCompany(Company.Name);
                CompanyInformation.Get();
                if CompanyInformation."Import Curr. Exch. Rates" then begin
                    Currency.ChangeCompany(Company.Name);
                    Currency.SetRange(Import, true);
                    if Currency.FindSet() then
                        repeat
                            Currency.TestField("RU Bank Code");

                            if GetExchRateParameters(Currency."RU Bank Code", ExchRateAmount, RelationalExchRateAmount, XMLRootNode) then begin
                                CurrencyExchangeRate.ChangeCompany(Company.Name);
                                if not CurrencyExchangeRate.Get(Currency.Code, DateLoaded) then begin
                                    CurrencyExchangeRate.Init();
                                    CurrencyExchangeRate."Currency Code" := Currency.Code;
                                    CurrencyExchangeRate."Starting Date" := DateLoaded;
                                    CurrencyExchangeRate."Exchange Rate Amount" := ExchRateAmount;
                                    CurrencyExchangeRate."Adjustment Exch. Rate Amount" := ExchRateAmount;
                                    CurrencyExchangeRate."Relational Exch. Rate Amount" := RelationalExchRateAmount;
                                    CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := RelationalExchRateAmount;
                                    CurrencyExchangeRate.Insert();
                                end else
                                    if CompanyInformation.IsNeedToReplaceCurrExchRate(Currency.Code, DateLoaded, Company.Name) then begin
                                        CurrencyExchangeRate."Exchange Rate Amount" := ExchRateAmount;
                                        CurrencyExchangeRate."Adjustment Exch. Rate Amount" := ExchRateAmount;
                                        CurrencyExchangeRate."Relational Exch. Rate Amount" := RelationalExchRateAmount;
                                        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := RelationalExchRateAmount;
                                        CurrencyExchangeRate.Modify();
                                    end;
                            end;
                        until Currency.Next() = 0;
                end;
            until Company.Next() = 0;
    end;
}

