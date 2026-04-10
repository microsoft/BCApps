#pragma warning disable AA0247
report 12466 "FA Turnover"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/FATurnover.rdlc';
    ApplicationArea = FixedAssets;
    Caption = 'FA Turnover';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(FA; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Period; Period)
            {
            }
            column(RequestFilter; RequestFilter)
            {
            }
            column(CurrentDate; CurrentDate)
            {
            }
            column(USERID; UserId)
            {
            }
            column(GETFILTERS; GetFilters)
            {
            }
            column(NotShowZero; NotShowZero)
            {
            }
            column(FA_Depreciation_Book__Depreciation; "FA Depreciation Book".Depreciation)
            {
            }
            column(FA_Depreciation_Book___Acquisition_Cost_; "FA Depreciation Book"."Acquisition Cost")
            {
            }
            column(FA_Depreciation_Book___Book_Value_; "FA Depreciation Book"."Book Value")
            {
            }
            column(FA_Depreciation_Book__Quantity; "FA Depreciation Book".Quantity)
            {
            }
            column(Fixed_AssetsCaption; Fixed_AssetsCaptionLbl)
            {
            }
            column(FA_SheetCaption; FA_SheetCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(No_Caption; No_CaptionLbl)
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(Acquisition_DateCaption; Acquisition_DateCaptionLbl)
            {
            }
            column(Acquisition_Document_No_Caption; Acquisition_Document_No_CaptionLbl)
            {
            }
            column(FA_Depreciation_Book__Depreciation_Starting_Date_Caption; "FA Depreciation Book".FieldCaption("Depreciation Starting Date"))
            {
            }
            column(Depreciation_PeriodCaption; Depreciation_PeriodCaptionLbl)
            {
            }
            column(FA_Depreciation_Book_DepreciationCaption; "FA Depreciation Book".FieldCaption(Depreciation))
            {
            }
            column(FA_Depreciation_Book__Acquisition_Cost_Caption; "FA Depreciation Book".FieldCaption("Acquisition Cost"))
            {
            }
            column(FA_Depreciation_Book__Book_Value_Caption; "FA Depreciation Book".FieldCaption("Book Value"))
            {
            }
            column(FA_Depreciation_Book__Depreciation_Ending_Date_Caption; "FA Depreciation Book".FieldCaption("Depreciation Ending Date"))
            {
            }
            column(FA_Depreciation_Book__Disposal_Date_Caption; "FA Depreciation Book".FieldCaption("Disposal Date"))
            {
            }
            column(FA_Depreciation_Book_QuantityCaption; "FA Depreciation Book".FieldCaption(Quantity))
            {
            }
            column(FA_StatusCaption; FA_StatusCaptionLbl)
            {
            }
            column(NumberCaption; NumberCaptionLbl)
            {
            }
            column(FA_Depreciation_Book__No__of_Depreciation_Years_Caption; "FA Depreciation Book".FieldCaption("No. of Depreciation Years"))
            {
            }
            column(FA_Depreciation_Book__No__of_Depreciation_Months_Caption; "FA Depreciation Book".FieldCaption("No. of Depreciation Months"))
            {
            }
            column(No_Caption_Control1210025; No_Caption_Control1210025Lbl)
            {
            }
            column(NameCaption_Control1210026; NameCaption_Control1210026Lbl)
            {
            }
            column(Control1210029Caption; Control1210029CaptionLbl)
            {
            }
            column(Control1210030Caption; Control1210030CaptionLbl)
            {
            }
            column(FA_Depreciation_Book__Depreciation_Starting_Date_Caption_Control1210033; "FA Depreciation Book".FieldCaption("Depreciation Starting Date"))
            {
            }
            column(FA_Depreciation_Book__Acquisition_Cost_Caption_Control1210039; "FA Depreciation Book".FieldCaption("Acquisition Cost"))
            {
            }
            column(FA_Depreciation_Book_DepreciationCaption_Control1210042; "FA Depreciation Book".FieldCaption(Depreciation))
            {
            }
            column(FA_Depreciation_Book__Book_Value_Caption_Control1210045; "FA Depreciation Book".FieldCaption("Book Value"))
            {
            }
            column(FA_Sheet__Continuation_Caption; FA_Sheet__Continuation_CaptionLbl)
            {
            }
            column(Depreciation_PeriodCaption_Control1210035; Depreciation_PeriodCaption_Control1210035Lbl)
            {
            }
            column(FA_Depreciation_Book__Disposal_Date_Caption_Control1210041; "FA Depreciation Book".FieldCaption("Disposal Date"))
            {
            }
            column(FA_Depreciation_Book_QuantityCaption_Control1210055; "FA Depreciation Book".FieldCaption(Quantity))
            {
            }
            column(FA_StatusCaption_Control1210060; FA_StatusCaption_Control1210060Lbl)
            {
            }
            column(FA_Depreciation_Book__Depreciation_Ending_Date_Caption_Control1000000036; "FA Depreciation Book".FieldCaption("Depreciation Ending Date"))
            {
            }
            column(NumberCaption_Control1000000044; NumberCaption_Control1000000044Lbl)
            {
            }
            column(FA_Depreciation_Book__No__of_Depreciation_Years_Caption_Control1000000045; "FA Depreciation Book".FieldCaption("No. of Depreciation Years"))
            {
            }
            column(FA_Depreciation_Book__No__of_Depreciation_Months_Caption_Control1000000048; "FA Depreciation Book".FieldCaption("No. of Depreciation Months"))
            {
            }
            column(Totals_Caption; Totals_CaptionLbl)
            {
            }
            column(FA_No_; "No.")
            {
            }
            dataitem("FA Depreciation Book"; "FA Depreciation Book")
            {
                DataItemLink = "FA No." = field("No.");
                DataItemTableView = sorting("FA No.", "Depreciation Book Code");
                column(FA__No__; FA."No.")
                {
                }
                column(FA_Description; FA.Description)
                {
                }
                column(AcquisitionCostDate; AcquisitionCostDate)
                {
                }
                column(AcquisitionCostDocumentNo; AcquisitionCostDocumentNo)
                {
                }
                column(FA_Depreciation_Book__Depreciation_Starting_Date_; "Depreciation Starting Date")
                {
                }
                column(FA_Depreciation_Book__No__of_Depreciation_Years_; "No. of Depreciation Years")
                {
                }
                column(FA_Depreciation_Book_Depreciation; Depreciation)
                {
                }
                column(FA_Depreciation_Book__Acquisition_Cost_; "Acquisition Cost")
                {
                }
                column(FA_Depreciation_Book__Book_Value_; "Book Value")
                {
                }
                column(FA_Depreciation_Book__Depreciation_Ending_Date_; "Depreciation Ending Date")
                {
                }
                column(FA_Depreciation_Book__Disposal_Date_; "Disposal Date")
                {
                }
                column(FA_Depreciation_Book_Quantity; Quantity)
                {
                }
                column(FA_Status; FA.Status)
                {
                }
                column(Number; Number)
                {
                }
                column(FA_Depreciation_Book__No__of_Depreciation_Months_; "No. of Depreciation Months")
                {
                }
                column(FA_Depreciation_Book_FA_No_; "FA No.")
                {
                }
                column(FA_Depreciation_Book_Depreciation_Book_Code; "Depreciation Book Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if not (NotShowZero and ZeroLine()) then
                        Number += 1;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Depreciation Book Code", DepreciationBook);
                    SetRange("FA Posting Date Filter", StartingDate, EndingDate);
                    if FALocationCode <> '' then
                        SetFilter("FA Location Code Filter", FALocationCode);
                    if FAResponsibleCode <> '' then
                        SetFilter("FA Employee Filter", FAResponsibleCode);
                    if MaintenanceCodeFilter <> '' then
                        SetFilter("Maintenance Code Filter", MaintenanceCodeFilter);
                    if GlobalDim1Filter <> '' then
                        SetFilter("Global Dimension 1 Filter", GlobalDim1Filter);
                    if GlobalDim2Filter <> '' then
                        SetFilter("Global Dimension 2 Filter", GlobalDim2Filter);

                    if IsEmpty() then begin
                        "Acquisition Cost" := 0;
                        Depreciation := 0;
                        "Book Value" := 0;
                        Quantity := 0;
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                AcquisitionCostDate := 0D;
                AcquisitionCostDocumentNo := '';

                SetRange("No.");

                FALedgerEntry.Reset();
                FALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                FALedgerEntry.SetRange("FA No.", "No.");
                FALedgerEntry.SetRange("FA Posting Type", FALedgerEntry."FA Posting Type"::"Acquisition Cost");
                if FALedgerEntry.Find('-') then begin
                    AcquisitionCostDate := FALedgerEntry."Posting Date";
                    AcquisitionCostDocumentNo := FALedgerEntry."Document No.";
                end;

                RequestFilter := '' + Text010 + DepreciationBook;
                if FALocationCode <> '' then
                    RequestFilter := RequestFilter + ', ' + Text011 + FALocationCode;
                if FAResponsibleCode <> '' then
                    RequestFilter := RequestFilter + ', ' + Text012 + FAResponsibleCode;
                if GlobalDim1Filter <> '' then
                    RequestFilter := RequestFilter + ', ' + Text013 + GlobalDim1Filter;
                if GlobalDim2Filter <> '' then
                    RequestFilter := RequestFilter + ', ' + Text014 + GlobalDim2Filter;
                if MaintenanceCodeFilter <> '' then
                    RequestFilter := RequestFilter + ', ' + Text015 + MaintenanceCodeFilter;

                if StartingDate <> 0D then
                    Period := Text005 + Format(StartingDate) + Text006 + Format(EndingDate)
                else
                    Period := Text007 + Format(EndingDate);
            end;

            trigger OnPreDataItem()
            begin
                if DepreciationBook = '' then
                    Error(Text000);

                case FAkind of
                    0:
                        SetRange("Undepreciable FA");
                    1:
                        SetRange("Undepreciable FA", false);
                    2:
                        SetRange("Undepreciable FA", true);
                end;
                if FAClass <> '' then
                    SetRange("FA Class Code", FAClass);
                if FASubClass <> '' then
                    SetRange("FA Subclass Code", FASubClass);
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
                    field("Starting Date"; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the beginning of the period for which entries are adjusted. This field is usually left blank, but you can enter a date.';
                    }
                    field("Ending Date"; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field("Depreciation Book Code"; DepreciationBook)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Depreciation Book Code';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code for the depreciation book to be included in the report or batch job.';
                    }
                    field("FA Location Code"; FALocationCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Location Code';
                        TableRelation = "FA Location".Code;
                        ToolTip = 'Specifies the location, such as a building, where the fixed asset is located.';
                    }
                    field("Responsible Employee"; FAResponsibleCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Responsible Employee';
                        TableRelation = Employee."No.";
                        ToolTip = 'Specifies the employee who is responsible for the validity of the data in the report.';
                    }
                    field("Output FA"; FAkind)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Output FA';
                        OptionCaption = 'All,Depreciable,Undepreciable';
                        ToolTip = 'Specifies the type of fixed assets that you want to include in the report. Types include Depreciable, Undepreciable, and All.';
                    }
                    field("Skip zero lines"; NotShowZero)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Skip zero lines';
                        ToolTip = 'Specifies if lines with zero amount are not be included.';
                    }
                    field("Global Dimension 1 Filter"; GlobalDim1Filter)
                    {
                        ApplicationArea = Suite;
                        CaptionClass = '1,3,1';
                        Caption = 'Global Dimension 1 Filter';
                        TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
                        ToolTip = 'Specifies the dimensions by which data is shown. Global dimensions are linked to records or entries for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    }
                    field("Global Dimension 2 Filter"; GlobalDim2Filter)
                    {
                        ApplicationArea = Suite;
                        CaptionClass = '1,3,2';
                        Caption = 'Global Dimension 2 Filter';
                        TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
                        ToolTip = 'Specifies the dimensions by which data is shown. Global dimensions are linked to records or entries for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    }
                    field("FA Class Code"; FAClass)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Class Code';
                        TableRelation = "FA Class";
                        ToolTip = 'Specifies the class that the fixed asset belongs to.';
                    }
                    field("FA Subclass Code"; FASubClass)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'FA Subclass Code';
                        TableRelation = "FA Subclass";
                        ToolTip = 'Specifies the subclass of the class that the fixed asset belongs to.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            FASetup.Get();
            if DepreciationBook = '' then
                DepreciationBook := FASetup."Release Depr. Book";
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        Number := 0;
    end;

    var
        FALedgerEntry: Record "FA Ledger Entry";
        FASetup: Record "FA Setup";
        FADeprBook: Record "FA Depreciation Book";
#pragma warning disable AA0074
        Text005: Label 'for period from ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text006: Label ' to ';
#pragma warning restore AA0074
        DepreciationBook: Code[20];
#pragma warning disable AA0074
        Text007: Label 'As of';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text000: Label 'Enter Depreciation Book Code';
#pragma warning restore AA0074
        StartingDate: Date;
        EndingDate: Date;
        CurrentDate: Date;
        RequestFilter: Text;
        AcquisitionCostDate: Date;
        AcquisitionCostDocumentNo: Code[20];
        FALocationCode: Code[20];
        FAResponsibleCode: Code[20];
        GlobalDim1Filter: Code[20];
        GlobalDim2Filter: Code[20];
        MaintenanceCodeFilter: Code[10];
        FAkind: Option All,Depreciable,Undepreciable;
        FAClass: Code[10];
        FASubClass: Code[10];
#pragma warning disable AA0074
        Text010: Label 'Depreciation Book Code:';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text011: Label 'FA Location Code:';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text012: Label 'Responsible Employee: ';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text013: Label 'Global Dimension 1:';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text014: Label 'Global Dimension 2:';
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text015: Label 'Maintenance Code:';
#pragma warning restore AA0074
        NotShowZero: Boolean;
        Number: Integer;
        Period: Text[250];
        Fixed_AssetsCaptionLbl: Label 'Fixed Assets';
        FA_SheetCaptionLbl: Label 'FA Sheet';
        PageCaptionLbl: Label 'Page';
        No_CaptionLbl: Label 'No.';
        NameCaptionLbl: Label 'Name';
        Acquisition_DateCaptionLbl: Label 'Acquisition Date';
        Acquisition_Document_No_CaptionLbl: Label 'Acquisition Document No.';
        Depreciation_PeriodCaptionLbl: Label 'Depreciation Period';
        FA_StatusCaptionLbl: Label 'FA Status';
        NumberCaptionLbl: Label '³', Comment = 'Superscript character"3"';
        No_Caption_Control1210025Lbl: Label 'No.';
        NameCaption_Control1210026Lbl: Label 'Name';
        Control1210029CaptionLbl: Label 'Label1210029';
        Control1210030CaptionLbl: Label 'Label1210030';
        FA_Sheet__Continuation_CaptionLbl: Label 'FA Sheet. Continuation.';
        Depreciation_PeriodCaption_Control1210035Lbl: Label 'Depreciation Period';
        FA_StatusCaption_Control1210060Lbl: Label 'FA Status';
        NumberCaption_Control1000000044Lbl: Label '³', Comment = 'Superscript character"3"';
        Totals_CaptionLbl: Label 'Totals:';

    [Scope('OnPrem')]
    procedure SetParameters(var parFADeprBook: Record "FA Depreciation Book")
    begin
        FADeprBook.Copy(parFADeprBook);
        StartingDate := FADeprBook.GetRangeMin("FA Posting Date Filter");
        EndingDate := FADeprBook.GetRangeMax("FA Posting Date Filter");
        DepreciationBook := FADeprBook.GetFilter("Depreciation Book Code");
        FALocationCode := FADeprBook.GetFilter("FA Location Code Filter");
        FAResponsibleCode := FADeprBook.GetFilter("FA Employee Filter");
        GlobalDim1Filter := FADeprBook.GetFilter("Global Dimension 1 Filter");
        GlobalDim2Filter := FADeprBook.GetFilter("Global Dimension 2 Filter");
        MaintenanceCodeFilter := FADeprBook.GetFilter("Maintenance Code Filter");
    end;

    [Scope('OnPrem')]
    procedure ZeroLine(): Boolean
    begin
        exit(("FA Depreciation Book"."Acquisition Cost" = 0)
          and ("FA Depreciation Book".Depreciation = 0)
          and ("FA Depreciation Book"."Book Value" = 0))
    end;
}

