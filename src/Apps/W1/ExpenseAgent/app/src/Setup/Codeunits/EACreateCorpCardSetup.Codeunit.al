namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Setup;
using Microsoft.Foundation.NoSeries;
using System.IO;

codeunit 7442 "EA Create Corp Card Setup"
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
        tabledata "Bank Account" = rim,
        tabledata "Bank Account Ledger Entry" = r,
        tabledata "EA Corp Card" = rimd,
        tabledata "EA Corp Card Provider" = rimd,
        tabledata "EA Corp Card Settlement" = rimd,
        tabledata "EA Corp Card Settlement Line" = rimd,
        tabledata "EA Corp Card Statement" = rimd,
        tabledata "EA Corp Card Trans" = rm,
        tabledata Expense = rm,
        tabledata "Expense Category" = rm,
        tabledata "Expense Report Header" = rimd;

    trigger OnRun()
    begin
        CreateDefaults();
    end;

    internal procedure CreateDefaults()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardMCCMgt: Codeunit "EA Corp Card MCC Mgt";
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.InsertAccountingDefaults();
        EnsureCorpCardBankAccount();
        EnsureCorpCardProviders();

        CorpCardProvider.SetFilter(Code, '%1|%2', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok);
        if CorpCardProvider.FindSet() then
            repeat
                EnsureDataExchangeForProvider(CorpCardProvider);
            until CorpCardProvider.Next() = 0;

        EnsureDefaultCorpCardLinks();
        EnsureCorpCardSetup();
        CorpCardMCCMgt.InitializeDefaultMCCMappings();
        EnsureCorpCardExpenseCategoryPostingGroups();
    end;

    local procedure EnsureCorpCardExpenseCategoryPostingGroups()
    var
        CorpCardMCCMap: Record "EA Corp Card MCC Map";
        ExpenseCategory: Record "Expense Category";
        TempExpenseCategory: Record "Expense Category" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.BuildCategorySeeds(TempExpenseCategory);
        if CorpCardMCCMap.FindSet() then
            repeat
                if ExpenseCategory.Get(CorpCardMCCMap."Expense Category") and
                   (ExpenseCategory."Posting Group" = '') and
                   TempExpenseCategory.Get(ExpenseCategory.Code)
                then begin
                    ExpenseCategory.Validate("Posting Group", TempExpenseCategory."Posting Group");
                    ExpenseCategory.Modify(true);
                end;
            until CorpCardMCCMap.Next() = 0;
    end;

    internal procedure CreateCsvSampleScenario()
    begin
        CreateCsvSampleScenario('');
    end;

    internal procedure CreateCsvSampleScenario(PaymentBankAccountNo: Code[20])
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        CorpCardSettlement: Record "EA Corp Card Settlement";
        CorpCardSettlementLine: Record "EA Corp Card Settlement Line";
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardFeedMgt: Codeunit "EA Corp Card Feed Mgt";
        CorpCardSettlementMgt: Codeunit "EA Corp Card Settlement Mgt";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
    begin
        CreateDefaults();

        CorpCardTrans.SetRange("Provider Code", CorpCardCsvProviderCodeTok);
        CorpCardTrans.SetRange("Provider Trans Id", CorpCardSampleFirstTransIdTok);
        if not CorpCardTrans.IsEmpty() then
            Error(CsvSampleScenarioAlreadyExistsErr);

        CorpCardProvider.Get(CorpCardCsvProviderCodeTok);
        EnsureSamplePayloadForProvider(CorpCardProvider);
        CorpCardFeedMgt.RunImport(CorpCardProvider.Code);

        CorpCardProvider.Get(CorpCardProvider.Code);
        CorpCardStatement.Get(CorpCardProvider."Last Statement Entry No.");
        CorpCardStatement.TestField(Status, CorpCardStatement.Status::Imported);
        if CorpCardStatement.Imported <> GetCorpCardSampleTransactionCount() then
            Error(CsvSampleImportCountErr, GetCorpCardSampleTransactionCount(), CorpCardStatement.Imported);

        CompleteCsvSampleStatement(CorpCardStatement);
        CorpCardStatementMgt.ValidateStatement(CorpCardStatement);
        if PaymentBankAccountNo = '' then
            PaymentBankAccountNo := FindLcyPaymentBankAccount();
        ConfigureCsvProviderSettlementAccounts(CorpCardProvider, PaymentBankAccountNo);
        CreateAndPostCsvSampleExpenseReports(CorpCardStatement);

        CorpCardSettlement.Init();
        CorpCardSettlement.Validate("Provider Code", CorpCardProvider.Code);
        CorpCardSettlement.Validate("Settlement No.", CorpCardSampleSettlementNoTok);
        CorpCardSettlement.Validate("Settlement Date", WorkDate());
        CorpCardSettlement.Validate("Currency Code", '');
        CorpCardSettlement.Validate("Settlement Amount", CorpCardStatement.GetTotalInCurrency(''));
        CorpCardSettlement.Insert(true);

        CorpCardSettlementLine.Init();
        CorpCardSettlementLine."Settlement Entry No." := CorpCardSettlement."Settlement Entry No.";
        CorpCardSettlementLine."Line No." := 10000;
        CorpCardSettlementLine.Validate("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardSettlementLine.Insert(true);

        CorpCardSettlementMgt.SetReadyToPost(CorpCardSettlement);
        CorpCardSettlementMgt.PostSettlement(CorpCardSettlement);
    end;

    local procedure EnsureCorpCardBankAccount()
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        NoSeries: Record "No. Series";
    begin
        if BankAccount.Get(CorpCardBankAccountTok) then
            exit;

        BankAccount.Init();
        BankAccount.Validate("No.", CorpCardBankAccountTok);
        BankAccount.Validate(Name, CorpCardBankAccountNameLbl);
        BankAccount."Bank Account No." := CorpCardBankAccountNoTok;
        if BankAccountPostingGroup.Get(LcyBankAccountPostingGroupTok) then
            BankAccount."Bank Acc. Posting Group" := BankAccountPostingGroup.Code;
        if NoSeries.Get(PaymentReconciliationNoSeriesTok) then
            BankAccount."Pmt. Rec. No. Series" := NoSeries.Code;
        if BankExportImportSetup.Get(SepaCamtImportFormatTok) then
            BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
        BankAccount.Insert(true);
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

            EnsureSamplePayloadForProvider(CorpCardProvider);
        end;
    end;

    local procedure EnsureDefaultCorpCardLinks()
    var
        CorpCard: Record "EA Corp Card";
        ExpenseUser: Record "Expense User";
        SequenceNo: Integer;
    begin
        if not ExpenseUser.FindSet() then
            exit;

        repeat
            SequenceNo += 1;
            EnsureDemoCorpCard(
                CorpCard, BuildProviderSampleCardId(SequenceNo),
                CorpCardCsvProviderCodeTok, ExpenseUser."No.");
        until (ExpenseUser.Next() = 0) or (SequenceNo = 8);

        RemoveUnusedManagedProviderCards();
    end;

    local procedure EnsureDemoCorpCard(var CorpCard: Record "EA Corp Card"; CardId: Code[50]; ProviderCode: Code[20]; ExpenseUserNo: Code[20])
    begin
        if not CorpCard.Get(CardId) then begin
            CorpCard.Init();
            CorpCard."Card Id" := CardId;
            CorpCard."Provider Code" := ProviderCode;
            CorpCard.Insert(true);
        end;

        CorpCard."Provider Code" := ProviderCode;
        CorpCard."Expense User No." := ExpenseUserNo;
        CorpCard."External Card Ref" := CopyStr(ExpenseUserNo, 1, MaxStrLen(CorpCard."External Card Ref"));
        CorpCard."Masked Card No." := BuildMaskedCardNo(CorpCard."Card Id");
        CorpCard."Valid From" := Today();
        CorpCard.Modify(true);
    end;

    local procedure RemoveUnusedManagedProviderCards()
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCard.SetFilter("Provider Code", '%1|%2', CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok);
        if CorpCard.FindSet(true) then
            repeat
                if IsDemoCorpCardId(CorpCard."Card Id") then
                    continue;

                CorpCardTrans.SetRange("Card Id", CorpCard."Card Id");
                if CorpCardTrans.IsEmpty() then
                    CorpCard.Delete(true);
            until CorpCard.Next() = 0;
    end;

    local procedure IsDemoCorpCardId(CardId: Code[50]): Boolean
    var
        SequenceNo: Integer;
    begin
        for SequenceNo := 1 to 8 do
            if CardId = BuildProviderSampleCardId(SequenceNo) then
                exit(true);

        exit(false);
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
            if (CorpCardProvider.Code <> CorpCardCsvProviderCodeTok) or
               (CorpCardProvider."Source File Name" <> CorpCardCsvSampleFileNameTok) or
               (CorpCardProvider."Source Payload Record Count" = GetCorpCardSampleTransactionCount())
            then
                exit;

        if not GetProviderSamplePayload(CorpCardProvider.Code, SamplePayload, SampleFileName) then
            exit;

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(PayloadOutStr, TextEncoding::UTF8);
        PayloadOutStr.WriteText(SamplePayload);
        Clear(PayloadOutStr);
        CorpCardProvider."Source File Name" := CopyStr(SampleFileName, 1, MaxStrLen(CorpCardProvider."Source File Name"));
        CorpCardProvider.UpdateSourcePayloadRecordCount();
        CorpCardProvider.Modify(true);
    end;

    local procedure GetProviderSamplePayload(ProviderCode: Code[20]; var SamplePayload: Text; var SampleFileName: Text[250]): Boolean
    var
        PrimaryCardId: Code[50];
    begin
        PrimaryCardId := BuildProviderSampleCardId(1);

        case ProviderCode of
            CorpCardCsvProviderCodeTok:
                begin
                    SamplePayload := BuildCsvSamplePayload();
                    SampleFileName := CorpCardCsvSampleFileNameTok;
                    exit(true);
                end;
            CorpCardXmlProviderCodeTok:
                begin
                    SamplePayload := BuildXmlSamplePayload(PrimaryCardId);
                    SampleFileName := CorpCardXmlSampleFileNameTok;
                    exit(true);
                end;
        end;

        exit(false);
    end;

    local procedure BuildProviderSampleCardId(SequenceNo: Integer): Code[50]
    begin
        exit(CopyStr(StrSubstNo(CorpCardSampleCardIdTok, PadNumberLeft(SequenceNo, 4)), 1, 50));
    end;

    local procedure BuildCsvSamplePayload(): Text
    var
        CsvPayloadBuilder: TextBuilder;
        TransactionNo: Integer;
    begin
        CsvPayloadBuilder.AppendLine('ProviderTransId,CardId,TransDate,PostingDate,Amount,CurrencyCode,MerchantRaw,MCC,Country,Notes');
        for TransactionNo := 1 to GetCorpCardSampleTransactionCount() do
            AppendCsvSampleTransaction(CsvPayloadBuilder, TransactionNo);

        exit(CsvPayloadBuilder.ToText());
    end;

    local procedure AppendCsvSampleTransaction(var CsvPayloadBuilder: TextBuilder; TransactionNo: Integer)
    var
        AmountInCents: Integer;
        CardSequenceNo: Integer;
        DayNo: Integer;
        MerchantName: Text;
        MCC: Code[4];
    begin
        CardSequenceNo := ((TransactionNo - 1) mod 6) + 1;
        DayNo := (TransactionNo mod 28) + 1;
        if TransactionNo <= 54 then
            AmountInCents := 1250 + (TransactionNo * 713)
        else
            AmountInCents := 1525 + ((TransactionNo - 55) * 713);
        GetCsvSampleMerchant(TransactionNo, MerchantName, MCC);

        CsvPayloadBuilder.AppendLine(
            StrSubstNo(
                CorpCardSampleCsvLineTok,
                PadNumberLeft(TransactionNo, 5), PadNumberLeft(CardSequenceNo, 4), PadNumberLeft(DayNo, 2),
                PadNumberLeft(DayNo + 1, 2), FormatAmountInCents(AmountInCents), MerchantName, MCC, TransactionNo));
    end;

    local procedure GetCsvSampleMerchant(TransactionNo: Integer; var MerchantName: Text; var MCC: Code[4])
    begin
        case ((TransactionNo - 1) mod 10) + 1 of
            1:
                begin
                    MerchantName := 'Contoso Air';
                    MCC := '4511';
                end;
            2:
                begin
                    MerchantName := 'Fabrikam Hotel';
                    MCC := '7011';
                end;
            3:
                begin
                    MerchantName := 'Northwind Taxi';
                    MCC := '4121';
                end;
            4:
                begin
                    MerchantName := 'Adventure Meals';
                    MCC := '5812';
                end;
            5:
                begin
                    MerchantName := 'Proseware Rail';
                    MCC := '4112';
                end;
            6:
                begin
                    MerchantName := 'Litware Fuel';
                    MCC := '5541';
                end;
            7:
                begin
                    MerchantName := 'Tailspin Office';
                    MCC := '5943';
                end;
            8:
                begin
                    MerchantName := 'Alpine Parking';
                    MCC := '7523';
                end;
            9:
                begin
                    MerchantName := 'Woodgrove Supplies';
                    MCC := '5111';
                end;
            10:
                begin
                    MerchantName := 'BlueYonder Travel';
                    MCC := '4722';
                end;
        end;
    end;

    local procedure FormatAmountInCents(AmountInCents: Integer): Text
    begin
        exit(StrSubstNo('%1.%2', AmountInCents div 100, PadNumberLeft(AmountInCents mod 100, 2)));
    end;

    local procedure GetCorpCardSampleTransactionCount(): Integer
    begin
        exit(60);
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

    local procedure CompleteCsvSampleStatement(var CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        CorpCardTrans.FindFirst();
        CorpCardStatement.CalcFields("Transaction Total");
        CorpCardStatement.Validate("Statement No.", CorpCardSampleStatementNoTok);
        CorpCardStatement.Validate("Statement Date", DMY2Date(30, 6, 2026));
        CorpCardStatement.Validate("Period Start Date", DMY2Date(1, 6, 2026));
        CorpCardStatement.Validate("Period End Date", DMY2Date(28, 6, 2026));
        CorpCardStatement.Validate("Currency Code", CorpCardTrans."Currency Code");
        CorpCardStatement.Validate("Statement Total", CorpCardStatement."Transaction Total");
        CorpCardStatement.Modify(true);
    end;

    local procedure ConfigureCsvProviderSettlementAccounts(var CorpCardProvider: Record "EA Corp Card Provider"; PaymentBankAccountNo: Code[20])
    var
        CorpCardBankAccount: Record "Bank Account";
        PaymentBankAccount: Record "Bank Account";
    begin
        EnsureCsvSampleBankAccount(
            CorpCardBankAccount, CorpCardBankAccountTok, CorpCardBankAccountNameLbl,
            CorpCardBankAccountNoTok, '');
        PaymentBankAccount.Get(PaymentBankAccountNo);
        PaymentBankAccount.TestField("Bank Acc. Posting Group", LcyBankAccountPostingGroupTok);
        PaymentBankAccount.TestField("Currency Code", '');

        CorpCardProvider.Validate("Corp Card Bank Account No.", CorpCardBankAccount."No.");
        CorpCardProvider.Validate("Payment Bank Account No.", PaymentBankAccount."No.");
        CorpCardProvider.Modify(true);
    end;

    local procedure EnsureCsvSampleBankAccount(var BankAccount: Record "Bank Account"; BankAccountNo: Code[20]; BankAccountName: Text[100]; ExternalBankAccountNo: Text[30]; CurrencyCode: Code[10])
    var
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        NoSeries: Record "No. Series";
        IsModified: Boolean;
    begin
        BankAccountPostingGroup.Get(LcyBankAccountPostingGroupTok);
        BankAccountPostingGroup.TestField("G/L Account No.");

        if not BankAccount.Get(BankAccountNo) then begin
            BankAccount.Init();
            BankAccount.Validate("No.", BankAccountNo);
            BankAccount.Validate(Name, BankAccountName);
            BankAccount."Bank Account No." := ExternalBankAccountNo;
            BankAccount.Validate("Currency Code", CurrencyCode);
            BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
            if NoSeries.Get(PaymentReconciliationNoSeriesTok) then
                BankAccount."Pmt. Rec. No. Series" := NoSeries.Code;
            if BankExportImportSetup.Get(SepaCamtImportFormatTok) then
                BankAccount."Bank Statement Import Format" := BankExportImportSetup.Code;
            BankAccount.Insert(true);
            exit;
        end;

        if BankAccount."Currency Code" <> CurrencyCode then
            Error(BankAccountCurrencyMismatchErr, BankAccount."No.", BankAccount."Currency Code", CurrencyCode);
        if BankAccount."Bank Acc. Posting Group" = '' then begin
            BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
            IsModified := true;
        end;
        if BankAccount.Name = '' then begin
            BankAccount.Validate(Name, BankAccountName);
            IsModified := true;
        end;
        if BankAccount."Bank Account No." = '' then begin
            BankAccount."Bank Account No." := ExternalBankAccountNo;
            IsModified := true;
        end;

        if IsModified then
            BankAccount.Modify(true);
    end;

    local procedure FindLcyPaymentBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.SetFilter("No.", '<>%1', CorpCardBankAccountTok);
        BankAccount.SetRange("Bank Acc. Posting Group", LcyBankAccountPostingGroupTok);
        BankAccount.SetRange("Currency Code", '');
        if BankAccount.FindFirst() then
            exit(BankAccount."No.");

        Error(NoLcyPaymentBankAccountErr);
    end;

    local procedure CreateAndPostCsvSampleExpenseReports(CorpCardStatement: Record "EA Corp Card Statement")
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        ExpenseUserNos: Dictionary of [Code[20], Boolean];
        ExpenseUserNo: Code[20];
    begin
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        if CorpCardTrans.FindSet() then
            repeat
                CorpCard.Get(CorpCardTrans."Card Id");
                CorpCard.TestField("Expense User No.");
                if not ExpenseUserNos.ContainsKey(CorpCard."Expense User No.") then
                    ExpenseUserNos.Add(CorpCard."Expense User No.", true);
            until CorpCardTrans.Next() = 0;

        foreach ExpenseUserNo in ExpenseUserNos.Keys() do
            CreateAndPostCsvSampleExpenseReport(CorpCardStatement, ExpenseUserNo);
    end;

    local procedure CreateAndPostCsvSampleExpenseReport(CorpCardStatement: Record "EA Corp Card Statement"; ExpenseUserNo: Code[20])
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        Expense: Record Expense;
        ExpenseReportHeader: Record "Expense Report Header";
        CreateExpenseReport: Codeunit "Create Expense Report";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        ExpenseAdded: Boolean;
    begin
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        if CorpCardTrans.FindSet() then
            repeat
                CorpCard.Get(CorpCardTrans."Card Id");
                if CorpCard."Expense User No." <> ExpenseUserNo then
                    continue;

                CorpCardTrans.TestField("Expense No.");
                Expense.Get(CorpCardTrans."Expense No.");
                if not ExpenseAdded then begin
                    ExpenseReportHeader.Init();
                    ExpenseReportHeader.Validate("Expense User No.", ExpenseUserNo);
                    ExpenseReportHeader.Validate("Expense Report Date", CorpCardStatement."Statement Date");
                    ExpenseReportHeader.Validate("Posting Date", WorkDate());
                    ExpenseReportHeader.Validate("VAT Bus. Posting Group", Expense."VAT Bus. Posting Group");
                    ExpenseReportHeader.Insert(true);
                end;

                if Expense.Status = Expense.Status::Open then
                    Expense.PerformManualRelease();
                CreateExpenseReport.AddSingleExpenseToExpenseReport(Expense, ExpenseReportHeader);
                ExpenseAdded := true;
            until CorpCardTrans.Next() = 0;

        if not ExpenseAdded then
            Error(NoCsvSampleExpensesErr, ExpenseUserNo);

        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);
        UpdateCsvSampleTransactionAmountsLCY(CorpCardStatement, ExpenseUserNo);
    end;

    local procedure UpdateCsvSampleTransactionAmountsLCY(CorpCardStatement: Record "EA Corp Card Statement"; ExpenseUserNo: Code[20])
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange("Statement Entry No.", CorpCardStatement."Statement Entry No.");
        if CorpCardTrans.FindSet(true) then
            repeat
                CorpCard.Get(CorpCardTrans."Card Id");
                if CorpCard."Expense User No." <> ExpenseUserNo then
                    continue;

                BankAccountLedgerEntry.SetRange("EA Corp Card Trans Entry No.", CorpCardTrans."Entry No.");
                BankAccountLedgerEntry.SetRange(Reversed, false);
                if not BankAccountLedgerEntry.FindFirst() then
                    Error(CorpCardBankLedgerEntryMissingErr, CorpCardTrans."Entry No.");
                BankAccountLedgerEntry.TestField("Currency Code", '');
                CorpCardTrans."Amount (LCY)" := -BankAccountLedgerEntry.Amount;
                CorpCardTrans.Modify(true);
            until CorpCardTrans.Next() = 0;
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
        exit(ProviderCode in [CorpCardCsvProviderCodeTok, CorpCardXmlProviderCodeTok]);
    end;

    local procedure ResolveDefaultDataExchByFeedType(CorpCardProvider: Record "EA Corp Card Provider"; var DesiredDefCode: Code[20]; var DesiredLineCode: Code[20])
    begin
        case CorpCardProvider."Feed Type" of
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
        exit(DataExchDefCode in [CorpCardCsvDataExchDefCodeTok, CorpCardXmlDataExchDefCodeTok]);
    end;

    local procedure IsKnownDefaultLineCode(LineCode: Code[20]): Boolean
    begin
        exit(LineCode in [CorpCardCsvDataExchLineCodeTok, CorpCardXmlDataExchLineCodeTok]);
    end;

    local procedure IsXmlDefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit(DataExchDefCode = CorpCardXmlDataExchDefCodeTok);
    end;

    local procedure IsXmlFeedType(FeedType: Enum "EA Corp Card Feed Type"): Boolean
    begin
        exit(FeedType = FeedType::XML);
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

    local procedure EnsureDataExchDefinition(DataExchDefCode: Code[20]; IsXml: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        IsModified: Boolean;
    begin
        if not DataExchDef.Get(DataExchDefCode) then begin
            DataExchDef.Init();
            DataExchDef.Code := DataExchDefCode;
            if IsXml then
                DataExchDef.Name := CorpCardXmlDataExchDefNameLbl
            else
                DataExchDef.Name := CorpCardCsvDataExchDefNameLbl;
            if IsXml then
                DataExchDef."Header Lines" := 0
            else
                DataExchDef."Header Lines" := 1;
            ApplyTemplateDefaults(DataExchDef, IsXml);
            EnsureDataExchRuntimeSettings(DataExchDef, IsXml);
            DataExchDef.Insert(true);
            exit;
        end;

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

        if EnsureDataExchRuntimeSettings(DataExchDef, IsXml) then
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

    local procedure EnsureDataExchRuntimeSettings(var DataExchDef: Record "Data Exch. Def"; IsXml: Boolean) WasModified: Boolean
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
            if IsXml then
                DataExchLineDef.Name := CorpCardXmlDataExchLineNameLbl
            else
                DataExchLineDef.Name := CorpCardCsvDataExchLineNameLbl;
            DataExchLineDef."Column Count" := 10;
            if IsXml then
                DataExchLineDef."Data Line Tag" := CorpCardXmlDataLineTagLbl;
            DataExchLineDef.Insert(true);
        end else begin
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

        EnsureColumnDef(DataExchDefCode, LineDefCode, 1, 'ProviderTransId', ResolveXmlPath(IsXml, 'ProviderTransId'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 2, 'CardId', ResolveXmlPath(IsXml, 'CardId'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 3, 'TransDate', ResolveXmlPath(IsXml, 'TransDate'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 4, 'PostingDate', ResolveXmlPath(IsXml, 'PostingDate'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 5, 'Amount', ResolveXmlPath(IsXml, 'Amount'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 6, 'CurrencyCode', ResolveXmlPath(IsXml, 'CurrencyCode'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 7, 'MerchantRaw', ResolveXmlPath(IsXml, 'MerchantRaw'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 8, 'MCC', ResolveXmlPath(IsXml, 'MCC'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 9, 'Country', ResolveXmlPath(IsXml, 'Country'));
        EnsureColumnDef(DataExchDefCode, LineDefCode, 10, 'Notes', ResolveXmlPath(IsXml, 'Notes'));
    end;

    local procedure ResolveXmlPath(IsXml: Boolean; NodeName: Text[250]): Text[250]
    begin
        if not IsXml then
            exit('');

        exit(NodeName);
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
        CorpCardCsvDataExchDefCodeTok: Label 'EACCARDCSV', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchLineCodeTok: Label 'TRANS', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchDefCodeTok: Label 'EACCARDXML', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchLineCodeTok: Label 'TRANSXML', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchDefNameLbl: Label 'Corporate Card CSV Import';
        CorpCardXmlDataExchDefNameLbl: Label 'Corporate Card XML Import';
        CorpCardCsvDataExchLineNameLbl: Label 'Transactions';
        CorpCardXmlDataExchLineNameLbl: Label 'Transactions';
        CorpCardXmlDataLineTagLbl: Label '/CorporateCardTransactions/Transaction';
        CorpCardDataExchMappingNameLbl: Label 'Corp Card Transaction Mapping';
        CorpCardCsvProviderDescriptionLbl: Label 'Corporate Card CSV Provider';
        CorpCardXmlProviderDescriptionLbl: Label 'Corporate Card XML Provider';
        CorpCardCsvSampleFileNameTok: Label 'CorpCard-Sample-60.csv', Locked = true;
        CorpCardXmlSampleFileNameTok: Label 'CorpCard-Sample-60.xml', Locked = true;
        CorpCardSampleFirstTransIdTok: Label 'TXN00001', MaxLength = 50, Locked = true;
        CorpCardSampleSettlementNoTok: Label 'CSV-SAMPLE-SETTLEMENT', MaxLength = 50, Locked = true;
        CorpCardSampleStatementNoTok: Label 'CSV-SAMPLE-2026-06', MaxLength = 50, Locked = true;
        CorpCardSampleCardIdTok: Label 'CORPCARD-%1', MaxLength = 50, Locked = true;
        CorpCardSampleCsvLineTok: Label 'TXN%1,CORPCARD-%2,2026-06-%3,2026-06-%4,%5,USD,%6,%7,US,Sample transaction %8', Locked = true;
        CorpCardBankAccountTok: Label 'CORPCARD', Locked = true;
        CorpCardBankAccountNameLbl: Label 'Corporate Card Settlement Account', MaxLength = 100;
        CorpCardBankAccountNoTok: Label '99-55-000', Locked = true;
        LcyBankAccountPostingGroupTok: Label 'LCY', MaxLength = 20, Locked = true;
        PaymentReconciliationNoSeriesTok: Label 'PREC', Locked = true;
        SepaCamtImportFormatTok: Label 'SEPA CAMT', Locked = true;
        CsvSampleImportCountErr: Label 'The CSV sample import must create %1 transactions, but it created %2.', Comment = '%1 = expected transaction count, %2 = actual transaction count';
        CsvSampleScenarioAlreadyExistsErr: Label 'The CSV sample corporate card scenario has already been imported.';
        NoCsvSampleExpensesErr: Label 'No CSV sample expenses were found for expense user %1.', Comment = '%1 = expense user number';
        BankAccountCurrencyMismatchErr: Label 'Bank account %1 uses currency %2, but the CSV sample statement uses currency %3.', Comment = '%1 = bank account number, %2 = bank account currency code, %3 = statement currency code';
        NoLcyPaymentBankAccountErr: Label 'No local-currency bank account with the LCY posting group was found for the CSV sample settlement.';
        CorpCardBankLedgerEntryMissingErr: Label 'No corporate card bank account ledger entry was found for transaction %1.', Comment = '%1 = corporate card transaction entry number';
}
