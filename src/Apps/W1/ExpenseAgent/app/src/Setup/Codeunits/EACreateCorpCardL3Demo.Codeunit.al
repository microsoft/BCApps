namespace Microsoft.ExpenseAgent;

using System.IO;

codeunit 7234 "EA Create Corp Card L3 Demo"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "Data Exch. Def" = rimd,
        tabledata "Data Exch. Line Def" = rimd,
        tabledata "Data Exch. Column Def" = rimd,
        tabledata "Data Exch. Mapping" = rimd,
        tabledata "Data Exch. Field Mapping" = rimd,
        tabledata "EA Corp Card Provider" = rimd,
        tabledata "EA Corp Card MCC Map" = rimd,
        tabledata "Expense Category" = rimd,
        tabledata "Expense Agent Setup" = rimd;

    trigger OnRun()
    begin
        CreateDefaults();
    end;

    internal procedure CreateDefaults()
    var
        CorpCardMCCMgt: Codeunit "EA Corp Card MCC Mgt";
    begin
        EnsureProvider();
        EnsureProviderCardLinks();
        EnsureDataExchangeDefinition();
        EnsureSamplePayload();
        CorpCardMCCMgt.InitializeDefaultMCCMappings();
    end;

    local procedure EnsureProvider()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        if not CorpCardProvider.Get(Level3ProviderCodeTok) then begin
            CorpCardProvider.Init();
            CorpCardProvider.Code := Level3ProviderCodeTok;
            CorpCardProvider.Description := Level3ProviderDescriptionLbl;
            CorpCardProvider.Enabled := true;
            CorpCardProvider."Feed Type" := CorpCardProvider."Feed Type"::XML;
            CorpCardProvider."Data Exch Def Code" := Level3DataExchDefCodeTok;
            CorpCardProvider."Data Exch Map Code" := Level3HeaderLineCodeTok;
            CorpCardProvider."Source File Name" := Level3SourceFileNameTok;
            CorpCardProvider."Import Frequency (Min)" := 1440;
            CorpCardProvider.Insert(true);
            exit;
        end;

        if CorpCardProvider.Description = '' then
            CorpCardProvider.Description := Level3ProviderDescriptionLbl;
        if CorpCardProvider."Feed Type" = CorpCardProvider."Feed Type"::DataExch then
            CorpCardProvider."Feed Type" := CorpCardProvider."Feed Type"::XML;
        CorpCardProvider."Data Exch Def Code" := Level3DataExchDefCodeTok;
        CorpCardProvider."Data Exch Map Code" := Level3HeaderLineCodeTok;
        if CorpCardProvider."Source File Name" = '' then
            CorpCardProvider."Source File Name" := Level3SourceFileNameTok;
        if CorpCardProvider."Import Frequency (Min)" = 0 then
            CorpCardProvider."Import Frequency (Min)" := 1440;
        CorpCardProvider.Modify(true);
    end;

    local procedure EnsureDataExchangeDefinition()
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchMapping: Record "Data Exch. Mapping";
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        if not DataExchDef.Get(Level3DataExchDefCodeTok) then begin
            DataExchDef.Init();
            DataExchDef.Code := Level3DataExchDefCodeTok;
            DataExchDef.Name := Level3DataExchDefNameLbl;
            DataExchDef.Type := DataExchDef.Type::"Generic Import";
            DataExchDef."File Type" := DataExchDef."File Type"::Xml;
            DataExchDef."Header Lines" := 0;
            DataExchDef."Reading/Writing Codeunit" := Codeunit::"Import XML File to Data Exch.";
            DataExchDef."Ext. Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            DataExchDef."Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            DataExchDef.Insert(true);
        end else begin
            DataExchDef.Type := DataExchDef.Type::"Generic Import";
            DataExchDef."File Type" := DataExchDef."File Type"::Xml;
            DataExchDef."Header Lines" := 0;
            DataExchDef."Reading/Writing Codeunit" := Codeunit::"Import XML File to Data Exch.";
            if DataExchDef."Ext. Data Handling Codeunit" = 0 then
                DataExchDef."Ext. Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            if DataExchDef."Data Handling Codeunit" = 0 then
                DataExchDef."Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            DataExchDef.Modify(true);
        end;

        EnsureLineDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, Level3HeaderLineNameLbl, HeaderDataLineTagLbl, '', 9);
        EnsureLineDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, Level3DetailLineNameLbl, DetailDataLineTagLbl, Level3HeaderLineCodeTok, 7);

        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 1, 'ProviderTransId', '/Transactions/Transaction/ProviderTransId');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 2, 'CardId', '/Transactions/Transaction/CardId');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 3, 'TransDate', '/Transactions/Transaction/TransDate');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 4, 'PostingDate', '/Transactions/Transaction/PostingDate');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 5, 'Amount', '/Transactions/Transaction/Amount');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 6, 'CurrencyCode', '/Transactions/Transaction/CurrencyCode');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 7, 'MerchantRaw', '/Transactions/Transaction/MerchantRaw');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 8, 'MCC', '/Transactions/Transaction/MCC');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 9, 'Country', '/Transactions/Transaction/Country');

        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 1, 'ProviderTransId', '/Transactions/Transaction/ProviderTransId');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 2, 'Description', '/Transactions/Transaction/Level3/TaxLine/Description');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 3, 'Quantity', '/Transactions/Transaction/Level3/TaxLine/Quantity');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 4, 'UnitCost', '/Transactions/Transaction/Level3/TaxLine/UnitCost');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 5, 'VATAmount', '/Transactions/Transaction/Level3/TaxLine/VATAmount');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 6, 'TaxAmount', '/Transactions/Transaction/Level3/TaxLine/TaxAmount');
        EnsureColumnDef(Level3DataExchDefCodeTok, Level3DetailLineCodeTok, 7, 'TaxCode', '/Transactions/Transaction/Level3/TaxLine/TaxCode');

        if not DataExchMapping.Get(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, Database::"EA Corp Card Trans") then begin
            DataExchMapping.Init();
            DataExchMapping."Data Exch. Def Code" := Level3DataExchDefCodeTok;
            DataExchMapping."Data Exch. Line Def Code" := Level3HeaderLineCodeTok;
            DataExchMapping."Table ID" := Database::"EA Corp Card Trans";
            DataExchMapping.Name := Level3MappingNameLbl;
            DataExchMapping."Mapping Codeunit" := Codeunit::"EA Corp Card DE Noop";
            DataExchMapping.Insert(true);
        end;

        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 1, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Provider Trans Id"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 2, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Card Id"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 3, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Trans Date"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 4, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Posting Date"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 5, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(Amount));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 6, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Currency Code"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 7, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo("Merchant Raw"));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 8, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(MCC));
        EnsureFieldMapping(Level3DataExchDefCodeTok, Level3HeaderLineCodeTok, 9, Database::"EA Corp Card Trans", CorpCardTrans.FieldNo(Country));
    end;

    local procedure EnsureLineDef(DataExchDefCode: Code[20]; LineCode: Code[20]; LineName: Text[100]; DataLineTag: Text[250]; ParentCode: Code[20]; ColumnCount: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        if not DataExchLineDef.Get(DataExchDefCode, LineCode) then begin
            DataExchLineDef.Init();
            DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
            DataExchLineDef.Code := LineCode;
            DataExchLineDef.Name := LineName;
            DataExchLineDef."Data Line Tag" := DataLineTag;
            DataExchLineDef."Parent Code" := ParentCode;
            DataExchLineDef."Column Count" := ColumnCount;
            DataExchLineDef.Insert(true);
            exit;
        end;

        DataExchLineDef.Name := LineName;
        DataExchLineDef."Data Line Tag" := DataLineTag;
        DataExchLineDef."Parent Code" := ParentCode;
        DataExchLineDef."Column Count" := ColumnCount;
        DataExchLineDef.Modify(true);
    end;

    local procedure EnsureColumnDef(DataExchDefCode: Code[20]; LineCode: Code[20]; ColumnNo: Integer; ColumnName: Text[100]; PathTxt: Text[250])
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
    begin
        if DataExchColumnDef.Get(DataExchDefCode, LineCode, ColumnNo) then begin
            DataExchColumnDef.Name := ColumnName;
            DataExchColumnDef.Path := PathTxt;
            DataExchColumnDef.Show := true;
            DataExchColumnDef.Modify(true);
            exit;
        end;

        DataExchColumnDef.Init();
        DataExchColumnDef."Data Exch. Def Code" := DataExchDefCode;
        DataExchColumnDef."Data Exch. Line Def Code" := LineCode;
        DataExchColumnDef."Column No." := ColumnNo;
        DataExchColumnDef.Name := ColumnName;
        DataExchColumnDef.Path := PathTxt;
        DataExchColumnDef.Show := true;
        DataExchColumnDef.Insert(true);
    end;

    local procedure EnsureFieldMapping(DataExchDefCode: Code[20]; LineCode: Code[20]; ColumnNo: Integer; TableId: Integer; FieldId: Integer)
    var
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        DataExchFieldMapping.Reset();
        DataExchFieldMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchFieldMapping.SetRange("Data Exch. Line Def Code", LineCode);
        DataExchFieldMapping.SetRange("Table ID", TableId);
        DataExchFieldMapping.SetRange("Column No.", ColumnNo);
        if DataExchFieldMapping.FindFirst() then begin
            if DataExchFieldMapping."Field ID" <> FieldId then begin
                DataExchFieldMapping."Field ID" := FieldId;
                DataExchFieldMapping.Modify(true);
            end;
            exit;
        end;

        DataExchFieldMapping.Init();
        DataExchFieldMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchFieldMapping."Data Exch. Line Def Code" := LineCode;
        DataExchFieldMapping."Table ID" := TableId;
        DataExchFieldMapping."Column No." := ColumnNo;
        DataExchFieldMapping."Field ID" := FieldId;
        DataExchFieldMapping.Insert(true);
    end;

    local procedure EnsureSamplePayload()
    var
        CorpCardProvider: Record "EA Corp Card Provider";
        ProviderOutStr: OutStream;
    begin
        if not CorpCardProvider.Get(Level3ProviderCodeTok) then
            exit;

        Clear(CorpCardProvider."Source Payload");
        CorpCardProvider."Source Payload".CreateOutStream(ProviderOutStr, TextEncoding::UTF8);
        ProviderOutStr.WriteText(GetLevel3SamplePayload());
        CorpCardProvider."Source File Name" := Level3SourceFileNameTok;
        CorpCardProvider.Modify(true);
    end;

    local procedure GetLevel3SamplePayload(): Text
    var
        PrimaryCardId: Code[50];
        SecondaryCardId: Code[50];
    begin
        GetDemoCardIds(PrimaryCardId, SecondaryCardId);

        exit(
          '<?xml version="1.0" encoding="utf-8"?>' +
          '<Transactions>' +
            '<Transaction>' +
              '<ProviderTransId>L3TXN0001</ProviderTransId>' +
                            '<CardId>' + PrimaryCardId + '</CardId>' +
              '<TransDate>2026-06-14</TransDate>' +
              '<PostingDate>2026-06-15</PostingDate>' +
              '<Amount>245.00</Amount>' +
              '<CurrencyCode>EUR</CurrencyCode>' +
              '<MerchantRaw>Fabrikam Hotel</MerchantRaw>' +
              '<MCC>7011</MCC>' +
              '<Country>DE</Country>' +
              '<Level3>' +
                '<TaxLine>' +
                  '<Description>Room charge</Description>' +
                  '<Quantity>1</Quantity>' +
                  '<UnitCost>200.00</UnitCost>' +
                  '<VATAmount>24.00</VATAmount>' +
                  '<TaxAmount>24.00</TaxAmount>' +
                  '<TaxCode>VAT12</TaxCode>' +
                '</TaxLine>' +
                '<TaxLine>' +
                  '<Description>Breakfast</Description>' +
                  '<Quantity>1</Quantity>' +
                  '<UnitCost>20.00</UnitCost>' +
                  '<VATAmount>1.00</VATAmount>' +
                  '<TaxAmount>1.00</TaxAmount>' +
                  '<TaxCode>VAT5</TaxCode>' +
                '</TaxLine>' +
              '</Level3>' +
            '</Transaction>' +
            '<Transaction>' +
              '<ProviderTransId>L3TXN0002</ProviderTransId>' +
                            '<CardId>' + SecondaryCardId + '</CardId>' +
              '<TransDate>2026-06-16</TransDate>' +
              '<PostingDate>2026-06-17</PostingDate>' +
              '<Amount>112.00</Amount>' +
              '<CurrencyCode>EUR</CurrencyCode>' +
              '<MerchantRaw>Contoso Restaurant</MerchantRaw>' +
              '<MCC>5812</MCC>' +
              '<Country>DE</Country>' +
              '<Level3>' +
                '<TaxLine>' +
                  '<Description>Meal</Description>' +
                  '<Quantity>1</Quantity>' +
                  '<UnitCost>100.00</UnitCost>' +
                  '<VATAmount>12.00</VATAmount>' +
                  '<TaxAmount>12.00</TaxAmount>' +
                  '<TaxCode>VAT12</TaxCode>' +
                '</TaxLine>' +
              '</Level3>' +
            '</Transaction>' +
          '</Transactions>');
    end;

    local procedure EnsureProviderCardLinks()
    var
        ExpenseUser: Record "Expense User";
        CorpCard: Record "EA Corp Card";
    begin
        if not ExpenseUser.FindSet() then
            exit;

        repeat
            CorpCard.Reset();
            CorpCard.SetRange("Provider Code", Level3ProviderCodeTok);
            CorpCard.SetRange("Expense User No.", ExpenseUser."No.");
            if not CorpCard.IsEmpty() then
                continue;

            CorpCard.Init();
            CorpCard."Card Id" := GetNextCardId();
            CorpCard."Provider Code" := Level3ProviderCodeTok;
            CorpCard."Expense User No." := ExpenseUser."No.";
            CorpCard."External Card Ref" := CopyStr(ExpenseUser."No.", 1, MaxStrLen(CorpCard."External Card Ref"));
            CorpCard."Masked Card No." := BuildMaskedCardNo(CorpCard."Card Id");
            CorpCard."Valid From" := Today();
            CorpCard.Insert(true);
        until ExpenseUser.Next() = 0;

        EnsureSampleCardIdsForLevel3Provider();
    end;

    local procedure EnsureSampleCardIdsForLevel3Provider()
    var
        CorpCard: Record "EA Corp Card";
        ExistingProviderCard: Record "EA Corp Card";
        TargetCardId: Code[50];
        ExternalRef: Code[50];
        FallbackExpenseUserNo: Code[20];
        SequenceNo: Integer;
    begin
        ExistingProviderCard.SetRange("Provider Code", Level3ProviderCodeTok);
        ExistingProviderCard.SetFilter("Expense User No.", '<>%1', '');
        if ExistingProviderCard.FindFirst() then
            FallbackExpenseUserNo := ExistingProviderCard."Expense User No.";

        for SequenceNo := 1 to 6 do begin
            TargetCardId := CopyStr(StrSubstNo('%1-%2', Level3CardPrefixTok, PadNumberLeft(SequenceNo, 4)), 1, MaxStrLen(TargetCardId));
            if CorpCard.Get(TargetCardId) then
                continue;

            CorpCard.Init();
            CorpCard."Card Id" := TargetCardId;
            CorpCard."Provider Code" := Level3ProviderCodeTok;
            CorpCard."Expense User No." := FallbackExpenseUserNo;
            if FallbackExpenseUserNo <> '' then
                ExternalRef := CopyStr(FallbackExpenseUserNo, 1, MaxStrLen(ExternalRef))
            else
                ExternalRef := CopyStr(StrSubstNo('%1-%2', Level3ProviderCodeTok, PadNumberLeft(SequenceNo, 4)), 1, MaxStrLen(ExternalRef));
            CorpCard."External Card Ref" := ExternalRef;
            CorpCard."Masked Card No." := BuildMaskedCardNo(CorpCard."Card Id");
            CorpCard."Valid From" := Today();
            CorpCard.Insert(true);
        end;
    end;

    local procedure GetDemoCardIds(var PrimaryCardId: Code[50]; var SecondaryCardId: Code[50])
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetRange("Provider Code", Level3ProviderCodeTok);
        if CorpCard.FindSet() then begin
            PrimaryCardId := CorpCard."Card Id";
            if CorpCard.Next() <> 0 then
                SecondaryCardId := CorpCard."Card Id";
        end;

        if PrimaryCardId = '' then
            PrimaryCardId := 'CRDL3-0001';
        if SecondaryCardId = '' then
            SecondaryCardId := PrimaryCardId;
    end;

    local procedure GetNextCardId(): Code[50]
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

    var
        Level3ProviderCodeTok: Label 'CORPCARDL3', MaxLength = 20, Locked = true;
        Level3ProviderDescriptionLbl: Label 'Corporate Card Level 3 Demo';
        Level3DataExchDefCodeTok: Label 'EACCL3VAT', MaxLength = 20, Locked = true;
        Level3HeaderLineCodeTok: Label 'L3HDR', MaxLength = 20, Locked = true;
        Level3DetailLineCodeTok: Label 'L3DTL', MaxLength = 20, Locked = true;
        Level3DataExchDefNameLbl: Label 'Corporate Card Level 3 VAT Demo Import';
        Level3HeaderLineNameLbl: Label 'Corporate Card Transactions';
        Level3DetailLineNameLbl: Label 'Corporate Card Tax Details';
        Level3MappingNameLbl: Label 'Corp Card Level 3 Header Mapping';
        Level3SourceFileNameTok: Label 'CorpCard-Level3-Demo.xml', MaxLength = 250, Locked = true;
        HeaderDataLineTagLbl: Label '/Transactions/Transaction';
        DetailDataLineTagLbl: Label '/Transactions/Transaction/Level3/TaxLine';
        Level3CardPrefixTok: Label 'CRDL3', Locked = true;
        CardIDTok: Label 'CARD-%1', Locked = true;
}