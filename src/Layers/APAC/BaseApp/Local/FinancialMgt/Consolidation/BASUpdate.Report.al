// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;

report 11604 "BAS-Update"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FinancialMgt/Consolidation/BASUpdate.rdlc';
    Caption = 'BAS-Update';
    Permissions = TableData "G/L Entry" = rm,
                  TableData "VAT Entry" = rm,
                  TableData "BAS Calculation Sheet" = rm,
                  TableData "BAS Calc. Sheet Entry" = rimd;

    dataset
    {
        dataitem("BAS Setup"; "BAS Setup")
        {
            DataItemTableView = where(Print = const(true));
            RequestFilterFields = "Setup Name";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(Heading; Heading)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(Heading2; Heading2)
            {
            }
            column(SelectionTypeNo; SelectionTypeNo)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(BASSetupFilter; BASSetupFilter)
            {
            }
            column(FirstPage; FirstPage)
            {
            }
            column(HeaderText; HeaderText)
            {
            }
            column(BAS_Setup__TABLECAPTION__________BASSetupFilter; TableCaption + ': ' + BASSetupFilter)
            {
            }
            column(BAS_Setup__Row_No__; "Row No.")
            {
            }
            column(BAS_Setup__Field_Description_; "Field Description")
            {
            }
            column(TotalAmount; TotalAmount)
            {
                AutoFormatType = 1;
            }
            column(BAS_Setup__Field_Label_No__; "Field Label No.")
            {
            }
            column(BAS_Setup_Setup_Name; "Setup Name")
            {
            }
            column(BAS_Setup_Line_No_; "Line No.")
            {
            }
            column(BAS_Calculation_Sheet___UpdateCaption; BAS_Calculation_Sheet___UpdateCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Amounts_are_in_whole_LCYs_Caption; Amounts_are_in_whole_LCYs_CaptionLbl)
            {
            }
            column(The_report_includes_all_GST_entries_Caption; The_report_includes_all_GST_entries_CaptionLbl)
            {
            }
            column(The_report_includes_only_closed_GST_entries_Caption; The_report_includes_only_closed_GST_entries_CaptionLbl)
            {
            }
            column(BAS_Setup__Row_No__Caption; FieldCaption("Row No."))
            {
            }
            column(BAS_Setup__Field_Description_Caption; FieldCaption("Field Description"))
            {
            }
            column(TotalAmountCaption; TotalAmountCaptionLbl)
            {
            }
            column(BAS_Setup__Field_Label_No__Caption; FieldCaption("Field Label No."))
            {
            }

            trigger OnAfterGetRecord()
            begin
                CalcLineTotal("BAS Setup", TotalAmount, 0);
                TotalAmount := Round(TotalAmount, 1, '<');
                if "Print with" = "Print with"::"Opposite Sign" then
                    TotalAmount := -TotalAmount;

                if UpdateBASCalcSheet then begin
                    ProgressCurrent += 1;
                    Window.Update(1, "Field Label No.");
                    Window.Update(2, Round(ProgressCurrent / ProgressTotal * 10000, 1));
                    case "Field No." of
                        BASCalcSheet.FieldNo("1A"):
                            BASCalcSheet."1A" := TotalAmount;
                        BASCalcSheet.FieldNo("1C"):
                            BASCalcSheet."1C" := TotalAmount;
                        BASCalcSheet.FieldNo("1E"):
                            BASCalcSheet."1E" := TotalAmount;
                        BASCalcSheet.FieldNo("4"):
                            BASCalcSheet."4" := TotalAmount;
                        BASCalcSheet.FieldNo("1B"):
                            BASCalcSheet."1B" := TotalAmount;
                        BASCalcSheet.FieldNo("1D"):
                            BASCalcSheet."1D" := TotalAmount;
                        BASCalcSheet.FieldNo("1F"):
                            BASCalcSheet."1F" := TotalAmount;
                        BASCalcSheet.FieldNo("1G"):
                            BASCalcSheet."1G" := TotalAmount;
                        BASCalcSheet.FieldNo("5B"):
                            BASCalcSheet."5B" := TotalAmount;
                        BASCalcSheet.FieldNo("6B"):
                            BASCalcSheet."6B" := TotalAmount;
                        BASCalcSheet.FieldNo(G1):
                            BASCalcSheet.G1 := TotalAmount;
                        BASCalcSheet.FieldNo(G2):
                            BASCalcSheet.G2 := TotalAmount;
                        BASCalcSheet.FieldNo(G3):
                            BASCalcSheet.G3 := TotalAmount;
                        BASCalcSheet.FieldNo(G4):
                            BASCalcSheet.G4 := TotalAmount;
                        BASCalcSheet.FieldNo(G7):
                            BASCalcSheet.G7 := TotalAmount;
                        BASCalcSheet.FieldNo(W1):
                            BASCalcSheet.W1 := TotalAmount;
                        BASCalcSheet.FieldNo(W2):
                            BASCalcSheet.W2 := TotalAmount;
                        BASCalcSheet.FieldNo(T1):
                            BASCalcSheet.T1 := TotalAmount;
                        BASCalcSheet.FieldNo(G10):
                            BASCalcSheet.G10 := TotalAmount;
                        BASCalcSheet.FieldNo(G11):
                            BASCalcSheet.G11 := TotalAmount;
                        BASCalcSheet.FieldNo(G13):
                            BASCalcSheet.G13 := TotalAmount;
                        BASCalcSheet.FieldNo(G14):
                            BASCalcSheet.G14 := TotalAmount;
                        BASCalcSheet.FieldNo(G15):
                            BASCalcSheet.G15 := TotalAmount;
                        BASCalcSheet.FieldNo(G18):
                            BASCalcSheet.G18 := TotalAmount;
                        BASCalcSheet.FieldNo(W3):
                            BASCalcSheet.W3 := TotalAmount;
                        BASCalcSheet.FieldNo(W4):
                            BASCalcSheet.W4 := TotalAmount;
                        BASCalcSheet.FieldNo("7C"):
                            BASCalcSheet."7C" := TotalAmount;
                        BASCalcSheet.FieldNo("7D"):
                            BASCalcSheet."7D" := TotalAmount;
                    end;
                end;

                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;
            end;

            trigger OnPostDataItem()
            begin
                if UpdateBASCalcSheet then begin
                    BASCalcSheet."BAS GST Division Factor" := GLSetup."BAS GST Division Factor";
                    BASCalcSheet."BAS Setup Name" := GetFilter("Setup Name");
                    BASCalcSheet.Updated := true;
                    BASCalcSheet.Modify();
                    Window.Close();
                end;
            end;

            trigger OnPreDataItem()
            var
                GLEntry: Record "G/L Entry";
                VATEntry: Record "VAT Entry";
            begin
                if GetFilter("Setup Name") = '' then
                    if SetupName = '' then
                        Error(Text1450003, FieldCaption("Setup Name"))
                    else
                        SetRange("Setup Name", SetupName);

                SetRange("Setup Name", GetRangeMin("Setup Name"));
                GLSetup.Get();
                if UpdateBASCalcSheet then begin
                    BASCalcSheet.TestField(A1);
                    BASCalcSheet.TestField("BAS Version");
                    if BASCalcSheet.Exported then
                        Error(Text1450007, BASCalcSheet.TableCaption());

                    BASCalcSheet2.SetRange(A1, BASCalcSheet.A1);
                    BASCalcSheet2.SetRange(Exported, true);
                    if BASCalcSheet2.FindFirst() then
                        if not Confirm(
                             Text1450015 + '\' + Text1450016 + '\' + Text1450017,
                             false, BASCalcSheet2."BAS Version", BASCalcSheet2.A1, BASCalcSheet."BAS Version")
                        then
                            Error('');

                    if BASCalcSheet.Consolidated then begin
                        if not Confirm(Text1450008 + Text1450009, false, BASCalcSheet.A1) then
                            CurrReport.Quit();
                        if not GLSetup."BAS Group Company" then
                            Error(Text1450010);
                        if GLSetup."BAS Group Company" then
                            BASCalcSheet.TestField("Group Consolidated", true);
                        BASCalcEntry.Reset();
                        BASCalcEntry.SetCurrentKey("Consol. BAS Doc. No.", "Consol. Version No.");
                        BASCalcEntry.SetRange("Consol. BAS Doc. No.", BASCalcSheet.A1);
                        BASCalcEntry.SetRange("Consol. Version No.", BASCalcSheet."BAS Version");
                        if BASCalcEntry.FindFirst() then
                            repeat
                                BASCalcEntry."Consol. BAS Doc. No." := '';
                                BASCalcEntry."Consol. Version No." := 0;
                                BASCalcEntry.Modify();
                            until not BASCalcEntry.FindFirst();

                        if BASBusUnits.Find('-') then
                            repeat
                                BASCalcSheet1.ChangeCompany(BASBusUnits."Company Name");
                                BASCalcSheet1.Get(BASBusUnits."Document No.", BASBusUnits."BAS Version");
                                BASCalcSheet1.Consolidated := false;
                                BASCalcSheet1.Modify();
                            until BASBusUnits.Next() = 0;
                        BASCalcSheet.Consolidated := false;
                        BASCalcSheet."Group Consolidated" := false;
                    end;

                    if BASCalcSheet.Updated then
                        if not Confirm(Text1450011 + Text1450012, false) then
                            CurrReport.Quit();

                    BASCalcEntry.Reset();
                    BASCalcEntry.SetRange("Company Name", CompanyName);
                    BASCalcEntry.SetRange("BAS Document No.", BASCalcSheet.A1);
                    BASCalcEntry.SetRange("BAS Version", BASCalcSheet."BAS Version");
                    if BASCalcEntry.FindFirst() then
                        BASCalcEntry.DeleteAll();

                    GLEntry.SetCurrentKey("BAS Doc. No.", "BAS Version");
                    GLEntry.SetRange("BAS Doc. No.", BASCalcSheet.A1);
                    if GLEntry.FindFirst() then begin
                        GLEntry.ModifyAll("BAS Doc. No.", '');
                        GLEntry.ModifyAll("BAS Version", 0);
                    end;
                    GLEntry.Reset();

                    VATEntry.SetCurrentKey("BAS Doc. No.", "BAS Version");
                    VATEntry.SetRange("BAS Doc. No.", BASCalcSheet.A1);
                    if VATEntry.FindFirst() then begin
                        VATEntry.ModifyAll("BAS Doc. No.", '');
                        VATEntry.ModifyAll("BAS Version", 0);
                    end;
                    VATEntry.Reset();

                    BASCalcSheet."1A" := 0;
                    BASCalcSheet."1C" := 0;
                    BASCalcSheet."1E" := 0;
                    BASCalcSheet."4" := 0;
                    BASCalcSheet."1B" := 0;
                    BASCalcSheet."1D" := 0;
                    BASCalcSheet."1F" := 0;
                    BASCalcSheet."1G" := 0;
                    BASCalcSheet."5B" := 0;
                    BASCalcSheet."6B" := 0;
                    BASCalcSheet.G1 := 0;
                    BASCalcSheet.G2 := 0;
                    BASCalcSheet.G3 := 0;
                    BASCalcSheet.G4 := 0;
                    BASCalcSheet.G7 := 0;
                    BASCalcSheet.W1 := 0;
                    BASCalcSheet.W2 := 0;
                    BASCalcSheet.T1 := 0;
                    BASCalcSheet.G10 := 0;
                    BASCalcSheet.G11 := 0;
                    BASCalcSheet.G13 := 0;
                    BASCalcSheet.G14 := 0;
                    BASCalcSheet.G15 := 0;
                    BASCalcSheet.G18 := 0;
                    BASCalcSheet.W3 := 0;
                    BASCalcSheet.W4 := 0;

                    Window.Open(Text1450013 + Text1450014);
                    ProgressTotal := Count;
                    ProgressCurrent := 0;
                end;

                GLSetup.TestField("LCY Code");
                HeaderText := StrSubstNo(Text1450002, GLSetup."LCY Code");
                SelectionTypeNo := Selection.AsInteger();
                PageGroupNo := 1;
                NextPageGroupNo := 1;
                FirstPage := true;
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
                    field("BASCalcSheet.A1"; BASCalcSheet.A1)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(BASCalcSheet.FieldName(A1));
                        Caption = 'Document No.';
                        Editable = false;
                        ToolTip = 'Specifies the original document that is associated with this entry.';
                    }
                    field("BASCalcSheet.""BAS Version"""; BASCalcSheet."BAS Version")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BAS Version';
                        Editable = false;
                        ToolTip = 'Specifies the Business Activity Statement (BAS) version number that you want to use.';
                    }
                    field("BASCalcSheet.A3"; BASCalcSheet.A3)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(BASCalcSheet.FieldName(A3));
                        Caption = 'Period Covered From';
                        Editable = false;
                        ToolTip = 'Specifies the start date of the BAS update.';
                    }
                    field("BASCalcSheet.A4"; BASCalcSheet.A4)
                    {
                        ApplicationArea = Basic, Suite;
                        CaptionClass = Format(BASCalcSheet.FieldName(A4));
                        Caption = 'Period Covered To';
                        Editable = false;
                        ToolTip = 'Specifies the last date of the BAS update.';
                    }
                    field(UpdateBASCalcSheet; UpdateBASCalcSheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Update BAS Calc. Sheet';
                        ToolTip = 'Specifies that this is an update of an existing business activity statement.';
                    }
                    field(IncludeGSTEntries; Selection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include GST Entries';
                        ToolTip = 'Specifies that you want to include GST entries in the BAS.';
                    }
                    field(PeriodSelection; PeriodSelection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Include GST Entries';
                        ToolTip = 'Specifies that you want to include GST entries in the BAS.';
                    }
                    field(ExcludeClosingEntries; ExcludeClosingEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Exclude Closing Entries';
                        Enabled = ExcludeClosingEntriesEnable;
                        ToolTip = 'Specifies that you want to exclude closing entries from the report.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            ExcludeClosingEntriesEnable := true;
        end;

        trigger OnOpenPage()
        begin
            UpdateRequestForm();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("Enable GST (Australia)", true);
    end;

    trigger OnPreReport()
    var
        BASSetup: Record "BAS Setup";
        BASSetupName: Code[20];
    begin
        "BAS Setup".SetRange("Date Filter", BASCalcSheet.A3, BASCalcSheet.A4);
        if PeriodSelection = PeriodSelection::"Before and Within Period" then
            Heading := Text1450000
        else
            Heading := Text1450004;
        Heading2 := StrSubstNo(Text1450005, BASCalcSheet.A3, BASCalcSheet.A4);
        BASSetupFilter := "BAS Setup".GetFilters();
        BASSetupName := "BAS Setup".GetFilter("Setup Name");
        BASSetup.Reset();
        BASSetup.SetRange("Setup Name", BASSetupName);
        BASSetup.SetFilter(Type, '%1', BASSetup.Type::"Row Totaling");
        BASSetup.SetRange(Print, false);
        if BASSetup.FindFirst() then
            Error(Text1450018, BASSetup."Row No.");
    end;

    var
        Text1450000: Label 'GST entries before and within the period';
        Text1450002: Label 'All amounts are in %1';
        Text1450003: Label 'Please specify filter for %1.';
        Text1450004: Label 'GST entries within the period';
        Text1450005: Label 'Period: %1..%2';
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASCalcSheet1: Record "BAS Calculation Sheet";
        BASCalcSheet2: Record "BAS Calculation Sheet";
        BASCalcEntry: Record "BAS Calc. Sheet Entry";
        BASBusUnits: Record "BAS Business Unit";
        GLSetup: Record "General Ledger Setup";
        Selection: Enum "VAT Statement Report Selection";
        RowNo: array[6] of Code[10];
        SetupName: Code[20];
        BASSetupFilter: Text[250];
        Heading: Text[50];
        ErrorText: Text[80];
        HeaderText: Text[50];
        Heading2: Text[50];
        FieldLabelNo: array[6] of Text[30];
        Amount: Decimal;
        TotalAmount: Decimal;
        ProgressCurrent: Integer;
        ProgressTotal: Integer;
        i: Integer;
        UpdateBASCalcSheet: Boolean;
        ExcludeClosingEntries: Boolean;
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        Text1450007: Label 'This %1 has been exported. It cannot be updated.';
        Text1450008: Label '%1 has been consolidated. You will have to run the consolidate function again.\';
        Text1450009: Label 'Do you want to continue?';
        Text1450010: Label 'You cannot run this function because this BAS has been consolidated from the group company.';
        Text1450011: Label 'The update has already been completed.\';
        Text1450012: Label 'Do you want to overwrite current BAS version?';
        Text1450013: Label 'Current Field     #1##########\';
        Text1450014: Label 'Progress          @2@@@@@@@@@@@@@@@@@@@@';
        Window: Dialog;
        Text1450015: Label 'Version %1 of BAS Document %2 has already been exported.';
        Text1450016: Label 'If you continue with the update of version %3, you must re export BAS Document %2 to close the entries for this period.';
        Text1450017: Label 'Do you want to continue ?';
        BASCalcEntry1: Record "BAS Calc. Sheet Entry";
        Text1450018: Label 'You have not selected the print option for Row No %1, this is mandatory for updating values on BAS calculation sheet.';
        SelectionTypeNo: Integer;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        FirstPage: Boolean;
        ExcludeClosingEntriesEnable: Boolean;
        BAS_Calculation_Sheet___UpdateCaptionLbl: Label 'BAS Calculation Sheet - Update';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Amounts_are_in_whole_LCYs_CaptionLbl: Label 'Amounts are in whole LCYs.';
        The_report_includes_all_GST_entries_CaptionLbl: Label 'The report includes all GST entries.';
        The_report_includes_only_closed_GST_entries_CaptionLbl: Label 'The report includes only closed GST entries.';
        TotalAmountCaptionLbl: Label 'Amount';

    [Scope('OnPrem')]
    procedure CalcLineTotal(BASSetup2: Record "BAS Setup"; var TotalAmount: Decimal; Level: Integer): Boolean
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        BASSetup2.CalcFields("Field Label No.");
        if Level = 0 then begin
            TotalAmount := 0;
            Clear(RowNo);
            Clear(FieldLabelNo);
        end;
        case BASSetup2.Type of
            BASSetup2.Type::"Account Totaling":
                begin
                    GLEntry.Reset();
                    GLEntry.SetCurrentKey(
                      "G/L Account No.",
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date",
                      "BAS Doc. No.");
                    GLEntry.SetFilter("G/L Account No.", BASSetup2."Account Totaling");
                    GLEntry.SetRange("BAS Adjustment", BASSetup2."BAS Adjustment");
                    GLEntry.SetRange("VAT Bus. Posting Group", BASSetup2."GST Bus. Posting Group");
                    GLEntry.SetRange("VAT Prod. Posting Group", BASSetup2."GST Prod. Posting Group");
                    GLEntry.SetFilter(
                      "Posting Date",
                      GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    if BASCalcSheet.Exported then
                        GLEntry.SetRange("BAS Doc. No.", BASCalcSheet.A1)
                    else
                        GLEntry.SetRange("BAS Doc. No.", '');
                    Amount := 0;
                    if BASSetup2."Account Totaling" <> '' then
                        if GLEntry.Find('-') then
                            repeat
                                if
                                   (ExcludeClosingEntries and
                                    (GLEntry."Posting Date" = NormalDate(GLEntry."Posting Date"))) or
                                   (not ExcludeClosingEntries)
                                then begin
                                    case BASSetup2."Amount Type" of
                                        BASSetup2."Amount Type"::Amount:
                                            Amount := Amount + GLEntry.Amount;
                                        BASSetup2."Amount Type"::"GST Amount":
                                            Amount := Amount + GLEntry."VAT Amount";
                                    end;
                                    if UpdateBASCalcSheet then begin
                                        BASCalcEntry.Init();
                                        BASCalcEntry."Company Name" := CompanyName;
                                        BASCalcEntry."BAS Document No." := BASCalcSheet.A1;
                                        BASCalcEntry."BAS Version" := BASCalcSheet."BAS Version";
                                        if Level = 0 then
                                            BASCalcEntry."Field Label No." := BASSetup2."Field Label No."
                                        else
                                            BASCalcEntry."Field Label No." := FieldLabelNo[Level];
                                        BASCalcEntry.Type := BASCalcEntry.Type::"G/L Entry";
                                        BASCalcEntry."Entry No." := GLEntry."Entry No.";
                                        BASCalcEntry."Amount Type" := BASSetup2."Amount Type";
                                        case BASSetup2."Amount Type" of
                                            BASSetup2."Amount Type"::Amount:
                                                BASCalcEntry.Amount := GLEntry.Amount;
                                            BASSetup2."Amount Type"::"GST Amount":
                                                BASCalcEntry.Amount := GLEntry."VAT Amount";
                                        end;
                                        BASCalcEntry."Gen. Posting Type" := BASSetup2."Gen. Posting Type";
                                        BASCalcEntry."GST Bus. Posting Group" := BASSetup2."GST Bus. Posting Group";
                                        BASCalcEntry."GST Prod. Posting Group" := BASSetup2."GST Prod. Posting Group";
                                        BASCalcEntry."BAS Adjustment" := BASSetup2."BAS Adjustment";
                                        if not BASCalcEntry.Insert() then
                                            BASCalcEntry.Modify();
                                    end;
                                end;
                            until GLEntry.Next() = 0;
                    CalcTotalAmount(BASSetup2, TotalAmount);
                end;
            BASSetup2.Type::"GST Entry Totaling":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey(
                      Type,
                      Closed,
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date",
                      "BAS Doc. No.");
                    VATEntry.SetRange(Type, BASSetup2."Gen. Posting Type");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                    end;
                    VATEntry.SetRange("BAS Adjustment", BASSetup2."BAS Adjustment");
                    VATEntry.SetRange("VAT Bus. Posting Group", BASSetup2."GST Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", BASSetup2."GST Prod. Posting Group");
                    VATEntry.SetFilter(
                      "Posting Date",
                      GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    if BASCalcSheet.Exported then
                        VATEntry.SetRange("BAS Doc. No.", BASCalcSheet.A1)
                    else
                        VATEntry.SetRange("BAS Doc. No.", '');
                    case BASSetup2."Amount Type" of
                        BASSetup2."Amount Type"::Amount:
                            begin
                                VATEntry.CalcSums(Amount);
                                Amount := VATEntry.Amount;
                            end;
                        BASSetup2."Amount Type"::Base:
                            begin
                                VATEntry.CalcSums(Base);
                                Amount := VATEntry.Base;
                            end;
                        BASSetup2."Amount Type"::"Unrealized Amount":
                            begin
                                VATEntry.CalcSums("Unrealized Amount");
                                Amount := VATEntry."Unrealized Amount";
                            end;
                        BASSetup2."Amount Type"::"Unrealized Base":
                            begin
                                VATEntry.CalcSums("Unrealized Base");
                                Amount := VATEntry."Unrealized Base";
                            end;
                    end;
                    if UpdateBASCalcSheet and VATEntry.Find('-') then
                        repeat
                            BASCalcEntry.Init();
                            BASCalcEntry."Company Name" := CompanyName;
                            BASCalcEntry."BAS Document No." := BASCalcSheet.A1;
                            BASCalcEntry."BAS Version" := BASCalcSheet."BAS Version";
                            if Level = 0 then
                                BASCalcEntry."Field Label No." := BASSetup2."Field Label No."
                            else
                                BASCalcEntry."Field Label No." := FieldLabelNo[Level];
                            BASCalcEntry.Type := BASCalcEntry.Type::"GST Entry";
                            BASCalcEntry."Entry No." := VATEntry."Entry No.";
                            BASCalcEntry."Amount Type" := BASSetup2."Amount Type";
                            case BASSetup2."Amount Type" of
                                BASSetup2."Amount Type"::Amount:
                                    BASCalcEntry.Amount := VATEntry.Amount;
                                BASSetup2."Amount Type"::Base:
                                    BASCalcEntry.Amount := VATEntry.Base;
                                BASSetup2."Amount Type"::"Unrealized Amount":
                                    BASCalcEntry.Amount := VATEntry."Unrealized Amount";
                                BASSetup2."Amount Type"::"Unrealized Base":
                                    BASCalcEntry.Amount := VATEntry."Unrealized Base";
                            end;
                            BASCalcEntry."Gen. Posting Type" := BASSetup2."Gen. Posting Type";
                            BASCalcEntry."GST Bus. Posting Group" := BASSetup2."GST Bus. Posting Group";
                            BASCalcEntry."GST Prod. Posting Group" := BASSetup2."GST Prod. Posting Group";
                            BASCalcEntry."BAS Adjustment" := BASSetup2."BAS Adjustment";
                            if not BASCalcEntry.Insert() then
                                BASCalcEntry.Modify();
                        until VATEntry.Next() = 0;

                    CalcTotalAmount(BASSetup2, TotalAmount);
                end;
            BASSetup2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := BASSetup2."Row No.";
                    FieldLabelNo[Level] := BASSetup2."Field Label No.";

                    if BASSetup2."Row Totaling" = '' then
                        exit(true);
                    BASSetup2.SetRange("Setup Name", BASSetup2."Setup Name");
                    BASSetup2.SetFilter("Row No.", BASSetup2."Row Totaling");
                    if BASSetup2.Find('-') then
                        repeat
                            if not CalcLineTotal(BASSetup2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                BASSetup2.FieldError("Row No.", ErrorText);
                            end;
                        until BASSetup2.Next() = 0;
                end;
        end;

        exit(true);
    end;

    local procedure CalcTotalAmount(BASSetup2: Record "BAS Setup"; var TotalAmount: Decimal)
    begin
        if BASSetup2."Calculate with" = 1 then
            Amount := -Amount;
        TotalAmount := TotalAmount + Amount;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(var NewBASCalcSheet: Record "BAS Calculation Sheet"; NewUpdateBASCalcSheet: Boolean; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewExcludeClosingEntries: Boolean)
    begin
        BASCalcSheet.Copy(NewBASCalcSheet);
        "BAS Setup".SetRange("Setup Name", BASCalcSheet."BAS Setup Name");
        UpdateBASCalcSheet := NewUpdateBASCalcSheet;
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        ExcludeClosingEntries := NewExcludeClosingEntries;
    end;

    [Scope('OnPrem')]
    procedure InitializeSetupName(NewSetupName: Code[20])
    begin
        SetupName := NewSetupName
    end;

    local procedure UpdateRequestForm()
    begin
        PageUpdateRequestForm();
    end;

    [Scope('OnPrem')]
    procedure GetPeriodFilter(PeriodSelection2: Enum "VAT Statement Report Period Selection"; A32: Date; A42: Date): Text[250]
    begin
        if PeriodSelection2 = PeriodSelection2::"Before and Within Period" then
            exit(StrSubstNo('%1..%2', 20000701D, A42));

        exit(StrSubstNo('%1..%2', A32, A42));
    end;

    [Scope('OnPrem')]
    procedure CalcExportLineTotal(BASSetup2: Record "BAS Setup"; var TotalAmount: Decimal; Level: Integer; DocumentNo: Code[11]; VersionNo: Integer): Boolean
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        /* first thing...
        BASSetup2.CALCFIELDS("Field Label No.");
        IF Level = 0 THEN BEGIN
          TotalAmount := 0;
          Amount := 0;
          CLEAR(RowNo);
          CLEAR(FieldLabelNo);
        END;
        BASCalcSheetEntry.Reset();
        BASCalcSheetEntry.SETCURRENTKEY(
          "Company Name",
          "BAS Document No.",
          "BAS Version",
          "Field Label No.",
          "GST Bus. Posting Group",
          "GST Prod. Posting Group",
          "BAS Adjustment");
        BASCalcSheetEntry.SETRANGE("Company Name",COMPANYNAME);
        BASCalcSheetEntry.SETRANGE("BAS Document No.",DocumentNo);
        BASCalcSheetEntry.SETRANGE("BAS Version",VersionNo);
        BASCalcSheetEntry.SETRANGE("Field Label No.",BASSetup2."Field Label No.");
        BASCalcSheetEntry.SETRANGE("GST Bus. Posting Group",BASSetup2."GST Bus. Posting Group");
        BASCalcSheetEntry.SETRANGE("GST Prod. Posting Group",BASSetup2."GST Prod. Posting Group");
        BASCalcSheetEntry.SETRANGE("BAS Adjustment",BASSetup2."BAS Adjustment");
        IF BASCalcSheetEntry.FIND('-') THEN
          REPEAT
            CASE BASSetup2."Amount Type" OF
              BASSetup2."Amount Type"::Amount:
                Amount := Amount + BASCalcSheetEntry.Amount;
              BASSetup2."Amount Type"::"GST Amount":
                Amount := Amount + BASCalcSheetEntry.Amount;
            END;
          UNTIL BASCalcSheetEntry.Next() = 0;
        CalcTotalAmount(BASSetup2,TotalAmount);
        EXIT(TRUE);
        */
        BASSetup2.CalcFields("Field Label No.");
        if Level = 0 then begin
            TotalAmount := 0;
            Amount := 0;
            Clear(RowNo);
            Clear(FieldLabelNo);
        end;
        case BASSetup2.Type of
            BASSetup2.Type::"Account Totaling":
                begin
                    GLEntry.Reset();
                    GLEntry.SetCurrentKey(
                      "G/L Account No.",
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date",
                      "BAS Doc. No.");
                    GLEntry.SetFilter("G/L Account No.", BASSetup2."Account Totaling");
                    GLEntry.SetRange("BAS Adjustment", BASSetup2."BAS Adjustment");
                    GLEntry.SetRange("VAT Bus. Posting Group", BASSetup2."GST Bus. Posting Group");
                    GLEntry.SetRange("VAT Prod. Posting Group", BASSetup2."GST Prod. Posting Group");
                    GLEntry.SetFilter(
                      "Posting Date",
                      GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    GLEntry.SetRange("BAS Doc. No.", DocumentNo);
                    if BASSetup2."Account Totaling" <> '' then
                        if GLEntry.Find('-') then
                            repeat
                                if
                                   (ExcludeClosingEntries and
                                    (GLEntry."Posting Date" = NormalDate(GLEntry."Posting Date"))) or
                                   (not ExcludeClosingEntries)
                                then begin
                                    BASCalcEntry1.Reset();
                                    BASCalcEntry1.SetCurrentKey("Company Name", Type, "Entry No.", "BAS Document No.", "BAS Version");
                                    BASCalcEntry1.SetRange("Company Name", CompanyName);
                                    BASCalcEntry1.SetRange(Type, BASCalcEntry1.Type::"G/L Entry");
                                    BASCalcEntry1.SetRange("Entry No.", GLEntry."Entry No.");
                                    BASCalcEntry1.SetRange("BAS Document No.", DocumentNo);
                                    BASCalcEntry1.SetRange("BAS Version", VersionNo);
                                    if BASCalcEntry1.FindFirst() then
                                        case BASSetup2."Amount Type" of
                                            BASSetup2."Amount Type"::Amount:
                                                Amount := Amount + GLEntry.Amount;
                                            BASSetup2."Amount Type"::"GST Amount":
                                                Amount := Amount + GLEntry."VAT Amount";
                                        end;
                                end;
                            until GLEntry.Next() = 0;
                    CalcTotalAmount(BASSetup2, TotalAmount);
                end;
            BASSetup2.Type::"GST Entry Totaling":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey(
                      Type,
                      Closed,
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date",
                      "BAS Doc. No.");
                    VATEntry.SetRange(Type, BASSetup2."Gen. Posting Type");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                    end;
                    VATEntry.SetRange("BAS Adjustment", BASSetup2."BAS Adjustment");
                    VATEntry.SetRange("VAT Bus. Posting Group", BASSetup2."GST Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", BASSetup2."GST Prod. Posting Group");
                    VATEntry.SetFilter(
                      "Posting Date",
                      GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    VATEntry.SetRange("BAS Doc. No.", DocumentNo);
                    if VATEntry.Find('-') then
                        repeat
                            BASCalcEntry1.Reset();
                            BASCalcEntry1.SetCurrentKey("Company Name", Type, "Entry No.", "BAS Document No.", "BAS Version");
                            BASCalcEntry1.SetRange("Company Name", CompanyName);
                            BASCalcEntry1.SetRange(Type, BASCalcEntry1.Type::"GST Entry");
                            BASCalcEntry1.SetRange("Entry No.", VATEntry."Entry No.");
                            BASCalcEntry1.SetRange("BAS Document No.", DocumentNo);
                            BASCalcEntry1.SetRange("BAS Version", VersionNo);
                            if BASCalcEntry1.FindFirst() then
                                case BASSetup2."Amount Type" of
                                    BASSetup2."Amount Type"::Amount:
                                        Amount := Amount + VATEntry.Amount;
                                    BASSetup2."Amount Type"::Base:
                                        Amount := Amount + VATEntry.Base;
                                    BASSetup2."Amount Type"::"Unrealized Amount":
                                        Amount := Amount + VATEntry."Unrealized Amount";
                                    BASSetup2."Amount Type"::"Unrealized Base":
                                        Amount := Amount + VATEntry."Unrealized Base";
                                end;

                        until VATEntry.Next() = 0;
                    CalcTotalAmount(BASSetup2, TotalAmount);
                end;
            BASSetup2.Type::"Row Totaling":
                begin
                    if Level >= ArrayLen(RowNo) then
                        exit(false);
                    Level := Level + 1;
                    RowNo[Level] := BASSetup2."Row No.";
                    FieldLabelNo[Level] := BASSetup2."Field Label No.";

                    if BASSetup2."Row Totaling" = '' then
                        exit(true);
                    BASSetup2.SetRange("Setup Name", BASSetup2."Setup Name");
                    BASSetup2.SetFilter("Row No.", BASSetup2."Row Totaling");
                    if BASSetup2.Find('-') then
                        repeat
                            if not CalcLineTotal(BASSetup2, TotalAmount, Level) then begin
                                if Level > 1 then
                                    exit(false);
                                for i := 1 to ArrayLen(RowNo) do
                                    ErrorText := ErrorText + RowNo[i] + ' => ';
                                ErrorText := ErrorText + '...';
                                BASSetup2.FieldError("Row No.", ErrorText);
                            end;
                        until BASSetup2.Next() = 0;
                end;
        end;

        exit(true);

    end;

    local procedure PageUpdateRequestForm()
    begin
        ExcludeClosingEntriesEnable := PeriodSelection = PeriodSelection::"Before and Within Period";
        if ExcludeClosingEntriesEnable = false then
            ExcludeClosingEntries := false;
    end;
}

