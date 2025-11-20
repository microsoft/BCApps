// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using System.Telemetry;

page 242 "Consolidate Wizard"
{
    Caption = 'Run Consolidation';
    PageType = NavigatePage;
    SourceTable = "Business Unit";
    SourceTableTemporary = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    SaveValues = true;

    layout
    {
        area(Content)
        {
            group(Step0)
            {
                Visible = (Step = 0);
                field(StartingDate; TempConsolidationProcess."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Date';
                    ClosingDates = true;
                    ToolTip = 'Specifies the starting date for the consolidation period.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        UpdateOtherDateAfterOneIsEdited(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
                        if (TempConsolidationProcess."Starting Date" <> 0D) and (TempConsolidationProcess."Ending Date" <> 0D) then
                            ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", true);
                        UpdateBusinessUnitDefaultConsolidateState();
                        SetNextActionEnabled();
                    end;
                }
                field(EndingDate; TempConsolidationProcess."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ending Date';
                    ClosingDates = true;
                    ToolTip = 'Specifies the ending date for the consolidation period. This date is used as the posting date of the consolidation entries.';
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        UpdateOtherDateAfterOneIsEdited(TempConsolidationProcess."Ending Date", TempConsolidationProcess."Starting Date");
                        if (TempConsolidationProcess."Starting Date" <> 0D) and (TempConsolidationProcess."Ending Date" <> 0D) then
                            ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", true);
                        UpdateBusinessUnitDefaultConsolidateState();
                        SetNextActionEnabled();
                    end;
                }
                field(JournalTemplateName; TempConsolidationProcess."Journal Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal Template Name';
                    TableRelation = "Gen. Journal Template";
                    Tooltip = 'Specifies the name of the journal template that is used for posting.';
                    ShowMandatory = true;
                    Visible = JournalTemplateNameMandatory;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Journal Template Name" <> '') and (TempConsolidationProcess."Journal Batch Name" <> '') then
                            ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;

                }
                field(JournalBatchName; TempConsolidationProcess."Journal Batch Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal Batch Name';
                    ToolTip = 'Specifies the name of the journal batch that is used for the posting.';
                    ShowMandatory = true;
                    Visible = JournalTemplateNameMandatory;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalLine: Record "Gen. Journal Line";
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GenJnlManagement: Codeunit GenJnlManagement;
                    begin
                        if TempConsolidationProcess."Journal Template Name" = '' then
                            exit(false);
                        GenJournalLine."Journal Template Name" := TempConsolidationProcess."Journal Template Name";
                        GenJournalLine."Journal Batch Name" := TempConsolidationProcess."Journal Batch Name";
                        GenJnlManagement.SetJnlBatchName(GenJournalLine);
                        if GenJournalLine."Journal Batch Name" <> '' then
                            GenJournalBatch.Get(TempConsolidationProcess."Journal Template Name", GenJournalLine."Journal Batch Name");
                        Text := GenJournalLine."Journal Batch Name";
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        if (TempConsolidationProcess."Journal Template Name" <> '') and (TempConsolidationProcess."Journal Batch Name" <> '') then
                            ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;
                }
                field(DocumentNo; TempConsolidationProcess."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document No.';
                    Tooltip = 'Specifies the G/L document number used for posting.';
                    ShowMandatory = true;
                    Visible = not JournalTemplateNameMandatory;

                    trigger OnValidate()
                    begin
                        ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
                        SetNextActionEnabled();
                    end;
                }
                field(TransferedDimensions; TempConsolidationProcess."Dimensions to Transfer")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Editable = false;
                    ToolTip = 'Specifies the dimensions to transfer from the imported entries.';

                    trigger OnAssistEdit()
                    var
                        Dimension: Record Dimension;
                    begin
                        if Dimension.IsEmpty() then
                            Error(NoDimensionsInConsolidationCompanyErr);
                        DimensionSelectionBuffer.SetDimSelectionMultiple(3, REPORT::"Import Consolidation from DB", TempConsolidationProcess."Dimensions to Transfer");
                    end;
                }
                field(ParentCurrencyCode; TempConsolidationProcess."Parent Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parent Currency Code';
                    Tooltip = 'Specifies the parent currency code.';
                }
            }
            group(Step1)
            {
                Visible = (Step = 1);
                label(Description)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = FullDescriptionTxt;
                }
                group(BusinessUnitsGroup)
                {
                    Caption = 'Business Units to consolidate';
                    ShowCaption = false;
                    Editable = true;
                    Enabled = true;
                    repeater(BusinessUnits)
                    {
                        field(Code; Rec.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Code';
                            ToolTip = 'Specifies the code of the business unit.';
                            Editable = false;
                            TableRelation = "Business Unit";
                            DrillDown = true;
                            StyleExpr = StyleTxt;
                        }
                        field(Name; CompanyName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Company Name';
                            ToolTip = 'Specifies the name of business unit.';
                            Editable = false;
                            StyleExpr = StyleTxt;
                        }
                        field(LastConsolidationEndingDate; LastConsolidationEndingDate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Consolidation Ending Date';
                            ToolTip = 'Specifies the last consolidation''s run ending date for this business unit.';
                            Editable = false;
                            StyleExpr = StyleTxt;

                            trigger OnDrillDown()
                            var
                                BusUnitInConsProcess: Record "Bus. Unit In Cons. Process";
                                ConsForBusinessUnits: Page "Cons. for Business Units";
                            begin
                                BusUnitInConsProcess.SetRange("Business Unit Code", Rec.Code);
                                BusUnitInConsProcess.SetRange(Status, BusUnitInConsProcess.Status::Finished);
                                ConsForBusinessUnits.SetTableView(BusUnitInConsProcess);
                                ConsForBusinessUnits.Run();
                            end;
                        }
                        field(Consolidate; Rec.Consolidate)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Consolidate';
                            ToolTip = 'Specifies if the business unit should be included in the consolidation.';

                            trigger OnValidate()
                            var
                                ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
                            begin
                                if Rec.Consolidate and (Rec."Default Data Import Method" = Rec."Default Data Import Method"::API) then begin
                                    ImportConsolidationFromAPI.AcquireTokenAndStoreInIsolatedStorage(Rec);
                                    if not ImportConsolidationFromAPI.IsStoredTokenValidForBusinessUnit(Rec) then
                                        Error(NotPossibleToGetTokenMsg);
                                end;
                                UpdateCurrentRecAccessGrantedState();
                            end;
                        }
                        field(AccessGranted; AccessGranted)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Access Granted';
                            ToolTip = 'Specifies if access to the Business Central company of this business unit has been granted.';
                            OptionCaption = 'Not Needed,No,Yes';
                            Editable = false;
                            Visible = false;
                        }
                        field("Default Data Import Method"; Rec."Default Data Import Method")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Data Import Method';
                            ToolTip = 'Specifies the default data import method for the business unit.';
                            StyleExpr = StyleTxt;
                        }
                    }
                }
            }
            group(Step2)
            {
                Visible = (Step = 2);
                label(CurrencyDescription)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Review and configure the currency exchange rates used for the business units that require currency translation.';
                }
                group(CurrencyBusinessUnitsGroup)
                {
                    Caption = 'Business Units to consolidate';
                    ShowCaption = false;
                    Editable = true;
                    Enabled = true;
                    repeater(CurrencyBusinessUnits)
                    {
                        Editable = RequiresCurrencyTranslation;
                        field(BUCode; Rec.Code)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Code';
                            ToolTip = 'Specifies the code of the business unit.';
                            Editable = false;
                            TableRelation = "Business Unit";
                        }
                        field(BUName; CompanyName)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Company Name';
                            ToolTip = 'Specifies the name of business unit.';
                            Editable = false;
                        }
                        field(CurrencyCode; Rec."Currency Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Currency Code';
                            Editable = false;
                            ToolTip = 'Specifies the currency code.';
                        }
                        field(CurrencySource; Rec."Currency Exchange Rate Table")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Exchange Rates Source';
                            Tooltip = 'Specifies where are the exchange rates taken from for the Historical accounts';
                        }
                        field(AverageCurrencyFactor; Rec."Income Currency Factor")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Average Currency Factor';
                            ToolTip = 'Specifies the exchange rate to use for balance sheet accounts.';
                            AutoFormatType = 0;
                            DecimalPlaces = 2;
                            trigger OnDrillDown()
                            begin
                                if not Rec.Consolidate then
                                    Error(BusinessUnitNotSelectedForConsolidationErr);
                                UpdateBusinessUnitCurrencyFactors();
                            end;
                        }
                        field(ClosingCurrencyFactor; Rec."Balance Currency Factor")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Closing Currency Factor';
                            ToolTip = 'Specifies the exchange rate to use for income statement accounts.';
                            AutoFormatType = 0;
                            DecimalPlaces = 2;
                            trigger OnDrillDown()
                            begin
                                if not Rec.Consolidate then
                                    Error(BusinessUnitNotSelectedForConsolidationErr);
                                UpdateBusinessUnitCurrencyFactors();
                            end;
                        }
                        field(LastClosingCurrencyFactor; Rec."Last Balance Currency Factor")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Last Closing Currency Factor';
                            ToolTip = 'Specifies the last closing currency factor used in the previous reconciliation. This will be used to adjust the balance entries.';
                            AutoFormatType = 0;
                            DecimalPlaces = 2;
                            trigger OnDrillDown()
                            begin
                                if not Rec.Consolidate then
                                    Error(BusinessUnitNotSelectedForConsolidationErr);
                                UpdateBusinessUnitCurrencyFactors();
                            end;
                        }

                    }
                }
            }
            group(Step3)
            {
                Visible = (Step = 3);
                label(ConfirmFinalize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ready to perform the consolidation. Click "Finish" to start the consolidation process.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Finalize)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Finish';
                Image = Approve;
                Visible = (Step = 3);

                trigger OnAction()
                begin
                    ConsolidateBusinessUnits.ValidateConsolidationParameters(TempConsolidationProcess, Rec, true);
                    if not ConsolidateBusinessUnits.ValidateAndRunConsolidation(TempConsolidationProcess, Rec) then begin
                        CurrPage.Close();
                        Error(GetLastErrorText());
                    end;
                    Message(ConsolidationScheduledMsg);
                    CurrPage.Close();
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Next';
                Image = NextRecord;
                Enabled = NextActionEnabled;
                Visible = (Step <> 3);

                trigger OnAction()
                begin
                    Step += 1;
                    if Step = 2 then begin
                        Rec.SetRange(Consolidate, true);
                        if Rec.IsEmpty() then begin
                            Step -= 1;
                            Rec.Reset();
                            Message(NoBusinessUnitsSelectedErr);
                            SetNextActionEnabled();
                            exit;
                        end;
                        ConsolidateBusinessUnits.ValidateBusinessUnitsToConsolidate(Rec, false);
                        if not BusinessUnitsToConsolidateNeedCurrencyTranslation() then
                            Step += 1;
                    end;
                    SetNextActionEnabled();
                end;
            }
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                InFooterBar = true;
                Caption = 'Back';
                Image = PreviousRecord;
                Enabled = (Step <> 0);

                trigger OnAction()
                begin
                    if Step = 3 then
                        if not BusinessUnitsToConsolidateNeedCurrencyTranslation() then
                            Step -= 1;
                    Step -= 1;
                    if Step = 1 then
                        Rec.SetRange(Consolidate);
                end;
            }
            action(ConfigureCurrency)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Configure currency';
                InFooterBar = true;
                Visible = (Step = 2);
                Image = Currency;

                trigger OnAction()
                begin
                    if not Rec.Consolidate then
                        Error(BusinessUnitNotSelectedForConsolidationErr);
                    UpdateBusinessUnitCurrencyFactors();
                end;
            }
            action(GrantAccess)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Grant Access';
                InFooterBar = true;
                Visible = (Step = 1) and AnyBusinessUnitNeedsAccessGranted;
                Image = Lock;

                trigger OnAction()
                var
                    BusinessUnit: Record "Business Unit";
                    ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
                begin
                    CurrPage.SetSelectionFilter(BusinessUnit);
                    if BusinessUnit.Count() <> 1 then
                        Error(SelectOneBusinessUnitToProvideAccessErr);
                    BusinessUnit.FindFirst();
                    if BusinessUnit."Default Data Import Method" <> BusinessUnit."Default Data Import Method"::API then begin
                        Message(AccessIsAlreadyGrantedMsg);
                        exit;
                    end;
                    ImportConsolidationFromAPI.AcquireTokenAndStoreInIsolatedStorage(BusinessUnit);
                    UpdateCurrentRecAccessGrantedState(true);
                end;
            }
        }
    }
    var
        TempConsolidationProcess: Record "Consolidation Process" temporary;
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
        ConsolidateBusinessUnits: Codeunit "Consolidate Business Units";
        ConsolidationCurrency: Codeunit "Consolidation Currency";
        AccessGrantedStates: Dictionary of [Code[20], Integer];
        LastConsolidationEndingDate: Date;
        CompanyName: Text;
        StyleTxt: Text;
        FullDescriptionTxt: Text;
        Step: Integer;
        AccessGranted: Option NotNeeded,No,Yes;
        AnyBusinessUnitNeedsAccessGranted, JournalTemplateNameMandatory : Boolean;
        NextActionEnabled, RequiresCurrencyTranslation : Boolean;
        BusinessUnitNotSelectedForConsolidationErr: Label 'This business unit has not been selected for consolidation.';
        NoBusinessUnitsToConsolidateErr: Label 'There are no business units configured for consolidation. You can enable the field "Consolidate" in each of the business unit''s setup page.';
        ConsolidationScheduledMsg: Label 'The consolidation has been successful. The current consolidation company has imported the entries from the selected business units.';
        AccessIsAlreadyGrantedMsg: Label 'Access is already granted.';
        DescriptionTxt: Label 'Select the business units to consolidate in the period %1..%2 with the column "Consolidate".', Comment = '%1 - starting date, %2 - ending date';
        DescriptionMissingAuthTxt: Label 'The business units %1 have not been granted access. Select each of them and use the action "Grant Access" to authenticate into these companies.', Comment = '%1 - list of comma separated business units'' codes';
        NoDimensionsInConsolidationCompanyErr: Label 'There are no dimensions configured for the current consolidation company. You can add and configure dimensions in the "Dimensions" page.';
        SelectOneBusinessUnitToProvideAccessErr: Label 'Select only one business unit to provide access to.';
        NotPossibleToGetTokenMsg: Label 'It was not possible to get authorization for this business unit. You can verify the setup in the Business Unit Card page.';
        NoBusinessUnitsSelectedErr: Label 'You have to select at least one business unit to consolidate.';


    trigger OnOpenPage()
    var
        BusinessUnit: Record "Business Unit";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        FeatureTelemetry.LogUptake('0000KOK', ImportConsolidationFromAPI.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        GeneralLedgerSetup.Get();
        Clear(TempConsolidationProcess."Dimensions to Transfer");
        TempConsolidationProcess."Parent Currency Code" := GeneralLedgerSetup."LCY Code";
        JournalTemplateNameMandatory := GeneralLedgerSetup."Journal Templ. Name Mandatory";
        FullDescriptionTxt := StrSubstNo(DescriptionTxt, TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
        BusinessUnit.SetRange(Consolidate, true);
        if not BusinessUnit.FindSet() then
            Error(NoBusinessUnitsToConsolidateErr);
        repeat
            if BusinessUnitConfiguredForAutomaticImport(BusinessUnit) then begin
                Rec.TransferFields(BusinessUnit);
                Rec.Consolidate := GetDefaultConsolidateState(Rec, TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
                AccessGrantedStates.Add(BusinessUnit.Code, AccessGranted::NotNeeded);
                Rec.Insert();
            end;
        until BusinessUnit.Next() = 0;
        SetNextActionEnabled();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateCurrentRecState();
    end;

    local procedure UpdateOtherDateAfterOneIsEdited(DateEdited: Date; var OtherDate: Date)
    begin
        if DateEdited = 0D then
            exit;
        if DateEdited = ClosingDate(DateEdited) then begin
            OtherDate := DateEdited;
            exit;
        end;
        if OtherDate = 0D then
            exit;
        if OtherDate = ClosingDate(OtherDate) then
            OtherDate := 0D;
    end;

    local procedure UpdateBusinessUnitDefaultConsolidateState()
    begin
        Rec.Reset();
        Rec.FindSet();
        repeat
            Rec.Consolidate := GetDefaultConsolidateState(Rec, TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
            Rec.Modify();
        until Rec.Next() = 0;
    end;

    local procedure GetDefaultConsolidateState(BusinessUnit: Record "Business Unit"; StartingDate: Date; EndingDate: Date): Boolean
    var
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
        ShouldConsolidateByDefaultDueToAccess: Boolean;
        ShouldConsolidateByDefaultDueToDatePeriod: Boolean;
    begin
        if BusinessUnit."Default Data Import Method" <> BusinessUnit."Default Data Import Method"::API then
            ShouldConsolidateByDefaultDueToAccess := true
        else
            ShouldConsolidateByDefaultDueToAccess := ImportConsolidationFromAPI.IsStoredTokenValidForBusinessUnit(BusinessUnit);
        ShouldConsolidateByDefaultDueToDatePeriod := BusinessUnitHasNotBeenConsolidatedInPeriod(BusinessUnit, StartingDate, EndingDate);
        exit(ShouldConsolidateByDefaultDueToAccess and ShouldConsolidateByDefaultDueToDatePeriod);
    end;

    local procedure BusinessUnitHasNotBeenConsolidatedInPeriod(BusinessUnit: Record "Business Unit"; FromDate: Date; ToDate: Date): Boolean
    begin
        if (FromDate = 0D) or (ToDate = 0D) then
            exit(true);
        exit(not ConsolidateBusinessUnits.BusinessUnitConsolidationProcessesInDateRange(BusinessUnit, FromDate, ToDate));
    end;

    local procedure BusinessUnitConfiguredForAutomaticImport(BusinessUnit: Record "Business Unit"): Boolean
    begin
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit(BusinessUnit."Company Name" <> '');
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::API then
            exit(BusinessUnit."BC API URL" <> '');
    end;

    local procedure UpdateBusinessUnitCurrencyFactors()
    var
        BusinessUnit: Record "Business Unit";
    begin
        ConsolidationCurrency.ConfigureBusinessUnitCurrencies(Rec, TempConsolidationProcess);
        BusinessUnit.Get(Rec.Code);
        BusinessUnit."Balance Currency Factor" := Rec."Balance Currency Factor";
        BusinessUnit."Last Balance Currency Factor" := Rec."Last Balance Currency Factor";
        BusinessUnit."Income Currency Factor" := Rec."Income Currency Factor";
        BusinessUnit."Currency Exchange Rate Table" := Rec."Currency Exchange Rate Table";
        BusinessUnit.Modify();
    end;

    local procedure BusinessUnitsToConsolidateNeedCurrencyTranslation(): Boolean
    begin
        Rec.SetRange(Consolidate, true);
        if not Rec.FindSet() then
            exit(false);
        repeat
            if BusinessUnitNeedsCurrencyTranslation(Rec) then
                exit(true);
        until Rec.Next() = 0;
        exit(false);
    end;

    local procedure BusinessUnitNeedsCurrencyTranslation(BusinessUnit: Record "Business Unit"): Boolean
    begin
        exit((BusinessUnit."Currency Code" <> '') and (BusinessUnit."Currency Code" <> TempConsolidationProcess."Parent Currency Code"));
    end;

    local procedure UpdateCurrentRecState()
    begin
        if (Step = 1) or (Step = 2) then begin
            if Rec."Default Data Import Method" = Rec."Default Data Import Method"::Database then
                CompanyName := Rec."Company Name";
            if Rec."Default Data Import Method" = Rec."Default Data Import Method"::API then
                CompanyName := Rec."External Company Name";
        end;
        if Step = 1 then begin
            UpdateCurrentRecAccessGrantedState();
            LastConsolidationEndingDate := ConsolidateBusinessUnits.GetLastConsolidationEndingDate(Rec);
        end;
        if Step = 2 then
            RequiresCurrencyTranslation := BusinessUnitNeedsCurrencyTranslation(Rec);
    end;

    local procedure UpdateCurrentRecAccessGrantedState()
    begin
        UpdateCurrentRecAccessGrantedState(false);
    end;

    local procedure UpdateCurrentRecAccessGrantedState(WarnConfig: Boolean)
    begin
        AccessGranted := GetBusinessUnitAccessGranted(Rec, WarnConfig);
        StyleTxt := GetStyleExprForBusinessUnit(Rec, AccessGranted);
        AccessGrantedStates.Set(Rec.Code, AccessGranted);
        UpdateFullDescription();
    end;

    local procedure UpdateFullDescription(): Text
    var
        BusinessUnitCode: Code[20];
        BusinessUnitState: Option;
        CompaniesTxt: Text;
    begin
        FullDescriptionTxt := StrSubstNo(DescriptionTxt, TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date");
        foreach BusinessUnitCode in AccessGrantedStates.Keys() do begin
            BusinessUnitState := AccessGrantedStates.Get(BusinessUnitCode);
            if BusinessUnitState = AccessGranted::No then begin
                if CompaniesTxt <> '' then
                    CompaniesTxt += ', ';
                CompaniesTxt += BusinessUnitCode;
            end;
        end;
        if CompaniesTxt <> '' then
            FullDescriptionTxt += StrSubstNo(DescriptionMissingAuthTxt, CompaniesTxt);
    end;

    local procedure GetStyleExprForBusinessUnit(BusinessUnit: Record "Business Unit"; AccessGrantedStatus: Option): Text
    begin
        if not BusinessUnit.Consolidate then
            exit('None');
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit('Favorable');
        if AccessGrantedStatus = AccessGranted::No then
            exit('Attention');
        exit('Favorable');
    end;

    local procedure GetBusinessUnitAccessGranted(BusinessUnit: Record "Business Unit"; WarnConfig: Boolean): Option
    var
        ImportConsolidationFromAPI: Codeunit "Import Consolidation from API";
    begin
        if BusinessUnit."Default Data Import Method" = BusinessUnit."Default Data Import Method"::Database then
            exit(AccessGranted::NotNeeded);
        AnyBusinessUnitNeedsAccessGranted := true;
        if ImportConsolidationFromAPI.IsStoredTokenValidForBusinessUnit(BusinessUnit) then
            exit(AccessGranted::Yes);
        if WarnConfig then
            Message(NotPossibleToGetTokenMsg);
        exit(AccessGranted::No);
    end;

    local procedure SetNextActionEnabled()
    begin
        NextActionEnabled := ValidateDatesForConsolidation() and ValidateJournalForConsolidation();
    end;

    [TryFunction()]
    local procedure ValidateDatesForConsolidation()
    begin
        ConsolidateBusinessUnits.ValidateDatesForConsolidation(TempConsolidationProcess."Starting Date", TempConsolidationProcess."Ending Date", false);
    end;

    [TryFunction()]
    local procedure ValidateJournalForConsolidation()
    begin
        ConsolidateBusinessUnits.ValidateJournalForConsolidation(JournalTemplateNameMandatory, TempConsolidationProcess."Journal Template Name", TempConsolidationProcess."Journal Batch Name", TempConsolidationProcess."Document No.");
    end;
}
