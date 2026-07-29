// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.IO;

codeunit 6913 EACorpCardDESeed
{
    Access = Internal;
    Permissions = tabledata "Data Exch. Def" = rimd,
                  tabledata "Data Exch. Line Def" = rimd,
                  tabledata "Data Exch. Column Def" = rimd,
                  tabledata "Data Exch. Mapping" = rimd,
                  tabledata "Data Exch. Field Mapping" = rimd,
                  tabledata EACorpCardProvider = rm;

    internal procedure EnsureForProvider(var CorpCardProvider: Record EACorpCardProvider)
    begin
        EnsureProviderDefaults(CorpCardProvider);
        EnsureDataExchDefinition(CorpCardProvider."Data Exch Def Code", IsXmlDefinitionCode(CorpCardProvider."Data Exch Def Code"));
        EnsureDataExchLineAndColumns(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code", IsXmlDefinitionCode(CorpCardProvider."Data Exch Def Code"));
        EnsureDataExchMapping(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");
        EnsureFieldMappings(CorpCardProvider."Data Exch Def Code", CorpCardProvider."Data Exch Map Code");

        // Seed both predefined setups so admins can switch between CSV/XML without manual rebuild.
        EnsureDataExchDefinition(CorpCardCsvDataExchDefCodeTok, false);
        EnsureDataExchLineAndColumns(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok, false);
        EnsureDataExchMapping(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok);
        EnsureFieldMappings(CorpCardCsvDataExchDefCodeTok, CorpCardCsvDataExchLineCodeTok);

        EnsureDataExchDefinition(CorpCardXmlDataExchDefCodeTok, true);
        EnsureDataExchLineAndColumns(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok, true);
        EnsureDataExchMapping(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok);
        EnsureFieldMappings(CorpCardXmlDataExchDefCodeTok, CorpCardXmlDataExchLineCodeTok);

        EnsureDataExchDefinition(CorpCardCamtDataExchDefCodeTok, true);
        EnsureDataExchLineAndColumns(CorpCardCamtDataExchDefCodeTok, CorpCardCamtDataExchLineCodeTok, true);
        EnsureDataExchMapping(CorpCardCamtDataExchDefCodeTok, CorpCardCamtDataExchLineCodeTok);
        EnsureFieldMappings(CorpCardCamtDataExchDefCodeTok, CorpCardCamtDataExchLineCodeTok);
    end;

    local procedure EnsureProviderDefaults(var CorpCardProvider: Record EACorpCardProvider)
    var
        IsXmlSource: Boolean;
        IsModified: Boolean;
        DesiredDefCode: Code[20];
        DesiredLineCode: Code[20];
    begin
        if IsCamtFileName(CorpCardProvider."Source File Name") then begin
            DesiredDefCode := CorpCardCamtDataExchDefCodeTok;
            DesiredLineCode := CorpCardCamtDataExchLineCodeTok;
        end else begin
            IsXmlSource := IsXmlFileName(CorpCardProvider."Source File Name");
            if IsXmlSource then begin
                DesiredDefCode := CorpCardXmlDataExchDefCodeTok;
                DesiredLineCode := CorpCardXmlDataExchLineCodeTok;
            end else begin
                DesiredDefCode := CorpCardCsvDataExchDefCodeTok;
                DesiredLineCode := CorpCardCsvDataExchLineCodeTok;
            end;
        end;

        if (CorpCardProvider."Data Exch Def Code" = '') or IsKnownDefaultDefinition(CorpCardProvider."Data Exch Def Code") then
            if CorpCardProvider."Data Exch Def Code" <> DesiredDefCode then begin
                CorpCardProvider."Data Exch Def Code" := DesiredDefCode;
                IsModified := true;
            end;

        if (CorpCardProvider."Data Exch Map Code" = '') or IsKnownDefaultLineCode(CorpCardProvider."Data Exch Map Code") then
            if CorpCardProvider."Data Exch Map Code" <> DesiredLineCode then begin
                CorpCardProvider."Data Exch Map Code" := DesiredLineCode;
                IsModified := true;
            end;

        if IsModified then
            CorpCardProvider.Modify(true);
    end;

    local procedure IsKnownDefaultDefinition(DataExchDefCode: Code[20]): Boolean
    begin
        exit(DataExchDefCode in [CorpCardCsvDataExchDefCodeTok, CorpCardXmlDataExchDefCodeTok, CorpCardCamtDataExchDefCodeTok]);
    end;

    local procedure IsKnownDefaultLineCode(LineCode: Code[20]): Boolean
    begin
        exit(LineCode in [CorpCardCsvDataExchLineCodeTok, CorpCardXmlDataExchLineCodeTok, CorpCardCamtDataExchLineCodeTok]);
    end;

    local procedure IsXmlDefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit((DataExchDefCode = CorpCardXmlDataExchDefCodeTok) or (DataExchDefCode = CorpCardCamtDataExchDefCodeTok));
    end;

    local procedure IsCamtDefinitionCode(DataExchDefCode: Code[20]): Boolean
    begin
        exit(DataExchDefCode = CorpCardCamtDataExchDefCodeTok);
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

    local procedure EnsureDataExchDefinition(DataExchDefCode: Code[20]; IsXml: Boolean)
    var
        DataExchDef: Record "Data Exch. Def";
        IsModified: Boolean;
    begin
        if not DataExchDef.Get(DataExchDefCode) then begin
            DataExchDef.Init();
            DataExchDef.Code := DataExchDefCode;
            if IsCamtDefinitionCode(DataExchDefCode) then
                DataExchDef.Name := CorpCardCamtDataExchDefNameLbl
            else
                if IsXml then
                    DataExchDef.Name := CorpCardXmlDataExchDefNameLbl
                else
                    DataExchDef.Name := CorpCardCsvDataExchDefNameLbl;
            if IsXml then
                DataExchDef."Header Lines" := 0
            else
                DataExchDef."Header Lines" := 1;
            DataExchDef."Ext. Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            DataExchDef."Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            ApplyTemplateDefaults(DataExchDef, IsXml);
            DataExchDef.Insert(true);
            exit;
        end;

        if IsCamtDefinitionCode(DataExchDefCode) then begin
            if DataExchDef.Name <> CorpCardCamtDataExchDefNameLbl then begin
                DataExchDef.Name := CorpCardCamtDataExchDefNameLbl;
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

        if DataExchDef."Ext. Data Handling Codeunit" = 0 then begin
            DataExchDef."Ext. Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            IsModified := true;
        end;

        if DataExchDef."Data Handling Codeunit" = 0 then begin
            DataExchDef."Data Handling Codeunit" := Codeunit::"Process Data Exch.";
            IsModified := true;
        end;

        if IsModified then
            DataExchDef.Modify(true);
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
        IsCamt: Boolean;
        IsModified: Boolean;
    begin
        IsCamt := IsCamtDefinitionCode(DataExchDefCode);

        DataExchLineDef.Reset();
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchLineDef.SetRange(Code, LineDefCode);
        if not DataExchLineDef.FindFirst() then begin
            DataExchLineDef.Init();
            DataExchLineDef."Data Exch. Def Code" := DataExchDefCode;
            DataExchLineDef.Code := LineDefCode;
            if IsCamt then
                DataExchLineDef.Name := CorpCardCamtDataExchLineNameLbl
            else
                if IsXml then
                    DataExchLineDef.Name := CorpCardXmlDataExchLineNameLbl
                else
                    DataExchLineDef.Name := CorpCardCsvDataExchLineNameLbl;
            DataExchLineDef."Column Count" := 10;
            if IsCamt then
                DataExchLineDef."Data Line Tag" := CorpCardCamtDataLineTagLbl
            else
                if IsXml then
                    DataExchLineDef."Data Line Tag" := CorpCardXmlDataLineTagLbl;
            DataExchLineDef.Insert(true);
        end else begin
            if IsCamt then begin
                if DataExchLineDef."Data Line Tag" <> CorpCardCamtDataLineTagLbl then begin
                    DataExchLineDef."Data Line Tag" := CorpCardCamtDataLineTagLbl;
                    IsModified := true;
                end;
                if DataExchLineDef.Name <> CorpCardCamtDataExchLineNameLbl then begin
                    DataExchLineDef.Name := CorpCardCamtDataExchLineNameLbl;
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

        case NodeName of
            'ProviderTransId':
                exit('Refs/EndToEndId');
            'CardId':
                exit('RmtInf/Ustrd');
            'TransDate':
                exit('RltdDts/IntrBkSttlmDt/Dt');
            'PostingDate':
                exit('RltdDts/IntrBkSttlmDt/Dt');
            'Amount':
                exit('AmtDtls/TxAmt/Amt');
            'CurrencyCode':
                exit('AmtDtls/TxAmt/Amt');
            'MerchantRaw':
                exit('RltdPties/Cdtr/Nm');
            'MCC':
                exit('AddtlTxInf');
            'Country':
                exit('RltdPties/Cdtr/PstlAdr/Ctry');
            'Notes':
                exit('AddtlTxInf');
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
        DataExchMapping.SetRange("Table ID", Database::EACorpCardTrans);
        if DataExchMapping.FindSet() then
            repeat
                IsModified := false;
                if DataExchMapping."Data Exch. Line Def Code" = '' then begin
                    DataExchMapping."Data Exch. Line Def Code" := LineDefCode;
                    IsModified := true;
                end;
                if DataExchMapping."Mapping Codeunit" = 0 then begin
                    DataExchMapping."Mapping Codeunit" := Codeunit::EACorpCardDENoop;
                    IsModified := true;
                end;
                if IsModified then
                    DataExchMapping.Modify(true);
            until DataExchMapping.Next() = 0;

        DataExchMapping.Reset();
        DataExchMapping.SetRange("Data Exch. Def Code", DataExchDefCode);
        DataExchMapping.SetRange("Data Exch. Line Def Code", LineDefCode);
        DataExchMapping.SetRange("Table ID", Database::EACorpCardTrans);
        if DataExchMapping.FindFirst() then begin
            if DataExchMapping."Mapping Codeunit" = 0 then begin
                DataExchMapping."Mapping Codeunit" := Codeunit::EACorpCardDENoop;
                IsModified := true;
            end;

            if IsModified then
                DataExchMapping.Modify(true);
            exit;
        end;

        DataExchMapping.Init();
        DataExchMapping."Data Exch. Def Code" := DataExchDefCode;
        DataExchMapping."Data Exch. Line Def Code" := LineDefCode;
        DataExchMapping."Table ID" := Database::EACorpCardTrans;
        DataExchMapping.Name := CorpCardDataExchMappingNameLbl;
        DataExchMapping."Mapping Codeunit" := Codeunit::EACorpCardDENoop;
        DataExchMapping.Insert(true);
    end;

    local procedure EnsureFieldMappings(DataExchDefCode: Code[20]; LineDefCode: Code[20])
    var
        CorpCardTrans: Record EACorpCardTrans;
    begin
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 1, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Provider Trans Id"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 2, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Card Id"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 3, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Trans Date"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 4, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Posting Date"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 5, Database::EACorpCardTrans, CorpCardTrans.FieldNo(Amount));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 6, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Currency Code"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 7, Database::EACorpCardTrans, CorpCardTrans.FieldNo("Merchant Raw"));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 8, Database::EACorpCardTrans, CorpCardTrans.FieldNo(MCC));
        EnsureFieldMapping(DataExchDefCode, LineDefCode, 9, Database::EACorpCardTrans, CorpCardTrans.FieldNo(Country));
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
        CorpCardCsvDataExchDefCodeTok: Label 'EACCARDCSV', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchLineCodeTok: Label 'TRANS', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchDefCodeTok: Label 'EACCARDXML', MaxLength = 20, Locked = true;
        CorpCardXmlDataExchLineCodeTok: Label 'TRANSXML', MaxLength = 20, Locked = true;
        CorpCardCamtDataExchDefCodeTok: Label 'EACCARDCAMT', MaxLength = 20, Locked = true;
        CorpCardCamtDataExchLineCodeTok: Label 'TRANSCAMT', MaxLength = 20, Locked = true;
        CorpCardCsvDataExchDefNameLbl: Label 'Corporate Card CSV Import';
        CorpCardXmlDataExchDefNameLbl: Label 'Corporate Card XML Import';
        CorpCardCamtDataExchDefNameLbl: Label 'Corporate Card CAMT Import';
        CorpCardCsvDataExchLineNameLbl: Label 'Transactions';
        CorpCardXmlDataExchLineNameLbl: Label 'Transactions';
        CorpCardCamtDataExchLineNameLbl: Label 'CAMT Transactions';
        CorpCardXmlDataLineTagLbl: Label 'Transaction';
        CorpCardCamtDataLineTagLbl: Label 'TxDtls';
        CorpCardDataExchMappingNameLbl: Label 'Corp Card Transaction Mapping';
}
