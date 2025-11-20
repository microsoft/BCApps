// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Environment;
using System.Integration;

table 135 "Acc. Sched. KPI Web Srv. Setup"
{
    Caption = 'Acc. Sched. KPI Web Srv. Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';

            trigger OnValidate()
            begin
                TestField("Primary Key", '');
            end;
        }
        field(2; "Forecasted Values Start"; Option)
        {
            Caption = 'Forecasted Values Start';
            OptionCaption = 'After Latest Closed Period,After Current Date';
            OptionMembers = "After Latest Closed Period","After Current Date";
        }
        field(3; "G/L Budget Name"; Code[10])
        {
            Caption = 'G/L Budget Name';
            TableRelation = "G/L Budget Name";
        }
        field(4; Period; Option)
        {
            Caption = 'Period';
            OptionCaption = 'Fiscal Year - Last Locked Period,Current Fiscal Year,Current Calendar Year,Current Calendar Quarter,Current Month,Today,Current Period,Last Locked Period,Current Fiscal Year + 3 Previous Years';
            OptionMembers = "Fiscal Year - Last Locked Period","Current Fiscal Year","Current Calendar Year","Current Calendar Quarter","Current Month",Today,"Current Period","Last Locked Period","Current Fiscal Year + 3 Previous Years";
        }
        field(5; "View By"; Option)
        {
            Caption = 'View By';
            InitValue = Month;
            OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
            OptionMembers = Day,Week,Month,Quarter,Year,Period;
        }
        field(6; "Web Service Name"; Text[240])
        {
            Caption = 'Web Service Name';

            trigger OnValidate()
            var
                i: Integer;
                s: Text;
            begin
                if "Web Service Name" = '' then
                    exit;
                s := LowerCase("Web Service Name");
                for i := 1 to StrLen(s) do
                    if not (s[i] in ['a' .. 'z', '0' .. '9', '-']) then
                        Error(ServiceNameErr);
            end;
        }
        field(7; Published; Boolean)
        {
            CalcFormula = exist("Web Service" where("Object Type" = const(Page),
                                                     "Object ID" = const(197),
                                                     Published = const(true)));
            Caption = 'Published';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Data Last Updated"; DateTime)
        {
            Caption = 'Data Last Updated';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Last G/L Entry Included"; Integer)
        {
            Caption = 'Last G/L Entry Included';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Data Time To Live (hours)"; Integer)
        {
            Caption = 'Data Time To Live (hours)';
            InitValue = 24;

            trigger OnValidate()
            begin
                if "Data Time To Live (hours)" = 0 then
                    "Data Time To Live (hours)" := 4;
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AccSchedKPIWebSrvLine: Record "Acc. Sched. KPI Web Srv. Line";
    begin
        AccSchedKPIWebSrvLine.DeleteAll();
    end;

    trigger OnInsert()
    begin
        TestField("Primary Key", '');
    end;

    trigger OnModify()
    begin
        "Last G/L Entry Included" := 0;
        "Data Last Updated" := 0DT;
    end;

    var
        ServiceNameErr: Label 'The service name may only contain letters A-Z, a-z, digits 0-9, and hyphens (-). No other characters are allowed.';

    procedure GetPeriodLength(var NoOfLines: Integer; var StartDate: Date; var EndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        TotalNoOfDays: Integer;
    begin
        case Period of
            Period::"Fiscal Year - Last Locked Period":
                GetFiscalYear(GetLastClosedAccDate(), StartDate, EndDate);
            Period::"Current Fiscal Year":
                GetFiscalYear(WorkDate(), StartDate, EndDate);
            Period::"Current Period":
                begin
                    AccountingPeriod.SetFilter("Starting Date", '<=%1', WorkDate());
                    if AccountingPeriod.FindLast() then
                        StartDate := AccountingPeriod."Starting Date";
                    AccountingPeriod.SetRange("Starting Date");
                    if AccountingPeriod.Find('>') then
                        EndDate := AccountingPeriod."Starting Date" - 1
                    else
                        EndDate := CalcDate('<CM>', StartDate);
                end;
            Period::"Last Locked Period":
                begin
                    AccountingPeriod.SetFilter("Starting Date", '<=%1', GetLastClosedAccDate());
                    if AccountingPeriod.FindLast() then
                        StartDate := AccountingPeriod."Starting Date";
                    AccountingPeriod.SetRange("Starting Date");
                    if AccountingPeriod.Find('>') then
                        EndDate := AccountingPeriod."Starting Date" - 1
                    else
                        EndDate := CalcDate('<CM>', StartDate);
                end;
            Period::"Current Calendar Year":
                begin
                    StartDate := CalcDate('<-CY>', WorkDate());
                    EndDate := CalcDate('<CY>', StartDate);
                end;
            Period::"Current Calendar Quarter":
                begin
                    StartDate := CalcDate('<-CQ>', WorkDate());
                    EndDate := CalcDate('<CQ>', StartDate);
                end;
            Period::"Current Month":
                begin
                    StartDate := CalcDate('<-CM>', WorkDate());
                    EndDate := CalcDate('<CM>', StartDate);
                end;
            Period::Today:
                begin
                    StartDate := WorkDate();
                    EndDate := WorkDate();
                end;
            Period::"Current Fiscal Year + 3 Previous Years":
                begin
                    GetFiscalYear(WorkDate(), StartDate, EndDate);
                    StartDate := CalcDate('<-3Y>', StartDate);
                    AccountingPeriod.SetRange("New Fiscal Year", true);
                    if AccountingPeriod.FindFirst() then // Get oldest accounting year
                        if AccountingPeriod."Starting Date" > StartDate then
                            StartDate := AccountingPeriod."Starting Date";
                end;
        end;
        TotalNoOfDays := EndDate - StartDate + 1;

        case "View By" of
            "View By"::Period:
                begin
                    AccountingPeriod.Reset();
                    AccountingPeriod.SetRange("Starting Date", StartDate, EndDate);
                    NoOfLines := AccountingPeriod.Count();
                end;
            "View By"::Year:
                NoOfLines := CalcNoOfLines(365, TotalNoOfDays);
            "View By"::Quarter:
                NoOfLines := CalcNoOfLines(90, TotalNoOfDays);
            "View By"::Month:
                NoOfLines := CalcNoOfLines(30, TotalNoOfDays);
            "View By"::Week:
                NoOfLines := CalcNoOfLines(7, TotalNoOfDays);
            "View By"::Day:
                NoOfLines := CalcNoOfLines(1, TotalNoOfDays);
        end;

        if NoOfLines = 0 then
            NoOfLines := 1;
    end;

    local procedure GetFiscalYear(Date: Date; var StartDate: Date; var EndDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        StartDate := Date;
        AccountingPeriod.SetFilter("Starting Date", '<=%1', Date);
        AccountingPeriod.SetRange("New Fiscal Year", true);
        if AccountingPeriod.FindLast() then
            StartDate := AccountingPeriod."Starting Date";
        AccountingPeriod.SetRange("Starting Date");
        if AccountingPeriod.Find('>') then
            EndDate := AccountingPeriod."Starting Date" - 1
        else
            EndDate := CalcDate('<1Y-1D>', StartDate);
    end;

    local procedure CalcNoOfLines(NoOfDaysPerLine: Integer; TotalNoOfDays: Integer): Integer
    begin
        exit(TotalNoOfDays div NoOfDaysPerLine);
    end;

    procedure CalcNextStartDate(OrgStartDate: Date; OffSet: Integer): Date
    var
        AccountingPeriod: Record "Accounting Period";
        DateCalc: DateFormula;
        DateCalcStr: Text;
    begin
        if OffSet = 0 then
            exit(OrgStartDate);

        case "View By" of
            "View By"::Period:
                begin
                    AccountingPeriod."Starting Date" := OrgStartDate;
                    AccountingPeriod.Find('=><');
                    AccountingPeriod.Next(OffSet);
                    exit(AccountingPeriod."Starting Date")
                end;
            "View By"::Year:
                DateCalcStr := '<%1Y>';
            "View By"::Quarter:
                DateCalcStr := '<%1Q>';
            "View By"::Month:
                DateCalcStr := '<%1M>';
            "View By"::Week:
                DateCalcStr := '<%1W>';
            "View By"::Day:
                DateCalcStr := '<%1D>';
        end;

        Evaluate(DateCalc, StrSubstNo(DateCalcStr, OffSet));
        exit(CalcDate(DateCalc, OrgStartDate));
    end;

    procedure GetLastClosedAccDate(): Date
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GLSetup."Allow Posting From" <> 0D then
            exit(GLSetup."Allow Posting From" - 1);
        exit(WorkDate());
    end;

    procedure GetLastBudgetChangedDate(): Date
    var
        GLBudgetEntry: Record "G/L Budget Entry";
    begin
        if "G/L Budget Name" <> '' then
            GLBudgetEntry.SetRange("Budget Name", "G/L Budget Name");
        GLBudgetEntry.SetCurrentKey("Last Date Modified", "Budget Name");
        if GLBudgetEntry.FindLast() then
            exit(GLBudgetEntry."Last Date Modified");
        exit(0D);
    end;

    [Scope('OnPrem')]
    procedure PublishWebService()
    var
        WebService: Record "Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        TestField("Web Service Name");
        DeleteWebService();

        if EnvironmentInfo.IsSaaS() then begin
            WebServiceManagement.CreateTenantWebService(WebService."Object Type"::Page,
              PAGE::"Acc. Sched. KPI Web Service", "Web Service Name", true);
            WebServiceManagement.CreateTenantWebService(WebService."Object Type"::Query,
              QUERY::"Dimension Sets", '', true);
        end else begin
            WebServiceManagement.CreateWebService(WebService."Object Type"::Page,
              PAGE::"Acc. Sched. KPI Web Service", "Web Service Name", true);
            WebServiceManagement.CreateWebService(WebService."Object Type"::Query,
              QUERY::"Dimension Sets", '', true);
        end;
    end;

    [Scope('OnPrem')]
    procedure DeleteWebService()
    var
        WebService: Record "Web Service";
        TenantWebService: Record "Tenant Web Service";
        EnvironmentInfo: Codeunit "Environment Information";
        AccSchedKPIEventHandler: Codeunit "Acc. Sched. KPI Event Handler";
    begin
        AccSchedKPIEventHandler.ResetAccSchedKPIWevSrvSetup();

        if EnvironmentInfo.IsSaaS() then begin
            TenantWebService.SetRange("Object Type", WebService."Object Type"::Page);
            TenantWebService.SetRange("Object ID", PAGE::"Acc. Sched. KPI Web Service");
            TenantWebService.SetRange("Service Name", "Web Service Name");
            if TenantWebService.IsEmpty() then
                TenantWebService.SetRange("Service Name");
            MarkAndResetTenantWebService(TenantWebService);

            TenantWebService.SetRange("Object Type", WebService."Object Type"::Page);
            TenantWebService.SetRange("Object ID", PAGE::"Acc. Sched. KPI WS Dimensions");
            MarkAndResetTenantWebService(TenantWebService);

            TenantWebService.SetRange("Object Type", WebService."Object Type"::Query);
            TenantWebService.SetRange("Object ID", QUERY::"Dimension Sets");
            MarkAndResetTenantWebService(TenantWebService);

            TenantWebService.MarkedOnly(true);
            TenantWebService.DeleteAll();
        end else begin
            WebService.SetRange("Object Type", WebService."Object Type"::Page);
            WebService.SetRange("Object ID", PAGE::"Acc. Sched. KPI Web Service");
            WebService.SetRange("Service Name", "Web Service Name");
            if WebService.IsEmpty() then
                WebService.SetRange("Service Name");
            MarkAndReset(WebService);

            WebService.SetRange("Object Type", WebService."Object Type"::Page);
            WebService.SetRange("Object ID", PAGE::"Acc. Sched. KPI WS Dimensions");
            MarkAndReset(WebService);

            WebService.SetRange("Object Type", WebService."Object Type"::Query);
            WebService.SetRange("Object ID", QUERY::"Dimension Sets");
            MarkAndReset(WebService);

            WebService.MarkedOnly(true);
            WebService.DeleteAll();
        end;
    end;

    local procedure MarkAndReset(var WebService: Record "Web Service")
    begin
        if WebService.FindSet() then
            repeat
                WebService.Mark(true);
            until WebService.Next() = 0;
        WebService.SetRange("Object Type");
        WebService.SetRange("Object ID");
        WebService.SetRange("Service Name");
    end;

    local procedure MarkAndResetTenantWebService(var TenantWebService: Record "Tenant Web Service")
    begin
        if TenantWebService.FindSet() then
            repeat
                TenantWebService.Mark(true);
            until TenantWebService.Next() = 0;
        TenantWebService.SetRange("Object Type");
        TenantWebService.SetRange("Object ID");
        TenantWebService.SetRange("Service Name");
    end;
}

