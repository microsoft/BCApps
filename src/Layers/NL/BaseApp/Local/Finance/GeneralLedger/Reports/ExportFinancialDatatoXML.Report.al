// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System;
using System.IO;
using System.Utilities;
using System.Xml;

report 11420 "Export Financial Data to XML"
{
    ApplicationArea = Basic, Suite;
    Caption = 'NL Export Financial Data to XML';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            DataItemTableView = sorting(Number);
            dataitem("G/L Account"; "G/L Account")
            {
                DataItemTableView = sorting("No.");
                RequestFilterFields = "Business Unit Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";

                trigger OnAfterGetRecord()
                begin
                    CreateDataRow("G/L Account");
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Account Type", "G/L Account"."Account Type"::Posting);
                    SetRange(Blocked, false);
                    SetRange("Date Filter", StartDate, EndDate);
                    if ElementValue[Integer.Number] = ElementValue[Integer.Number] ::Budget then begin
                        if GLBudgetName = '' then
                            CurrReport.Break();
                        SetRange("Budget Filter", GLBudgetName);
                    end;
                end;
            }
            dataitem("G/L Account 2"; "G/L Account")
            {
                DataItemTableView = sorting("No.");

                trigger OnAfterGetRecord()
                begin
                    CreateDataRow("G/L Account 2");
                end;

                trigger OnPreDataItem()
                begin
                    if (PrevStartDate = 0D) or (PrevEndDate = 0D) then
                        CurrReport.Break();
                    CopyFilters("G/L Account");
                    SetRange("Date Filter", PrevStartDate, PrevEndDate);
                    if ElementValue[Integer.Number] = ElementValue[Integer.Number] ::Budget then begin
                        if PrevGLBudgetName = '' then
                            CurrReport.Break();
                        SetRange("Budget Filter", PrevGLBudgetName);
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                case ElementValue[Number] of
                    ElementValue[Number] ::OpeningBalance:
                        Window.Update(1, Text009);
                    ElementValue[Number] ::Debit:
                        Window.Update(1, Text010);
                    ElementValue[Number] ::Credit:
                        Window.Update(1, Text011);
                    ElementValue[Number] ::NetDifference:
                        Window.Update(1, Text012);
                    ElementValue[Number] ::ClosingTransactions:
                        Window.Update(1, Text013);
                    ElementValue[Number] ::ClosingBalance:
                        Window.Update(1, Text014);
                    ElementValue[Number] ::Budget:
                        Window.Update(1, Text015);
                end;
                Window.Update(2, Round(Number / (i - 1) * 10000, 1));
            end;

            trigger OnPostDataItem()
            begin
                XMLDoc.Save(ServerFileName);
            end;

            trigger OnPreDataItem()
            begin
                SetupColumns();
                SetRange(Number, 1, i - 1);
                CreateHeaderInfo();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Current Period")
                    {
                        Caption = 'Current Period';
                        field(StartingDate_CurrentPeriod; StartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the start date of the comparative period.';

                            trigger OnValidate()
                            begin
                                SetEndingDate();
                                SetPreviousDates();
                            end;
                        }
                        field(EndingDate_CurrentPeriod; EndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date of the comparative period.';

                            trigger OnValidate()
                            begin
                                SetPreviousDates();
                            end;
                        }
                        field(BudgetNameOptional; GLBudgetName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Budget Name (optional)';
                            LookupPageID = "G/L Budget Names";
                            TableRelation = "G/L Budget Name";
                            ToolTip = 'Specifies the name of the budget to include in the file.';
                        }
                    }
                    group("Comparative Period (optional)")
                    {
                        Caption = 'Comparative Period (optional)';
                        field(StartingDate_ComparativePeriod; PrevStartDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Starting Date';
                            ToolTip = 'Specifies the start date of the comparative period.';

                            trigger OnValidate()
                            begin
                                if PrevStartDate = 0D then
                                    PrevEndDate := 0D;
                            end;
                        }
                        field(EndingDate_ComparativePeriod; PrevEndDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Ending Date';
                            ToolTip = 'Specifies the end date of the comparative period.';

                            trigger OnValidate()
                            begin
                                if PrevEndDate = 0D then
                                    PrevStartDate := 0D;
                            end;
                        }
                        field(BudgetName; PrevGLBudgetName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Budget Name';
                            LookupPageID = "G/L Budget Names";
                            TableRelation = "G/L Budget Name";
                            ToolTip = 'Specifies the name of the budget to include in the file.';
                        }
                    }
                    field(IncludeOpeningBalance; IncludeOpeningBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Opening Balance';
                        ToolTip = 'Specifies if the opening balance for the current year and the previous year is included in the file.';
                    }
                    field(IncludeNetChanges; IncludeNetChanges)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Net Changes';
                        ToolTip = 'Specifies if the net changes balance for the current year and the previous year is included in the file.';
                    }
                    field(IncludeClosingTransaction; IncludeClosingTransaction)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Transactions';
                        ToolTip = 'Specifies if the closing transactions balance for the current year and the previous year is included in the file.';
                    }
                    field(IncludeClosingBalance; IncludeClosingBalance)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Closing Balance';
                        ToolTip = 'Specifies if the closing balance is included in the file.';
                    }
                    field(ISOLCYCode; ISOLCYCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'ISO LCY Code';
                        ToolTip = 'Specifies the code for LCY.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ISOLCYCode := 'EUR';
    end;

    trigger OnPostReport()
    begin
        if FileName = '' then
            FileManagement.DownloadHandler(ServerFileName, '', '', FileManagement.GetToFilterText('', ServerFileName), FileNameTxt)
        else
            FileManagement.CopyServerFile(ServerFileName, FileName, true);
        FileManagement.DeleteServerFile(ServerFileName);
    end;

    trigger OnPreReport()
    begin
        CompanyInfo.Get();
        CheckDates();
        ServerFileName := FileManagement.ServerTempFileName('xml');
        XMLDoc := XMLDoc.XmlDocument();
        Window.Open(
          '#1#################################\\' +
          '@2@@@@@@@@@@@@@@@@@@@@@\');
    end;

    var
        CompanyInfo: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        XMLDOMMgt: Codeunit "XML DOM Management";
        FileManagement: Codeunit "File Management";
        Window: Dialog;
        XMLDoc: DotNet XmlDocument;
        CurrXMLNode: DotNet XmlNode;
        ChildXMLNode: DotNet XmlNode;
        GLBudgetName: Code[10];
        PrevGLBudgetName: Code[10];
        ISOLCYCode: Code[3];
        StartDate: Date;
        EndDate: Date;
        PrevStartDate: Date;
        PrevEndDate: Date;
        IncludeOpeningBalance: Option Include,Exclude;
        IncludeClosingBalance: Option Include,Exclude;
        IncludeNetChanges: Option Include,Exclude;
        IncludeClosingTransaction: Option Include,Exclude;
        ElementValue: array[8] of Option ,OpeningBalance,Debit,Credit,NetDifference,ClosingTransactions,ClosingBalance,Budget;
        ServerFileName: Text;
        FileName: Text;
        i: Integer;
        j: Integer;
        Text001: Label '<-1Y>', Locked = true;
        Text002: Label '%1 and %2 do not belong to the same fiscal year.';
        Text003: Label 'Current period ending date cannot be before starting date.';
        Text004: Label 'Comparative period ending date cannot be before starting date.';
        Text009: Label 'Exporting Opening Balance Data';
        Text010: Label 'Exporting Debit Data';
        Text011: Label 'Exporting Credit Data';
        Text012: Label 'Exporting Net Difference Data';
        Text013: Label 'Exporting Closing Transactions Data';
        Text014: Label 'Exporting Closing Balance Data';
        Text015: Label 'Exporting Budget Data';
        Text016: Label 'Current Period starting date cannot be blank. ';
        Text017: Label 'Current Period ending date cannot be blank. ';
        Text018: Label '%1 is not within any valid accounting period. ';
        Text019: Label 'Comparative period ending date cannot be blank when starting date is filled in.';
        Text020: Label 'Comparative period starting date cannot be blank when ending date is filled in.';
        FileNameTxt: Label 'Financial Data.xml';

    [Scope('OnPrem')]
    procedure CreateHeaderInfo()
    begin
        XMLDOMMgt.LoadXMLDocumentFromText('<?xml version="1.0" encoding="UTF-8"?>' +
          '<sxr-dbr:DataBridge xmlns="http://www.semansys.com/xbrl/sxr/XBRLDataBridge/v2" ' +
          'xmlns:sxr-dbr="http://www.semansys.com/xbrl/sxr/XBRLDataBridge/v2" ' +
          'xmlns:sxr-common="http://www.semansys.com/xbrl/sxr/common" ' +
          'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ' +
          'xsi:schemaLocation="http://www.semansys.com/xbrl/sxr/XBRLDataBridge/v2 ' +
          'http://xbrlone.com/xbrl/xsd/2007/sxr-DataBridge-2007-09-05.xsd">' +
          '</sxr-dbr:DataBridge>', XMLDoc);
        CurrXMLNode := XMLDoc.DocumentElement;

        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:Header', '', '', ChildXMLNode);
        CurrXMLNode := ChildXMLNode;

        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:Name', 'Ledger Balance', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:Author', UserId, '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:SourceSystem', 'Microsoft Dynamics NAV', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:Type', '', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:Description', CompanyInfo.Name, '', ChildXMLNode);
        XMLDOMMgt.AddElement(
          CurrXMLNode, 'sxr-common:Comment', 'This data has been produced based on data in Microsoft Dynamics NAV', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:DueDate', Format(WorkDate(), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:CreationDate', Format(WorkDate(), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:ModificationDate', Format(WorkDate(), 0, 9), '', ChildXMLNode);
        CurrXMLNode := CurrXMLNode.ParentNode;
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:DataSource', '', '', ChildXMLNode);
        CurrXMLNode := ChildXMLNode;
    end;

    [Scope('OnPrem')]
    procedure CreateDataRow(var GLAcc: Record "G/L Account")
    begin
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:DataRow', '', '', ChildXMLNode);
        CurrXMLNode := ChildXMLNode;
        XMLDOMMgt.AddAttribute(CurrXMLNode, 'id', 'dr' + Format(j));

        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:AccountCode', GLAcc."No.", '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:AccountName', GLAcc.Name, '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:AccountDescription', Format(GLAcc."Income/Balance", 0, 1), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:AccountValue', Format(CalculateAccountValue(GLAcc), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:DecimalDigits', '2', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-dbr:ScenarioElement', '', '', ChildXMLNode);
        CurrXMLNode := ChildXMLNode;

        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:ElementName', 'msDynamicsScenario', '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:ElementValue', Format(ElementValue[Integer.Number], 0, 1), '', ChildXMLNode);
        CurrXMLNode := CurrXMLNode.ParentNode;

        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:PeriodStart', Format(GLAcc.GetRangeMin("Date Filter"), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:PeriodEnd', Format(GLAcc.GetRangeMax("Date Filter"), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:PeriodInstant', Format(GLAcc.GetRangeMax("Date Filter"), 0, 9), '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:EntityCode', CompanyInfo.Name, '', ChildXMLNode);
        XMLDOMMgt.AddElement(CurrXMLNode, 'sxr-common:CurrencyCode', ISOLCYCode, '', ChildXMLNode);
        CurrXMLNode := CurrXMLNode.ParentNode;

        j := j + 1;
    end;

    [Scope('OnPrem')]
    procedure CalculateAccountValue(var GLAcc: Record "G/L Account"): Decimal
    var
        GLAcc2: Record "G/L Account";
        TempDate: Date;
    begin
        case ElementValue[Integer.Number] of
            ElementValue[Integer.Number] ::OpeningBalance:
                begin
                    GLAcc2.Get(GLAcc."No.");
                    TempDate := ClosingDate(GLAcc.GetRangeMin("Date Filter"));
                    GLAcc2.SetFilter("Date Filter", '..%1', CalcDate('<-1D>', TempDate));
                    GLAcc2.CalcFields("Balance at Date");
                    exit(GLAcc2."Balance at Date");
                end;
            ElementValue[Integer.Number] ::Debit:
                begin
                    GLAcc.CalcFields("Debit Amount");
                    exit(GLAcc."Debit Amount");
                end;
            ElementValue[Integer.Number] ::Credit:
                begin
                    GLAcc.CalcFields("Credit Amount");
                    exit(GLAcc."Credit Amount");
                end;
            ElementValue[Integer.Number] ::NetDifference:
                begin
                    GLAcc.CalcFields("Net Change");
                    exit(GLAcc."Net Change");
                end;
            ElementValue[Integer.Number] ::ClosingTransactions:
                begin
                    GLAcc2.Get(GLAcc."No.");
                    GLAcc2.SetFilter("Date Filter", '%1', ClosingDate(GLAcc.GetRangeMax("Date Filter")));
                    GLAcc2.CalcFields("Net Change");
                    exit(GLAcc2."Net Change");
                end;
            ElementValue[Integer.Number] ::ClosingBalance:
                begin
                    GLAcc2.Get(GLAcc."No.");
                    GLAcc2.SetFilter("Date Filter", '..%1', ClosingDate(GLAcc.GetRangeMax("Date Filter")));
                    GLAcc2.CalcFields("Balance at Date");
                    exit(GLAcc2."Balance at Date");
                end;
            ElementValue[Integer.Number] ::Budget:
                begin
                    GLAcc.CalcFields("Budget at Date");
                    exit(GLAcc."Budget at Date");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetEndingDate()
    begin
        AccountingPeriod.Reset();
        AccountingPeriod.SetFilter("Starting Date", '>%1', StartDate);
        if AccountingPeriod.FindFirst() then
            EndDate := AccountingPeriod."Starting Date" - 1;
    end;

    [Scope('OnPrem')]
    procedure SetPreviousDates()
    begin
        if StartDate <> 0D then
            PrevStartDate := CalcDate(Text001, StartDate);
        if EndDate <> 0D then
            PrevEndDate := CalcDate(Text001, EndDate);
    end;

    [Scope('OnPrem')]
    procedure SetFileName(ServerFileName: Text)
    begin
        FileName := ServerFileName;
    end;

    [Scope('OnPrem')]
    procedure SetupColumns()
    begin
        i := 1;
        if IncludeOpeningBalance = IncludeOpeningBalance::Include then begin
            ElementValue[i] := ElementValue[i] ::OpeningBalance;
            i := i + 1;
        end;
        ElementValue[i] := ElementValue[i] ::Debit;
        i := i + 1;
        ElementValue[i] := ElementValue[i] ::Credit;
        i := i + 1;
        if IncludeNetChanges = IncludeNetChanges::Include then begin
            ElementValue[i] := ElementValue[i] ::NetDifference;
            i := i + 1;
        end;
        if IncludeClosingTransaction = IncludeClosingTransaction::Include then begin
            ElementValue[i] := ElementValue[i] ::ClosingTransactions;
            i := i + 1;
        end;
        if IncludeClosingBalance = IncludeClosingBalance::Include then begin
            ElementValue[i] := ElementValue[i] ::ClosingBalance;
            i := i + 1;
        end;
        if (GLBudgetName <> '') or (PrevGLBudgetName <> '') then begin
            ElementValue[i] := ElementValue[i] ::Budget;
            i := i + 1;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckDates()
    var
        AccountingPeriod2: Record "Accounting Period";
        AccountingPeriod3: Record "Accounting Period";
    begin
        if StartDate = 0D then
            Error(Text016);
        if EndDate = 0D then
            Error(Text017);
        if EndDate < StartDate then
            Error(Text003);
        if (PrevStartDate <> 0D) and (PrevEndDate = 0D) then
            Error(Text019);
        if (PrevStartDate = 0D) and (PrevEndDate <> 0D) then
            Error(Text020);
        if PrevEndDate < PrevStartDate then
            Error(Text004);

        // Current period filters should be within same fiscal year
        AccountingPeriod2.SetRange("New Fiscal Year", true);
        AccountingPeriod2.SetFilter("Starting Date", '<=%1', StartDate);
        if AccountingPeriod2.IsEmpty() then
            Error(Text018, StartDate);

        AccountingPeriod2.FindLast();

        AccountingPeriod3.SetRange("New Fiscal Year", true);
        AccountingPeriod3.SetFilter("Starting Date", '<=%1', EndDate);
        if AccountingPeriod3.IsEmpty() then
            Error(Text018, EndDate);

        AccountingPeriod3.FindLast();

        if AccountingPeriod2."Starting Date" <> AccountingPeriod3."Starting Date" then
            Error(
              Text002,
              StartDate, EndDate);

        // Comparative period filters should be within same fiscal year
        if (PrevStartDate <> 0D) and (PrevEndDate <> 0D) then begin
            Clear(AccountingPeriod2);
            Clear(AccountingPeriod3);

            AccountingPeriod2.SetRange("New Fiscal Year", true);
            AccountingPeriod2.SetFilter("Starting Date", '<=%1', PrevStartDate);
            if AccountingPeriod2.IsEmpty() then
                Error(Text018, PrevStartDate);

            AccountingPeriod2.FindLast();

            AccountingPeriod3.SetRange("New Fiscal Year", true);
            AccountingPeriod3.SetFilter("Starting Date", '<=%1', PrevEndDate);
            if AccountingPeriod3.IsEmpty() then
                Error(Text018, PrevEndDate);

            AccountingPeriod3.FindLast();
            if AccountingPeriod2."Starting Date" <> AccountingPeriod3."Starting Date" then
                Error(
                  Text002,
                  PrevStartDate, PrevEndDate);
        end;
    end;
}

