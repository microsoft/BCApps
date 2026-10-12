// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;

report 6952 "Expense Report Summary Page"
{
    Caption = 'Expense Report Summary Page';
    DefaultRenderingLayout = "ExpenseReportSummaryPage.rdlc";
    ApplicationArea = Basic, Suite;

    dataset
    {
        dataitem("Expense Report Header"; "Expense Report Header")
        {
            RequestFilterFields = "No.";
            CalcFields = "Amount (LCY)", "Reimbursable Amount (LCY)";

            column(ExpenseReportNo; "No.")
            {
            }
            column(CompanyAddress1; CompanyAddress[1])
            {
            }
            column(CompanyAddress2; CompanyAddress[2])
            {
            }
            column(CompanyAddress3; CompanyAddress[3])
            {
            }
            column(CompanyAddress4; CompanyAddress[4])
            {
            }
            column(CompanyAddress5; CompanyAddress[5])
            {
            }
            column(CompanyAddress6; CompanyAddress[6])
            {
            }
            column(CompanyAddress7; CompanyAddress[7])
            {
            }
            column(CompanyAddress8; CompanyAddress[8])
            {
            }
            column(CompanyCity; CompanyInformation.City)
            {
            }
            column(ExpenseUserName; "Expense User Name")
            {
            }
            column(SubmissionDate; DT2Date("Submission DateTime"))
            {
            }
            column(ReportMonth; Format("Expense Report Date", 0, '<Month Text> <Year4>'))
            {
            }
            column(HeaderDescription; Description)
            {
            }
            column(JobTitle; ExpenseUser."Job Title")
            {
            }
            column(PeriodFrom; PeriodFrom)
            {
            }
            column(PeriodTo; PeriodTo)
            {
            }
            column(GrandTotalLCY; "Amount (LCY)")
            {
            }
            column(PrepaymentAmount; PrepaymentAmount)
            {
            }
            column(PaidAmount; PaidAmount)
            {
            }
            column(ReportTitleLbl; ReportTitleLbl)
            {
            }
            column(DetailsLbl; DetailsLbl)
            {
            }
            column(PerDiemSectionLbl; PerDiemSectionLbl)
            {
            }
            column(MileageSectionLbl; MileageSectionLbl)
            {
            }
            column(OtherExpensesSectionLbl; OtherExpensesSectionLbl)
            {
            }
            column(TotalLbl; TotalLbl)
            {
            }
            column(PrepaymentLbl; PrepaymentLbl)
            {
            }
            column(PaidAmountLbl; PaidAmountLbl)
            {
            }
            column(SigningApplicantLbl; SigningApplicantLbl)
            {
            }
            column(OrderGivenByLbl; OrderGivenByLbl)
            {
            }
            column(AccountantLbl; AccountantLbl)
            {
            }
            column(PeriodLbl; PeriodLbl)
            {
            }
            column(ExpenseUserNameLbl; "Expense Report Header".FieldCaption("Expense User Name"))
            {
            }
            column(JobTitleLbl; JobTitleLbl)
            {
            }
            column(DescriptionLbl; "Expense Report Header".FieldCaption(Description))
            {
            }
            column(PerDiemExpenseLocationLbl; ExpenseReportLine.FieldCaption("Expense Location"))
            {
            }
            column(PerDiemStartingDateTimeLbl; ExpenseReportLine.FieldCaption("Starting Date and Time"))
            {
            }
            column(PerDiemEndingDateTimeLbl; ExpenseReportLine.FieldCaption("Ending Date and Time"))
            {
            }
            column(PerDiemNumberOfFullDaysLbl; PerDiemNumberOfFullDaysLbl)
            {
            }
            column(PerDiemNumberOfHoursLbl; PerDiemNumberOfHoursLbl)
            {
            }
            column(PerDiemAmountLbl; PerDiemAmountLbl)
            {
            }
            column(PerDiemTotalLbl; PerDiemTotalLbl)
            {
            }
            column(PerDiemCurrencyLbl; ExpenseReportLine.FieldCaption("Expense Currency Code"))
            {
            }
            column(MileageStartingPointLbl; ExpenseReportLine.FieldCaption("Starting Point"))
            {
            }
            column(MileageEndingPointLbl; ExpenseReportLine.FieldCaption("Ending Point"))
            {
            }
            column(MileageMileageLbl; ExpenseReportLine.FieldCaption(Mileage))
            {
            }
            column(MileageTotalMileageLbl; MileageTotalMileageLbl)
            {
            }
            column(MileageRoundTripLbl; ExpenseReportLine.FieldCaption("Round Trip"))
            {
            }
            column(MileageUOMLbl; ExpenseReportLine.FieldCaption("Unit of Measure Code"))
            {
            }
            column(MileageAmountPerMileageLbl; MileageAmountPerMileageLbl)
            {
            }
            column(MileageTotalAmountLCYLbl; MileageTotalAmountLCYLbl)
            {
            }
            column(OtherExpenseCategoryLbl; OtherExpenseCategoryLbl)
            {
            }
            column(OtherRefundableAmountLCYLbl; OtherRefundableAmountLCYLbl)
            {
            }
            column(PerDiemLbl; PerDiemLbl)
            {
            }
            column(MileageLbl; MileageLbl)
            {
            }
            column(OtherLbl; OtherLbl)
            {
            }
            column(Page_Lbl; PageLbl)
            {
            }
            column(HasPerDiemLines; ShowPerDiemCategory)
            {
            }
            column(HasMileageLines; ShowMileageCategory)
            {
            }
            column(HasOtherExpenseLines; ShowOtherCategory)
            {
            }

            dataitem(PerDiemLine; "Expense Report Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = where("Expense Detail Required" = const("Per Diem"));

                column(PerDiem_ExpenseLocation; ExpenseLocationDescription)
                {
                }
                column(PerDiem_LineNo; "Line No.")
                {
                }
                column(PerDiem_StartingDateTime; "Starting Date and Time")
                {
                }
                column(PerDiem_EndingDateTime; "Ending Date and Time")
                {
                }
                column(PerDiem_NumberOfFullDays; NumberOfFullDays)
                {
                }
                column(PerDiem_NumberOfHours; NumberOfHours)
                {
                }
                column(PerDiem_UnitAmount; PerDiemUnitAmount)
                {
                }
                column(PerDiem_Amount; "Amount")
                {
                }
                column(PerDiem_Currency; "Expense Currency Code")
                {
                }
                column(Document_No_PerDiemLine; "Document No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ExpenseLocationDescription := GetExpenseLocationDescription("Expense Location");
                    PerDiemUnitAmount := GetPerDiemDailyRate("Document No.", "Line No.");
                    CalcPerDiemDaysHours("Starting Date and Time", "Ending Date and Time", NumberOfFullDays, NumberOfHours);
                end;
            }

            dataitem(MileageLine; "Expense Report Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = where("Expense Detail Required" = const("Mileage"));

                column(Mileage_StartingPoint; "Starting Point")
                {
                }
                column(Document_No_MileageLine; "Document No.")
                {
                }
                column(Mileage_LineNo; "Line No.")
                {
                }
                column(Mileage_EndingPoint; "Ending Point")
                {
                }
                column(Mileage_Mileage; Mileage)
                {
                }
                column(Mileage_RoundTrip; "Round Trip")
                {
                }
                column(Mileage_TotalMileage; TotalMileage)
                {
                }
                column(Mileage_UOM; "Unit of Measure Code")
                {
                }
                column(Mileage_AmountPerMileage; AmountPerMileage)
                {
                }
                column(Mileage_AmountLCY; "Amount (LCY)")
                {
                }
                trigger OnAfterGetRecord()
                begin
                    AmountPerMileage := GetMileageRate("Expense Date", "Expense Currency Code", "Expense Currency Factor", "Vehicle Type");
                    TotalMileage := ExpenseAutoPopulation.GetEffectiveDistance(Mileage, "Round Trip");
                end;
            }

            dataitem(OtherExpenseLine; "Expense Report Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = where("Expense Detail Required" = filter(<> "Per Diem" & <> "Mileage"));

                column(Other_Category; ExpenseCategoryDescription)
                {
                }
                column(Document_No_OtherExpenseLine; "Document No.")
                {
                }
                column(Other_LineNo; "Line No.")
                {
                }
                column(Other_RefundableAmountLCY; "Refundable Amount (LCY)")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    ExpenseCategoryDescription := GetExpenseCategoryDescription("Expense Category");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                ExpenseUser.Get("Expense User No.");
                CalculateReportPeriod("No.", PeriodFrom, PeriodTo);
                PaidAmount := "Amount (LCY)" - PrepaymentAmount;
                CheckExpenseCategoryLines("No.", ShowPerDiemCategory, ShowMileageCategory, ShowOtherCategory);
            end;
        }
    }
    rendering
    {
        layout("ExpenseReportSummaryPage.rdlc")
        {
            Type = RDLC;
            LayoutFile = 'src/ExpenseReport/Reports/ExpenseReportSummaryPage.rdlc';
            Caption = 'Expense Report Summary Page';
        }
    }

    trigger OnPreReport()
    begin
        CompanyInformation.Get();
        FormatAddress.Company(CompanyAddress, CompanyInformation);
    end;

    var
        CompanyInformation: Record "Company Information";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseUser: Record "Expense User";
        ExpenseLocation: Record "Expense Location";
        ExpenseCategory: Record "Expense Category";
        FormatAddress: Codeunit "Format Address";
        ExpenseAutoPopulation: Codeunit "Expense Auto Population";
        NumberOfFullDays: Integer;
        NumberOfHours: Integer;
        AmountPerMileage: Decimal;
        TotalMileage: Decimal;
        PerDiemUnitAmount: Decimal;
        PrepaymentAmount: Decimal;
        PaidAmount: Decimal;
        PeriodFrom: Date;
        PeriodTo: Date;
        ShowPerDiemCategory: Boolean;
        ShowMileageCategory: Boolean;
        ShowOtherCategory: Boolean;
        ExpenseLocationDescription: Text[100];
        ExpenseCategoryDescription: Text[100];
        ReportTitleLbl: Label 'Expense Report:';
        DetailsLbl: Label 'Details';
        PerDiemSectionLbl: Label 'Per-diem';
        MileageSectionLbl: Label 'Mileage';
        OtherExpensesSectionLbl: Label 'Other expenses';
        TotalLbl: Label 'Total';
        PrepaymentLbl: Label 'Prepayment amount';
        PaidAmountLbl: Label 'Paid Amount';
        SigningApplicantLbl: Label 'Place for signing as the Applicant';
        OrderGivenByLbl: Label 'Order given by:';
        AccountantLbl: Label 'Accountant:';
        PeriodLbl: Label 'Expense Report Period:';
        JobTitleLbl: Label 'Job Title';
        PerDiemNumberOfFullDaysLbl: Label 'No. of Full Days';
        PerDiemNumberOfHoursLbl: Label 'No. of Hours';
        PerDiemAmountLbl: Label 'Unit Amount';
        PerDiemTotalLbl: Label 'Total Per-diem';
        MileageAmountPerMileageLbl: Label 'Amount per Mileage';
        MileageTotalMileageLbl: Label 'Total Mileage';
        MileageTotalAmountLCYLbl: Label 'Total Amount (LCY)';
        OtherExpenseCategoryLbl: Label 'Expense Category';
        OtherRefundableAmountLCYLbl: Label 'Refundable Amount (LCY)';
        PerDiemLbl: Label 'Per-diem';
        MileageLbl: Label 'Mileage';
        OtherLbl: Label 'Other';
        PageLbl: Label 'Page';
        CompanyAddress: array[8] of Text[100];

    local procedure CalculateReportPeriod(DocumentNo: Code[20]; var FromDate: Date; var ToDate: Date)
    begin
        FromDate := 0D;
        ToDate := 0D;

        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        if ExpenseReportLine.FindSet() then
            repeat
                if (FromDate = 0D) or (ExpenseReportLine."Expense Date" < FromDate) then
                    FromDate := ExpenseReportLine."Expense Date";
                if (ToDate = 0D) or (ExpenseReportLine."Expense Date" > ToDate) then
                    ToDate := ExpenseReportLine."Expense Date";
            until ExpenseReportLine.Next() = 0;
    end;

    local procedure CheckExpenseCategoryLines(DocumentNo: Code[20]; var HasPerDiem: Boolean; var HasMileage: Boolean; var HasOther: Boolean)
    begin
        ExpenseReportLine.Reset();
        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange("Expense Detail Required", ExpenseReportLine."Expense Detail Required"::"Per Diem");
        HasPerDiem := ExpenseReportLine.Count > 0;

        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetRange("Expense Detail Required", ExpenseReportLine."Expense Detail Required"::Mileage);
        HasMileage := ExpenseReportLine.Count > 0;

        ExpenseReportLine.SetRange("Document No.", DocumentNo);
        ExpenseReportLine.SetFilter("Expense Detail Required", '<>%1&<>%2', ExpenseReportLine."Expense Detail Required"::"Per Diem", ExpenseReportLine."Expense Detail Required"::Mileage);
        HasOther := ExpenseReportLine.Count > 0;
    end;

    local procedure GetExpenseCategoryDescription(CategoryCode: Code[20]): Text[100]
    begin
        if ExpenseCategory.Get(CategoryCode) then
            exit(ExpenseCategory."Posting Description");
        exit(CategoryCode);
    end;

    local procedure GetExpenseLocationDescription(LocationCode: Code[20]): Text[100]
    begin
        if ExpenseLocation.Get(LocationCode) then
            exit(ExpenseLocation.Description);
        exit(LocationCode);
    end;

    local procedure GetPerDiemDailyRate(DocumentNo: Code[20]; LineNo: Integer): Decimal
    var
        ExpenseReportLinePerDiem: Record "Expense Report Line Per Diem";
    begin
        ExpenseReportLinePerDiem.SetRange("Expense Report No.", DocumentNo);
        ExpenseReportLinePerDiem.SetRange("Expense Report Line No.", LineNo);
        if ExpenseReportLinePerDiem.FindFirst() then
            exit(ExpenseReportLinePerDiem."Original Per Diem Amount");
    end;

    local procedure GetMileageRate(ExpenseDate: Date; CurrencyCode: Code[10]; CurrencyFactor: Decimal; VehicleType: Code[20]): Decimal
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if ExpenseAgentSetup.Get() then
            exit(ExpenseAutoPopulation.GetStandardRateOfMileage(ExpenseDate, CurrencyCode, CurrencyFactor, ExpenseAgentSetup."Standard Rate of Mileage", VehicleType));
    end;

    local procedure CalcPerDiemDaysHours(StartDateTime: DateTime; EndDateTime: DateTime; var Days: Integer; var Hours: Integer)
    var
        DurationMs: BigInteger;
        OneHourMs: BigInteger;
        OneDayMs: BigInteger;
    begin
        Days := 0;
        Hours := 0;

        if (StartDateTime <> 0DT) and (EndDateTime <> 0DT) and (EndDateTime >= StartDateTime) then begin
            OneHourMs := 60 * 60 * 1000;
            OneDayMs := 24 * OneHourMs;
            DurationMs := EndDateTime - StartDateTime;

            Days := DurationMs div OneDayMs;
            Hours := DurationMs div OneHourMs;
        end;
    end;
}