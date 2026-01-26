// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using System;
using System.IO;

report 12150 "VAT Payment Communication"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Periodic VAT Payment Communication';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                field(VATSettlementEndingDate; StartDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT settlement ending date', Comment = 'ITA Fine periodo di liquid';
                    ToolTip = 'Specifies the last date for which VAT statement entries are included.';
                }
                field(YearOfDeclaration; YearOfDeclaration)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Supply code';
                    ToolTip = 'Specifies the two digits that will be added to the IVP value of the CodiceFornitura XML node in the exported file.';

                    trigger OnValidate()
                    begin
                        if (YearOfDeclaration < 0) or (YearOfDeclaration > 99) then
                            Error(InvalidYearOfDeclarationErr);
                    end;
                }
                field(DeclarantFiscalcode; TaxDeclarant)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Declarant fiscal code', Comment = 'ITA Codice Fiscale dichiarante';
                    ToolTip = 'Specifies the fiscal code of the person that generates the report.';
                }
                field(DeclarantAppointmentCode; ChargeCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Declarant appointment code', Comment = 'ITA Codice carica dichiarante';
                    ToolTip = 'Specifies the code of the person that generates the report.';
                }
                field(Signed; IsSigned)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Signed';
                    ToolTip = 'Specifies if the report is signed.';
                }
                field("Commitment submission"; CommitmentSubmission)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Commitment submission';
                    ToolTip = 'Specifies the role of the person that generates the report.';
                }
                field(Intermediary; IsIntermediary)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Intermediary';
                    ToolTip = 'Specifies the if the person that generates the report is intermediary.';
                }
                field("Flag deviations"; FlagDeviations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Flag deviations';
                    ToolTip = 'Specifies if the report has any abnormalities.';
                }
                field(Subcontracting; IsSubcontracting)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subcontracting';
                    ToolTip = 'Specifies if the person that generates the report is a subcontractor.';
                }
                field("Exceptional events"; ExceptionalEvents)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exceptional events';
                    ToolTip = 'Specifies if there were any exceptional events during this period.';
                }
                field(ExtraordinaryOperations; ExtraordinaryOperations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Extraordinary Operations';
                    ToolTip = 'Specifies if there were any extraordinary operations during this period.';
                }
                field(MethodOfCalcAdvanced; MethodOfCalcAdvanced)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Method Of Calc. Advanced Amount';
                    ToolTip = 'Specifies the calculation method for advanced amounts during this period.';
                }
                field("Module Number"; ModuleNumber)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Module Number';
                    ToolTip = 'Specifies the module number.';
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        var
            GeneralLedgerSetup: Record "General Ledger Setup";
        begin
            GeneralLedgerSetup.Get();
            StartDate := CalcDate('<CQ-1Q+1D>', GeneralLedgerSetup."Last Settlement Date" + 1);
            YearOfDeclaration := 18;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        VATReportSetup: Record "VAT Report Setup";
        FileManagement: Codeunit "File Management";
        VATPmtCommDataLookup: Codeunit "VAT Pmt. Comm. Data Lookup";
        VATPmtCommXMLGenerator: Codeunit "VAT Pmt. Comm. XML Generator";
        XMLDoc: DotNet XmlDocument;
        SuggestedFileName: Text;
        ServerFilePathAlreadySet: Boolean;
    begin
        if StartDate = 0D then
            Error(StartDateBlankErr);

        if (TaxDeclarant <> '') and (ChargeCode = '') then
            Error(ChargeCodeBlankErr);

        if ModuleNumber = 0 then
            Error(ModuleNumberBlankErr);

        if ServerFilePath = '' then
            ServerFilePath := FileManagement.ServerTempFileName('xml')
        else
            ServerFilePathAlreadySet := true;

        VATPmtCommDataLookup.Init();
        VATPmtCommDataLookup.SetStartDate(StartDate);
        VATPmtCommDataLookup.SetYearOfDeclaration(YearOfDeclaration);
        VATPmtCommDataLookup.SetTaxDeclarant(TaxDeclarant);
        VATPmtCommDataLookup.SetChargeCode(ChargeCode);
        VATPmtCommDataLookup.SetIsSigned(IsSigned);
        VATPmtCommDataLookup.SetCommitmentSubmission(CommitmentSubmission);
        VATPmtCommDataLookup.SetIsIntermediary(IsIntermediary);
        VATPmtCommDataLookup.SetFlagDeviations(FlagDeviations);
        VATPmtCommDataLookup.SetSubcontracting(IsSubcontracting);
        VATPmtCommDataLookup.SetExceptions(ExceptionalEvents);
        VATPmtCommDataLookup.SetMethodOfCalcAdvanced(MethodOfCalcAdvanced);
        VATPmtCommDataLookup.SetExtraordinaryOperations(ExtraordinaryOperations);
        VATPmtCommDataLookup.SetModuleNumber(ModuleNumber);

        VATPmtCommXMLGenerator.SetVATPmtCommDataLookup(VATPmtCommDataLookup);
        VATPmtCommXMLGenerator.CreateXml(XMLDoc);

        XMLDoc.Save(ServerFilePath);
        VATReportSetup.Get();
        SuggestedFileName := 'IT' + VATPmtCommDataLookup.GetFiscalCode() + '_LI_' +
          VATPmtCommDataLookup.FormatCommunicationId(VATReportSetup."Spesometro Communication ID") +
          '.xml';
        if not ServerFilePathAlreadySet then
            Download(ServerFilePath, SaveXmlAsLbl, '',
              FileManagement.GetToFilterText('', SuggestedFileName), SuggestedFileName);
    end;

    var
        StartDate: Date;
        YearOfDeclaration: Integer;
        TaxDeclarant: Text[16];
        ChargeCode: Text[2];
        IsSigned: Boolean;
        CommitmentSubmission: Option Skip,Contributor,Sender;
        IsIntermediary: Boolean;
        FlagDeviations: Boolean;
        IsSubcontracting: Boolean;
        ExceptionalEvents: Option Skip,"1","9";
        StartDateBlankErr: Label 'You have to choose a start date.';
        ChargeCodeBlankErr: Label 'Charge code cannot be blank.';
        ServerFilePath: Text;
        SaveXmlAsLbl: Label 'Save xml as...';
        InvalidYearOfDeclarationErr: Label 'The year of declaration has to be an integer between 0 and 99.';
        MethodOfCalcAdvanced: Option "No advance",Historical,Budgeting,Analytical,"Specific Subjects";
        ExtraordinaryOperations: Boolean;
        ModuleNumber: Option ,"1","2","3","4","5";
        ModuleNumberBlankErr: Label 'You must enter a module number.';

    [Scope('OnPrem')]
    procedure InitializeRequest(StartDateValue: Date; YearOfDeclarationValue: Integer; TaxDeclarantValue: Text[16]; ChargeCodeValue: Text[2]; IsSignedValue: Boolean; CommitmentSubmissionValue: Option; IsIntermediaryValue: Boolean; FlagDeviationsValue: Boolean; IsSubcontractingValue: Boolean; ExceptionalEventsValue: Option; ExtraordinaryOperationsValue: Boolean; MethodOfCalcAdvancedValue: Option; ModuleNumberValue: Option; DestinationFileValue: Text)
    begin
        StartDate := StartDateValue;
        YearOfDeclaration := YearOfDeclarationValue;
        TaxDeclarant := TaxDeclarantValue;
        ChargeCode := ChargeCodeValue;
        IsSigned := IsSignedValue;
        CommitmentSubmission := CommitmentSubmissionValue;
        IsIntermediary := IsIntermediaryValue;
        FlagDeviations := FlagDeviationsValue;
        IsSubcontracting := IsSubcontractingValue;
        ExceptionalEvents := ExceptionalEventsValue;
        ExtraordinaryOperations := ExtraordinaryOperationsValue;
        MethodOfCalcAdvanced := MethodOfCalcAdvancedValue;
        ModuleNumber := ModuleNumberValue;
        ServerFilePath := DestinationFileValue;
    end;
}

