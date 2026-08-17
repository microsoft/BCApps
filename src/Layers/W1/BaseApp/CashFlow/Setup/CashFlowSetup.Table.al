// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.History;
using System.AI;
using System.Environment;
using System.Security.Encryption;

table 843 "Cash Flow Setup"
{
    Caption = 'Cash Flow Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Cash Flow Setup";
    LookupPageID = "Cash Flow Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Cash Flow Forecast No. Series"; Code[20])
        {
            Caption = 'Cash Flow Forecast No. Series';
            TableRelation = "No. Series";
        }
        field(3; "Receivables CF Account No."; Code[20])
        {
            Caption = 'Receivables CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Receivables CF Account No.");
            end;
        }
        field(4; "Payables CF Account No."; Code[20])
        {
            Caption = 'Payables CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Payables CF Account No.");
            end;
        }
        field(5; "Sales Order CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            Caption = 'Sales Order CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Sales Order CF Account No.");
            end;
        }
        field(6; "Purch. Order CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Purch. Order CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Purch. Order CF Account No.");
            end;
        }
        field(8; "FA Budget CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Budget CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("FA Budget CF Account No.");
            end;
        }
        field(9; "FA Disposal CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Fixed Asset" = R;
            Caption = 'FA Disposal CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("FA Disposal CF Account No.");
            end;
        }
        field(11; "CF No. on Chart in Role Center"; Code[20])
        {
            Caption = 'CF No. on Chart in Role Center';

            trigger OnValidate()
            begin
                if not ConfirmedChartRoleCenterCFNo("CF No. on Chart in Role Center") then
                    "CF No. on Chart in Role Center" := xRec."CF No. on Chart in Role Center";
            end;
        }
        field(12; "Job CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Job Planning Line" = R;
            Caption = 'Project CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Job CF Account No.");
            end;
        }
        field(13; "Automatic Update Frequency"; Option)
        {
            Caption = 'Automatic Update Frequency';
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;

            trigger OnValidate()
            var
                CashFlowManagement: Codeunit "Cash Flow Management";
            begin
                if "Automatic Update Frequency" = xRec."Automatic Update Frequency" then
                    exit;

                CashFlowManagement.DeleteJobQueueEntries();
                CashFlowManagement.CreateAndStartJobQueueEntry("Automatic Update Frequency");
            end;
        }
        field(14; "Tax CF Account No."; Code[20])
        {
            AccessByPermission = TableData "VAT Entry" = R;
            Caption = 'Tax CF Account No.';
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Tax CF Account No.");
            end;
        }
        field(19; "Taxable Period"; Option)
        {
            Caption = 'Taxable Period';
            InitValue = Quarterly;
            OptionCaption = 'Monthly,Quarterly,Accounting Period,Yearly';
            OptionMembers = Monthly,Quarterly,"Accounting Period",Yearly;
        }
        field(20; "Tax Payment Window"; DateFormula)
        {
            Caption = 'Tax Payment Window';
        }
        field(21; "Tax Bal. Account Type"; Option)
        {
            Caption = 'Tax Bal. Account Type';
            OptionCaption = ' ,Vendor,G/L Account';
            OptionMembers = " ",Vendor,"G/L Account";

            trigger OnValidate()
            begin
                EmptyTaxBalAccountIfTypeChanged(xRec."Tax Bal. Account Type");
            end;
        }
        field(22; "Tax Bal. Account No."; Code[20])
        {
            Caption = 'Tax Bal. Account No.';
            TableRelation = if ("Tax Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Tax Bal. Account Type" = const(Vendor)) Vendor;
        }
        field(23; "API Key"; Text[250])
        {
            Caption = 'API Key';

            trigger OnValidate()
            begin
                if not IsNullGuid("Service Pass API Key ID") then
                    EnableEncryption();
                SaveUserDefinedAPIKey("API Key");
            end;
        }
        field(24; "API URL"; Text[250])
        {
            Caption = 'API URL';

            trigger OnValidate()
            var
                AzureMLConnector: Codeunit "Azure ML Connector";
            begin
                AzureMLConnector.ValidateApiUrl("API URL");
            end;
        }
        field(25; "Variance %"; Integer)
        {
            Caption = 'Variance %';
            InitValue = 35;
            MaxValue = 100;
            MinValue = 1;
        }
        field(26; "Historical Periods"; Integer)
        {
            Caption = 'Historical Periods';
            InitValue = 24;
            MaxValue = 24;
            MinValue = 5;
        }
        field(27; Horizon; Integer)
        {
            Caption = 'Horizon';
            InitValue = 4;
            MaxValue = 24;
            MinValue = 3;
        }
        field(28; "Period Type"; Option)
        {
            Caption = 'Period Type';
            InitValue = Month;
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(29; TimeOut; Integer)
        {
            Caption = 'TimeOut';
            InitValue = 120;
            MinValue = 1;
        }
        field(30; "Service Pass API Key ID"; Guid)
        {
            Caption = 'Service Pass API Key ID';
            Description = 'The Key for retrieving the API Key from Isolated Storage.';
        }
        field(33; "Time Series Model"; Option)
        {
            Caption = 'Time Series Model';
            OptionCaption = 'ARIMA,ETS,STL,ETS+ARIMA,ETS+STL,ALL,TBATS', Locked = true;
            OptionMembers = ARIMA,ETS,STL,"ETS+ARIMA","ETS+STL",ALL,TBATS;
        }
        field(34; "Azure AI Enabled"; Boolean)
        {
            Caption = 'Azure AI Enabled';
            InitValue = false;
        }
        field(35; "Show AzureAI Notification"; Boolean)
        {
            Caption = 'Show AzureAI Notification';
            InitValue = true;
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

    var
        IsolatedStorageManagement: Codeunit "Isolated Storage Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Cash Flow Forecast %1 %2 is shown in the chart on the Role Center. Do you want to show this Cash Flow Forecast instead?', Comment = 'Cash Flow <No.> <Description> is shown in the chart on the Role Center.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CheckAccountType("Code": Code[20])
    var
        CFAccount: Record "Cash Flow Account";
    begin
        if Code <> '' then begin
            CFAccount.Get(Code);
            CFAccount.TestField("Account Type", CFAccount."Account Type"::Entry);
        end;
    end;

    procedure SetChartRoleCenterCFNo(CashFlowNo: Code[20])
    begin
        Get();
        "CF No. on Chart in Role Center" := CashFlowNo;
        Modify();
    end;

    procedure GetChartRoleCenterCFNo(): Code[20]
    begin
        Get();
        exit("CF No. on Chart in Role Center");
    end;

    local procedure ConfirmedChartRoleCenterCFNo(NewCashFlowNo: Code[20]): Boolean
    var
        CashFlowForecast: Record "Cash Flow Forecast";
    begin
        if NewCashFlowNo = '' then
            exit(true);

        if not (xRec."CF No. on Chart in Role Center" in ['', NewCashFlowNo]) then begin
            CashFlowForecast.Get(xRec."CF No. on Chart in Role Center");
            exit(Confirm(StrSubstNo(Text001, CashFlowForecast."No.", CashFlowForecast.Description), true));
        end;
        exit(true);
    end;

    procedure GetTaxPaymentDueDate(ReferenceDate: Date): Date
    var
        EndOfTaxPeriod: Date;
    begin
        Get();
        EndOfTaxPeriod := CalculateTaxableDate(ReferenceDate, true);
        exit(CalcDate("Tax Payment Window", EndOfTaxPeriod));
    end;

    procedure GetTaxPeriodStartEndDates(TaxDueDate: Date; var StartDate: Date; var EndDate: Date)
    begin
        Get();
        EndDate := GetTaxPeriodEndDate(TaxDueDate);
        StartDate := CalculateTaxableDate(EndDate, false);
    end;

    procedure GetTaxPaymentStartDate(TaxDueDate: Date): Date
    begin
        Get();
        exit(CalcDate('<1D>', GetTaxPeriodEndDate(TaxDueDate)));
    end;

    procedure GetTaxPeriodEndDate(TaxDueDate: Date): Date
    var
        ReverseDateFormula: DateFormula;
    begin
        Get();
        Evaluate(ReverseDateFormula, ReverseDateFormulaAsText());
        exit(CalcDate(ReverseDateFormula, TaxDueDate));
    end;

    procedure GetCurrentPeriodStartDate(): Date
    begin
        Get();
        exit(CalculateTaxableDate(WorkDate(), false));
    end;

    procedure GetCurrentPeriodEndDate(): Date
    begin
        Get();
        exit(CalculateTaxableDate(WorkDate(), true));
    end;

    procedure UpdateTaxPaymentInfo(NewTaxablePeriod: Option; NewPaymentWindow: DateFormula; NewTaxBalAccountType: Option; NewTaxBalAccountNum: Code[20])
    var
        Modified: Boolean;
    begin
        Get();
        if "Taxable Period" <> NewTaxablePeriod then begin
            "Taxable Period" := NewTaxablePeriod;
            Modified := true;
        end;

        if "Tax Payment Window" <> NewPaymentWindow then begin
            "Tax Payment Window" := NewPaymentWindow;
            Modified := true;
        end;

        if "Tax Bal. Account Type" <> NewTaxBalAccountType then begin
            "Tax Bal. Account Type" := NewTaxBalAccountType;
            Modified := true;
        end;

        if "Tax Bal. Account No." <> NewTaxBalAccountNum then begin
            "Tax Bal. Account No." := NewTaxBalAccountNum;
            Modified := true;
        end;

        if Modified then
            Modify();
    end;

    local procedure CalculateTaxableDate(ReferenceDate: Date; FindLastRec: Boolean) Result: Date
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        case "Taxable Period" of
            "Taxable Period"::Monthly:
                if FindLastRec then
                    Result := CalcDate('<CM>', ReferenceDate)
                else
                    Result := CalcDate('<-CM>', ReferenceDate);
            "Taxable Period"::Quarterly:
                if FindLastRec then
                    Result := CalcDate('<CQ>', ReferenceDate)
                else
                    Result := CalcDate('<-CQ>', ReferenceDate);
            "Taxable Period"::"Accounting Period":
                if FindLastRec then begin
                    // The end of the current accounting period is the start of the next acc. period - 1 day
                    AccountingPeriod.SetFilter("Starting Date", '>%1', ReferenceDate);
                    AccountingPeriod.FindFirst();
                    Result := AccountingPeriod."Starting Date" - 1;
                end else begin
                    // The end of the current accounting period is the start of the next acc. period - 1 day
                    AccountingPeriod.SetFilter("Starting Date", '<=%1', ReferenceDate);
                    AccountingPeriod.FindFirst();
                    Result := AccountingPeriod."Starting Date";
                end;
            "Taxable Period"::Yearly:
                if FindLastRec then
                    Result := CalcDate('<CY>', ReferenceDate)
                else
                    Result := CalcDate('<-CY>', ReferenceDate);
        end;
    end;

    local procedure ReverseDateFormulaAsText() Result: Text
    var
        TempChar: Char;
    begin
        Result := Format("Tax Payment Window");
        if Result = '' then
            exit('');

        if not (CopyStr(Result, 1, 1) in ['+', '-']) then
            Result := '+' + Result;

        TempChar := '#';
        Result := ReplaceCharInString(Result, '+', TempChar);
        Result := ReplaceCharInString(Result, '-', '+');
        Result := ReplaceCharInString(Result, TempChar, '-');
    end;

    local procedure ReplaceCharInString(StringToReplace: Text; OldChar: Char; NewChar: Char) Result: Text
    var
        Index: Integer;
        FirstPart: Text;
        LastPart: Text;
    begin
        Index := StrPos(StringToReplace, Format(OldChar));
        Result := StringToReplace;
        while Index > 0 do begin
            if Index > 1 then
                FirstPart := CopyStr(Result, 1, Index - 1);
            if Index < StrLen(Result) then
                LastPart := CopyStr(Result, Index + 1);
            Result := FirstPart + Format(NewChar) + LastPart;
            Index := StrPos(Result, Format(OldChar));
        end;
    end;

    procedure HasValidTaxAccountInfo(): Boolean
    begin
        exit("Tax Bal. Account Type" <> "Tax Bal. Account Type"::" ");
    end;

    procedure EmptyTaxBalAccountIfTypeChanged(OldTypeValue: Option)
    begin
        if "Tax Bal. Account Type" <> OldTypeValue then
            "Tax Bal. Account No." := '';
    end;

    [Scope('OnPrem')]
    procedure SaveUserDefinedAPIKey(APIKeyValue: SecretText)
    begin
        if IsNullGuid("Service Pass API Key ID") then
            "Service Pass API Key ID" := CreateGuid();

        IsolatedStorageManagement.Set("Service Pass API Key ID", APIKeyValue, DATASCOPE::Company);
    end;


    [Scope('OnPrem')]
    procedure GetMLCredentials(var ApiUrl: Text[250]; var ApiKey: SecretText; var LimitValue: Decimal; var UsingStandardCredentials: Boolean): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
        Value: SecretText;
    begin
        // user-defined credentials
        if IsAPIUserDefined() then begin
            IsolatedStorageManagement.Get("Service Pass API Key ID", DATASCOPE::Company, Value);
            ApiKey := Value;
            if (ApiKey.IsEmpty()) or ("API URL" = '') then
                exit(false);
            ApiUrl := "API URL";
            UsingStandardCredentials := false;
            exit(true);
        end;

        UsingStandardCredentials := true;
        // if credentials not user-defined retrieve it from Azure Key Vault
        if EnvironmentInfo.IsSaaS() then
            exit(RetrieveSaaSMLCredentials(ApiUrl, ApiKey, LimitValue));
    end;

    local procedure RetrieveSaaSMLCredentials(var ApiUrl: Text[250]; var ApiKey: SecretText; var LimitValue: Decimal): Boolean
    var
        TimeSeriesManagement: Codeunit "Time Series Management";
        LimitType: Option;
    begin
        exit(TimeSeriesManagement.GetMLForecastCredentials(ApiUrl, ApiKey, LimitType, LimitValue));
    end;

    internal procedure EnableEncryption()
    var
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        if not CryptographyManagement.IsEncryptionEnabled() then
            CryptographyManagement.EnableEncryption(false);
    end;

    [Scope('OnPrem')]
    internal procedure GetUserDefinedAPIKeySecret(): SecretText
    var
        Value: SecretText;
    begin
        // user-defined credentials
        if not IsNullGuid("Service Pass API Key ID") then begin
            IsolatedStorageManagement.Get("Service Pass API Key ID", DATASCOPE::Company, Value);
            exit(Value);
        end;
    end;

    procedure IsAPIUserDefined(): Boolean
    begin
        exit(not (IsNullGuid("Service Pass API Key ID") or ("API URL" = '')));
    end;
}