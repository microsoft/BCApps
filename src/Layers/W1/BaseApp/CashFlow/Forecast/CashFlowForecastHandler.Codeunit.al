// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using System.AI;
using System.Environment;
using System.Utilities;
using System.Visualization;

codeunit 850 "Cash Flow Forecast Handler"
{
    Permissions = TableData "Cash Flow Azure AI Buffer" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CashFlowSetup: Record "Cash Flow Setup";
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
        CashFlowManagement: Codeunit "Cash Flow Management";
        TimeSeriesManagement: Codeunit "Time Series Management";
        ClientTypeManagement: Codeunit "Client Type Management";
        NumberOfPeriodsWithHistory: Integer;
        PeriodType: Integer;
        ForecastStartDate: Date;
        XPAYABLESTxt: Label 'PAYABLES', Locked = true;
        XRECEIVABLESTxt: Label 'RECEIVABLES', Locked = true;
        XPAYABLESCORRECTIONTxt: Label 'Payables Correction';
        XRECEIVABLESCORRECTIONTxt: Label 'Receivables Correction';
        XTAXPAYABLESTxt: Label 'TAX TO RETURN', Locked = true;
        XTAXRECEIVABLESTxt: Label 'TAX TO PAY', Locked = true;
        XTAXPAYABLESCORRECTIONTxt: Label 'Tax from Purchase entries';
        XTAXRECEIVABLESCORRECTIONTxt: Label 'Tax from Sales entries';
        XTAXSALESORDERSTxt: Label 'Tax from Sales Orders';
        XTAXPURCHORDERSTxt: Label 'Tax from Purchase Orders';
        XSALESORDERSTxt: Label 'Sales Orders';
        XPURCHORDERSTxt: Label 'Purchase Orders';
        AzureAIMustBeEnabledErr: Label '%1 in %2 must be set to true.', Comment = '%1 =Azure AI Enabled field, %2-Cash Flow Setup';
        AzureAIAPIURLEmptyErr: Label 'You must specify an %1 and an %2 for the %3.', Comment = '%1 =API URL field,%2 =API Key field, %3-Cash Flow Setup';
        AzureMachineLearningLimitReachedErr: Label 'The Microsoft Azure Machine Learning limit has been reached. Please contact your system administrator.';
        TimeSeriesManagementInitFailedErr: Label 'Cannot initialize Microsoft Azure Machine Learning. Try again later. If the problem continues, contact your system administrator.';
        MinimumHistoricalDataErr: Label 'There is not enough historical data for Azure AI to create a forecast.';
        PredictionHasHighVarianceErr: Label 'The calculated forecast for %1 for the period from %2 shows a degree of variance that is higher than the setup allows.', Comment = '%1 =PAYABLES or RECEIVABLES,%2 =Date';
        SetupScheduledForecastingMsg: Label 'You can include Azure AI capabilities in the cash flow forecast.';
        EnableAzureAITxt: Label 'Enable Azure AI';
        DontAskAgainTxt: Label 'Don''t ask again';
        ScheduledForecastingEnabledMsg: Label 'The Azure AI forecast has been enabled.', Comment = '%1 = weekday (e.g. Monday)';

    procedure CalculateForecast(): Boolean
    begin
        TempErrorMessage.ClearLog();

        if not Initialize() then begin
            ErrorMessage.CopyFromTemp(TempErrorMessage);
            Commit();
            exit(false);
        end;

        CalculateVATAndLedgerForecast();
        Commit();
        exit(true);
    end;

    local procedure CalculateVATAndLedgerForecast(): Boolean
    var
        TempTimeSeriesForecast: Record "Time Series Forecast" temporary;
        TempTimeSeriesBuffer: Record "Time Series Buffer" temporary;
    begin
        // Get forecast using time series
        if not PrepareForecast(TempTimeSeriesBuffer) then begin
            ErrorMessage.CopyFromTemp(TempErrorMessage);
            Commit();
            exit(false);
        end;

        TimeSeriesManagement.SetPreparedData(TempTimeSeriesBuffer, PeriodType, ForecastStartDate, NumberOfPeriodsWithHistory);
        TimeSeriesManagement.Forecast(CashFlowSetup.Horizon, 80, CashFlowSetup."Time Series Model");
        TimeSeriesManagement.GetForecast(TempTimeSeriesForecast);

        // Insert forecasted data
        ClearCashFlowAzureAIBuffer();
        CashFlowAzureAIBufferFill(TempTimeSeriesBuffer, TempTimeSeriesForecast);
        ErrorMessage.CopyFromTemp(TempErrorMessage);
    end;

    local procedure CalculatePostedSalesDocsSumAmountInPeriod(StartingDate: Date; PeriodType: Option): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;

        CustLedgerEntry.SetCurrentKey("Due Date");
        CustLedgerEntry.SetRange("Due Date", StartingDate, GetPeriodEndingDate(StartingDate, PeriodType));

        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.CalcFields("Amount (LCY)");
                Total := Total + CustLedgerEntry."Amount (LCY)";
            until CustLedgerEntry.Next() = 0;
        exit(Abs(Round(Total, 0.01)));
    end;

    local procedure CalculatePostedPurchDocsSumAmountInPeriod(StartingDate: Date; PeriodType: Option): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Total: Decimal;
    begin
        Total := 0;

        VendorLedgerEntry.SetCurrentKey("Due Date");
        VendorLedgerEntry.SetRange("Due Date", StartingDate, GetPeriodEndingDate(StartingDate, PeriodType));

        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields("Amount (LCY)");
                Total := Total + VendorLedgerEntry."Amount (LCY)";
            until VendorLedgerEntry.Next() = 0;
        exit(Abs(Round(Total, 0.01)));
    end;

    local procedure CalculatePostedDocsSumTaxInPeriod(EndingDate: Date; IsSales: Boolean): Decimal
    var
        VATEntry: Record "VAT Entry";
        Total: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        Total := 0;

        VATEntry.SetCurrentKey("Document Date");
        CashFlowSetup.GetTaxPeriodStartEndDates(EndingDate, StartDate, EndDate);
        VATEntry.SetRange("Document Date", StartDate, EndDate);
        if IsSales then
            VATEntry.SetRange(Type, VATEntry.Type::Sale)
        else
            VATEntry.SetRange(Type, VATEntry.Type::Purchase);

        if VATEntry.FindSet() then
            repeat
                Total := Total + VATEntry.Amount;
            until VATEntry.Next() = 0;
        exit(Abs(Round(Total, 0.01)));
    end;

    local procedure CalculateNotPostedSalesOrderSumAmountInPeriod(StartingDate: Date; PeriodType: Option; IsTax: Boolean): Decimal
    var
        SalesHeader: Record "Sales Header";
        TaxEndingDate: Date;
        TaxStartingDate: Date;
        Total: Decimal;
        AmountValue: Decimal;
    begin
        Total := 0;
        // in case of tax starting Date is tax payment due Date
        if IsTax then begin
            SalesHeader.SetCurrentKey("Document Date");
            CashFlowSetup.GetTaxPeriodStartEndDates(StartingDate, TaxStartingDate, TaxEndingDate);
            SalesHeader.SetRange("Document Date", TaxStartingDate, TaxEndingDate)
        end else begin
            SalesHeader.SetCurrentKey("Due Date");
            SalesHeader.SetRange("Due Date", StartingDate, GetPeriodEndingDate(StartingDate, PeriodType));
        end;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);

        if SalesHeader.FindSet() then
            repeat
                if IsTax then
                    AmountValue := -CashFlowManagement.GetTaxAmountFromSalesOrder(SalesHeader)
                else
                    AmountValue := CashFlowManagement.GetTotalAmountFromSalesOrder(SalesHeader);
                Total := Total + AmountValue;
            until SalesHeader.Next() = 0;
        if Total < 0 then
            Total := 0;
        exit(Abs(Round(Total, 0.01)));
    end;

    local procedure CalculateNotPostedPurchOrderSumAmountInPeriod(StartingDate: Date; PeriodType: Option; IsTax: Boolean): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        Total: Decimal;
        AmountValue: Decimal;
        TaxEndingDate: Date;
        TaxStartingDate: Date;
    begin
        Total := 0;
        PurchaseHeader.SetCurrentKey("Due Date");
        // in case of tax starting Date is tax payment due Date
        if IsTax then begin
            PurchaseHeader.SetCurrentKey("Document Date");
            CashFlowSetup.GetTaxPeriodStartEndDates(StartingDate, TaxStartingDate, TaxEndingDate);
            PurchaseHeader.SetRange("Document Date", TaxStartingDate, TaxEndingDate)
        end else begin
            PurchaseHeader.SetCurrentKey("Due Date");
            PurchaseHeader.SetRange("Due Date", StartingDate, GetPeriodEndingDate(StartingDate, PeriodType));
        end;
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);

        if PurchaseHeader.FindSet() then
            repeat
                if IsTax then
                    AmountValue := CashFlowManagement.GetTaxAmountFromPurchaseOrder(PurchaseHeader)
                else
                    AmountValue := CashFlowManagement.GetTotalAmountFromPurchaseOrder(PurchaseHeader);
                Total := Total - AmountValue;
            until PurchaseHeader.Next() = 0;
        if Total > 0 then
            Total := 0;
        exit(Abs(Round(Total, 0.01)));
    end;

    procedure PrepareForecast(var TimeSeriesBuffer: Record "Time Series Buffer"): Boolean
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        TempCustTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        TempVendTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        VATEntry: Record "VAT Entry";
        TempVATTimeSeriesBuffer: Record "Time Series Buffer" temporary;
        HasMinimumHistory: Boolean;
        HasMinimumHistoryLoc: Boolean;
        NumberOfPeriodsWithHistoryLoc: Integer;
    begin
        CashFlowSetup.Get();
        PeriodType := CashFlowSetup."Period Type";
        SetFiltersOnRecords(CustLedgerEntry, VendorLedgerEntry);
        // check if there is a minimum history needed for forecast
        HasMinimumHistory := TimeSeriesManagement.HasMinimumHistoricalData(
            NumberOfPeriodsWithHistory,
            CustLedgerEntry,
            CustLedgerEntry.FieldNo("Due Date"),
            CashFlowSetup."Period Type",
            ForecastStartDate);

        OnAfterHasMinimumHistoricalData(
          HasMinimumHistoryLoc,
          NumberOfPeriodsWithHistoryLoc,
          CashFlowSetup."Period Type",
          ForecastStartDate);

        HasMinimumHistory := (HasMinimumHistory or HasMinimumHistoryLoc);
        if not HasMinimumHistory then begin
            TempErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, MinimumHistoricalDataErr);
            exit(false);
        end;

        if NumberOfPeriodsWithHistoryLoc > NumberOfPeriodsWithHistory then
            NumberOfPeriodsWithHistory := NumberOfPeriodsWithHistoryLoc;

        // Prepare Sales History
        PrepareData(
          TempCustTimeSeriesBuffer,
          CustLedgerEntry,
          CustLedgerEntry.FieldNo("Document Type"),
          CustLedgerEntry.FieldNo("Due Date"),
          CustLedgerEntry.FieldNo("Amount (LCY)"),
          Format(CustLedgerEntry."Document Type"::Invoice),
          Format(CustLedgerEntry."Document Type"::"Credit Memo")
          );
        OnAfterPrepareSalesHistoryData(TempCustTimeSeriesBuffer, PeriodType, ForecastStartDate, NumberOfPeriodsWithHistory);
        AppendRecords(TimeSeriesBuffer, TempCustTimeSeriesBuffer, XRECEIVABLESTxt);

        // Prepare Purchase History
        PrepareData(
          TempVendTimeSeriesBuffer,
          VendorLedgerEntry,
          VendorLedgerEntry.FieldNo("Document Type"),
          VendorLedgerEntry.FieldNo("Due Date"),
          VendorLedgerEntry.FieldNo("Amount (LCY)"),
          Format(VendorLedgerEntry."Document Type"::Invoice),
          Format(VendorLedgerEntry."Document Type"::"Credit Memo")
          );
        OnAfterPreparePurchHistoryData(TempVendTimeSeriesBuffer, PeriodType, ForecastStartDate, NumberOfPeriodsWithHistory);
        AppendRecords(TimeSeriesBuffer, TempVendTimeSeriesBuffer, XPAYABLESTxt);

        VATEntry.SetCurrentKey("Document Date");
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        // Prepare VAT History
        TimeSeriesPrepareAndGetData(
          TempVATTimeSeriesBuffer,
          VATEntry,
          VATEntry.FieldNo(Type),
          VATEntry.FieldNo("Document Date"),
          VATEntry.FieldNo(Amount)
          );
        AppendRecords(TimeSeriesBuffer, TempVATTimeSeriesBuffer, XTAXRECEIVABLESTxt);

        TempVATTimeSeriesBuffer.DeleteAll();
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        // Prepare VAT History
        TimeSeriesPrepareAndGetData(
          TempVATTimeSeriesBuffer,
          VATEntry,
          VATEntry.FieldNo(Type),
          VATEntry.FieldNo("Document Date"),
          VATEntry.FieldNo(Amount)
          );
        AppendRecords(TimeSeriesBuffer, TempVATTimeSeriesBuffer, XTAXPAYABLESTxt);

        exit(true);
    end;

    procedure CashFlowAzureAIBufferFill(var TimeSeriesBuffer: Record "Time Series Buffer"; var TimeSeriesForecast: Record "Time Series Forecast")
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
        ForecastedRemainingAmount: Decimal;
    begin
        CashFlowSetup.Get();
        PeriodType := CashFlowSetup."Period Type";
        // History Records
        if TimeSeriesBuffer.FindSet() then
            repeat
                NewCashFlowAzureAIBufferRecord(TimeSeriesBuffer."Group ID",
                  TimeSeriesBuffer.Value,
                  1,
                  0,
                  CashFlowAzureAIBuffer.Type::History,
                  TimeSeriesBuffer."Period Start Date",
                  PeriodType,
                  TimeSeriesBuffer."Period No."
                  );
            until TimeSeriesBuffer.Next() = 0;

        AggregateTaxRecordsToTaxablePeriod(TimeSeriesForecast, XTAXPAYABLESTxt);
        AggregateTaxRecordsToTaxablePeriod(TimeSeriesForecast, XTAXRECEIVABLESTxt);
        // Forecast
        if TimeSeriesForecast.FindSet() then
            repeat
                // if Variance % is big, do not insert it
                if TimeSeriesForecast."Delta %" >= CashFlowSetup."Variance %" then
                    TempErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Warning,
                      StrSubstNo(PredictionHasHighVarianceErr, TimeSeriesForecast."Group ID", TimeSeriesForecast."Period Start Date"))
                else
                    if IsAmountValid(TimeSeriesForecast) then begin
                        // Azure AI Forecast

                        ForecastedRemainingAmount := Abs(TimeSeriesForecast.Value);
                        NewCashFlowAzureAIBufferRecord(TimeSeriesForecast."Group ID",
                          TimeSeriesForecast.Value,
                          TimeSeriesForecast."Delta %",
                          TimeSeriesForecast.Delta,
                          CashFlowAzureAIBuffer.Type::Forecast,
                          TimeSeriesForecast."Period Start Date",
                          PeriodType,
                          TimeSeriesForecast."Period No."
                          );

                        // Corrections: Payables Corrections, Receivables Corrections, Sales Orders, Purchase Orders
                        case TimeSeriesForecast."Group ID" of
                            XPAYABLESTxt:
                                begin
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XPAYABLESCORRECTIONTxt, PeriodType);
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XPURCHORDERSTxt, PeriodType);
                                end;
                            XRECEIVABLESTxt:
                                begin
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XRECEIVABLESCORRECTIONTxt, PeriodType);
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XSALESORDERSTxt, PeriodType);
                                end;
                            XTAXPAYABLESTxt:
                                begin
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XTAXPAYABLESCORRECTIONTxt, PeriodType);
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XTAXPURCHORDERSTxt, PeriodType);
                                end;
                            XTAXRECEIVABLESTxt:
                                begin
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XTAXRECEIVABLESCORRECTIONTxt, PeriodType);
                                    NewCorrectionRecord(ForecastedRemainingAmount, TimeSeriesForecast, XTAXSALESORDERSTxt, PeriodType);
                                end;
                        end;
                    end;
            until TimeSeriesForecast.Next() = 0;
    end;

    local procedure ClearCashFlowAzureAIBuffer()
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
    begin
        CashFlowAzureAIBuffer.Reset();
        CashFlowAzureAIBuffer.DeleteAll();
    end;

    local procedure SetFiltersOnRecords(var CustLedgerEntry: Record "Cust. Ledger Entry"; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CustLedgerEntry.SetCurrentKey("Due Date");
        CustLedgerEntry.SetFilter("Document Type",
          '%1|%2',
          CustLedgerEntry."Document Type"::Invoice,
          CustLedgerEntry."Document Type"::"Credit Memo");

        VendorLedgerEntry.SetCurrentKey("Due Date");
        VendorLedgerEntry.SetFilter("Document Type",
          '%1|%2',
          VendorLedgerEntry."Document Type"::Invoice,
          VendorLedgerEntry."Document Type"::"Credit Memo");
    end;

    local procedure PrepareData(var TempTimeSeriesBuffer: Record "Time Series Buffer" temporary; RecordVariant: Variant; GroupIdFieldNo: Integer; DateFieldNo: Integer; ValueFieldNo: Integer; InvoiceOption: Text; CreditMemoOption: Text)
    var
        TempCreditMemoTimeSeriesBuffer: Record "Time Series Buffer" temporary;
    begin
        TimeSeriesPrepareAndGetData(TempTimeSeriesBuffer, RecordVariant, GroupIdFieldNo, DateFieldNo, ValueFieldNo);
        TempCreditMemoTimeSeriesBuffer.Copy(TempTimeSeriesBuffer, true);
        TempCreditMemoTimeSeriesBuffer.SetRange("Group ID", CreditMemoOption);

        TempTimeSeriesBuffer.SetRange("Group ID", InvoiceOption);

        if TempTimeSeriesBuffer.FindSet() and TempCreditMemoTimeSeriesBuffer.FindSet() then
            repeat
                TempTimeSeriesBuffer.Value := TempTimeSeriesBuffer.Value + TempCreditMemoTimeSeriesBuffer.Value;
                TempTimeSeriesBuffer.Modify();
            until (TempTimeSeriesBuffer.Next() = 0) and (TempCreditMemoTimeSeriesBuffer.Next() = 0);
    end;

    local procedure TimeSeriesPrepareAndGetData(var TempTimeSeriesBuffer: Record "Time Series Buffer" temporary; RecordVariant: Variant; GroupIdFieldNo: Integer; DateFieldNo: Integer; ValueFieldNo: Integer)
    begin
        TimeSeriesManagement.PrepareData(
          RecordVariant,
          GroupIdFieldNo,
          DateFieldNo,
          ValueFieldNo,
          PeriodType,
          ForecastStartDate,
          NumberOfPeriodsWithHistory);

        TimeSeriesManagement.GetPreparedData(TempTimeSeriesBuffer);
    end;

    local procedure AppendRecords(var TargetTimeSeriesBuffer: Record "Time Series Buffer"; var SourceTimeSeriesBuffer: Record "Time Series Buffer"; Label: Text[50])
    begin
        if SourceTimeSeriesBuffer.FindSet() then
            repeat
                if TargetTimeSeriesBuffer.Get(Label, SourceTimeSeriesBuffer."Period No.") then begin
                    TargetTimeSeriesBuffer.Validate(Value, (TargetTimeSeriesBuffer.Value + SourceTimeSeriesBuffer.Value));
                    TargetTimeSeriesBuffer.Modify();
                end else begin
                    TargetTimeSeriesBuffer.Validate(Value, SourceTimeSeriesBuffer.Value);
                    TargetTimeSeriesBuffer.Validate("Period Start Date", SourceTimeSeriesBuffer."Period Start Date");
                    TargetTimeSeriesBuffer.Validate("Period No.", SourceTimeSeriesBuffer."Period No.");
                    TargetTimeSeriesBuffer.Validate("Group ID", Label);
                    TargetTimeSeriesBuffer.Insert();
                end;
            until SourceTimeSeriesBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure Initialize(): Boolean
    var
        AzureAIUsage: Codeunit "Azure AI Usage";
        AzureAIService: Enum "Azure AI Service";
        APIURL: Text[250];
        APIKey: SecretText;
        LimitValue: Decimal;
        IsInitialized: Boolean;
        TimeSeriesLibState: Option Uninitialized,Initialized,"Data Prepared",Done;
        UsingStandardCredentials: Boolean;
    begin
        if not CashFlowSetup.Get() then
            exit(false);

        IsInitialized := true;

        // check if Azure AI is enabled
        TempErrorMessage.SetContext(CashFlowSetup);
        if not CashFlowSetup."Azure AI Enabled" then begin
            TempErrorMessage.LogMessage(
              CashFlowSetup, CashFlowSetup.FieldNo("Azure AI Enabled"), ErrorMessage."Message Type"::Error,
              StrSubstNo(AzureAIMustBeEnabledErr, CashFlowSetup.FieldCaption("Azure AI Enabled"),
                CashFlowSetup.TableCaption()));
            IsInitialized := false;
        end;

        // check Azure ML settings
        if not CashFlowSetup.GetMLCredentials(APIURL, APIKey, LimitValue, UsingStandardCredentials) then begin
            TempErrorMessage.LogMessage(
              CashFlowSetup, CashFlowSetup.FieldNo("API URL"), ErrorMessage."Message Type"::Error,
              StrSubstNo(AzureAIAPIURLEmptyErr, CashFlowSetup.FieldCaption("API URL"),
                CashFlowSetup.FieldCaption("API Key"), CashFlowSetup.TableCaption()));
            IsInitialized := false;
        end;
        if IsInitialized = false then
            exit(false);

        // check - it will be fixed with Time Series Lib
        if not CashFlowSetup.IsAPIUserDefined() then
            if AzureAIUsage.IsLimitReached(AzureAIService::"Machine Learning", LimitValue) then begin
                TempErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, AzureMachineLearningLimitReachedErr);
                exit(false);
            end;

        // Time series Lib
        if not TimeSeriesManagement.Initialize(APIURL, APIKey, CashFlowSetup.TimeOut, UsingStandardCredentials) then begin
            TempErrorMessage.LogSimpleMessage(ErrorMessage."Message Type"::Error, TimeSeriesManagementInitFailedErr);
            exit(false);
        end;

        TimeSeriesManagement.SetMaximumHistoricalPeriods(CashFlowSetup."Historical Periods");
        TimeSeriesManagement.GetState(TimeSeriesLibState);

        // set defaults
        PeriodType := CashFlowSetup."Period Type";
        ForecastStartDate := GetForecastStartDate(PeriodType);
        exit(true);
    end;

    local procedure GetPeriodEndingDate(StartingDate: Date; PeriodType: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodType of
            PeriodType::Day:
                exit(StartingDate);
            PeriodType::Week:
                exit(CalcDate('<+1W-1D>', StartingDate));
            PeriodType::Month:
                exit(CalcDate('<+1M-1D>', StartingDate));
            PeriodType::Quarter:
                exit(CalcDate('<+1Q-1D>', StartingDate));
            PeriodType::Year:
                exit(CalcDate('<+1Y-1D>', StartingDate));
        end;
    end;

    local procedure NewCashFlowAzureAIBufferRecord(GroupIdValue: Text[50]; AmountValue: Decimal; DeltaPercentValue: Decimal; DeltaValue: Decimal; TypeValue: Option; PeriodStartValue: Date; PeriodTypeValue: Option; PeriodNoValue: Integer)
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
    begin
        CashFlowAzureAIBuffer.Init();
        CashFlowAzureAIBuffer.Validate("Group Id", GroupIdValue);
        CashFlowAzureAIBuffer.Validate(Amount, AmountValue);
        CashFlowAzureAIBuffer.Validate("Delta %", DeltaPercentValue);
        CashFlowAzureAIBuffer.Validate(Delta, DeltaValue);
        CashFlowAzureAIBuffer.Validate(Type, TypeValue);
        CashFlowAzureAIBuffer.Validate("Period Start", PeriodStartValue);
        CashFlowAzureAIBuffer.Validate("Period Type", PeriodTypeValue);
        CashFlowAzureAIBuffer.Validate("Period No.", PeriodNoValue);
        CashFlowAzureAIBuffer.Insert();
    end;

    local procedure NewCorrectionRecord(var ForecastedRemainingAmount: Decimal; TimeSeriesForecast: Record "Time Series Forecast"; GroupIDValue: Text[100]; PeriodTypeValue: Option)
    var
        CashFlowAzureAIBuffer: Record "Cash Flow Azure AI Buffer";
        CorrectionAmount: Decimal;
    begin
        if ForecastedRemainingAmount = 0 then
            exit;
        // correction must not be bigger than forecasted amount
        CorrectionAmount := GetCorrectionAmount(TimeSeriesForecast, GroupIDValue, PeriodTypeValue);

        if CorrectionAmount = 0 then
            exit;

        // if correction amount smaller than forecasted, keep correction and reduce forecasted remaining amount
        if ForecastedRemainingAmount < CorrectionAmount then begin
            CorrectionAmount := ForecastedRemainingAmount;
            ForecastedRemainingAmount := 0;
        end else
            ForecastedRemainingAmount -= CorrectionAmount;

        ConvertValueBasedOnType(CorrectionAmount, TimeSeriesForecast."Group ID");
        // insert correction
        CashFlowAzureAIBuffer.Init();
        CashFlowAzureAIBuffer.Validate("Group Id", GroupIDValue);
        CashFlowAzureAIBuffer.Validate(Amount, CorrectionAmount);
        CashFlowAzureAIBuffer.Validate(Type, CashFlowAzureAIBuffer.Type::Correction);
        CashFlowAzureAIBuffer.Validate("Period Start", TimeSeriesForecast."Period Start Date");
        CashFlowAzureAIBuffer.Validate("Period Type", PeriodTypeValue);
        CashFlowAzureAIBuffer.Validate("Period No.", TimeSeriesForecast."Period No.");
        CashFlowAzureAIBuffer.Insert();
    end;

    local procedure GetCorrectionAmount(TimeSeriesForecast: Record "Time Series Forecast"; GroupIDValue: Text[100]; PeriodType: Option): Decimal
    begin
        case GroupIDValue of
            XPAYABLESCORRECTIONTxt:
                exit(CalculatePostedPurchDocsSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType));
            XPURCHORDERSTxt:
                exit(CalculateNotPostedPurchOrderSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType, false));
            XRECEIVABLESCORRECTIONTxt:
                exit(CalculatePostedSalesDocsSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType));
            XSALESORDERSTxt:
                exit(CalculateNotPostedSalesOrderSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType, false));
            XTAXPAYABLESCORRECTIONTxt:
                exit(CalculatePostedDocsSumTaxInPeriod(TimeSeriesForecast."Period Start Date", false));
            XTAXPURCHORDERSTxt:
                exit(CalculateNotPostedPurchOrderSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType, true));
            XTAXRECEIVABLESCORRECTIONTxt:
                exit(CalculatePostedDocsSumTaxInPeriod(TimeSeriesForecast."Period Start Date", true));
            XTAXSALESORDERSTxt:
                exit(CalculateNotPostedSalesOrderSumAmountInPeriod(TimeSeriesForecast."Period Start Date", PeriodType, true));
        end;
    end;

    local procedure IsAmountValid(TimeSeriesForecast: Record "Time Series Forecast"): Boolean
    begin
        if ((TimeSeriesForecast."Group ID" = XPAYABLESTxt) or (TimeSeriesForecast."Group ID" = XTAXRECEIVABLESTxt)) and (TimeSeriesForecast.Value < 0) then
            exit(true);
        if ((TimeSeriesForecast."Group ID" = XRECEIVABLESTxt) or (TimeSeriesForecast."Group ID" = XTAXPAYABLESTxt)) and (TimeSeriesForecast.Value > 0) then
            exit(true);
        exit(false);
    end;

    local procedure GetForecastStartDate(PeriodType: Option Day,Week,Month,Quarter,Year): Date
    begin
        case PeriodType of
            PeriodType::Day:
                exit(WorkDate());
            PeriodType::Week:
                exit(CalcDate('<CW+1D-1W>', WorkDate()));
            PeriodType::Month:
                exit(CalcDate('<CM+1D-1M>', WorkDate()));
            PeriodType::Quarter:
                exit(CalcDate('<CQ+1D-1Q>', WorkDate()));
            PeriodType::Year:
                exit(CalcDate('<CY+1D-1Y>', WorkDate()));
        end;
    end;

    local procedure CreateSetupNotification()
    var
        SetupNotification: Notification;
    begin
        if not ShowNotification() then
            exit;

        SetupNotification.Message := SetupScheduledForecastingMsg;
        SetupNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
        SetupNotification.AddAction(EnableAzureAITxt, CODEUNIT::"Cash Flow Forecast Handler", 'SetupAzureAI');
        SetupNotification.AddAction(DontAskAgainTxt, CODEUNIT::"Cash Flow Forecast Handler", 'DeactivateNotification');
        SetupNotification.Send();
    end;

    local procedure ShowNotification(): Boolean
    var
        CashFlowSetup: Record "Cash Flow Setup";
        O365GettingStarted: Record "O365 Getting Started";
    begin
        if O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then
            if O365GettingStarted."Tour in Progress" then
                exit(false);

        if not CashFlowSetup.Get() then
            exit(false);

        if CashFlowSetup."Azure AI Enabled" then
            exit(false);

        if not CashFlowSetup."Show AzureAI Notification" then
            exit(false);

        if CashFlowSetup."CF No. on Chart in Role Center" = '' then
            exit(false);

        exit(true);
    end;

    procedure DeactivateNotification(SetupNotification: Notification)
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        if not CashFlowSetup.Get() then
            exit;
        CashFlowSetup."Show AzureAI Notification" := false;
        CashFlowSetup.Modify(true);
    end;

    procedure SetupAzureAI(SetupNotification: Notification)
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if CashFlowSetup.Get() then
            PAGE.RunModal(PAGE::"Cash Flow Setup", CashFlowSetup);
        if CashFlowSetup.Get() then begin
            if EnvironmentInfo.IsSaaS() and CashFlowSetup."Azure AI Enabled" then
                Message(ScheduledForecastingEnabledMsg);
            CashFlowSetup."Show AzureAI Notification" := false;
            CashFlowSetup.Modify(true);
        end;
    end;

    local procedure ConvertValueBasedOnType(var Value: Decimal; Type: Text)
    begin
        if (Type = XRECEIVABLESTxt) or (Type = XTAXPAYABLESTxt) then
            Value := -Value;
    end;

    local procedure AggregateTaxRecordsToTaxablePeriod(var TimeSeriesForecast: Record "Time Series Forecast"; GroupID: Text[100])
    var
        NextForecastDate: Date;
        TaxablePeriodEndDate: Date;
        CurrentSum: Decimal;
        LastPeriodNo: Integer;
        PeriodTypeOption: Option Day,Week,Month,Quarter,Year;
    begin
        TimeSeriesForecast.SetRange("Group ID", GroupID);
        CurrentSum := 0;
        // Get the biggest taxable period endDate to avoid insertion of first record
        if TimeSeriesForecast.FindLast() then
            LastPeriodNo := TimeSeriesForecast."Period No.";
        PeriodTypeOption := PeriodType;
        if TimeSeriesForecast.FindSet() then
            repeat
                CurrentSum += TimeSeriesForecast.Value;
                TaxablePeriodEndDate := CashFlowSetup.GetTaxPaymentDueDate(TimeSeriesForecast."Period Start Date");
                TaxablePeriodEndDate := CashFlowSetup.GetTaxPeriodEndDate(TaxablePeriodEndDate);
                NextForecastDate := TimeSeriesForecast."Period Start Date";
                case PeriodType of
                    PeriodTypeOption::Day:
                        NextForecastDate := CalcDate('<+1D>', NextForecastDate);
                    PeriodTypeOption::Week:
                        NextForecastDate := CalcDate('<+1W>', NextForecastDate);
                    PeriodTypeOption::Month:
                        NextForecastDate := CalcDate('<+1M>', NextForecastDate);
                    PeriodTypeOption::Quarter:
                        NextForecastDate := CalcDate('<+1Q>', NextForecastDate);
                    PeriodTypeOption::Year:
                        NextForecastDate := CalcDate('<+1Y>', NextForecastDate);
                end;
                if (NextForecastDate > TaxablePeriodEndDate) or (TimeSeriesForecast."Period No." = LastPeriodNo) then begin
                    TimeSeriesForecast.Value := CurrentSum;
                    TimeSeriesForecast."Period Start Date" := CashFlowSetup.GetTaxPaymentDueDate(TimeSeriesForecast."Period Start Date");
                    TimeSeriesForecast.Modify();
                    CurrentSum := 0;
                end else
                    TimeSeriesForecast.Delete();
            until (TimeSeriesForecast.Next() = 0);

        TimeSeriesForecast.SetRange("Group ID");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Cash Flow Forecast Chart", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenCashFlowForecastChart(var Rec: Record "Business Chart Buffer")
    begin
        CreateSetupNotification();
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterPrepareSalesHistoryData(var TimeSeriesBuffer: Record "Time Series Buffer"; PeriodType: Integer; ForecastStartDate: Date; NumberOfPeriodsWithHistory: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterPreparePurchHistoryData(var TimeSeriesBuffer: Record "Time Series Buffer"; PeriodType: Integer; ForecastStartDate: Date; NumberOfPeriodsWithHistory: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnAfterHasMinimumHistoricalData(var HasMinimumHistoryLoc: Boolean; var NumberOfPeriodsWithHistoryLoc: Integer; PeriodType: Integer; ForecastStartDate: Date)
    begin
    end;
}

