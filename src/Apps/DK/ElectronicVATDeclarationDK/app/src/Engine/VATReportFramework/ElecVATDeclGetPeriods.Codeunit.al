namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

codeunit 13610 "Elec. VAT Decl. Get Periods"
{
    Access = Internal;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PeriodsInsertedLbl: Label '%1 periods were received from server. %2 new periods were inserted.', Comment = '%1, %2: number of periods.';
        DueDateNotFoundErr: Label 'The VAT return period received from SKAT does not contain a due date.';
        FrequencyNotFoundErr: Label 'The VAT return period received from SKAT does not contain a reporting frequency.';
        UnsupportedFrequencyErr: Label 'The reporting frequency %1 received from SKAT is not supported.', Comment = '%1: reporting frequency received from SKAT';
        OverlappingPeriodErr: Label 'VAT return period %1 (%2 - %3) overlaps the period received from SKAT (%4 - %5). Delete the existing period if it is not linked to a VAT return, and then get VAT return periods again.', Comment = '%1: existing period number; %2, %3: existing start and end dates; %4, %5: received start and end dates';
        FeatureNameTxt: Label 'Electronic VAT Declaration DK', Locked = true;
        VATReturnPeriodsRcvdTxt: Label 'VAT Return Periods received.', Locked = true;

    trigger OnRun()
    var
        SKATResponse: Interface "Elec. VAT Decl. Response";
        StartDate: Date;
        EndDate: Date;
    begin
        FeatureTelemetry.LogUptake('0000LR9', FeatureNameTxt, "Feature Uptake Status"::Used);
        StartDate := WorkDate() - 365;
        EndDate := WorkDate() + 365;
        SKATResponse := GetResponseFromServer(StartDate, EndDate);
        GetVATReturnPeriodsFromResponse(SKATResponse);
        FeatureTelemetry.LogUsage('0000LRA', FeatureNameTxt, VATReturnPeriodsRcvdTxt);
    end;

    local procedure GetResponseFromServer(StartDate: Date; EndDate: Date): Interface "Elec. VAT Decl. Response"
    var
        ElecVATDeclSKATAPI: Codeunit "Elec. VAT Decl. SKAT API";
    begin
        exit(ElecVATDeclSKATAPI.GetVATReturnPeriods(StartDate, EndDate));
    end;

    local procedure GetVATReturnPeriodsFromResponse(SKATResponse: Interface "Elec. VAT Decl. Response")
    begin
        GetVATReturnPeriodsFromResponseText(SKATResponse.GetResponseBodyAsText());
    end;

    procedure GetVATReturnPeriodsFromResponseText(ResponseText: Text)
    var
        ElecVATDeclAzKeyVault: Codeunit "Elec. VAT Decl. Az. Key Vault";
    begin
        GetVATReturnPeriodsFromResponseText(ResponseText, ElecVATDeclAzKeyVault.IsReportingFrequencyEnabled());
    end;

    procedure GetVATReturnPeriodsFromResponseText(ResponseText: Text; ReportingFrequencyEnabled: Boolean)
    var
        PeriodsInserted: Integer;
        TotalPeriodsFetched: Integer;
    begin
        if ReportingFrequencyEnabled then
            GetFrequencyAwareVATReturnPeriods(ResponseText, TotalPeriodsFetched, PeriodsInserted)
        else
            GetQuarterlyVATReturnPeriods(ResponseText, TotalPeriodsFetched, PeriodsInserted);

        Message(PeriodsInsertedLbl, TotalPeriodsFetched, PeriodsInserted);
    end;

    local procedure GetFrequencyAwareVATReturnPeriods(ResponseText: Text; var TotalPeriodsFetched: Integer; var PeriodsInserted: Integer)
    var
        ElecVATDeclXml: Codeunit "Elec. VAT Decl. Xml";
        DueDate: Date;
        DueDateXmlNode: XmlNode;
        FrequencyXmlNode: XmlNode;
        PeriodXmlNode: XmlNode;
        PeriodXmlNodeList: XmlNodeList;
        ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency";
        i: Integer;
    begin
        PeriodXmlNodeList := ElecVATDeclXml.TryGetPeriodNodesFromResponseText(ResponseText);
        TotalPeriodsFetched := PeriodXmlNodeList.Count();
        for i := 1 to TotalPeriodsFetched do begin
            PeriodXmlNodeList.Get(i, PeriodXmlNode);
            if not ElecVATDeclXml.TryGetDueDateNodeFromPeriodNode(PeriodXmlNode, DueDateXmlNode) then
                Error(DueDateNotFoundErr);
            if not ElecVATDeclXml.TryGetFrequencyNodeFromPeriodNode(PeriodXmlNode, FrequencyXmlNode) then
                Error(FrequencyNotFoundErr);
            Evaluate(DueDate, DueDateXmlNode.AsXmlElement().InnerText());
            ReportingFrequency := GetReportingFrequency(FrequencyXmlNode.AsXmlElement().InnerText());
            if InsertVATReturnPeriod(DueDate, ReportingFrequency) then
                PeriodsInserted += 1;
        end;
    end;

    local procedure GetQuarterlyVATReturnPeriods(ResponseText: Text; var TotalPeriodsFetched: Integer; var PeriodsInserted: Integer)
    var
        ElecVATDeclXml: Codeunit "Elec. VAT Decl. Xml";
        DueDate: Date;
        DueDateXmlNode: XmlNode;
        DueDateXmlNodeList: XmlNodeList;
    begin
        DueDateXmlNodeList := ElecVATDeclXml.TryGetDueDateNodesFromResponseText(ResponseText);
        TotalPeriodsFetched := DueDateXmlNodeList.Count();
        foreach DueDateXmlNode in DueDateXmlNodeList do begin
            Evaluate(DueDate, DueDateXmlNode.AsXmlElement().InnerText());
            if InsertLegacyVATReturnPeriod(DueDate) then
                PeriodsInserted += 1;
        end;
    end;

    local procedure InsertLegacyVATReturnPeriod(DueDate: Date) ActuallyInserted: Boolean
    var
        VATReturnPeriod: Record "VAT Return Period";
        EndDate: Date;
        StartDate: Date;
    begin
        EndDate := CalcDate('<-3M+CM>', DueDate);
        StartDate := CalcDate('<-1Q+1D>', EndDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        if not VATReturnPeriod.IsEmpty() then
            exit;

        VATReturnPeriod.Validate("End Date", EndDate);
        VATReturnPeriod.Validate("Due Date", DueDate);
        VATReturnPeriod.Validate("Start Date", StartDate);
        VATReturnPeriod.Insert(true);
        ActuallyInserted := true;
    end;

    procedure GetReportingFrequency(FrequencyText: Text) ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency"
    var
        NormalizedFrequency: Text;
    begin
        NormalizedFrequency := LowerCase(FrequencyText.Trim());
        case true of
            NormalizedFrequency.Contains('ned'):
                exit(ReportingFrequency::Monthly);
            NormalizedFrequency.Contains('alv'):
                exit(ReportingFrequency::"Semi-Annual");
            NormalizedFrequency.Contains('vartal'):
                exit(ReportingFrequency::Quarterly);
        end;
        Error(UnsupportedFrequencyErr, FrequencyText);
    end;

    local procedure InsertVATReturnPeriod(DueDate: Date; ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency") ActuallyInserted: Boolean
    var
        VATReturnPeriod: Record "VAT Return Period";
        EndDate: Date;
        StartDate: Date;
    begin
        EndDate := CalcPeriodEndDate(DueDate, ReportingFrequency);
        StartDate := CalcPeriodStartDate(EndDate, ReportingFrequency);
        VATReturnPeriod.SetRange("Start Date", StartDate);
        VATReturnPeriod.SetRange("End Date", EndDate);
        if not VATReturnPeriod.IsEmpty() then
            exit;

        VATReturnPeriod.Reset();
        VATReturnPeriod.SetFilter("Start Date", '<=%1', EndDate);
        VATReturnPeriod.SetFilter("End Date", '>=%1', StartDate);
        if VATReturnPeriod.FindFirst() then
            Error(OverlappingPeriodErr, VATReturnPeriod."No.", VATReturnPeriod."Start Date", VATReturnPeriod."End Date", StartDate, EndDate);

        VATReturnPeriod.Validate("End Date", EndDate);
        VATReturnPeriod.Validate("Due Date", DueDate);
        VATReturnPeriod.Validate("Start Date", StartDate);
        VATReturnPeriod.Insert(true);
        ActuallyInserted := true;
    end;

    procedure CalcPeriodEndDate(DueDate: Date; ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency"): Date
    begin
        case ReportingFrequency of
            ReportingFrequency::Monthly:
                exit(CalcDate('<-1M+CM>', DueDate));
            ReportingFrequency::Quarterly:
                exit(CalcDate('<-3M+CM>', DueDate));
            ReportingFrequency::"Semi-Annual":
                exit(CalcDate('<-6M+CM>', DueDate));
        end;
    end;

    procedure CalcPeriodStartDate(EndDate: Date; ReportingFrequency: Enum "Elec. VAT Decl. Rep. Frequency"): Date
    begin
        case ReportingFrequency of
            ReportingFrequency::Monthly:
                exit(CalcDate('<-CM>', EndDate));
            ReportingFrequency::Quarterly:
                exit(CalcDate('<-CQ>', EndDate));
            ReportingFrequency::"Semi-Annual":
                exit(CalcDate('<-5M-CM>', EndDate));
        end;
    end;
}