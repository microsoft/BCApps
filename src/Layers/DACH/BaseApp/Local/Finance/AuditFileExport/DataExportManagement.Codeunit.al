// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AuditFileExport;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System;
using System.IO;
using System.Xml;

codeunit 11000 "Data Export Management"
{
    Permissions = TableData "Data Export Setup" = rim;

    trigger OnRun()
    begin
    end;

    var
        IndentQst: Label 'There are table relations defined for the table %1. If you indent the table, the relation will be deleted. Do you want to continue?';
        UnindentQst: Label 'There are table relations defined for the table %1. If you unindent the table, the relation will be deleted. Do you want to continue?';
        RelationsExistErr: Label 'Table relations only exist for indented tables.';
        GLSetup: Record "General Ledger Setup";
        IndexNotCreatedErr: Label 'The index.xml file was not created.';
        GLAccTxt: Label 'GLAcc 2022', Locked = true;
        FAAccTxt: Label 'FAAcc 2022', Locked = true;
        ItemAccTxt: Label 'Item 2022', Locked = true;
        GLAccRenamedTxt: Label 'GLAcc22~%1', Comment = '%1 - index number like 1, 2, 3 etc.', Locked = true;
        FAAccRenamedTxt: Label 'FAAcc22~%1', Comment = '%1 - index number like 1, 2, 3 etc.', Locked = true;
        ItemAccRenamedTxt: Label 'Item 22~%1', Comment = '%1 - index number like 1, 2, 3 etc.', Locked = true;
        GLAccDefinitionTxt: Label 'Required data for exporting G/L and personal data';
        FAAccDefinitionTxt: Label 'Required data for exporting Fixed Asset data';
        ItemAccDefinitionTxt: Label 'Required data for exporting Item and Invoice data';

    [Scope('OnPrem')]
    procedure UpdateTableRelation(DataExportRecordSource: Record "Data Export Record Source")
    var
        DataExportTableRelationPage: Page "Data Export Table Relation";
    begin
        if DataExportRecordSource."Relation To Table No." = 0 then
            Error(RelationsExistErr);

        DataExportRecordSource.FilterGroup(2);
        DataExportRecordSource.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
        DataExportRecordSource.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
        DataExportRecordSource.SetRange("Line No.", DataExportRecordSource."Line No.");
        DataExportRecordSource.FilterGroup(0);
        Clear(DataExportTableRelationPage);
        DataExportTableRelationPage.SetTableView(DataExportRecordSource);
        DataExportTableRelationPage.RunModal();
    end;

    [Scope('OnPrem')]
    procedure UpdateSourceIndentation(var DataExportRecordSource: Record "Data Export Record Source"; OldIndentation: Integer)
    var
        RelDataExportRecordSource: Record "Data Export Record Source";
        FoundRelation: Boolean;
        Indented: Boolean;
    begin
        DataExportRecordSource.CalcFields("Table Relation Defined", "Table Name");
        if DataExportRecordSource."Table Relation Defined" then
            case true of
                OldIndentation < DataExportRecordSource.Indentation:
                    if not Confirm(IndentQst, false, DataExportRecordSource."Table Name") then begin
                        DataExportRecordSource.Indentation := OldIndentation;
                        exit;
                    end;
                else
                    if not Confirm(UnindentQst, false, DataExportRecordSource."Table Name") then begin
                        DataExportRecordSource.Indentation := OldIndentation;
                        exit;
                    end;
            end;

        FoundRelation := false;
        case true of
            DataExportRecordSource.Indentation < 0:
                DataExportRecordSource.Indentation := 0;
            DataExportRecordSource.Indentation = 0:
                begin
                    FoundRelation := true;
                    DataExportRecordSource."Relation To Table No." := 0;
                    DataExportRecordSource."Relation To Line No." := 0;
                end;
            else begin
                RelDataExportRecordSource.Copy(DataExportRecordSource);
                if RelDataExportRecordSource.Find('<') then begin
                    if RelDataExportRecordSource.Indentation >= DataExportRecordSource.Indentation - 1 then
                        repeat
                            if RelDataExportRecordSource.Indentation = DataExportRecordSource.Indentation - 1 then begin
                                FoundRelation := true;
                                DataExportRecordSource."Relation To Table No." := RelDataExportRecordSource."Table No.";
                                DataExportRecordSource."Relation To Line No." := RelDataExportRecordSource."Line No.";
                            end;
                        until (RelDataExportRecordSource.Next(-1) = 0) or FoundRelation
                    else
                        DataExportRecordSource.Indentation := OldIndentation;
                end else
                    DataExportRecordSource.Indentation := OldIndentation
            end;
        end;

        if FoundRelation then begin
            RelDataExportRecordSource.Copy(DataExportRecordSource);
            if RelDataExportRecordSource.Find('>') then
                if OldIndentation < DataExportRecordSource.Indentation then // indent:
                    repeat
                        Indented := false;
                        if RelDataExportRecordSource.Indentation > OldIndentation then begin
                            RelDataExportRecordSource.Indentation := RelDataExportRecordSource.Indentation + DataExportRecordSource.Indentation - OldIndentation;
                            Indented := true;
                            RelDataExportRecordSource.Modify();
                        end;
                    until (not Indented) or (RelDataExportRecordSource.Next() = 0)
                else // unindent:
                    repeat
                        Indented := false;
                        if RelDataExportRecordSource.Indentation >= OldIndentation then begin
                            RelDataExportRecordSource.Indentation := RelDataExportRecordSource.Indentation + DataExportRecordSource.Indentation - OldIndentation;
                            if RelDataExportRecordSource.Indentation = DataExportRecordSource.Indentation then begin
                                RelDataExportRecordSource."Relation To Table No." := DataExportRecordSource."Relation To Table No.";
                                RelDataExportRecordSource."Relation To Line No." := DataExportRecordSource."Relation To Line No.";
                            end;
                            RelDataExportRecordSource.Modify();
                            Indented := true;
                        end;
                    until (not Indented) or (RelDataExportRecordSource.Next() = 0);
        end;

        if FoundRelation then begin
            DataExportRecordSource.Modify();
            DeleteTableRelation(DataExportRecordSource."Data Export Code", DataExportRecordSource."Data Exp. Rec. Type Code", DataExportRecordSource."Table No.");
        end;
    end;

    local procedure DeleteTableRelation(DataExportCode: Code[10]; RecordCode: Code[10]; TableNo: Integer)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
    begin
        DataExportTableRelation.Reset();
        DataExportTableRelation.SetRange("Data Export Code", DataExportCode);
        DataExportTableRelation.SetRange("Data Exp. Rec. Type Code", RecordCode);
        DataExportTableRelation.SetRange("To Table No.", TableNo);
        DataExportTableRelation.DeleteAll();
    end;

    [Scope('OnPrem')]
    procedure CreateIndexXML(var TempDataExportRecordSource: Record "Data Export Record Source" temporary; ExportPath: Text; Description: Text; StartDate: Date; EndDate: Date; DTDFileName: Text)
    var
        DataExportRecordDefinition: Record "Data Export Record Definition";
        OutStr: OutStream;
        IndexFile: File;
    begin
        if DataExportRecordDefinition.Get(
             TempDataExportRecordSource."Data Export Code", TempDataExportRecordSource."Data Exp. Rec. Type Code")
        then
            ;

        IndexFile.Create(ExportPath + '\' + IndexFileName());
        IndexFile.CreateOutStream(OutStr);
        CreateIndexXmlStream(
          TempDataExportRecordSource, OutStr, Description, StartDate, EndDate,
          DTDFileName, Format(DataExportRecordDefinition."File Encoding"));
        IndexFile.Close();
    end;

    [Scope('OnPrem')]
    procedure CreateIndexXmlStream(var TempDataExportRecordSource: Record "Data Export Record Source" temporary; OutStr: OutStream; Description: Text; StartDate: Date; EndDate: Date; DTDFileName: Text; FileEncoding: Text)
    var
        DataExportRecField: Record "Data Export Record Field";
        CompanyInfo: Record "Company Information";
        TempPKDataExportRecordField: Record "Data Export Record Field" temporary;
        TempNonPKDataExportRecordField: Record "Data Export Record Field" temporary;
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLDocOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlElement;
        XMLMediaNode: DotNet XmlElement;
        Symbol: array[2] of Text[1];
    begin
        GLSetup.Get();

        if IsNull(XMLDocOut) then
            XMLDocOut := XMLDocOut.XmlDocument();

        LoadEmptyIndexXMLWithDTD(XMLDocOut, DTDFileName);

        if XMLDocOut.OuterXml = '' then
            Error(IndexNotCreatedErr);

        CompanyInfo.Get();
        XMLCurrNode := XMLDocOut.DocumentElement;
        XMLDOMManagement.AddNode(XMLCurrNode, 'Version', '');
        XMLDOMManagement.AddGroupNode(XMLCurrNode, 'DataSupplier');
        XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(CompanyName));
        XMLDOMManagement.AddNode(XMLCurrNode, 'Location',
          ConvertString(CompanyInfo.Address) + ' ' + ConvertString(CompanyInfo."Address 2") + ' ' +
          ConvertString(CompanyInfo."Post Code") + ' ' + ConvertString(CompanyInfo.City));
        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Comment', ConvertString(Description));
        if TempDataExportRecordSource.FindSet() then begin
            XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Media');
            XMLMediaNode := XMLCurrNode;
            XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(TempDataExportRecordSource."Data Exp. Rec. Type Code"));
            repeat
                XMLCurrNode := XMLMediaNode;
                XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Table');
                XMLDOMManagement.AddNode(XMLCurrNode, 'URL', ConvertString(TempDataExportRecordSource."Export File Name"));
                XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(TempDataExportRecordSource."Export Table Name"));
                TempDataExportRecordSource.CalcFields("Table Name");
                XMLDOMManagement.AddNode(XMLCurrNode, 'Description', ConvertString(TempDataExportRecordSource."Table Name"));
                if TempDataExportRecordSource."Period Field No." > 0 then begin
                    XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Validity');
                    XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Range');
                    XMLDOMManagement.AddNode(XMLCurrNode, 'From', Format(StartDate, 0, '<Day,2>.<Month,2>.<Year4>'));
                    XMLDOMManagement.AddLastNode(XMLCurrNode, 'To', Format(EndDate, 0, '<Day,2>.<Month,2>.<Year4>'));
                    XMLCurrNode := XMLCurrNode.ParentNode;
                end;
                XMLDOMManagement.AddNode(XMLCurrNode, FileEncoding, '');

                GetDelimiterSymbols(Symbol);
                XMLDOMManagement.AddNode(XMLCurrNode, 'DecimalSymbol', Symbol[1]);
                XMLDOMManagement.AddNode(XMLCurrNode, 'DigitGroupingSymbol', Symbol[2]);
                XMLDOMManagement.AddGroupNode(XMLCurrNode, 'VariableLength');
                FilterFields(DataExportRecField, TempDataExportRecordSource);
                CollectFieldNumbers(DataExportRecField, TempPKDataExportRecordField, TempNonPKDataExportRecordField);
                AddFieldsData(DataExportRecField, TempPKDataExportRecordField, 'VariablePrimaryKey', XMLCurrNode);
                AddFieldsData(DataExportRecField, TempNonPKDataExportRecordField, 'VariableColumn', XMLCurrNode);

            until TempDataExportRecordSource.Next() = 0;
        end;

        XMLDocOut.Save(OutStr);
        Clear(XMLDocOut);
    end;

    local procedure GetDelimiterSymbols(var Symbol: array[2] of Text[1])
    var
        DecimalSymbol: Decimal;
    begin
        DecimalSymbol := 1 / 10;
        if StrPos(Format(DecimalSymbol, 0, 1), ',') > 0 then begin
            Symbol[1] := ',';
            Symbol[2] := '.';
        end else begin
            Symbol[1] := '.';
            Symbol[2] := ',';
        end;
    end;

    local procedure FilterFields(var DataExportRecField: Record "Data Export Record Field"; DataExportRecordSource: Record "Data Export Record Source")
    begin
        DataExportRecField.SetRange("Data Export Code", DataExportRecordSource."Data Export Code");
        DataExportRecField.SetRange("Data Exp. Rec. Type Code", DataExportRecordSource."Data Exp. Rec. Type Code");
        DataExportRecField.SetRange("Table No.", DataExportRecordSource."Table No.");
        DataExportRecField.SetRange("Source Line No.", DataExportRecordSource."Line No.");
    end;

    local procedure CollectFieldNumbers(var DataExportRecField: Record "Data Export Record Field"; var TempPKDataExportRecordField: Record "Data Export Record Field" temporary; var TempNonPKDataExportRecordField: Record "Data Export Record Field" temporary)
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
    begin
        TempPKDataExportRecordField.DeleteAll();
        TempNonPKDataExportRecordField.DeleteAll();
        if DataExportRecField.FindSet() then begin
            RecRef.Open(DataExportRecField."Table No.");
            KeyRef := RecRef.KeyIndex(1);
            repeat
                if FieldIsInPrimaryKey(DataExportRecField."Field No.", KeyRef) then
                    AddFieldNoToBuffer(TempPKDataExportRecordField, DataExportRecField)
                else
                    AddFieldNoToBuffer(TempNonPKDataExportRecordField, DataExportRecField);
            until DataExportRecField.Next() = 0;
            RecRef.Close();
        end;
    end;

    local procedure FieldIsInPrimaryKey(FieldNumber: Integer; var KeyRef: KeyRef): Boolean
    var
        FieldRef: FieldRef;
        i: Integer;
    begin
        for i := 1 to KeyRef.FieldCount do begin
            FieldRef := KeyRef.FieldIndex(i);
            if FieldRef.Number = FieldNumber then
                exit(true);
        end;
        exit(false);
    end;

    local procedure AddFieldNoToBuffer(var TempDataExportRecordField: Record "Data Export Record Field" temporary; DataExportRecField: Record "Data Export Record Field")
    begin
        TempDataExportRecordField.Init();
        TempDataExportRecordField."Data Export Code" := DataExportRecField."Data Export Code";
        TempDataExportRecordField."Data Exp. Rec. Type Code" := DataExportRecField."Data Exp. Rec. Type Code";
        TempDataExportRecordField."Source Line No." := DataExportRecField."Source Line No.";
        TempDataExportRecordField."Table No." := DataExportRecField."Table No.";
        TempDataExportRecordField."Line No." := DataExportRecField."Line No.";
        TempDataExportRecordField."Field No." := DataExportRecField."Field No.";
        TempDataExportRecordField.Insert();
    end;

    local procedure AddFieldsData(var DataExportRecordField: Record "Data Export Record Field"; var TempDataExportRecordField: Record "Data Export Record Field" temporary; FieldTagName: Text; XMLRootNode: DotNet XmlElement)
    var
        DataExportRecordField2: Record "Data Export Record Field";
        XMLDOMManagement: Codeunit "XML DOM Management";
        XMLCurrNode: DotNet XmlElement;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        DataExportRecordField2.CopyFilters(DataExportRecordField);
        if DataExportRecordField2.FindFirst() then;
        RecRef.Open(DataExportRecordField2."Table No.");
        if TempDataExportRecordField.FindSet() then
            repeat
                FieldRef := RecRef.Field(TempDataExportRecordField."Field No.");

                XMLCurrNode := XMLRootNode;
                XMLDOMManagement.AddGroupNode(XMLCurrNode, FieldTagName);

                DataExportRecordField2.SetRange("Field No.", TempDataExportRecordField."Field No.");
                DataExportRecordField2.SetRange("Line No.", TempDataExportRecordField."Line No.");
                DataExportRecordField2.FindFirst();
                XMLDOMManagement.AddNode(XMLCurrNode, 'Name', ConvertString(DataExportRecordField2."Export Field Name"));
                DataExportRecordField2.CalcFields("Field Name");
                XMLDOMManagement.AddNode(XMLCurrNode, 'Description', ConvertString(DataExportRecordField2."Field Name"));

                case FieldRef.Type of
                    FieldType::Integer, FieldType::BigInteger:
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Numeric', '');
                    FieldType::Decimal:
                        begin
                            XMLDOMManagement.AddGroupNode(XMLCurrNode, 'Numeric');
                            XMLDOMManagement.AddLastNode(XMLCurrNode, 'Accuracy',
                              CopyStr(GLSetup."Amount Decimal Places", StrLen(GLSetup."Amount Decimal Places")));
                            XMLCurrNode := XMLCurrNode.ParentNode;
                        end;
                    FieldType::Date:
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'Date', '');
                    else
                        XMLDOMManagement.AddLastNode(XMLCurrNode, 'AlphaNumeric', '');
                end;
            until TempDataExportRecordField.Next() = 0;
        RecRef.Close();
    end;

    [Scope('OnPrem')]
    procedure FormatForIndexXML(InputText: Text[1024]): Text[50]
    begin
        InputText := DelChr(InputText, '=', '&''"<>');
        exit(CopyStr(ConvertString(InputText), 1, 50));
    end;

    procedure FormatFileName(InputText: Text): Text[250]
    begin
        InputText := DelChr(InputText, '=', '\/:*?"<>|~!$^&(){}[];'',@#`.-+=');
        InputText := DelChr(InputText, '=');
        exit(CopyStr(ConvertString(InputText), 1, 250));
    end;

    local procedure LoadEmptyIndexXMLWithDTD(var XMLDocOut: DotNet XmlDocument; DTDFileName: Text)
    var
        FileMgt: Codeunit "File Management";
        File: File;
        EmptyIndexXMLName: Text;
        EmptyDTDFileName: Text;
    begin
        EmptyIndexXMLName := FileMgt.ServerTempFileName('xml');
        EmptyDTDFileName := FileMgt.GetDirectoryName(EmptyIndexXMLName) + '\' + DTDFileName;
        File.TextMode(true);

        File.Create(EmptyDTDFileName);
        File.Close();

        File.Create(EmptyIndexXMLName);
        File.Write('<?xml version="1.0" encoding="UTF-8" ?>');
        File.Write('<!DOCTYPE DataSet SYSTEM "' + DTDFileName + '"><DataSet />');
        File.Close();
        // TFS 379960 - We keep XMLDocument.Load(FileName), because the validation against DTD file doesn't work for XmlDocument.Load(XmlTextReader)
        XMLDocOut.Load(EmptyIndexXMLName);
        Erase(EmptyIndexXMLName);
        Erase(EmptyDTDFileName);
    end;

    local procedure IndexFileName(): Text[30]
    begin
        exit('index.xml');
    end;

    local procedure ConvertString(String: Text) NewString: Text
    var
        StrLength: Integer;
        i: Integer;
    begin
        StrLength := StrLen(String);
        for i := 1 to StrLength do
            if String[i] in ['Ä', 'ä', 'Ö', 'ö', 'Ü', 'ü', 'ß'] then
                NewString := NewString + ConvertSpecialChars(String[i])
            else
                NewString := NewString + Format(String[i]);
    end;

    local procedure ConvertSpecialChars(Char: Char) Text: Text[2]
    begin
        case Char of
            'Ä':
                Text := 'Ae';
            'ä':
                Text := 'ae';
            'Ö':
                Text := 'Oe';
            'ö':
                Text := 'oe';
            'Ü':
                Text := 'Ue';
            'ü':
                Text := 'ue';
            'ß':
                Text := 'ss';
        end;
        exit(Text);
    end;

    procedure CreateDataExportForPersonalAndGLAccounting()
    var
        DataExportSetup: Record "Data Export Setup";
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportRecSource: Record "Data Export Record Source";
        DateFilterHandling: Option " ",Period,EndDate,StartDate;
        DataExportCode: Code[10];
        DataExpRecTypeCode: Code[10];
        CountryLineNo: Integer;
        GLAccLineNo: Integer;
        GLEntryLineNo: Integer;
        CustomerLineNo: Integer;
        CustLELineNo: Integer;
        DtldCustLELineNo: Integer;
        VendorLineNo: Integer;
        VendorLELineNo: Integer;
        DtldVendLELineNo: Integer;
        GLRegisterLineNo: Integer;
        GLSetupLineNo: Integer;
        VATEntryLineNo: Integer;
        VATSetupLineNo: Integer;
        DimValueLineNo: Integer;
        IndentationOne: Integer;
        IndentationTwo: Integer;
        FieldIdList: List of [Integer];
    begin
        if DataExportSetup.Get() then
            if DataExportSetup."Data Export 2022 G/L Acc. Code" <> '' then
                exit;

        CountryLineNo := 10000;
        GLAccLineNo := 20000;
        GLEntryLineNo := 30000;
        CustomerLineNo := 40000;
        CustLELineNo := 50000;
        DtldCustLELineNo := 60000;
        VendorLineNo := 70000;
        VendorLELineNo := 80000;
        DtldVendLELineNo := 90000;
        GLRegisterLineNo := 100000;
        GLSetupLineNo := 110000;
        VATEntryLineNo := 120000;
        VATSetupLineNo := 130000;
        DimValueLineNo := 140000;
        IndentationOne := 1;
        IndentationTwo := 2;
        DataExportCode := GetDataExportCode(GLAccTxt, GLAccRenamedTxt);
        DataExpRecTypeCode := GetDataExpRecTypeCode(GLAccTxt, GLAccRenamedTxt);

        InsertDataDef(DataExportCode, GLAccDefinitionTxt);
        InsertDataRecord(DataExpRecTypeCode, GLAccDefinitionTxt);
        InsertDataRecordDef(DataExportRecDef, DataExportCode, DataExpRecTypeCode, GLAccDefinitionTxt);

        // table 9 Country/Region
        InsertDataRecordDefTable(DataExportRecSource, DataExportRecDef, Database::"Country/Region", CountryLineNo);
        InsertDataRecordDefField(DataExportRecSource, Database::"Country/Region", 1, 10000);
        InsertDataRecordDefField(DataExportRecSource, Database::"Country/Region", 2, 20000);
        InsertDataRecordDefField(DataExportRecSource, Database::"Country/Region", 6, 30000);

        // table 15 G/L Account
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 4, 9, 14, 31, 32);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"G/L Account", GLAccLineNo, FieldIdList);
        UpdateDataRecordDefField(DataExportRecSource, 31, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 32, DateFilterHandling::Period);

        // table 17 G/L Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 3, 4, 5, 6, 7, 10, 17, 23, 24, 27, 29, 43, 48, 51, 52, 53, 54, 55, 56, 57, 58, 64, 65);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"G/L Entry", GLEntryLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::"G/L Account", GLAccLineNo, 4);

        // table 18 Customer
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 4, 5, 6, 7, 8, 9, 20, 21, 35, 45, 54, 61, 86, 91, 92, 99, 100, 102, 108);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::Customer, CustomerLineNo, FieldIdList);
        UpdateDataRecordDefField(DataExportRecSource, 61, DateFilterHandling::Period);
        UpdateDataRecordDefField(DataExportRecSource, 99, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 100, DateFilterHandling::EndDate);

        // table 21 Cust. Ledger Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 3, 4, 5, 6, 7, 16, 17, 23, 24, 27, 37, 45, 51, 52, 53, 60, 61, 62);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Cust. Ledger Entry", CustLELineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::Customer, CustomerLineNo, 4);
        UpdateDataRecordDefField(DataExportRecSource, 16, DateFilterHandling::EndDate);

        // table 379 Detailed Cust. Ledger Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 7, 8, 9, 35, 36);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Detailed Cust. Ledg. Entry", DtldCustLELineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationTwo, Database::"Cust. Ledger Entry", CustLELineNo, 4);

        // table 23 Vendor
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 4, 5, 6, 7, 8, 9, 21, 35, 45, 54, 61, 86, 91, 92, 99, 100, 102, 108);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::Vendor, VendorLineNo, FieldIdList);
        UpdateDataRecordDefField(DataExportRecSource, 61, DateFilterHandling::Period);
        UpdateDataRecordDefField(DataExportRecSource, 99, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 100, DateFilterHandling::EndDate);

        // table 25 Vendor Ledger Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 3, 4, 5, 6, 7, 16, 17, 23, 24, 27, 37, 45, 51, 52, 53, 60, 61, 62);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Vendor Ledger Entry", VendorLELineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::Vendor, VendorLineNo, 4);
        UpdateDataRecordDefField(DataExportRecSource, 16, DateFilterHandling::EndDate);

        // table 380 Detailed Vendor Ledg. Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 7, 8, 9, 35, 36);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Detailed Vendor Ledg. Entry", DtldVendLELineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationTwo, Database::"Vendor Ledger Entry", VendorLELineNo, 4);

        // table 45 G/L Register
        InsertDataRecordDefTable(DataExportRecSource, DataExportRecDef, Database::"G/L Register", GLRegisterLineNo);
        InsertDataRecordDefField(DataExportRecSource, Database::"G/L Register", 2, 10000);
        InsertDataRecordDefField(DataExportRecSource, Database::"G/L Register", 3, 20000);
        InsertDataRecordDefField(DataExportRecSource, Database::"G/L Register", 4, 30000);
        InsertDataRecordDefField(DataExportRecSource, Database::"G/L Register", 6, 40000);

        // table 98 General Ledger Setup
        InsertDataRecordDefTable(DataExportRecSource, DataExportRecDef, Database::"General Ledger Setup", GLSetupLineNo);
        InsertDataRecordDefField(DataExportRecSource, Database::"General Ledger Setup", 71, 10000);

        // table 254 VAT Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 15, 17, 19, 21, 35, 39, 40, 55);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"VAT Entry", VATEntryLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, 0, 0, 0, 4);

        // table 325 VAT Posting Setup
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 7, 9, 11);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"VAT Posting Setup", VATSetupLineNo, FieldIdList);

        // table 349 Dimension Value
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 7, 8, 9);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Dimension Value", DimValueLineNo, FieldIdList);

        // data table relation
        InsertDataTableRelation(DataExportRecDef, Database::"G/L Account", 1, Database::"G/L Entry", 3);
        InsertDataTableRelation(DataExportRecDef, Database::Customer, 1, Database::"Cust. Ledger Entry", 3);
        InsertDataTableRelation(DataExportRecDef, Database::"Cust. Ledger Entry", 1, Database::"Detailed Cust. Ledg. Entry", 2);
        InsertDataTableRelation(DataExportRecDef, Database::Vendor, 1, Database::"Vendor Ledger Entry", 3);
        InsertDataTableRelation(DataExportRecDef, Database::"Vendor Ledger Entry", 1, Database::"Detailed Vendor Ledg. Entry", 2);

        UpdateDataExportSetupGLAcc22Code(DataExportCode);
    end;

    procedure CreateDataExportForFAAccounting()
    var
        DataExportSetup: Record "Data Export Setup";
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportRecSource: Record "Data Export Record Source";
        DateFilterHandling: Option " ",Period,EndDate,StartDate;
        DataExportCode: Code[10];
        DataExpRecTypeCode: Code[10];
        FixedAssetLineNo: Integer;
        FALedgerEntryLineNo: Integer;
        FADeprBookLineNo: Integer;
        FAPostGroupLineNo: Integer;
        IndentationOne: Integer;
        FieldIdList: List of [Integer];
    begin
        if DataExportSetup.Get() then
            if DataExportSetup."Data Export 2022 FA Acc. Code" <> '' then
                exit;

        FixedAssetLineNo := 10000;
        FALedgerEntryLineNo := 20000;
        FADeprBookLineNo := 30000;
        FAPostGroupLineNo := 40000;
        IndentationOne := 1;
        DataExportCode := GetDataExportCode(FAAccTxt, FAAccRenamedTxt);
        DataExpRecTypeCode := GetDataExpRecTypeCode(FAAccTxt, FAAccRenamedTxt);

        InsertDataDef(DataExportCode, FAAccDefinitionTxt);
        InsertDataRecord(DataExpRecTypeCode, FAAccDefinitionTxt);
        InsertDataRecordDef(DataExportRecDef, DataExportCode, DataExpRecTypeCode, FAAccDefinitionTxt);

        // table 5600 Fixed Asset
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 4, 5, 11, 26);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Fixed Asset", FixedAssetLineNo, FieldIdList);

        // table 5601 FA Ledger Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 27, 33, 34, 35, 36, 37, 38, 53);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"FA Ledger Entry", FALedgerEntryLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::"Fixed Asset", FixedAssetLineNo, 5);

        // table 5612 FA Depreciation Book
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 30, 31, 32, 55, 56, 57);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"FA Depreciation Book", FADeprBookLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::"Fixed Asset", FixedAssetLineNo, 0);
        UpdateDataRecordDefField(DataExportRecSource, 15, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 16, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 17, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 18, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 19, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 20, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 21, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 22, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 23, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 24, DateFilterHandling::StartDate);
        UpdateDataRecordDefField(DataExportRecSource, 25, DateFilterHandling::EndDate);
        UpdateDataRecordDefField(DataExportRecSource, 26, DateFilterHandling::EndDate);

        // table 5606 FA Posting Group
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 2, 3, 4, 5, 6, 7, 9);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"FA Posting Group", FAPostGroupLineNo, FieldIdList);

        // data table relation
        InsertDataTableRelation(DataExportRecDef, Database::"Fixed Asset", 1, Database::"FA Ledger Entry", 3);
        InsertDataTableRelation(DataExportRecDef, Database::"Fixed Asset", 1, Database::"FA Depreciation Book", 1);

        UpdateDataExportSetupFAAcc22Code(DataExportCode);
    end;

    procedure CreateDataExportForInvoiceAndItemAccounting()
    var
        DataExportSetup: Record "Data Export Setup";
        DataExportRecDef: Record "Data Export Record Definition";
        DataExportRecSource: Record "Data Export Record Source";
        DateFilterHandling: Option " ",Period,EndDate,StartDate;
        DataExportCode: Code[10];
        DataExpRecTypeCode: Code[10];
        ItemLineNo: Integer;
        ItemLELineNo: Integer;
        SalesInvHdrLineNo: Integer;
        SalesCrMemoHdrLineNo: Integer;
        IndentationOne: Integer;
        FieldIdList: List of [Integer];
    begin
        if DataExportSetup.Get() then
            if DataExportSetup."Data Export 2022 Item Acc Code" <> '' then
                exit;

        ItemLineNo := 10000;
        ItemLELineNo := 20000;
        SalesInvHdrLineNo := 30000;
        SalesCrMemoHdrLineNo := 40000;
        IndentationOne := 1;
        DataExportCode := GetDataExportCode(ItemAccTxt, ItemAccRenamedTxt);
        DataExpRecTypeCode := GetDataExpRecTypeCode(ItemAccTxt, ItemAccRenamedTxt);

        InsertDataDef(DataExportCode, ItemAccDefinitionTxt);
        InsertDataRecord(DataExpRecTypeCode, ItemAccDefinitionTxt);
        InsertDataRecordDef(DataExportRecDef, DataExportCode, DataExpRecTypeCode, ItemAccDefinitionTxt);

        // table 27 Item
        Clear(FieldIdList);
        FieldIdList.AddRange(1, 3, 70, 90, 99);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::Item, ItemLineNo, FieldIdList);
        UpdateDataRecordDefField(DataExportRecSource, 70, DateFilterHandling::EndDate);

        // table 32 Item Ledger Entry
        Clear(FieldIdList);
        FieldIdList.AddRange(2, 3, 4, 5, 6, 12, 41, 52, 60, 5816);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Item Ledger Entry", ItemLELineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, IndentationOne, Database::Item, ItemLineNo, 3);

        // table 112 Sales Invoice Header
        Clear(FieldIdList);
        FieldIdList.AddRange(3, 2, 4, 5, 20, 27, 60, 61, 70, 78, 87, 93);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Sales Invoice Header", SalesInvHdrLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, 0, 0, 0, 20);

        // table 114 Sales Cr.Memo Header
        Clear(FieldIdList);
        FieldIdList.AddRange(3, 2, 4, 5, 20, 27, 60, 61, 70, 78, 87, 93);
        InsertDataRecordDefTableAndFields(
            DataExportRecSource, DataExportRecDef, Database::"Sales Cr.Memo Header", SalesCrMemoHdrLineNo, FieldIdList);
        UpdateDataRecordDefTable(DataExportRecSource, 0, 0, 0, 20);

        // data table relation
        InsertDataTableRelation(DataExportRecDef, Database::Item, 1, Database::"Item Ledger Entry", 2);

        UpdateDataExportSetupItemAcc22Code(DataExportCode);
    end;

    local procedure GetDataExportCode(Original: Code[10]; Renamed: Code[10]) DataExportCode: Code[10]
    var
        DataExport: Record "Data Export";
        Counter: Integer;
    begin
        DataExportCode := Original;
        while DataExport.Get(DataExportCode) do begin
            Counter += 1;
            DataExportCode := StrSubstNo(Renamed, Counter);
        end;
    end;

    local procedure GetDataExpRecTypeCode(Original: Code[10]; Renamed: Code[10]) DataExpRecTypeCode: Code[10]
    var
        DataExportRecordType: Record "Data Export Record Type";
        Counter: Integer;
    begin
        DataExpRecTypeCode := Original;
        while DataExportRecordType.Get(DataExpRecTypeCode) do begin
            Counter += 1;
            DataExpRecTypeCode := StrSubstNo(Renamed, Counter);
        end;
    end;

    local procedure InsertDataDef(NewCode: Code[10]; NewDescription: Text[50])
    var
        DataExport: Record "Data Export";
    begin
        DataExport.Init();
        DataExport.Validate(Code, NewCode);
        DataExport.Validate(Description, NewDescription);
        DataExport.Insert();
    end;

    local procedure InsertDataRecord(NewCode: Code[10]; NewDescription: Text[50])
    var
        DataExportRecordType: Record "Data Export Record Type";
    begin
        DataExportRecordType.Init();
        DataExportRecordType.Validate(Code, NewCode);
        DataExportRecordType.Validate(Description, NewDescription);
        DataExportRecordType.Insert();
    end;

    local procedure InsertDataRecordDef(var DataExportRecDef: Record "Data Export Record Definition"; GroupCode: Code[10]; RecordCode: Code[10]; NewDescription: Text[50])
    begin
        DataExportRecDef.Init();
        DataExportRecDef.Validate("Data Export Code", GroupCode);
        DataExportRecDef.Validate("Data Exp. Rec. Type Code", RecordCode);
        DataExportRecDef.Validate(Description, NewDescription);
        DataExportRecDef.Insert();
    end;

    local procedure InsertDataRecordDefTable(var DataExportRecSource: Record "Data Export Record Source"; var DataExportRecDef: Record "Data Export Record Definition"; TableNo: Integer; LineNo: Integer)
    begin
        DataExportRecSource.Init();
        DataExportRecSource.Validate("Data Export Code", DataExportRecDef."Data Export Code");
        DataExportRecSource.Validate("Data Exp. Rec. Type Code", DataExportRecDef."Data Exp. Rec. Type Code");
        DataExportRecSource.Validate("Table No.", TableNo);
        DataExportRecSource.Validate("Line No.", LineNo);
        DataExportRecSource.Insert();
    end;

    local procedure InsertDataRecordDefField(var DataExportRecSource: Record "Data Export Record Source"; TableNo: Integer; FieldId: Integer; LineNo: Integer)
    var
        DataExportRecField: Record "Data Export Record Field";
    begin
        DataExportRecSource.TestField("Table No.", TableNo);    // check to avoid inserting under the wrong table

        DataExportRecField.Init();
        DataExportRecField.Validate("Data Export Code", DataExportRecSource."Data Export Code");
        DataExportRecField.Validate("Data Exp. Rec. Type Code", DataExportRecSource."Data Exp. Rec. Type Code");
        DataExportRecField.Validate("Source Line No.", DataExportRecSource."Line No.");
        DataExportRecField.Validate("Table No.", DataExportRecSource."Table No.");
        DataExportRecField.Validate("Field No.", FieldId);
        DataExportRecField.Validate("Line No.", LineNo);
        DataExportRecField.Insert();
    end;

    local procedure InsertDataRecordDefFields(var DataExportRecSource: Record "Data Export Record Source"; TableNo: Integer; FieldIdList: List of [Integer])
    var
        FieldLineNo: Integer;
        FieldId: Integer;
    begin
        FieldLineNo := 10000;
        foreach FieldId in FieldIdList do begin
            InsertDataRecordDefField(DataExportRecSource, TableNo, FieldId, FieldLineNo);
            FieldLineNo += 10000;
        end;
    end;

    procedure InsertDataTableRelation(var DataExportRecDef: Record "Data Export Record Definition"; FromTableNo: Integer; FromFieldNo: Integer; ToTableNo: Integer; ToFieldNo: Integer)
    var
        DataExportTableRelation: Record "Data Export Table Relation";
    begin
        DataExportTableRelation.Init();
        DataExportTableRelation.Validate("Data Export Code", DataExportRecDef."Data Export Code");
        DataExportTableRelation.Validate("Data Exp. Rec. Type Code", DataExportRecDef."Data Exp. Rec. Type Code");
        DataExportTableRelation.Validate("From Table No.", FromTableNo);
        DataExportTableRelation.Validate("From Field No.", FromFieldNo);
        DataExportTableRelation.Validate("To Table No.", ToTableNo);
        DataExportTableRelation.Validate("To Field No.", ToFieldNo);
        DataExportTableRelation.Insert();
    end;

    local procedure InsertDataRecordDefTableAndFields(var DataExportRecSource: Record "Data Export Record Source"; var DataExportRecDef: Record "Data Export Record Definition"; TableNo: Integer; LineNo: Integer; FieldIdList: List of [Integer])
    begin
        InsertDataRecordDefTable(DataExportRecSource, DataExportRecDef, TableNo, LineNo);
        InsertDataRecordDefFields(DataExportRecSource, TableNo, FieldIdList);
    end;

    local procedure UpdateDataRecordDefTable(var DataExportRecSource: Record "Data Export Record Source"; NewIndentation: Integer; RelationToTableNo: Integer; RelationToLineNo: Integer; PeriodFieldNo: Integer)
    begin
        DataExportRecSource.Validate(Indentation, NewIndentation);
        DataExportRecSource.Validate("Relation To Table No.", RelationToTableNo);
        DataExportRecSource.Validate("Relation To Line No.", RelationToLineNo);
        DataExportRecSource.Validate("Period Field No.", PeriodFieldNo);
        DataExportRecSource.Modify(true);
    end;

    local procedure UpdateDataRecordDefField(var DataExportRecSource: Record "Data Export Record Source"; FieldId: Integer; DateFilterHandling: Option)
    var
        DataExportRecField: Record "Data Export Record Field";
    begin
        DataExportRecField.SetRange("Data Export Code", DataExportRecSource."Data Export Code");
        DataExportRecField.SetRange("Data Exp. Rec. Type Code", DataExportRecSource."Data Exp. Rec. Type Code");
        DataExportRecField.SetRange("Source Line No.", DataExportRecSource."Line No.");
        DataExportRecField.SetRange("Table No.", DataExportRecSource."Table No.");
        DataExportRecField.SetRange("Field No.", FieldId);
        if DataExportRecField.FindFirst() then begin
            DataExportRecField.Validate("Date Filter Handling", DateFilterHandling);
            DataExportRecField.Modify(true);
        end;
    end;

    local procedure UpdateDataExportSetupGLAcc22Code(GLAcc22Code: Code[10])
    var
        DataExportSetup: Record "Data Export Setup";
    begin
        if not DataExportSetup.Get() then
            DataExportSetup.Insert();

        DataExportSetup.Validate("Data Export 2022 G/L Acc. Code", GLAcc22Code);
        DataExportSetup.Modify(true);
    end;

    local procedure UpdateDataExportSetupFAAcc22Code(FAAcc22Code: Code[10])
    var
        DataExportSetup: Record "Data Export Setup";
    begin
        if not DataExportSetup.Get() then
            DataExportSetup.Insert();

        DataExportSetup.Validate("Data Export 2022 FA Acc. Code", FAAcc22Code);
        DataExportSetup.Modify(true);
    end;

    local procedure UpdateDataExportSetupItemAcc22Code(ItemAcc22Code: Code[10])
    var
        DataExportSetup: Record "Data Export Setup";
    begin
        if not DataExportSetup.Get() then
            DataExportSetup.Insert();

        DataExportSetup.Validate("Data Export 2022 Item Acc Code", ItemAcc22Code);
        DataExportSetup.Modify(true);
    end;
}

