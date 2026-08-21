// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.GovTalk;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Utilities;
using System.Utilities;

codeunit 10503 "GovTalk Subscribers"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    var
        WrongVATSatementSetupErr: Label 'VAT statement template %1 name %2 has a wrong setup. There must be nine rows, each with a value between 1 and 9 for the Box No. field.', Comment = '%1 = response node, %2 = status node';

    trigger OnRun()
    begin
    end;


    [EventSubscriber(ObjectType::Page, Page::"ECSL Report", 'OnBeforeCheckForErrors', '', false, false)]
    local procedure OnAfterCheckForErrors(var ErrorsExist: Boolean; ErrorMessage: Record "Error Message"; TempErrorMessage: Record "Error Message" temporary)
    var
        GovTalkSetup: Record "Gov Talk Setup";
    begin
        ErrorMessage.SetRange("Context Record ID", GovTalkSetup.RecordId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Class. Eval. Data Country", 'OnAfterClassifyCountrySpecificTables', '', false, false)]
    local procedure OnAfterClassifyCountrySpecificTables()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"GovTalk Message");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"Gov Talk Setup");
        DataClassificationEvalData.SetTableFieldsToNormal(DATABASE::"GovTalk Msg. Parts");
    end;

    [EventSubscriber(ObjectType::Report, Report::"EC Sales List", 'OnAfterVATEntryNext', '', false, false)]
    local procedure OnAfterVATEntryNext(ResetVATEntry: Boolean; var sender: Report "EC Sales List"; "VAT Entry": Record "VAT Entry")
    begin
        sender.SetNewGroupStarted(ResetVATEntry);
        sender.SetPrevVATRegNo("VAT Entry"."VAT Registration No.");
        sender.UpdateXMLFileRTCGB();
    end;

    [EventSubscriber(ObjectType::Report, Report::"EC Sales List", 'OnBeforeSetGrouping', '', false, false)]
    local procedure OnBeforeSetGrouping(ReportLayout: Option "Separate &Lines","Column with &Amount"; NotEUTrdPartyAmt: Decimal; Grouping: Option NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService; NotEUTrdPartyAmtService: Decimal; EUTrdPartyAmt: Decimal; EUTrdPartyAmtService: Decimal; var sender: Report "EC Sales List")
    begin
        if ReportLayout = ReportLayout::"Separate &Lines" then begin
            if NotEUTrdPartyAmt <> 0 then begin
                Grouping := Grouping::NotEUTrdPartyAmt;
                sender.SetIndicatorCode(sender.GetIndicatorCodeGB(false, false));
            end;
            if NotEUTrdPartyAmtService <> 0 then begin
                Grouping := Grouping::NotEUTrdPartyAmtService;
                sender.SetIndicatorCode(sender.GetIndicatorCodeGB(false, true));
            end;
            if EUTrdPartyAmt <> 0 then begin
                Grouping := Grouping::EUTrdPartyAmt;
                sender.SetIndicatorCode(sender.GetIndicatorCodeGB(true, false));
            end;
            if EUTrdPartyAmtService <> 0 then begin
                Grouping := Grouping::EUTrdPartyAmtService;
                sender.SetIndicatorCode(sender.GetIndicatorCodeGB(false, true));
            end;
        end;
        sender.SetEUTrdPartyAmt(EUTrdPartyAmt);
        sender.SetNotEUTrdPartyAmt(NotEUTrdPartyAmt);
        sender.SetNotEUTrdPartyAmtService(NotEUTrdPartyAmtService);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EC Sales List Suggest Lines", 'OnBeforeAddOrUpdateECLLine', '', false, false)]
    local procedure OnBeforeAddOrUpdateECLLine(EUVATEntries: Query "EU VAT Entries"; var ECSLVATReportLine: Record "ECSL VAT Report Line"; var IsHandled: Boolean)
    begin

        if not IsApplicableEntry(EUVATEntries) then
            IsHandled := true;
    end;

    local procedure IsApplicableEntry(EUVATEntries: Query "EU VAT Entries"): Boolean
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        EUVATEntriesGB: Query "EU VAT Entries GB";
    begin
        EUVATEntriesGB.SetRange(Entry_No, EUVATEntries.Entry_No);
        EUVATEntriesGB.Open();
        EUVATEntriesGB.Read();
        if EUVATEntries.Entry_No <> 0 then;
        if
           (EUVATEntriesGB.VAT_Entry_No = 0) and
           (EUVATEntriesGB.ECSL_Line_No = 0) and
           (EUVATEntriesGB.ECSL_Report_No = '')
        then
            exit(true);

        ECSLVATReportLineRelation.SetRange("VAT Entry No.", EUVATEntriesGB.VAT_Entry_No);
        EUVATEntriesGB.Close();
        if not ECSLVATReportLineRelation.FindSet() then
            exit(true);

        repeat
            if ECSLVATReportLine.Get(ECSLVATReportLineRelation."ECSL Report No.", ECSLVATReportLineRelation."ECSL Line No.") then begin
                ECSLVATReportLine.CalcFields("Line Status GB");
                if ECSLVATReportLine."Line Status GB" <> ECSLVATReportLine."Line Status GB"::Rejected then
                    exit(false);
            end;
        until ECSLVATReportLineRelation.Next() = 0;

        exit(true);
    end;


    [EventSubscriber(ObjectType::Table, Database::"VAT Report Archive", 'OnAfterNoSubmissionMessageAvailableError', '', false, false)]
    local procedure OnAfterNoSubmissionMessageAvailableError(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive"; VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        DummyGuid: Guid;
    begin
        if Rec.IsDummyGuid() then begin
            if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue, DummyGuid) then
                Error(NoSubmissionMessageAvailableErr);
        end else
            if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue, Rec."Xml Part ID") then
                Error(NoSubmissionMessageAvailableErr);
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Report", 'OnBeforeDownloadSubmissionMessage', '', false, false)]
    local procedure OnBeforeDownloadSubmissionMessage(var IsHandled: Boolean; var VATReportHeader: Record "VAT Report Header")
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        IsHandled := true;
        VATReportArchive.SetDummyGuid(true);
        VATReportArchive.DownloadSubmissionMessage(VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.");
        VATReportArchive.SetDummyGuid(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Report", 'OnBeforeDownloadResponseMessage', '', false, false)]
    local procedure OnBeforeDownloadResponseMessage(var IsHandled: Boolean; var VATReportHeader: Record "VAT Report Header")
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        IsHandled := true;
        VATReportArchive.SetDummyGuid(true);
        VATReportArchive.DownloadResponseMessage(VATReportHeader."VAT Report Config. Code".AsInteger(), VATReportHeader."No.");
        VATReportArchive.SetDummyGuid(false);
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Report Archive", 'OnAfterNoResponseMessageAvailableError', '', false, false)]
    local procedure OnAfterNoResponseMessageAvailableError(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive"; VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        DummyGuid: Guid;
    begin
        if Rec.IsDummyGuid() then begin
            if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue, DummyGuid) then
                Error(NoSubmissionMessageAvailableErr);
        end else
            if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue, Rec."Xml Part ID") then
                Error(NoSubmissionMessageAvailableErr);
    end;


    [EventSubscriber(ObjectType::Table, Database::"VAT Report Archive", 'OnAfterInitVATReportArchive', '', false, false)]
    local procedure OnAfterInitVATReportArchive(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive")
    begin
        VATReportArchive."Xml Part ID" := Rec.GetXMLPartID();
    end;

    [EventSubscriber(ObjectType::Report, Report::"VAT Report Request Page", 'OnBeforeVATStatementLineFindSet', '', false, false)]
    local procedure OnBeforeVATStatementLineFindSet(var VATStatementLine: Record "VAT Statement Line"; VATReportHeader: Record "VAT Report Header")
    begin
        if VATStatementLine.Count() <> 9 then
            Error(WrongVATSatementSetupErr, VATReportHeader."Statement Template Name", VATReportHeader."Statement Name");
    end;


    [EventSubscriber(ObjectType::Report, Report::"VAT Report Request Page", 'OnBeforeCalcLineTotalWithBase', '', false, false)]
    local procedure OnBeforeCalcLineTotalWithBase(var VATStatementReportLine: Record "VAT Statement Report Line"; VATStatementLine: Record "VAT Statement Line"; VATReportHeader: Record "VAT Report Header")
    begin
        VATStatementReportLine.Init();
        VATStatementReportLine.Validate("Box No.", VATStatementLine."Box No.");
        if not CheckBoxNo(VATStatementReportLine) then
            Error(WrongVATSatementSetupErr, VATReportHeader."Statement Template Name", VATReportHeader."Statement Name");
    end;

    local procedure CheckBoxNo(var VATStatementReportLine: Record "VAT Statement Report Line"): Boolean;
    var
        VATStatementReportLine2: Record "VAT Statement Report Line";
        IntegerValue: Integer;
    begin
        if not Evaluate(IntegerValue, VATStatementReportLine."Box No.") then
            exit(false);
        if (IntegerValue < 1) or (IntegerValue > 9) then
            exit(false);

        VATStatementReportLine2.Copy(VATStatementReportLine);
        VATStatementReportLine2.SetRange("Box No.", FORMAT(IntegerValue));
        if not VATStatementReportLine2.IsEmpty() then
            exit(false);

        VATStatementReportLine."Box No." := Format(IntegerValue);
        exit(true);
    end;
}

