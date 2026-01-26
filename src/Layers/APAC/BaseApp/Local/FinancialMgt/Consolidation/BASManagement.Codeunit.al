// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

codeunit 11601 "BAS Management"
{
    Permissions = TableData "G/L Entry" = rm,
                  TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "VAT Entry" = rm;

    trigger OnRun()
    begin
    end;

    var
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASCalcEntry: Record "BAS Calc. Sheet Entry";
        GLSetup: Record "General Ledger Setup";
        BASBusUnits: Record "BAS Business Unit";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        CompanyInfo: Record "Company Information";
        BASXMLFieldID: Record "BAS XML Field ID";
        TempBASXMLFieldID: Record "BAS XML Field ID" temporary;
        BASUpdate: Report "BAS-Update";
        XMLDocument: DotNet XmlDocument;
        XMLNode: DotNet XmlNode;
        XMLNodeLast: DotNet XmlNode;
        Window: Dialog;
        LineNo: Integer;
        BASAdjmtSet: Boolean;
        AdjmtSet: Boolean;
        Text1450000: Label 'Please select a file to import.';
        Text1450002: Label 'This BAS has already been imported. Do you want to import a new version?';
        Text1450003: Label 'Please select a file to export.';
        Text1450004: Label 'This BAS has already been exported. Do you want to export it again?';
        Text1450005: Label 'Version %1 of BAS %2 has already been exported. Do you wish to continue?';
        Text1450006: Label 'The BAS has not been updated. Please run the update function.';
        Text1450007: Label 'BAS %1 version %2 in %3 company does not exist.';
        Text1450008: Label 'Updating G/L Entries:\\';
        Text1450009: Label 'Company Name      #1####################\';
        Text1450010: Label 'Entry             #2############';
        Text1450012: Label 'Select the Group BAS';
        Text1450013: Label 'No BAS Business Unit has been defined.';
        Text1450011: Label 'BAS Business Unit %1 has already been consolidated.';
        Text1450022: Label 'BAS %1 version %2 in %3 company does not exist.';
        Text1450023: Label 'BAS %1 version %2 in %3 company has not been updated.';
        Text1450024: Label 'Field BAS GST Division Factor in table General Ledger Setup should have same value in subsidiary company %1 and consolidating company %2.';
        Text1450025: Label 'BAS subsidiaries have been consolidated successfully into BAS %1 version %2.';
        Text1450026: Label 'Field No. %1  is system calculated or user entered field.';
        Text1450027: Label 'This BAS Calculation Sheet has been exported. It cannot be updated.';
        Text1450028: Label 'Default BAS Setup';
        Text1450029: Label 'DEFAULT';

    [Scope('OnPrem')]
    procedure ImportBAS(var BASCalcSheet1: Record "BAS Calculation Sheet"; BASFileName: Text)
    var
        FileManagement: Codeunit "File Management";
        BASFile: File;
        BlobOutStream: OutStream;
        FileInStream: InStream;
    begin
        if BASFileName = '' then
            Error(Text1450000);

        LoadXMLFile(BASFileName);
        LoadXMLNodesInTempTable();

        GLSetup.Get();
        GLSetup.TestField("BAS GST Division Factor");

        BASCalcSheet1.Init();
        BASCalcSheet1.A1 := ReadXMLNodeValues(BASCalcSheet1.FieldNo(A1));
        BASCalcSheet.LockTable();
        BASCalcSheet.SetRange(A1, BASCalcSheet1.A1);
        if BASCalcSheet.FindLast() then begin
            if not Confirm(Text1450002, false) then
                exit;
            BASCalcSheet1."BAS Version" := BASCalcSheet."BAS Version" + 1;
        end else
            BASCalcSheet1."BAS Version" := 1;

        BASCalcSheet1.A2 := ReadXMLNodeValues(BASCalcSheet1.FieldNo(A2));
        BASCalcSheet1.A2a := ReadXMLNodeValues(BASCalcSheet1.FieldNo(A2a));
        CompanyInfo.Get();
        BASCalcSheet1.TestField(A2, CompanyInfo.ABN);
        if BASCalcSheet1.A2a <> '' then
            BASCalcSheet1.TestField(A2a, CompanyInfo."ABN Division Part No.");

        Evaluate(BASCalcSheet1.A3, ReadXMLNodeValues(BASCalcSheet1.FieldNo(A3)));
        Evaluate(BASCalcSheet1.A4, ReadXMLNodeValues(BASCalcSheet1.FieldNo(A4)));
        Evaluate(BASCalcSheet1.A5, ReadXMLNodeValues(BASCalcSheet1.FieldNo(A5)));
        Evaluate(BASCalcSheet1.A6, ReadXMLNodeValues(BASCalcSheet1.FieldNo(A6)));
        Evaluate(BASCalcSheet1.F1, ReadXMLNodeValues(BASCalcSheet1.FieldNo(F1)));
        Evaluate(BASCalcSheet1.T2, ReadXMLNodeValues(BASCalcSheet1.FieldNo(T2)));
        BASCalcSheet1."BAS GST Division Factor" := GLSetup."BAS GST Division Factor";
        BASCalcSheet1."File Name" := CopyStr(FileManagement.GetFileName(BASFileName), 1, MaxStrLen(BASCalcSheet1."File Name"));
        BASCalcSheet1."User Id" := UserId;
        BASCalcSheet1."BAS Setup Name" := Text1450029;
        FileManagement.IsAllowedPath(BASFileName, false);
        if not FILE.Exists(BASFileName) then
            exit;
        BASFile.Open(BASFileName);
        BASFile.CreateInStream(FileInStream);
        BASCalcSheet1."BAS Template XML File".CreateOutStream(BlobOutStream);
        CopyStream(BlobOutStream, FileInStream);
        BASCalcSheet1.Insert();
    end;

    [Scope('OnPrem')]
    procedure ExportBAS(var BASCalcSheet2: Record "BAS Calculation Sheet")
    var
        BASCalcSheetSubsid: Record "BAS Calculation Sheet";
        ToFile: Text;
        BASFileName: Text;
    begin
        ToFile := BASCalcSheet2."File Name";

        BASFileName := SaveBASTemplateToServerFile(BASCalcSheet2.A1, BASCalcSheet2."BAS Version");
        if BASFileName = '' then
            Error(Text1450003);
        if BASCalcSheet2.Exported then
            if not Confirm(Text1450004, false) then
                exit;
        GLSetup.Get();
        if GLSetup."BAS Group Company" then
            BASCalcSheet2.TestField(Consolidated, true);
        if GLSetup."BAS Group Company" then
            BASCalcSheet2.TestField("Group Consolidated", true);

        CheckBASCalcSheetExported(BASCalcSheet2.A1, BASCalcSheet2."BAS Version");

        if not BASCalcSheet2.Updated then
            Error(Text1450006);

        LoadXMLFile(BASFileName);
        LoadXMLNodesInTempTable();

        BASCalcSheet2.TestField(A1, ReadXMLNodeValues(BASCalcSheet2.FieldNo(A1)));

        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T2), Format(Abs(BASCalcSheet2.T2)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T3), Format(Abs(BASCalcSheet2.T3)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(F2), Format(Abs(BASCalcSheet2.F2)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T4), BASCalcSheet2.T4);
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(F1), Format(Abs(BASCalcSheet2.F1)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(F4), BASCalcSheet2.F4);
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G22), Format(Abs(BASCalcSheet2.G22)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G24), BASCalcSheet2.G24);
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1H"), Format(Abs(BASCalcSheet2."1H")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T8), Format(Abs(BASCalcSheet2.T8)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T9), Format(Abs(BASCalcSheet2.T9)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1A"), Format(Abs(BASCalcSheet2."1A")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1C"), Format(Abs(BASCalcSheet2."1C")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1E"), Format(Abs(BASCalcSheet2."1E")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("4"), Format(Abs(BASCalcSheet2."4")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1B"), Format(Abs(BASCalcSheet2."1B")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1D"), Format(Abs(BASCalcSheet2."1D")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1F"), Format(Abs(BASCalcSheet2."1F")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("1G"), Format(Abs(BASCalcSheet2."1G")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("5B"), Format(Abs(BASCalcSheet2."5B")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("6B"), Format(Abs(BASCalcSheet2."6B")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("7C"), Format(Abs(BASCalcSheet2."7C")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo("7D"), Format(Abs(BASCalcSheet2."7D")));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G1), Format(Abs(BASCalcSheet2.G1)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G2), Format(Abs(BASCalcSheet2.G2)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G3), Format(Abs(BASCalcSheet2.G3)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G4), Format(Abs(BASCalcSheet2.G4)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G7), Format(Abs(BASCalcSheet2.G7)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(W1), Format(Abs(BASCalcSheet2.W1)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(W2), Format(Abs(BASCalcSheet2.W2)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(T1), Format(Abs(BASCalcSheet2.T1)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G10), Format(Abs(BASCalcSheet2.G10)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G11), Format(Abs(BASCalcSheet2.G11)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G13), Format(Abs(BASCalcSheet2.G13)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G14), Format(Abs(BASCalcSheet2.G14)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G15), Format(Abs(BASCalcSheet2.G15)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(G18), Format(Abs(BASCalcSheet2.G18)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(W3), Format(Abs(BASCalcSheet2.W3)));
        UpdateXMLNodeValues(BASCalcSheet2.FieldNo(W4), Format(Abs(BASCalcSheet2.W4)));

        BASCalcSheet2."User Id" := UserId;
        BASCalcSheet2."Date of Export" := Today;
        BASCalcSheet2."Time of Export" := Time;
        BASCalcSheet2.Exported := true;
        BASCalcSheet2.Modify();

        if BASCalcSheet2."Group Consolidated" then begin
            BASBusUnits.FindSet();
            repeat
                BASCalcSheetSubsid.ChangeCompany(BASBusUnits."Company Name");
                if not BASCalcSheetSubsid.Get(BASBusUnits."Document No.", BASBusUnits."BAS Version") then
                    Error(Text1450007, BASBusUnits."Document No.", BASBusUnits."BAS Version", BASBusUnits."Company Name");
                BASCalcSheetSubsid.Exported := true;
                BASCalcSheetSubsid.Modify();
            until BASBusUnits.Next() = 0;
        end;

        BASCalcEntry.Reset();
        if GLSetup."BAS Group Company" then begin
            BASCalcEntry.SetCurrentKey("Consol. BAS Doc. No.", "Consol. Version No.");
            BASCalcEntry.SetRange("Consol. BAS Doc. No.", BASCalcSheet2.A1);
            BASCalcEntry.SetRange("Consol. Version No.", BASCalcSheet2."BAS Version");
        end else begin
            BASCalcEntry.SetRange("Company Name", CompanyName);
            BASCalcEntry.SetRange("BAS Document No.", BASCalcSheet2.A1);
            BASCalcEntry.SetRange("BAS Version", BASCalcSheet2."BAS Version");
        end;

        if BASCalcEntry.FindSet() then begin
            Window.Open(Text1450008 + Text1450009 + Text1450010);
            repeat
                GLEntry.ChangeCompany(BASCalcEntry."Company Name");
                VATEntry.ChangeCompany(BASCalcEntry."Company Name");
                Window.Update(1, BASCalcEntry."Company Name");
                case BASCalcEntry.Type of
                    BASCalcEntry.Type::"G/L Entry":
                        begin
                            GLEntry.Get(BASCalcEntry."Entry No.");
                            Window.Update(2, StrSubstNo('%1: %2', BASCalcEntry.Type, GLEntry."Entry No."));
                            GLEntry."BAS Doc. No." := BASCalcEntry."BAS Document No.";
                            GLEntry."BAS Version" := BASCalcEntry."BAS Version";
                            GLEntry."Consol. BAS Doc. No." := BASCalcEntry."Consol. BAS Doc. No.";
                            GLEntry."Consol. Version No." := BASCalcEntry."Consol. Version No.";
                            GLEntry.Modify();
                        end;
                    BASCalcEntry.Type::"GST Entry":
                        begin
                            VATEntry.Get(BASCalcEntry."Entry No.");
                            Window.Update(2, StrSubstNo('%1: %2', BASCalcEntry.Type, VATEntry."Entry No."));
                            VATEntry."BAS Doc. No." := BASCalcEntry."BAS Document No.";
                            VATEntry."BAS Version" := BASCalcEntry."BAS Version";
                            VATEntry."Consol. BAS Doc. No." := BASCalcEntry."Consol. BAS Doc. No.";
                            VATEntry."Consol. Version No." := BASCalcEntry."Consol. Version No.";
                            VATEntry.Modify();
                        end;
                end;
            until BASCalcEntry.Next() = 0;
        end;
        DownloadBASToClient(XMLDocument, ToFile);
    end;

    [Scope('OnPrem')]
    procedure UpdateBAS(var BASCalcSheet3: Record "BAS Calculation Sheet")
    begin
        if BASCalcSheet3.Exported then
            Error(Text1450027);
        Clear(BASUpdate);
        BASUpdate.InitializeRequest(
            BASCalcSheet3, true, "VAT Statement Report Selection"::Open,
            "VAT Statement Report Period Selection"::"Before and Within Period", false);
        BASUpdate.RunModal();
    end;

    [Scope('OnPrem')]
    procedure ImportSubsidiaries()
    var
        BASCalcSheetConsol: Record "BAS Calculation Sheet";
        BASCalcSheetSubsid: Record "BAS Calculation Sheet";
        GLSetupSubsid: Record "General Ledger Setup";
        TempBASCalcSheet: Record "BAS Calculation Sheet";
        BASCalcScheduleList: Page "BAS Calc. Schedule List";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
        GLSetup.TestField("BAS to be Lodged as a Group", true);
        GLSetup.TestField("BAS Group Company", true);

        if not BASBusUnits.FindFirst() then
            Error(Text1450013);

        BASCalcScheduleList.LookupMode(true);
        BASCalcScheduleList.Caption(Text1450012);
        if BASCalcScheduleList.RunModal() <> ACTION::LookupOK then
            exit;

        BASCalcScheduleList.GetRecord(BASCalcSheetConsol);
        TempBASCalcSheet.Init();
        TempBASCalcSheet.A1 := BASCalcSheetConsol.A1;
        TempBASCalcSheet."BAS Version" := BASCalcSheetConsol."BAS Version";
        repeat
            BASBusUnits.TestField("Document No.");
            BASBusUnits.TestField("BAS Version");
            BASCalcSheetSubsid.ChangeCompany(BASBusUnits."Company Name");
            if not BASCalcSheetSubsid.Get(BASBusUnits."Document No.", BASBusUnits."BAS Version") then
                Error(
                  Text1450022,
                  BASBusUnits."Document No.",
                  BASBusUnits."BAS Version",
                  BASBusUnits."Company Name");
            if not BASCalcSheetSubsid.Updated then
                Error(
                  Text1450023,
                  BASBusUnits."Document No.",
                  BASBusUnits."BAS Version",
                  BASBusUnits."Company Name");
            GLSetupSubsid.ChangeCompany(BASBusUnits."Company Name");
            GLSetupSubsid.Get();
            if GLSetupSubsid."BAS GST Division Factor" <> GLSetup."BAS GST Division Factor" then
                Error(
                  Text1450024,
                  BASBusUnits."Company Name",
                  CompanyName);

            TempBASCalcSheet.T3 += BASCalcSheetSubsid.T3;
            TempBASCalcSheet.T8 += BASCalcSheetSubsid.T8;
            TempBASCalcSheet.T9 += BASCalcSheetSubsid.T9;
            TempBASCalcSheet.F2 += BASCalcSheetSubsid.F2;
            TempBASCalcSheet.G22 += BASCalcSheetSubsid.G22;
            TempBASCalcSheet."1H" += BASCalcSheetSubsid."1H";
            TempBASCalcSheet."1A" += BASCalcSheetSubsid."1A";
            TempBASCalcSheet."1C" += BASCalcSheetSubsid."1C";
            TempBASCalcSheet."1E" += BASCalcSheetSubsid."1E";
            TempBASCalcSheet."4" += BASCalcSheetSubsid."4";
            TempBASCalcSheet."1B" += BASCalcSheetSubsid."1B";
            TempBASCalcSheet."1D" += BASCalcSheetSubsid."1D";
            TempBASCalcSheet."1F" += BASCalcSheetSubsid."1F";
            TempBASCalcSheet."1G" += BASCalcSheetSubsid."1G";
            TempBASCalcSheet."5B" += BASCalcSheetSubsid."5B";
            TempBASCalcSheet."6B" += BASCalcSheetSubsid."6B";
            TempBASCalcSheet."7C" += BASCalcSheetSubsid."7C";
            TempBASCalcSheet."7D" += BASCalcSheetSubsid."7D";
            TempBASCalcSheet.G1 += BASCalcSheetSubsid.G1;
            TempBASCalcSheet.G2 += BASCalcSheetSubsid.G2;
            TempBASCalcSheet.G3 += BASCalcSheetSubsid.G3;
            TempBASCalcSheet.G4 += BASCalcSheetSubsid.G4;
            TempBASCalcSheet.G7 += BASCalcSheetSubsid.G7;
            TempBASCalcSheet.W1 += BASCalcSheetSubsid.W1;
            TempBASCalcSheet.W2 += BASCalcSheetSubsid.W2;
            TempBASCalcSheet.T1 += BASCalcSheetSubsid.T1;
            TempBASCalcSheet.G10 += BASCalcSheetSubsid.G10;
            TempBASCalcSheet.G11 += BASCalcSheetSubsid.G11;
            TempBASCalcSheet.G13 += BASCalcSheetSubsid.G13;
            TempBASCalcSheet.G14 += BASCalcSheetSubsid.G14;
            TempBASCalcSheet.G15 += BASCalcSheetSubsid.G15;
            TempBASCalcSheet.G18 += BASCalcSheetSubsid.G18;
            TempBASCalcSheet.W3 += BASCalcSheetSubsid.W3;
            TempBASCalcSheet.W4 += BASCalcSheetSubsid.W4;

            if BASCalcSheetSubsid.Consolidated then
                Error(Text1450011, BASBusUnits."Company Name");
            BASCalcSheetSubsid.Consolidated := true;
            BASCalcSheetSubsid.Modify();

            BASCalcEntry.Reset();
            BASCalcEntry.SetRange("Company Name", BASBusUnits."Company Name");
            BASCalcEntry.SetRange("BAS Document No.", BASCalcSheetSubsid.A1);
            BASCalcEntry.SetRange("BAS Version", BASCalcSheetSubsid."BAS Version");
            if not BASCalcEntry.IsEmpty() then begin
                BASCalcEntry.ModifyAll("Consol. BAS Doc. No.", TempBASCalcSheet.A1);
                BASCalcEntry.ModifyAll("Consol. Version No.", TempBASCalcSheet."BAS Version");
            end;
        until BASBusUnits.Next() = 0;

        BASCalcEntry.Reset();
        BASCalcEntry.SetRange("Company Name", CompanyName);
        BASCalcEntry.SetRange("BAS Document No.", TempBASCalcSheet.A1);
        BASCalcEntry.SetRange("BAS Version", TempBASCalcSheet."BAS Version");
        if not BASCalcEntry.IsEmpty() then begin
            BASCalcEntry.ModifyAll("Consol. BAS Doc. No.", TempBASCalcSheet.A1);
            BASCalcEntry.ModifyAll("Consol. Version No.", TempBASCalcSheet."BAS Version");
        end;

        UpdateConsolBASCalculationSheet(TempBASCalcSheet, BASCalcSheetConsol);
        Message(Text1450025, TempBASCalcSheet.A1, TempBASCalcSheet."BAS Version");
    end;

    local procedure UpdateXMLNodeValues(FieldNumber: Integer; Amount: Text[100])
    begin
        BASXMLFieldID.SetCurrentKey("Field No.");
        BASXMLFieldID.SetRange("Field No.", FieldNumber);
        if BASXMLFieldID.FindFirst() then
            if TempBASXMLFieldID.Get(BASXMLFieldID."XML Field ID") then begin
                Amount := DelChr(Amount, '=', ',');
                XMLNode := XMLDocument.DocumentElement.SelectSingleNode(StrSubstNo('./%1', BASXMLFieldID."XML Field ID"));
                XMLNode.InnerText := Amount;
            end;
    end;

    local procedure ReadXMLNodeValues(FieldNumber: Integer): Text[1024]
    begin
        BASXMLFieldID.SetCurrentKey("Field No.");
        BASXMLFieldID.SetRange("Field No.", FieldNumber);
        if BASXMLFieldID.FindFirst() then begin
            if TempBASXMLFieldID.Get(BASXMLFieldID."XML Field ID") then begin
                XMLNode := XMLDocument.DocumentElement.SelectSingleNode(StrSubstNo('./%1', BASXMLFieldID."XML Field ID"));
                exit(XMLNode.InnerText);
            end;
        end else
            if not (FieldNumber in [
                                    BASCalcSheet.FieldNo(A1),
                                    BASCalcSheet.FieldNo(A2),
                                    BASCalcSheet.FieldNo(A2a)])
            then
                exit('0');

        exit('');
    end;

    [Scope('OnPrem')]
    procedure LoadXMLNodesInTempTable()
    var
        FirstNode: Boolean;
    begin
        TempBASXMLFieldID.Reset();
        TempBASXMLFieldID.DeleteAll();
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;
                if not TempBASXMLFieldID.Get(CopyStr(XMLNode.Name, 1, 80)) then begin
                    TempBASXMLFieldID.Init();
                    TempBASXMLFieldID."XML Field ID" := XMLNode.Name;
                    TempBASXMLFieldID.Insert();
                end;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateXMLFieldIDs(BASFileName: Text)
    var
        BASXMLFieldID: Record "BAS XML Field ID";
        FirstNode: Boolean;
    begin
        LoadXMLFile(BASFileName);
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;
                if not BASXMLFieldID.Get(CopyStr(XMLNode.Name, 1, 80)) then begin
                    BASXMLFieldID.Init();
                    BASXMLFieldID."XML Field ID" := XMLNode.Name;
                    BASXMLFieldID.Insert();
                end;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure UpdateXMLFieldSetup(BASFileName: Text; BASSetupName: Code[20])
    var
        BASXMLFieldIDSetup: Record "BAS XML Field ID Setup";
        FirstNode: Boolean;
    begin
        LoadXMLFile(BASFileName);
        if XMLDocument.HasChildNodes then begin
            XMLNode := XMLDocument.DocumentElement.FirstChild;
            XMLNodeLast := XMLDocument.DocumentElement.LastChild;
            FirstNode := true;
            if LineNo = 0 then
                LineNo := 10000;
            repeat
                if FirstNode then
                    FirstNode := false
                else
                    XMLNode := XMLNode.NextSibling;

                BASXMLFieldIDSetup.Reset();
                BASXMLFieldIDSetup.SetCurrentKey("XML Field ID");
                BASXMLFieldIDSetup.SetRange("Setup Name", BASSetupName);
                BASXMLFieldIDSetup.SetRange("XML Field ID", XMLNode.Name);
                if not BASXMLFieldIDSetup.FindFirst() then begin
                    BASXMLFieldIDSetup.Init();
                    BASXMLFieldIDSetup."Setup Name" := BASSetupName;
                    BASXMLFieldIDSetup."XML Field ID" := XMLNode.Name;
                    BASXMLFieldIDSetup."Line No." := LineNo;
                    BASXMLFieldIDSetup.Insert();
                end;
                LineNo := LineNo + 10000;
            until XMLNode.Name = XMLNodeLast.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure LoadXMLFile(BASFileName: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlReaderSettings: DotNet XmlReaderSettings;
    begin
        Clear(XMLDocument);
        XmlReaderSettings := XmlReaderSettings.XmlReaderSettings();
        XmlReaderSettings.DtdProcessing := 2; // Value of DtdProcessing.Parse has been assigned as integer because DtdProcessing has method Parse.
        XMLDOMManagement.LoadXMLDocumentFromFileWithXmlReaderSettings(BASFileName, XMLDocument, XmlReaderSettings);
    end;

    [Scope('OnPrem')]
    procedure CheckBASPeriod(DocDate: Date; InvDocDate: Date): Boolean
    var
        CompanyInfo: Record "Company Information";
        Date: Record Date;
    begin
        CompanyInfo.Get();
        if InvDocDate < 20000701D then
            exit(false);
        case CompanyInfo."Tax Period" of
            CompanyInfo."Tax Period"::Monthly:
                exit(InvDocDate < CalcDate('<D1-1M>', DocDate));
            CompanyInfo."Tax Period"::Quarterly:
                begin
                    Date.SetRange("Period Type", Date."Period Type"::Quarter);
                    Date.SetFilter("Period Start", '..%1', DocDate);
                    Date.FindLast();
                    exit(InvDocDate < Date."Period Start");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GenJnlLineVendorSetAdjmt(var GenJnlLine: Record "Gen. Journal Line"; var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(GenJnlLine."Document Date") then begin
            PurchSetup.Get();
            if not AdjmtSet then begin
                GenJnlLine.Adjustment := true;
                AdjmtSet := GenJnlLine.Adjustment;
            end;
            if not BASAdjmtSet then begin
                GenJnlLine."BAS Adjustment" := CheckBASPeriod(GenJnlLine."Document Date", VendLedgEntry."Document Date");
                BASAdjmtSet := GenJnlLine."BAS Adjustment";
            end;
            GenJnlLine."Adjmt. Entry No." := VendLedgEntry."Entry No.";
            if not GenJnlLine.Modify() then begin
                VendLedgEntry."Pre Adjmt. Reason Code" := VendLedgEntry."Reason Code";
                VendLedgEntry."Reason Code" := PurchSetup."Payment Discount Reason Code";
                VendLedgEntry.Modify();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GenJnlLineCustomerSetAdjmt(var GenJnlLine: Record "Gen. Journal Line"; var CustLedgEntry: Record "Cust. Ledger Entry")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(GenJnlLine."Document Date") then begin
            SalesSetup.Get();
            SalesSetup.TestField("Payment Discount Reason Code");
            if not AdjmtSet then begin
                GenJnlLine.Adjustment := true;
                AdjmtSet := GenJnlLine.Adjustment;
            end;
            if not BASAdjmtSet then begin
                GenJnlLine."BAS Adjustment" := CheckBASPeriod(GenJnlLine."Document Date", CustLedgEntry."Document Date");
                BASAdjmtSet := GenJnlLine."BAS Adjustment";
            end;
            GenJnlLine."Adjmt. Entry No." := CustLedgEntry."Entry No.";
            if not GenJnlLine.Modify() then;
            CustLedgEntry."Pre Adjmt. Reason Code" := CustLedgEntry."Reason Code";
            CustLedgEntry."Reason Code" := SalesSetup."Payment Discount Reason Code";
            CustLedgEntry.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure VendLedgEntryReplReasonCodes(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(VendLedgEntry."Document Date") then begin
            VendLedgEntry."Reason Code" := VendLedgEntry."Pre Adjmt. Reason Code";
            VendLedgEntry."Pre Adjmt. Reason Code" := '';
            VendLedgEntry.Modify();
        end;
    end;

    [Scope('OnPrem')]
    procedure CustLedgEntryReplReasonCodes(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(CustLedgEntry."Document Date") then begin
            CustLedgEntry."Reason Code" := CustLedgEntry."Pre Adjmt. Reason Code";
            CustLedgEntry."Pre Adjmt. Reason Code" := '';
            CustLedgEntry.Modify();
        end;
    end;

    procedure VendorRegistered(VendorNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        GLSetup.Get();
        if GLSetup.GSTEnabled(0D) then begin
            Vendor.Get(VendorNo);
            exit(Vendor.Registered);
        end;

        exit(true);
    end;

    procedure GetUnregGSTProdPostGroup(GSTBusPostGroup: Code[20]; VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PurchSetup: Record "Purchases & Payables Setup";
        GSTPostingSetup: Record "VAT Posting Setup";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("GST Prod. Posting Group");
        Vendor.Get(VendorNo);
        GSTPostingSetup.Get(GSTBusPostGroup, PurchSetup."GST Prod. Posting Group");
        if not Vendor."Foreign Vend" then
            GSTPostingSetup.TestField("VAT %", 0);
        exit(PurchSetup."GST Prod. Posting Group");
    end;

    [Scope('OnPrem')]
    procedure CheckBASFieldID(FieldID: Integer; DisplayErrorMessage: Boolean): Boolean
    begin
        if not (FieldID in [
                    BASCalcSheet.FieldNo("1A") .. BASCalcSheet.FieldNo("1E"),
                    BASCalcSheet.FieldNo("4"),
                    BASCalcSheet.FieldNo("1B") .. BASCalcSheet.FieldNo("1G"),
                    BASCalcSheet.FieldNo("5B"),
                    BASCalcSheet.FieldNo("6B"),
                    BASCalcSheet.FieldNo(G1) .. BASCalcSheet.FieldNo(G4),
                    BASCalcSheet.FieldNo(G7),
                    BASCalcSheet.FieldNo(W1) .. BASCalcSheet.FieldNo(T1),
                    BASCalcSheet.FieldNo(G10) .. BASCalcSheet.FieldNo(G11),
                    BASCalcSheet.FieldNo(G13) .. BASCalcSheet.FieldNo(G15),
                    BASCalcSheet.FieldNo(G18),
                    BASCalcSheet.FieldNo(W3) .. BASCalcSheet.FieldNo(W4),
                    BASCalcSheet.FieldNo("7C"),
                    BASCalcSheet.FieldNo("7D")])
then
            if DisplayErrorMessage then
                Error(Text1450026, FieldID);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure OpenBASSetup(var CurrentBASSetupName: Code[20]; var BASSetup2: Record "BAS Setup")
    begin
        TestBASSetupName(CurrentBASSetupName);
        BASSetup2.SetRange("Setup Name", CurrentBASSetupName);
    end;

    local procedure TestBASSetupName(var CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        if not BASSetupName.Get(CurrentBASSetupName) then
            if not BASSetupName.FindFirst() then begin
                BASSetupName.Init();
                BASSetupName.Name := Text1450029;
                BASSetupName.Description := Text1450028;
                BASSetupName.Insert();
                Commit();
            end;
        CurrentBASSetupName := BASSetupName.Name;
    end;

    [Scope('OnPrem')]
    procedure CheckBASSetupName(CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        BASSetupName.Get(CurrentBASSetupName);
    end;

    [Scope('OnPrem')]
    procedure CheckBASXMLSetupName(CurrentBASSetupName: Code[20])
    var
        BASSetupName: Record "BAS XML Field Setup Name";
    begin
        BASSetupName.Get(CurrentBASSetupName);
    end;

    [Scope('OnPrem')]
    procedure SetBASSetupName(CurrentBASSetupName: Code[20]; var BASSetup: Record "BAS Setup")
    begin
        BASSetup.SetRange("Setup Name", CurrentBASSetupName);
        if BASSetup.FindFirst() then;
    end;

    [Scope('OnPrem')]
    procedure LookupBASSetupName(var CurrentBASSetupName: Code[20]; var BASSetup: Record "BAS Setup")
    var
        BASSetupName: Record "BAS Setup Name";
    begin
        Commit();
        BASSetupName.Name := CurrentBASSetupName;
        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
            CurrentBASSetupName := BASSetupName.Name;
            SetBASSetupName(CurrentBASSetupName, BASSetup);
        end;
    end;

    [Scope('OnPrem')]
    procedure SetBASXMLSetupName(CurrentBASSetupName: Code[20]; var BASXMLFieldIDSetup: Record "BAS XML Field ID Setup")
    begin
        BASXMLFieldIDSetup.SetRange("Setup Name", CurrentBASSetupName);
        if BASXMLFieldIDSetup.FindFirst() then;
    end;

    [Scope('OnPrem')]
    procedure LookupBASXMLSetupName(var CurrentBASSetupName: Code[20]; var BASSetup4: Record "BAS XML Field ID Setup")
    var
        BASSetupName: Record "BAS XML Field Setup Name";
    begin
        Commit();
        BASSetupName.Name := CurrentBASSetupName;
        if PAGE.RunModal(0, BASSetupName) = ACTION::LookupOK then begin
            CurrentBASSetupName := BASSetupName.Name;
            SetBASXMLSetupName(CurrentBASSetupName, BASSetup4);
        end;
    end;

    local procedure UpdateConsolBASCalculationSheet(SourceBASCalculationSheet: Record "BAS Calculation Sheet"; var ConsolidatedBASCalculationSheet: Record "BAS Calculation Sheet")
    begin
        ConsolidatedBASCalculationSheet.Get(SourceBASCalculationSheet.A1, SourceBASCalculationSheet."BAS Version");
        ConsolidatedBASCalculationSheet.T3 := SourceBASCalculationSheet.T3;
        ConsolidatedBASCalculationSheet.T8 := SourceBASCalculationSheet.T8;
        ConsolidatedBASCalculationSheet.T9 := SourceBASCalculationSheet.T9;
        ConsolidatedBASCalculationSheet.F2 := SourceBASCalculationSheet.F2;
        ConsolidatedBASCalculationSheet.G22 := SourceBASCalculationSheet.G22;
        ConsolidatedBASCalculationSheet."1H" := SourceBASCalculationSheet."1H";
        ConsolidatedBASCalculationSheet."1A" := SourceBASCalculationSheet."1A";
        ConsolidatedBASCalculationSheet."1C" := SourceBASCalculationSheet."1C";
        ConsolidatedBASCalculationSheet."1E" := SourceBASCalculationSheet."1E";
        ConsolidatedBASCalculationSheet."4" := SourceBASCalculationSheet."4";
        ConsolidatedBASCalculationSheet."1B" := SourceBASCalculationSheet."1B";
        ConsolidatedBASCalculationSheet."1D" := SourceBASCalculationSheet."1D";
        ConsolidatedBASCalculationSheet."1F" := SourceBASCalculationSheet."1F";
        ConsolidatedBASCalculationSheet."1G" := SourceBASCalculationSheet."1G";
        ConsolidatedBASCalculationSheet."5B" := SourceBASCalculationSheet."5B";
        ConsolidatedBASCalculationSheet."6B" := SourceBASCalculationSheet."6B";
        ConsolidatedBASCalculationSheet."7C" := SourceBASCalculationSheet."7C";
        ConsolidatedBASCalculationSheet."7D" := SourceBASCalculationSheet."7D";
        ConsolidatedBASCalculationSheet.G1 := SourceBASCalculationSheet.G1;
        ConsolidatedBASCalculationSheet.G2 := SourceBASCalculationSheet.G2;
        ConsolidatedBASCalculationSheet.G3 := SourceBASCalculationSheet.G3;
        ConsolidatedBASCalculationSheet.G4 := SourceBASCalculationSheet.G4;
        ConsolidatedBASCalculationSheet.G7 := SourceBASCalculationSheet.G7;
        ConsolidatedBASCalculationSheet.W1 := SourceBASCalculationSheet.W1;
        ConsolidatedBASCalculationSheet.W2 := SourceBASCalculationSheet.W2;
        ConsolidatedBASCalculationSheet.T1 := SourceBASCalculationSheet.T1;
        ConsolidatedBASCalculationSheet.G10 := SourceBASCalculationSheet.G10;
        ConsolidatedBASCalculationSheet.G11 := SourceBASCalculationSheet.G11;
        ConsolidatedBASCalculationSheet.G13 := SourceBASCalculationSheet.G13;
        ConsolidatedBASCalculationSheet.G14 := SourceBASCalculationSheet.G14;
        ConsolidatedBASCalculationSheet.G15 := SourceBASCalculationSheet.G15;
        ConsolidatedBASCalculationSheet.G18 := SourceBASCalculationSheet.G18;
        ConsolidatedBASCalculationSheet.W3 := SourceBASCalculationSheet.W3;
        ConsolidatedBASCalculationSheet.W4 := SourceBASCalculationSheet.W4;
        ConsolidatedBASCalculationSheet.Updated := true;
        ConsolidatedBASCalculationSheet.Consolidated := true;
        ConsolidatedBASCalculationSheet."Group Consolidated" := true;
        ConsolidatedBASCalculationSheet.Modify();
    end;

    [Scope('OnPrem')]
    procedure SaveBASTemplateToServerFile(BASCalcSheetNo: Code[11]; BASVersion: Integer) FileName: Text
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
    begin
        BASCalculationSheet.Get(BASCalcSheetNo, BASVersion);
        BASCalculationSheet.CalcFields("BAS Template XML File");
        TempBlob.FromRecord(BASCalculationSheet, BASCalculationSheet.FieldNo("BAS Template XML File"));

        FileName := FileManagement.ServerTempFileName('xml');
        FileManagement.BLOBExportToServerFile(TempBlob, FileName);
    end;

    local procedure DownloadBASToClient(XMLDocument: DotNet XmlDocument; ToFile: Text)
    var
        FileManagement: Codeunit "File Management";
        ServerFileName: Text;
    begin
        ServerFileName := FileManagement.ServerTempFileName('xml');
        XMLDocument.Save(ServerFileName);
        FileManagement.DownloadHandler(ServerFileName, '', '', '', ToFile);
    end;

    local procedure CheckBASCalcSheetExported(BASCalcSheetNo: Code[11]; BASVersionNo: Integer)
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        BASCalculationSheet.SetRange(A1, BASCalcSheetNo);
        BASCalculationSheet.SetFilter("BAS Version", '<>%1', BASVersionNo);
        BASCalculationSheet.SetRange(Exported, true);
        if BASCalculationSheet.FindLast() then
            if BASCalculationSheet."BAS Version" <> BASVersionNo then
                if not Confirm(Text1450005, false, BASCalculationSheet."BAS Version", BASCalculationSheet.A1) then
                    Error('');
    end;
}

