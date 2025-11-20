namespace System.Threading;
using Microsoft.Foundation.Reporting;
using System.Environment;
using System.Device;

tableextension 472 "Job Queue Entry Ext." extends "Job Queue Entry"
{
    fields
    {
        modify("Object ID to Run")
        {
            trigger OnAfterValidate()
            var
                ReportManagementHelper: Codeunit "Report Management Helper";
                SelectedLayoutType: ReportLayoutType;
            begin
                if "Object Type to Run" <> "Object Type to Run"::Report then
                    exit;

                "Report Output Type" := "Report Output Type"::PDF;
                if ReportManagementHelper.IsProcessingOnly("Object ID to Run") then
                    "Report Output Type" := "Report Output Type"::"None (Processing only)"
                else begin
                    SelectedLayoutType := ReportManagementHelper.SelectedLayoutType("Object ID to Run");
                    if SelectedLayoutType in [ReportLayoutType::Rdlc, ReportLayoutType::Word, ReportLayoutType::Custom] then
                        "Report Output Type" := "Report Output Type"::Pdf
                    else
                        "Report Output Type" := "Report Output Type"::Excel;
                end;
            end;
        }
        modify("Report Output Type")
        {
            trigger OnAfterValidate()
            var
                InitServerPrinterTable: Codeunit "Init. Server Printer Table";
                EnvironmentInfo: Codeunit "Environment Information";
                ReportManagementHelper: Codeunit "Report Management Helper";
                ReportLayoutType: ReportLayoutType;
                IsHandled: Boolean;
            begin
                if not ReportManagementHelper.IsProcessingOnly("Object ID to Run") then begin
                    if "Report Output Type" = "Report Output Type"::"None (Processing only)" then
                        Error(ReportOutputTypeCannotBeNoneErr);

                    ReportLayoutType := ReportManagementHelper.SelectedLayoutType("Object ID to Run");

                    if ReportLayoutType = ReportLayoutType::Custom then
                        if not ("Report Output Type" in ["Report Output Type"::Print, "Report Output Type"::Word, "Report Output Type"::PDF]) then
                            Error(CustomLayoutReportCanHaveLimitedOutputTypeErr);

                    case "Report Output Type" of
                        "Job Queue Report Output Type"::PDF:
                            if ReportLayoutType in [ReportLayoutType::Excel] then
                                Error(UnsupportedOutputForSelectedLayoutErr, ReportLayoutType, "Report Output Type");
                        "Job Queue Report Output Type"::Print:
                            if ReportLayoutType in [ReportLayoutType::Excel] then
                                Error(UnsupportedOutputForSelectedLayoutErr, ReportLayoutType, "Report Output Type");
                        "Job Queue Report Output Type"::Word:
                            if not (ReportLayoutType in [ReportLayoutType::Word, ReportLayoutType::RDLC]) then
                                Error(UnsupportedOutputForSelectedLayoutErr, ReportLayoutType, "Report Output Type");
                    end;
                end;

                if "Report Output Type" = "Report Output Type"::Print then begin
                    if EnvironmentInfo.IsSaaS() then begin
                        IsHandled := false;
                        OnValidateReportOutputTypeOnBeforeShowPrintNotAllowedInSaaS(Rec, IsHandled);
                        if not IsHandled then begin
                            "Report Output Type" := "Report Output Type"::PDF;
                            Message(NoPrintOnSaaSMsg);
                        end;
                    end else
                        "Printer Name" := InitServerPrinterTable.FindClosestMatchToClientDefaultPrinter("Object ID to Run");
                end else
                    "Printer Name" := '';
            end;
        }
        modify("Printer Name")
        {
            trigger OnAfterValidate()
            begin
                TestField("Report Output Type", "Report Output Type"::Print);
            end;
        }
    }

    var
        NoPrintOnSaaSMsg: Label 'You cannot select a printer from this online product. Instead, save as PDF, or another format, which you can print later.\\The output type has been set to PDF.';
        ReportOutputTypeCannotBeNoneErr: Label 'You cannot set the report output to None because users can view the report. Use the None option when the report does something in the background. For example, when it is part of a batch job.';
        CustomLayoutReportCanHaveLimitedOutputTypeErr: Label 'This report uses a custom layout. To view the report you can open it in Word, print it, or save it as PDF.';
        UnsupportedOutputForSelectedLayoutErr: Label 'The selected layout type %1 does not support the selected output format %2.', Comment = '%1=Layout Type, %2=Output Format';

    procedure IsToReportInbox(): Boolean
    begin
        exit(
          ("Object Type to Run" = "Object Type to Run"::Report) and
          ("Report Output Type" in ["Report Output Type"::PDF, "Report Output Type"::Word,
                                    "Report Output Type"::Excel]));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateReportOutputTypeOnBeforeShowPrintNotAllowedInSaaS(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}