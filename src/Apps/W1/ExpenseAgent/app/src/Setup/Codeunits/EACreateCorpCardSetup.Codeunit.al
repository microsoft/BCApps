namespace Microsoft.ExpenseAgent;

using System.IO;

codeunit 7232 "EA Create Corp Card Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Expense Agent Setup" = rim,
        tabledata "Expense User" = r,
        tabledata "Data Exch. Def" = rimd,
        tabledata "Data Exch. Line Def" = rimd,
        tabledata "Data Exch. Column Def" = rimd,
        tabledata "Data Exch. Mapping" = rimd,
        tabledata "Data Exch. Field Mapping" = rimd,
        tabledata "EA Corp Card" = rimd,
        tabledata "EA Corp Card Provider" = rimd;

    trigger OnRun()
    begin
        CreateDefaults();
    end;

    internal procedure CreateDefaults()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardMCCMgt: Codeunit "EA Corp Card MCC Mgt";
    begin
        EnsureCorpCardProviders();

        CorpCardProvider.SetFilter(Code, '%1|%2|%3|%4|%5', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok, CorpCardIsoProviderCodeTok, CorpCardCamt053ProviderCodeTok, CorpCardCamt054ProviderCodeTok);
        if CorpCardProvider.FindSet() then
            repeat
                EnsureDataExchangeForProvider(CorpCardProvider);
                EnsureDefaultCorpCardLinks(CorpCardProvider.Code);
            until CorpCardProvider.Next() = 0;

        EnsureCorpCardSetup();
        CorpCardMCCMgt.InitializeDefaultMCCMappings();
    end;

    internal procedure EnsureDataExchangeForProvider(var CorpCardProvider: Record "EA Corp Card Provider")
    var
        IsXmlDefinition: Boolean;
        IsManagedDefaultProvider: Boolean;
    begin
        EnsureProviderDefaults(CorpCardProvider);
        IsXmlDefinition := IsXmlDefinitionCode(CorpCardProvider."Data Exch Def Code") or IsXmlFeedType(CorpCardProvider."Feed Type");
        IsManagedDefaultProvider := IsManagedProviderCode(CorpCardProvider.Code);

        EnsureDataExchDefinition(CorpCardProvider."Data Exch Def Code", IsXmlDefinition);
        if IsManagedDefaultProvider then begin
            EnsureDataExchLineAndColumns(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", IsXmlDefinition);
            EnsureDataExchMapping(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");
            EnsureFieldMappings(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");
        end;

        // Seed all predefined setups so admins can switch source formats without manual rebuild.
        if IsManagedDefaultProvider then begin
            EnsureDataExchDefinition(CorpCardCsvDataExchDefCodeTok, false);
            EnsureDataExchLineAndColumns(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok, false);
            EnsureDataExchMapping(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok);
            EnsureFieldMappings(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok);

            EnsureDataExchDefinition(CorpCardXmlDataExchDefCodeTok, true);
            EnsureDataExchLineAndColumns(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok, true);
            EnsureDataExchMapping(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok);
            EnsureFieldMappings(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok);

            EnsureDataExchDefinition(CorpCardIsoDataExchDefCodeTok, true);
            EnsureDataExchLineAndColumns(CorpCardIsoDataExchDefCodeTok, CorpCardIsoDataExchLineCodeTok, true);
            EnsureDataExchMapping(CorpCardIsoDataExchDefCodeTok, CorpCardIsoDataExchLineCodeTok);
            EnsureFieldMappings(CorpCardIsoDataExchDefCodeTok, CorpCardIsoDataExchLineCodeTok);

            EnsureDataExchDefinition(CorpCardCamt053DataExchDefCodeTok, true);
            EnsureDataExchLineAndColumns(CorpCardCamt053DataExchDefCodeTok, CorpCardCamt053DataExchLineCodeTok, true);
            EnsureDataExchMapping(CorpCardCamt053DataExchDefCodeTok, CorpCardCamt053DataExchLineCodeTok);
            EnsureFieldMappings(CorpCardCamt053DataExchDefCodeTok, CorpCardCamt053DataExchLineCodeTok);

            EnsureDataExchDefinition(CorpCardCamt054DataExchDefCodeTok, true);
            EnsureDataExchLineAndColumns(CorpCardCamt054DataExchDefCodeTok, CorpCardCamt054DataExchLineCodeTok, true);
            EnsureDataExchMapping(CorpCardCamt054DataExchDefCodeTok, CorpCardCamt054DataExchLineCodeTok);
            EnsureFieldMappings(CorpCardCamt054DataExchDefCodeTok, CorpCardCamt054DataExchLineCodeTok);

            EnsureSamplePayloadForProvider(CorpCardProvider);
        end;
    end;

    local procedure EnsureDefaultCorpCardLinks(ProviderCode: Code[20])
    var
        ExpenseUser: Record "Expense User";
        CorpCard: Record "EA Corp Card";
    begin
        if not ExpenseUser.FindSet() then
            exit;

        repeat
            CorpCard.Reset();
            CorpCard.SetRange("Provider Code", ProviderCode);
            CorpCard.SetRange("Expense User No.", ExpenseUser."No.");
            if not CorpCard.IsEmpty() then
                continue;

            CorpCard.Init();
            CorpCard."Card Id" := GetNextCorpCardId();
            CorpCard."Provider Code" := ProviderCode;
            CorpCard."Expense User No." := ExpenseUser."No.";
            CorpCard."External Card Ref" := CopyStr(ExpenseUser."No.", 1, MaxStrLen(CorpCard."External Card Ref"));
            CorpCard."Masked Card No." := BuildMaskedCardNo(CorpCard."Card Id");
            CorpCard."Valid From" := Today();
            CorpCard.Insert(true);
        until ExpenseUser.Next() = 0;

        EnsureSampleCardIdsForProvider(ProviderCode);
    end;

    local procedure EnsureSampleCardIdsForProvider(ProviderCode: Code[20])
    var
        CorpCard: Record "EA Corp Card";
        ExistingProviderCard: Record "EA Corp Card";
        TargetCardId: Code[50];
        PrefixTxt: Text;
        ExternalRef: Code[50];
        FallbackExpenseUserNo: Code[20];
        SequenceNo: Integer;
    begin
        PrefixTxt := GetProviderSampleCardPrefix(ProviderCode);
        if PrefixTxt = '' then
            exit;

        ExistingProviderCard.SetRange("Provider Code", ProviderCode);
        ExistingProviderCard.SetFilter("Expense User No.", '<>%1', '');
        if ExistingProviderCard.FindFirst() then
            FallbackExpenseUserNo := ExistingProviderCard."Expense User No.";

        for SequenceNo := 1 to 6 do begin
            TargetCardId := CopyStr(StrSubstNo('%1-%2', PrefixTxt, PadNumberLeft(SequenceNo, 4)), 1, MaxStrLen(TargetCardId));
            if CorpCard.Get(TargetCardId) then
                continue;

            CorpCard.Init();
            CorpCard."Card Id" := TargetCardId;
            CorpCard."Provider Code" := ProviderCode;
            CorpCard."Expense User No." := FallbackExpenseUserNo;
            if FallbackExpenseUserNo <> '' then
                ExternalRef := CopyStr(FallbackExpenseUserNo, 1, MaxStrLen(ExternalRef))
            else
                ExternalRef := CopyStr(StrSubstNo('%1-%2', ProviderCode, PadNumberLeft(SequenceNo, 4)), 1, MaxStrLen(ExternalRef));
            CorpCard."External Card Ref" := ExternalRef;
            CorpCard."Masked Card No." := BuildMaskedCardNo(CorpCard."Card Id");
            CorpCard."Valid From" := Today();
            CorpCard.Insert(true);
        end;
    end;

    local procedure GetProviderSampleCardPrefix(ProviderCode: Code[20]): Text
    begin
        case ProviderCode of
            CorpCardCsvProviderCodeTok:
                exit('CRDCSV');
            CorpCardXmlProviderCodeTok:
                exit('CRDXML');
            CorpCardIsoProviderCodeTok:
                exit('CRDISO');
            CorpCardCamt053ProviderCodeTok:
                exit('CRDC53');
            CorpCardCamt054ProviderCodeTok:
                exit('CRDC54');
            else
                exit('');
        end;
    end;

    local procedure GetNextCorpCardId(): Code[50]
    var
        CorpCard: Record "EA Corp Card";
        CandidateCardId: Code[50];
        SequenceNo: Integer;
    begin
        SequenceNo := 1;
        repeat
            CandidateCardId := CopyStr(StrSubstNo(CardIDTok, PadNumberLeft(SequenceNo, 4)), 1, MaxStrLen(CorpCard."Card Id"));
            SequenceNo += 1;
        until not CorpCard.Get(CandidateCardId);

        exit(CandidateCardId);
    end;

    local procedure PadNumberLeft(Value: Integer; TotalLength: Integer): Text
    var
        ValueTxt: Text;
    begin
        ValueTxt := Format(Value);
        while StrLen(ValueTxt) < TotalLength do
            ValueTxt := '0' + ValueTxt;

        exit(ValueTxt);
    end;

    local procedure BuildMaskedCardNo(CardId: Code[50]): Text[30]
    var
        StartPos: Integer;
        Last4: Text;
    begin
        StartPos := StrLen(CardId) - 3;
        if StartPos < 1 then
            StartPos := 1;

        Last4 := CopyStr(CardId, StartPos, 4);
        exit(CopyStr(StrSubstNo('****%1', Last4), 1, 30));
    end;

    local procedure EnsureCorpCardProviders()
    begin
        EnsureCorpCardProvider(CorpCardCsvProviderCodeTok, CorpCardCsvProviderDescriptionLbl, Enum::"EA Corp Card Feed Type"::CSV, CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok);
        EnsureCorpCardProvider(CorpCardXmlProviderCodeTok, CorpCardXmlProviderDescriptionLbl, Enum::"EA Corp Card Feed Type"::XML, CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok);
        EnsureCorpCardProvider(CorpCardIsoProviderCodeTok, CorpCardIsoProviderDescriptionLbl, Enum::"EA Corp Card Feed Type"::ISO20022, CorpCardIsoDataExchDefCodeTok, CorpCardIsoDataExchLineCodeTok);
        EnsureCorpCardProvider(CorpCardCamt053ProviderCodeTok, CorpCardCamt053ProviderDescriptionLbl, Enum::"EA Corp Card Feed Type"::CAMT053, CorpCardCamt053DataExchDefCodeTok, CorpCardCamt053DataExchLineCodeTok);
        EnsureCorpCardProvider(CorpCardCamt054ProviderCodeTok, CorpCardCamt054ProviderDescriptionLbl, Enum::"EA Corp Card Feed Type"::CAMT054, CorpCardCamt054DataExchDefCodeTok, CorpCardCamt054DataExchLineCodeTok);
    end;

    local procedure EnsureCorpCardProvider(ProviderCode: Code[20]; Description: Text[100]; FeedType: Enum "EA Corp Card Feed Type"; DataExchDefCode: Code[20]; DataExchLineCode: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        if not CorpCardProvider.Get(ProviderCode) then begin
            CorpCardProvider.Init();
            CorpCardProvider.Code := ProviderCode;
            CorpCardProvider.Description := Description;
            CorpCardProvider.Enabled := true;
            CorpCardProvider."Feed Type" := FeedType;
            CorpCardProvider."Data Exch Def Code" := DataExchDefCode;
            CorpCardProvider."Data Exch Map Code" := DataExchLineCode;
            CorpCardProvider."Import Frequency (Min)" := 1440;
            CorpCardProvider.Insert(true);
            EnsureSamplePayloadForProvider(CorpCardProvider);
            exit;
        end;

        if CorpCardProvider.Description = '' then
            CorpCardProvider.Description := Description;
        if CorpCardProvider."Feed Type" = CorpCardProvider."Feed Type"::DataExch then
            CorpCardProvider."Feed Type" := FeedType;
        if CorpCardProvider."Data Exch Def Code" = '' then
            CorpCardProvider."Data Exch Def Code" := DataExchDefCode;
        if CorpCardProvider."Data Exch Map Code" = '' then
            CorpCardProvider."Data Exch Map Code" := DataExchLineCode;
        if CorpCardProvider."Import Frequency (Min)" = 0 then
            CorpCardProvider."Import Frequency (Min)" := 1440;
        CorpCardProvider.Modify(true);
        EnsureSamplePayloadForProvider(CorpCardProvider);
    end;

    local procedure EnsureSamplePayloadForProvider(var CorpCardProvider: Record "EA Corp Card Provider")
    var
        PayloadOutStr: OutStream;
        SamplePayload: Text;
        SampleFileName: Text[250];
    begin
        CorpCardProvider.CalcFields("Source Payload");
        if CorpCardProvider."Source Payload".HasValue then
            exit;

        if not GetProviderSamplePayload(CorpCardProvider.Code, SamplePayload, SampleFileName) then
            exit;

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(PayloadOutStr, TextEncoding::UTF8);
        PayloadOutStr.WriteText(SamplePayload);
        CorpCardProvider."Source File Name" := CopyStr(SampleFileName, 1, MaxStrLen(CorpCardProvider."Source File Name"));
        CorpCardProvider.Modify(true);
    end;

    local procedure GetProviderSamplePayload(ProviderCode: Code[20]; var SamplePayload: Text; var SampleFileName: Text[250]): Boolean
    var
        PrimaryCardId: Code[50];
    begin
        PrimaryCardId := BuildProviderSampleCardId(ProviderCode, 1);
        if PrimaryCardId = '' then
            exit(false);

        case ProviderCode of
            CorpCardCsvProviderCodeTok:
                begin
                    SamplePayload := BuildCsvSamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardCsvSampleFileNameTok;
                    exit(true);
                end;
            CorpCardXmlProviderCodeTok:
                begin
                    SamplePayload := BuildXmlSamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardXmlSampleFileNameTok;
                    exit(true);
                end;
            CorpCardIsoProviderCodeTok:
                begin
                    SamplePayload := BuildIsoSamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardIsoSampleFileNameTok;
                    exit(true);
                end;
            CorpCardCamt053ProviderCodeTok:
                begin
                    SamplePayload := BuildCamt053SamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardCamt053SampleFileNameTok;
                    exit(true);
                end;
            CorpCardCamt054ProviderCodeTok:
                begin
                    SamplePayload := BuildCamt054SamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardCamt054SampleFileNameTok;
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure BuildProviderSampleCardId(ProviderCode: Code[20]; SequenceNo: Integer): Code[50]
    var
        PrefixTxt: Text;
    begin
        PrefixTxt := GetProviderSampleCardPrefix(ProviderCode);
        if PrefixTxt = '' then
            exit('');

        exit(CopyStr(StrSubstNo('%1-%2', PrefixTxt, PadNumberLeft(SequenceNo, 4)), 1, 50));
    end;

    local procedure BuildCsvSamplePayload(CardId: Code[50]): Text
    begin
        exit(
            'ProviderTransId,CardId,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes' + NewLineTxt() +
            'CSVTXN0001,' + CardId + ',2026-06-02,2026-06-03,19.63,USD,Contoso Air,4511,US,Seeded CSV sample');
    end;

    local procedure BuildXmlSamplePayload(CardId: Code[50]): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<CorporateCardTransactions>' +
                '<Transaction>' +
                    '<ProviderTransId>XMLTXN0001</ProviderTransId>' +
                    '<CardId>' + CardId + '</CardId>' +
                    '<TransDate>2026-06-02</TransDate>' +
                    '<PostingDate>2026-06-03</PostingDate>' +
                    '<Amount>19.63</Amount>' +
                    '<CurrencyCode>USD</CurrencyCode>' +
                    '<MerchantRaw>Contoso Air</MerchantRaw>' +
                    '<MCC>4511</MCC>' +
                    '<Country>US</Country>' +
                    '<Notes>Seeded XML sample</Notes>' +
                '</Transaction>' +
            '</CorporateCardTransactions>');
    end;

    local procedure BuildIsoSamplePayload(CardId: Code[50]): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Document>' +
                '<Notification>' +
                    '<Transaction>' +
                        '<ProviderTransId>ISOTXN0001</ProviderTransId>' +
                        '<CardId>' + CardId + '</CardId>' +
                        '<TransDate>2026-06-02</TransDate>' +
                        '<PostingDate>2026-06-03</PostingDate>' +
                        '<Amount>19.63</Amount>' +
                        '<CurrencyCode>USD</CurrencyCode>' +
                        '<MerchantRaw>Contoso Air</MerchantRaw>' +
                        '<MCC>4511</MCC>' +
                        '<Country>US</Country>' +
                        '<Notes>Seeded ISO20022 sample</Notes>' +
                    '</Transaction>' +
                '</Notification>' +
            '</Document>');
    end;

    local procedure BuildCamt053SamplePayload(CardId: Code[50]): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Document>' +
                '<BkToCstmrStmt>' +
                    '<Stmt>' +
                        '<Ntry>' +
                            '<BookgDt><Dt>2026-06-03</Dt></BookgDt>' +
                            '<ValDt><Dt>2026-06-03</Dt></ValDt>' +
                            '<NtryDtls>' +
                                '<TxDtls>' +
                                    '<Refs><EndToEndId>CAMT53TXN001</EndToEndId></Refs>' +
                                    '<RmtInf><Ustrd>' + CardId + '</Ustrd></RmtInf>' +
                                    '<AmtDtls><TxAmt><Amt Ccy="USD">19.63</Amt></TxAmt></AmtDtls>' +
                                    '<RltdPties><Cdtr><Nm>Contoso Air</Nm><PstlAdr><Ctry>US</Ctry></PstlAdr></Cdtr></RltdPties>' +
                                    '<AddtlTxInf>4511</AddtlTxInf>' +
                                '</TxDtls>' +
                            '</NtryDtls>' +
                        '</Ntry>' +
                    '</Stmt>' +
                '</BkToCstmrStmt>' +
            '</Document>');
    end;

    local procedure BuildCamt054SamplePayload(CardId: Code[50]): Text
    begin
        exit(
            '<?xml version="1.0" encoding="utf-8"?>' +
            '<Document>' +
                '<BkToCstmrStmt>' +
                    '<Stmt>' +
                        '<Ntry>' +
                            '<NtryDtls>' +
                                '<TxDtls>' +
                                    '<Refs><EndToEndId>CAMT54TXN001</EndToEndId></Refs>' +
                                    '<RmtInf><Ustrd>' + CardId + '</Ustrd></RmtInf>' +
                                    '<RltdDts><IntrBkSttlmDt><Dt>2026-06-03</Dt></IntrBkSttlmDt></RltdDts>' +
                                    '<AmtDtls><TxAmt><Amt Ccy="USD">19.63</Amt></TxAmt></AmtDtls>' +
                                    '<RltdPties><Cdtr><Nm>Contoso Air</Nm><PstlAdr><Ctry>US</Ctry></PstlAdr></Cdtr></RltdPties>' +
                                    '<AddtlTxInf>4511</AddtlTxInf>' +
                                '</TxDtls>' +
                            '</NtryDtls>' +
                        '</Ntry>' +
                    '</Stmt>' +
                '</BkToCstmrStmt>' +
            '</Document>');
    end;

    local procedure NewLineTxt(): Text
    var
        NewLineChar: Char;
    begin
        NewLineChar := 10;
        exit(Format(NewLineChar));
    end;

    local procedure EnsureCorpCardSetup()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        SetupChanged: Boolean;
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert(true);
        end;

        if ExpenseAgentSetup."Corp Card Default Provider" = '' then begin
            ExpenseAgentSetup."Corp Card Create Mode" := ExpenseAgentSetup."Corp Card Create Mode"::AutoDraft;
            ExpenseAgentSetup."Corp Card Auto Create Draft" := true;
            ExpenseAgentSetup."Corp Card Date Match Window" := 7;
            ExpenseAgentSetup."Corp Card Amount Tolerance" := 5;
            ExpenseAgentSetup."Corp Card Default Provider" := CorpCardCsvProviderCodeTok;
            ExpenseAgentSetup.Modify(true);
            exit;
        end;

        SetupChanged := false;
        if ExpenseAgentSetup."Corp Card Date Match Window" = 0 then begin
            ExpenseAgentSetup."Corp Card Date Match Window" := 7;
            SetupChanged := true;
        end;
        if ExpenseAgentSetup."Corp Card Amount Tolerance" = 0 then begin
            ExpenseAgentSetup."Corp Card Amount Tolerance" := 5;
            SetupChanged := true;
        end;

        if SetupChanged then
            ExpenseAgentSetup.Modify(true);
    end;

    local procedure EnsureProviderDefaults(var CorpCardProvider: Record "EA Corp Card Provider")
    var
        IsModified: Boolean;
        DesiredDefCode: Code[20];
        DesiredLineCode: Code[20];
        IsManagedDefaultProvider: Boolean;
    begin
        ResolveDefaultDataExchByFeedType(CorpCardProvider, DesiredDefCode, DesiredLineCode);
        IsManagedDefaultProvider := IsManagedProviderCode(CorpCardProvider.Code);

        if IsManagedDefaultProvider or (CorpCardProvider."Data Exch Def Code" = '') or IsKnownDefaultDefinition(CorpCardProvider."Data Exch Def Code") then
            if CorpCardProvider."Data Exch Def Code" <> DesiredDefCode then begin
                CorpCardProvider."Data Exch Def Code" := DesiredDefCode;
                IsModified := true;
            end;

        if IsManagedDefaultProvider or (CorpCardProvider."Data Exch Map Code" = '') or IsKnownDefaultLineCode(CorpCardProvider."Data Exch Map Code") then
            if CorpCardProvider."Data Exch Map Code" <> DesiredLineCode then begin
                CorpCardProvider."Data Exch Map Code" := DesiredLineCode;
                IsModified := true;
            end;

        if IsModified then
            CorpCardProvider.Modify(true);
    end;

    local procedure IsManagedProviderCode(ProviderCode: Code[20]): Boolean
    begin
        exit(ProviderCode in [CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok, CorpCardIsoProviderCodeTok, CorpCardCamt053ProviderCodeTok, CorpCardCamt054ProviderCodeTok]);
    end;

    local procedure ResolveDefaultDataExchByFeedType(CorpCardProvider: Record "EA Corp Card Provider"; var DesiredDefCode: Code[20]; var DesiredLineCode: Code[20])
    begin
        case CorpCardProvider."Feed Type" of
            CorpCardProvider."Feed Type"::CAMT053:
                begin
                    DesiredDefCode := CorpCardCamt053DataExchDefCodeTok;
                    DesiredLineCode := CorpCardCamt053DataExchLineCodeTok;
                end;
            CorpCardProvider."Feed Type"::CAMT054:
                begin
                    DesiredDefCode := CorpCardCamt054DataExchDefCodeTok;
                    DesiredLineCode := CorpCardCamt054DataExchLineCodeTok;
                end;
            CorpCardProvider."Feed Type"::ISO20022:
                begin
                    DesiredDefCode := CorpCardIsoDataExchDefCodeTok;
                    DesiredLineCode := CorpCardIsoDataExchLineCodeTok;
                end;
            CorpCardProvider."Feed Type"::XML:
                begin
                    DesiredDefCode := CorpCardXmlDataExchDefCodeTok;
                    DesiredLineCode := CorpCardXmlDataExchLineCodeTok;
                end;
            CorpCardProvider."Feed Type"::CSV:
                begin
                    DesiredDefCode := CorpCardCsvDataExchDefCodeTok;
                    DesiredLineCode := CorpCardCsvDataExchLineCodeTok;
                end;
            else
                if IsCamt054FileName(CorpCardProvider."Source File Name") then begin
                    DesiredDefCode := CorpCardCamt054DataExchDefCodeTok;
                    DesiredLineCode := CorpCardCamt054DataExchLineCodeTok;
                end else
                    if IsCamtFileName(CorpCardProvider."Source File Name") then begin
                        DesiredDefCode := CorpCardCamt053DataExchDefCodeTok;
                        DesiredLineCode := CorpCardCamt053DataExchLineCodeTok;
                    end else
                        if IsXmlFileName(CorpCardProvider."Source File Name") then begin
                            DesiredDefCode := CorpCardXmlDataExchDefCodeTok;
                            DesiredLineCode := CorpCardXmlDataExchLineCodeTok;
                        end else begin
                            DesiredDefCode := CorpCardCsvDataExchDefCodeTok;
                            DesiredLineCode := CorpCardCsvDataExchLineCodeTok;
                        end;
        end;
    end;

    local procedure IsKnownDefaultDefinition(DataExchDefCode: Code[20]): Boolean
    begin
        exit(DataExchDefCode in [CorpCardCsvDataExchDefCodeTok, CorpCardXmlDataExchDefCodeTok, CorpCardIsoDataExchDefCodeTok, CorpCardCamt053DataExchDefCodeTok, CorpCardCamt054DataExchDefCodeTok]);
    end;

    local procedure IsKnownDefaultLineCode(LineCode: Code[20]): Boolean
    begin
        exit(LineCode in [CorpCardCsvDataExchLineCodeTok, CorpCardXmlDataExchLineCodeTok, CorpCardIsoDataExchLineCodeTok, CorpCardCamt053DataExchLineCodeTok, CorpCardCamt054DataExchLineCodeTok]);
    end;

    local procedure IsXmlDefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit((DataExchDefCode = CorpCardXmlDataExchDefCodeTok) or (DataExchDefCode = CorpCardIsoDataExchDefCodeTok) or (DataExchDefCode = CorpCardCamt053DataExchDefCodeTok) or (DataExchDefCode = CorpCardCamt054DataExchDefCodeTok));
    end;

    local procedure IsXmlFeedType(FeedType: Enum "EA Corp Card Feed Type"): Boolean
    begin
        exit(FeedType in [FeedType::XML, FeedType::ISO20022, FeedType::CAMT053, FeedType::CAMT054]);
    end;

    local procedure IsCamtDefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit((DataExchDefCode = CorpCardCamt053DataExchDefCodeTok) or (DataExchDefCode = CorpCardCamt054DataExchDefCodeTok));
    end;

    local procedure IsCamt054DefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit(DataExchDefCode = CorpCardCamt054DataExchDefCodeTok);
    end;

    local procedure IsXmlFileName(SourceFileName: Text): Boolean
    var
        StartPos: Integer;
    begin
        if SourceFileName = '' then
            exit(false);

        StartPos := StrLen(SourceFileName) - 3;
        if StartPos < 1 then
            StartPos := 1;

        exit(LowerCase(CopyStr(SourceFileName, StartPos, 4)) = '.xml');
    end;

    local procedure IsCamtFileName(SourceFileName: Text): Boolean
    begin
        if SourceFileName = '' then
            exit(false);

        exit(StrPos(LowerCase(SourceFileName), 'camt') > 0);
    end;

    local procedure IsCamt054FileName(SourceFileName: Text): Boolean
    var
        LowerSourceFileName: Text;
    begin
        if SourceFileName = '' then
            exit(false);

        LowerSourceFileName := LowerCase(SourceFileName);
        exit((StrPos(LowerSourceFileName, 'camt054') > 0) or (StrPos(LowerSourceFileName, 'camt.054') > 0));
    end;

    local procedure EnsureDataExchDefinition(DataExchDefCode: Code[20]; IsXml: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        IsModified: Boolean;
    begin
        if not DataExchDef.Get(DataExchDefCode) then begin
            DataExchDef.Init();
            DataExchDef.Code := DataExchDefCode;
            if DataExchDefCode = CorpCardCamt053DataExchDefCodeTok then
                DataExchDef.Name := CorpCardCamt053DataExchDefNameLbl
            else
                if DataExchDefCode = CorpCardCamt054DataExchDefCodeTok then
                    DataExchDef.Name := CorpCardCamt054DataExchDefNameLbl
                else
                    if DataExchDefCode = CorpCardIsoDataExchDefCodeTok then
                        DataExchDef.Name := CorpCardIsoDataExchDefNameLbl
                    else
                        if IsXml then
                            DataExchDef.Name := CorpCardXmlDataExchDefNameLbl
                        else
                            DataExchDef.Name := CorpCardCsvDataExchDefNameLbl;
            if IsXml then
                DataExchDef."Header Lines" := 0
            else
                DataExchDef."Header Lines" := 1;
            ApplyTemplateDefaults(DataExchDef, IsXml);
            EnsureDataExchRuntimeSettings(DataExchDef, DataExchDefCode, IsXml);
            DataExchDef.Insert(true);
            exit;
        end;

        if DataExchDefCode = CorpCardCamt053DataExchDefCodeTok then begin
            if DataExchDef.Name <> CorpCardCamt053DataExchDefNameLbl then begin
                DataExchDef.Name := CorpCardCamt053DataExchDefNameLbl;
                IsModified := true;
            end;
        end else
            if DataExchDefCode = CorpCardCamt054DataExchDefCodeTok then begin
                if DataExchDef.Name <> CorpCardCamt054DataExchDefNameLbl then begin
                    DataExchDef.Name := CorpCardCamt054DataExchDefNameLbl;
                    IsModified := true;
                end;
            end else
                if DataExchDefCode = CorpCardIsoDataExchDefCodeTok then begin
                    if DataExchDef.Name <> CorpCardIsoDataExchDefNameLbl then begin
                        DataExchDef.Name := CorpCardIsoDataExchDefNameLbl;
                        IsModified := true;
                    end;
                end else
                    if IsXml then begin
                        if DataExchDef.Name <> CorpCardXmlDataExchDefNameLbl then begin
                            DataExchDef.Name := CorpCardXmlDataExchDefNameLbl;
                            IsModified := true;
                        end;
                    end else
                        if DataExchDef.Name <> CorpCardCsvDataExchDefNameLbl then begin
                            DataExchDef.Name := CorpCardCsvDataExchDefNameLbl;
                            IsModified := true;
                        end;

        if ApplyTemplateDefaults(DataExchDef, IsXml) then
            IsModified := true;

        if EnsureDataExchRuntimeSettings(DataExchDef, DataExchDefCode, IsXml) then
            IsModified := true;

        if IsXml then begin
            if DataExchDef."Header Lines" <> 0 then begin
                DataExchDef."Header Lines" := 0;
                IsModified := true;
            end;
        end else
            if DataExchDef."Header Lines" = 0 then begin
                DataExchDef."Header Lines" := 1;
                IsModified := true;
            end;

        if IsModified then
            DataExchDef.Modify(true);
    end;

    local procedure EnsureDataExchRuntimeSettings(var DataExchDef: Record "Data Exch. Def"; DataExchDefCode: Code[20]; IsXml: Boolean) WasModified: Boolean
    begin
        if DataExchDef.Type <> DataExchDef.Type::"Generic Import" then begin
            DataExchDef.Type := DataExchDef.Type::"Generic Import";
            WasModified := true;
        end;

        if DataExchDef."Ext. Data Handling Codeunit" <> Codeunit::"Read Data Exch. from File" then begin
            DataExchDef."Ext. Data Handling Codeunit" := Codeunit::"Read Data Exch. from File";
            WasModified := true;
        end;

        if DataExchDef."Data Handling Codeunit" <> Codeunit::"Process Data Exch." then begin
            DataExchDef."Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            WasModified := true;
        end;

        if IsXml then begin
            if IsCamtDefinitionCode(DataExchDefCode) then begin
                if DataExchDef."Reading/Writing Codeunit" <> 1200 then begin
                    DataExchDef."Reading/Writing Codeunit" := 1200;
                    WasModified := true;
                end;
            end else
                if DataExchDef."Reading/Writing Codeunit" <> Codeunit::"Import XML File to Data Exch." then begin
                    DataExchDef."Reading/Writing Codeunit" := Codeunit::"Import XML File to Data Exch.";
                    WasModified := true;
                end;

            if DataExchDef."Reading/Writing XMLport" <> 0 then begin
                DataExchDef."Reading/Writing XMLport" := 0;
                WasModified := true;
            end;

            if DataExchDef."File Type" <> DataExchDef."File Type"::Xml then begin
                DataExchDef."File Type" := DataExchDef."File Type"::Xml;
                WasModified := true;
            end;
            exit;
        end;

        if DataExchDef."Reading/Writing Codeunit" <> 1283 then begin
            DataExchDef."Reading/Writing Codeunit" := 1283;
            WasModified := true;
        end;

        if DataExchDef."Reading/Writing XMLport" <> 0 then begin
            DataExchDef."Reading/Writing XMLport" := 0;
            WasModified := true;
        end;

        if DataExchDef."File Type" <> DataExchDef."File Type"::"Variable Text" then begin
            DataExchDef."File Type" := DataExchDef."File Type"::"Variable Text";
            WasModified := true;
        end;
    end;

    local procedure ApplyTemplateDefaults(var DataExchDef: Record "Data Exch. Def"; PreferXmlTemplate: Boolean) WasModified: Boolean
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchDefTemplate: Record "Data Exch. Def";
        FoundTemplate: Boolean;
    begin
        DataExchDefTemplate.Reset();
        DataExchDefTemplate.SetFilter(Code, '<>%1', DataExchDef.Code);
        DataExchDefTemplate.SetFilter("Ext. Data Handling Codeunit", '<>%1', 0);
        if PreferXmlTemplate then begin
            if DataExchDefTemplate.FindSet() then
                repeat
                    DataExchColumnDef.Reset();
                    DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefTemplate.Code);
                    DataExchColumnDef.SetFilter(Path, '<>%1', '');
                    if not DataExchColumnDef.IsEmpty() then begin
                        FoundTemplate := true;
                        break;
                    end;
                until DataExchDefTemplate.Next() = 0;

            if not FoundTemplate then
                exit(false);
        end else
            if not DataExchDefTemplate.FindFirst() then
                exit(false);

        if DataExchDef.Type <> DataExchDefTemplate.Type then begin
            DataExchDef.Type := DataExchDefTemplate.Type;
            WasModified := true;
        end;

        if DataExchDef."File Type" <> DataExchDefTemplate."File Type" then begin
            DataExchDef."File Type" := DataExchDefTemplate."File Type";
            WasModified := true;
        end;

        if DataExchDef."Column Separator" <> DataExchDefTemplate."Column Separator" then begin
            DataExchDef."Column Separator" := DataExchDefTemplate."Column Separator";
            WasModified := true;
        end;

        if DataExchDef."File Encoding" <> DataExchDefTemplate."File Encoding" then begin
            DataExchDef."File Encoding" := DataExchDefTemplate."File Encoding";
            WasModified := true;
        end;

        if DataExchDef."Line Separator" <> DataExchDefTemplate."Line Separator" then begin
            DataExchDef."Line Separator" := DataExchDefTemplate."Line Separator";
            WasModified := true;
        end;

        if DataExchDef."Reading/Writing Codeunit" = 0 then begin
            DataExchDef."Reading/Writing Codeunit" := DataExchDefTemplate."Reading/Writing Codeunit";
            WasModified := true;
        end;

        if DataExchDef."Validation Codeunit" = 0 then begin
            DataExchDef."Validation Codeunit" := DataExchDefTemplate."Validation Codeunit";
            WasModified := true;
        end;

        if DataExchDef."Data Handling Codeunit" = 0 then begin
            DataExchDef."Data Handling Codeunit" := DataExchDefTemplate."Data Handling Codeunit";
            WasModified := true;
        end;

        if DataExchDef."User Feedback Codeunit" = 0 then begin
            DataExchDef."User Feedback Codeunit" := DataExchDefTemplate."User Feedback Codeunit";
            WasModified := true;
        end;
    end;

    local procedure EnsureDataExchLineAndColumns(DataExchDefCode: Code[20]; LineDefCode: Code[20]; IsXml: Boolean)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        IsModified: Boolean;
    begin
        DataExchLineDef.Reset();
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange(Code, LineDefCode);
        if not DataExchLineDef.FindFirst() then begin
            DataExchLineDef.Init();
            DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
            DataExchLineDef.Code := LineDefCode;
            if DataExchDefCode = CorpCardCamt053DataExchDefCodeTok then
                DataExchLineDef.Name := CorpCardCamt053DataExchLineNameLbl
            else
                if DataExchDefCode = CorpCardCamt054DataExchDefCodeTok then
                    DataExchLineDef.Name := CorpCardCamt054DataExchLineNameLbl
                else
                    if DataExchDefCode = CorpCardIsoDataExchDefCodeTok then
                        DataExchLineDef.Name := CorpCardIsoDataExchLineNameLbl
                    else
                        if IsXml then
                            DataExchLineDef.Name := CorpCardXmlDataExchLineNameLbl
                        else
                            DataExchLineDef.Name := CorpCardCsvDataExchLineNameLbl;
            DataExchLineDef."Column Count" := 10;
            case DataExchDefCode of
                CorpCardCamt053DataExchDefCodeTok:
                    DataExchLineDef."Data Line Tag" := CorpCardCamt053DataLineTagLbl;
                CorpCardCamt054DataExchDefCodeTok:
                    DataExchLineDef."Data Line Tag" := CorpCardCamt054DataLineTagLbl;
                CorpCardIsoDataExchDefCodeTok:
                    DataExchLineDef."Data Line Tag" := CorpCardIsoDataLineTagLbl;
                else
                    if IsXml then
                        DataExchLineDef."Data Line Tag" := CorpCardXmlDataLineTagLbl;
            end;
            DataExchLineDef.Insert(true);
        end else begin
            if DataExchDefCode = CorpCardCamt053DataExchDefCodeTok then begin
                if DataExchLineDef."Data Line Tag" <> CorpCardCamt053DataLineTagLbl then begin
                    DataExchLineDef."Data Line Tag" := CorpCardCamt053DataLineTagLbl;
                    IsModified := true;
                end;
                if DataExchLineDef.Name <> CorpCardCamt053DataExchLineNameLbl then begin
                    DataExchLineDef.Name := CorpCardCamt053DataExchLineNameLbl;
                    IsModified := true;
                end;
            end else
                if DataExchDefCode = CorpCardCamt054DataExchDefCodeTok then begin
                    if DataExchLineDef."Data Line Tag" <> CorpCardCamt054DataLineTagLbl then begin
                        DataExchLineDef."Data Line Tag" := CorpCardCamt054DataLineTagLbl;
                        IsModified := true;
                    end;
                    if DataExchLineDef.Name <> CorpCardCamt054DataExchLineNameLbl then begin
                        DataExchLineDef.Name := CorpCardCamt054DataExchLineNameLbl;
                        IsModified := true;
                    end;
                end else
                    if DataExchDefCode = CorpCardIsoDataExchDefCodeTok then begin
                        if DataExchLineDef."Data Line Tag" <> CorpCardIsoDataLineTagLbl then begin
                            DataExchLineDef."Data Line Tag" := CorpCardIsoDataLineTagLbl;
                            IsModified := true;
                        end;
                        if DataExchLineDef.Name <> CorpCardIsoDataExchLineNameLbl then begin
                            DataExchLineDef.Name := CorpCardIsoDataExchLineNameLbl;
                            IsModified := true;
                        end;
                    end else
                        if IsXml then begin
                            if DataExchLineDef."Data Line Tag" <> CorpCardXmlDataLineTagLbl then begin
                                DataExchLineDef."Data Line Tag" := CorpCardXmlDataLineTagLbl;
                                IsModified := true;
                            end;
                            if DataExchLineDef.Name <> CorpCardXmlDataExchLineNameLbl then begin
                                DataExchLineDef.Name := CorpCardXmlDataExchLineNameLbl;
                                IsModified := true;
                            end;
                        end else
                            if DataExchLineDef.Name <> CorpCardCsvDataExchLineNameLbl then begin
                                DataExchLineDef.Name := CorpCardCsvDataExchLineNameLbl;
                                IsModified := true;
                            end;

            if DataExchLineDef."Column Count" <> 10 then begin
                DataExchLineDef."Column Count" := 10;
                IsModified := true;
            end;

            if IsModified then
                DataExchLineDef.Modify(true);
        end;

        EnsureColumnDef(DataExchDefCode, LineDefCode, 1, 'ProviderTransId', ResolveXmlPath(DataExchDefCode, IsXml, 'ProviderTransId'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 2, 'CardId', ResolveXmlPath(DataExchDefCode, IsXml, 'CardId'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 3, 'TransDate', ResolveXmlPath(DataExchDefCode, IsXml, 'TransDate'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 4, 'PostingDate', ResolveXmlPath(DataExchDefCode, IsXml, 'PostingDate'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 5, 'Amount', ResolveXmlPath(DataExchDefCode, IsXml, 'Amount'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 6, 'CurrencyCode', ResolveXmlPath(DataExchDefCode, IsXml, 'CurrencyCode'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 7, 'MerchantRaw', ResolveXmlPath(DataExchDefCode, IsXml, 'MerchantRaw'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 8, 'MCC', ResolveXmlPath(DataExchDefCode, IsXml, 'MCC'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 9, 'Country', ResolveXmlPath(DataExchDefCode, IsXml, 'Country'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 10, 'Notes', ResolveXmlPath(DataExchDefCode, IsXml, 'Notes'));
    end;

    local procedure ResolveXmlPath(DataExchDefCode: Code[20]; IsXml: Boolean; NodeName: Text[250]): Text[250]
    begin
        if not IsXml then
            exit('');

        if not IsCamtDefinitionCode(DataExchDefCode) then
            exit(NodeName);

        if IsCamt054DefinitionCode(DataExchDefCode) then
            case NodeName of
                'ProviderTransId':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId');
                'CardId':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RmtInf/Ustrd');
                'TransDate':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdDts/IntrBkSttlmDt/Dt');
                'PostingDate':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdDts/IntrBkSttlmDt/Dt');
                'Amount':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/TxAmt/Amt');
                'CurrencyCode':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/TxAmt/Amt[@Ccy]');
                'MerchantRaw':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/Nm');
                'MCC':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AddtlTxInf');
                'Country':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/PstlAdr/Ctry');
                'Notes':
                    exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AddtlTxInf');
            end;

        case NodeName of
            'ProviderTransId':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/Refs/EndToEndId');
            'CardId':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RmtInf/Ustrd');
            'TransDate':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/BookgDt/Dt');
            'PostingDate':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/ValDt/Dt');
            'Amount':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/TxAmt/Amt');
            'CurrencyCode':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AmtDtls/TxAmt/Amt[@Ccy]');
            'MerchantRaw':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/Nm');
            'MCC':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AddtlTxInf');
            'Country':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/RltdPties/Cdtr/PstlAdr/Ctry');
            'Notes':
                exit('/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls/AddtlTxInf');
        end;

        exit('');
    end;

    local procedure EnsureColumnDef(DataExchDefCode: Code[20]; LineDefCode: Code[20]; ColumnNo: Integer; ColumnName: Text[250]; PathTxt: Text[250])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        IsModified: Boolean;
    begin
        DataExchColumnDef.Reset();
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchColumnDef.SetRange("Column No.", ColumnNo);
        if DataExchColumnDef.FindFirst() then begin
            if DataExchColumnDef.Name <> ColumnName then begin
                DataExchColumnDef.Name := ColumnName;
                IsModified := true;
            end;
            if DataExchColumnDef.Path <> PathTxt then begin
                DataExchColumnDef.Path := PathTxt;
                IsModified := true;
            end;
            if not DataExchColumnDef.Show then begin
                DataExchColumnDef.Show := true;
                IsModified := true;
            end;

            if IsModified then
                DataExchColumnDef.Modify(true);
            exit;
        end;

        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchColumnDef."Data Exch. Line Def Code" := LineDefCode;
        DataExchColumnDef."Column No." := ColumnNo;
        DataExchColumnDef.Name := ColumnName;
        DataExchColumnDef.Path := PathTxt;
        DataExchColumnDef.Show := true;
        DataExchColumnDef.Insert(true);
    end;

    local procedure EnsureDataExchMapping(DataExchDefCode: Code[20]; LineDefCode: Code[20])
    var
        DataExchMapping: Record "Data Exch. Mapping";
        IsModified: Boolean;
    begin
        // Repair legacy rows that were created without a line definition code.
        DataExchMapping.Reset();
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Table ID", Database::"EA Corp Card Trans");
        if DataExchMapping.FindSet() then
            repeat
                IsModified := false;
                if DataExchMapping."Data Exch. Line Def Code" = '' then begin
                    DataExchMapping."Data Exch. Line Def Code" := LineDefCode;
                    IsModified := true;
                end;
                if DataExchMapping."Mapping Codeunit" = 0 then begin
                    DataExchMapping."Mapping Codeunit" := Codeunit::"EA Corp Card DE Noop";
                    IsModified := true;
                end;
                if IsModified then
                    DataExchMapping.Modify(true);
            until DataExchMapping.Next() = 0;

        DataExchMapping.Reset();
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchMapping.SetRange("Table ID", Database::"EA Corp Card Trans");
        if DataExchMapping.FindFirst() then begin
            if DataExchMapping."Mapping Codeunit" = 0 then begin
                DataExchMapping."Mapping Codeunit" := Codeunit::"EA Corp Card DE Noop";
                IsModified := true;
            end;

            if IsModified then
                DataExchMapping.Modify(true);
            exit;
        end;

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchMapping."Data Exch. Line Def Code" := LineDefCode;
        DataExchMapping."Table ID" := Database::"EA Corp Card Trans";
        DataExchMapping.Name := CorpCardDataExchMappingNameLbl;
        DataExchMapping."Mapping Codeunit" := Codeunit::"EA Corp Card DE Noop";
        DataExchMapping.Insert(true);
    end;

    local procedure EnsureFieldMappings(DataExchDefCode: Code[20]; LineDefCode: Code[20])
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 1, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Provider Trans Id"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 2, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Card Id"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 3, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Trans Date"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 4, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Posting Date"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 5, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(Amount));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 6, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Currency Code"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 7, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Merchant Raw"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 8, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(MCC));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 9, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(Country));
    end;

    local procedure EnsureFieldMapping(DataExchDefCode: Code[20]; LineDefCode: Code[20]; ColumnNo: Integer; TableId: Integer; FieldId: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Reset();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchFieldMapping.SetRange("Table ID", TableId);
        DataExchFieldMapping.SetRange("Column No.", ColumnNo);
        if DataExchFieldMapping.FindFirst() then
            exit;

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := LineDefCode;
        DataExchFieldMapping."Table ID" := TableId;
        DataExchFieldMapping."Column No." := ColumnNo;
        DataExchFieldMapping."Field ID" := FieldId;
        DataExchFieldMapping.Insert(true);
    end;

    var
        CorpCardCsvProviderCodeTok: Label 'CORPCARDCSV', MaxLength = 20, Locked = true;
        CorpCardXmlProviderCodeTok: Label 'CORPCARDXML', MaxLength = 20, Locked = true;
        CorpCardIsoProviderCodeTok: Label 'CORPCARDISO', MaxLength = 20, Locked = true;
        CorpCardCamt053ProviderCodeTok: Label 'CORPCAMT053', MaxLength = 20, Locked = true;
        CorpCardCamt054ProviderCodeTok: Label 'CORPCAMT054', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchDefCodeTok: Label 'EACCARDCSV', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchLineCodeTok: Label 'TRANS', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchDefCodeTok: Label 'EACCARDXML', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchLineCodeTok: Label 'TRANSXML', MaxLength = 20, Locked = true;
        CorpCardIsoDataExchDefCodeTok: Label 'EACCARDISO', MaxLength = 20, Locked = true;
        CorpCardIsoDataExchLineCodeTok: Label 'TRANSISO', MaxLength = 20, Locked = true;
        CorpCardCamt053DataExchDefCodeTok: Label 'EACCAMT053', MaxLength = 20, Locked = true;
        CorpCardCamt053DataExchLineCodeTok: Label 'TRANSCAMT', MaxLength = 20, Locked = true;
        CorpCardCamt054DataExchDefCodeTok: Label 'EACCAMT054', MaxLength = 20, Locked = true;
        CorpCardCamt054DataExchLineCodeTok: Label 'TRNCAMT054', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchDefNameLbl: Label 'Corporate Card CSV Import';
        CorpCardXmlDataExchDefNameLbl: Label 'Corporate Card XML Import';
        CorpCardIsoDataExchDefNameLbl: Label 'Corporate Card ISO20022 Import';
        CorpCardCamt053DataExchDefNameLbl: Label 'Corporate Card CAMT053 Import';
        CorpCardCamt054DataExchDefNameLbl: Label 'Corporate Card CAMT054 Import';
        CorpCardCsvDataExchLineNameLbl: Label 'Transactions';
        CorpCardXmlDataExchLineNameLbl: Label 'Transactions';
        CorpCardIsoDataExchLineNameLbl: Label 'ISO20022 Transactions';
        CorpCardCamt053DataExchLineNameLbl: Label 'CAMT053 Transactions';
        CorpCardCamt054DataExchLineNameLbl: Label 'CAMT054 Transactions';
        CorpCardXmlDataLineTagLbl: Label '/CorporateCardTransactions/Transaction';
        CorpCardCamt053DataLineTagLbl: Label '/Document/BkToCstmrStmt/Stmt/Ntry';
        CorpCardCamt054DataLineTagLbl: Label '/Document/BkToCstmrStmt/Stmt/Ntry/NtryDtls/TxDtls';
        CorpCardIsoDataLineTagLbl: Label '/Document/Notification/Transaction';
        CorpCardDataExchMappingNameLbl: Label 'Corp Card Transaction Mapping';
        CorpCardCsvProviderDescriptionLbl: Label 'Corporate Card CSV Provider';
        CorpCardXmlProviderDescriptionLbl: Label 'Corporate Card XML Provider';
        CorpCardIsoProviderDescriptionLbl: Label 'Corporate Card ISO20022 Provider';
        CorpCardCamt053ProviderDescriptionLbl: Label 'Corporate Card CAMT053 Provider';
        CorpCardCamt054ProviderDescriptionLbl: Label 'Corporate Card CAMT054 Provider';
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        CorpCardXmlSampleFileNameTok: Label 'CorpCard-Sample-60.xml', Locked = true;
        CorpCardIsoSampleFileNameTok: Label 'CorpCardISO20022Sample.xml', Locked = true;
        CorpCardCamt053SampleFileNameTok: Label 'CorpCard-Sample-60-SEPA-CAMT053.xml', Locked = true;
        CorpCardCamt054SampleFileNameTok: Label 'CorpCard-Sample-60-SEPA-CAMT054.xml', Locked = true;
        CardIDTok: Label 'CARD-%1', Locked = true;
}
