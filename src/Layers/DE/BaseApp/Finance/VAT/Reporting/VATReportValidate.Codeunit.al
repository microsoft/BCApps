// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Address;

/// <summary>
/// Validates VAT report data for completeness and accuracy before release.
/// Performs standard validation checks and manages error reporting for VAT submissions.
/// </summary>
codeunit 744 "VAT Report Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        ClearErrorLog();

        ValidateVATReportLinesExists(Rec);
        ValidateVATReportHeader(Rec);
        ValidateVATReportLines(Rec);

        ShowErrorLog();
    end;

    var
        TempVATReportErrorLog: Record "VAT Report Error Log" temporary;
        ErrorID: Integer;

        CannotReleaseNoLinesErr: Label 'You cannot release the VAT report because no lines exist.';
        FieldShouldBeFilledErr: Label 'Field %1 should be filled in table %2.', Comment = '%1 - Field caption, %2 - Table caption';
        PeriodAlreadyExistsErr: Label 'Period from %1 till %2 already exists on VAT Report %3.', Comment = '%1 - Start Date, %2 - End Date, %3 - VAT Report No.';
        CancellationMustHaveCorrectiveErr: Label 'Each cancellation line should have related corrective line.';
        ProcessingDateCannotBeEarlierErr: Label 'The %1 cannot be earlier than the %1 %2 (VAT Report %3).', Comment = '%1 - Field caption, %2 - Date value, %3 - VAT Report No.';
        EUCountryCodeMustBeTwoCharsErr: Label 'The EU Country/Region Code for country/region %1 must be exactly 2 characters.', Comment = '%1 - Country/Region Code';

    local procedure ClearErrorLog()
    begin
        TempVATReportErrorLog.Reset();
        TempVATReportErrorLog.DeleteAll();
    end;

    local procedure InsertErrorLog(ErrorMessage: Text[250])
    begin
        if TempVATReportErrorLog.FindLast() then
            ErrorID := TempVATReportErrorLog."Entry No." + 1
        else
            ErrorID := 1;

        TempVATReportErrorLog.Init();
        TempVATReportErrorLog."Entry No." := ErrorID;
        TempVATReportErrorLog."Error Message" := ErrorMessage;
        TempVATReportErrorLog.Insert();
    end;

    local procedure ShowErrorLog()
    begin
        if not TempVATReportErrorLog.IsEmpty() then begin
            PAGE.Run(PAGE::"VAT Report Error Log", TempVATReportErrorLog);
            Error('');
        end;
    end;

    local procedure ValidateVATReportLinesExists(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.IsEmpty() then begin
            InsertErrorLog(CannotReleaseNoLinesErr);
            ShowErrorLog();
        end;
    end;

    local procedure ValidateVATReportHeader(VATReportHeader: Record "VAT Report Header")
    var
        OrigVATReport: Record "VAT Report Header";
    begin
        if VATReportHeader."No." = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("No."), VATReportHeader.TableCaption));
        if VATReportHeader."Start Date" = 0D then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Start Date"), VATReportHeader.TableCaption));
        if VATReportHeader."End Date" = 0D then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("End Date"), VATReportHeader.TableCaption));
        if VATReportHeader."Processing Date" = 0D then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Processing Date"), VATReportHeader.TableCaption));
        if VATReportHeader."Report Period Type" = VATReportHeader."Report Period Type"::" " then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Report Period Type"), VATReportHeader.TableCaption));
        if VATReportHeader."Report Period No." = 0 then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Report Period No."), VATReportHeader.TableCaption));
        if VATReportHeader."Report Year" = 0 then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Report Year"), VATReportHeader.TableCaption));
        if VATReportHeader."Company Name" = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Company Name"), VATReportHeader.TableCaption));
        if VATReportHeader."Company Address" = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Company Address"), VATReportHeader.TableCaption));
        if VATReportHeader."Post Code" = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("Post Code"), VATReportHeader.TableCaption));
        if VATReportHeader.City = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption(City), VATReportHeader.TableCaption));
        if VATReportHeader."VAT Registration No." = '' then
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportHeader.FieldCaption("VAT Registration No."), VATReportHeader.TableCaption));
        case VATReportHeader."VAT Report Type" of
            VATReportHeader."VAT Report Type"::Standard:
                begin
                    VATReportHeader.TestField("Original Report No.", '');
                    ValidateVATReportPeriod(VATReportHeader);
                end;
            VATReportHeader."VAT Report Type"::Corrective:
                begin
                    VATReportHeader.TestField("Original Report No.");
                    OrigVATReport.Get(VATReportHeader."Original Report No.");
                    VATReportHeader.TestField("Start Date", OrigVATReport."Start Date");
                    VATReportHeader.TestField("End Date", OrigVATReport."End Date");
                    VATReportHeader.TestField("Report Period Type", OrigVATReport."Report Period Type");
                    VATReportHeader.TestField("Report Period No.", OrigVATReport."Report Period No.");
                    VATReportHeader.TestField("Report Year", OrigVATReport."Report Year");
                    if OrigVATReport."Processing Date" > VATReportHeader."Processing Date" then
                        Error(ProcessingDateCannotBeEarlierErr,
                          VATReportHeader.FieldCaption("Processing Date"), OrigVATReport."Processing Date", OrigVATReport."No.");
                end;
        end;
    end;

    local procedure ValidateVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
        CountryRegion: Record "Country/Region";
        CancelLines: Integer;
        CorrectLines: Integer;
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.FindSet() then
            repeat
                ValidateCountryRegionCode(VATReportLine, CountryRegion);

                if VATReportLine."VAT Registration No." = '' then
                    InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportLine.FieldCaption("VAT Registration No."), VATReportLine.TableCaption));

                case VATReportLine."Line Type" of
                    VATReportLine."Line Type"::Cancellation:
                        CancelLines += 1;
                    VATReportLine."Line Type"::Correction:
                        CorrectLines += 1;
                end;
            until VATReportLine.Next() = 0;
        if CancelLines <> CorrectLines then
            Error(CancellationMustHaveCorrectiveErr);
    end;

    local procedure ValidateCountryRegionCode(VATReportLine: Record "VAT Report Line"; var CountryRegion: Record "Country/Region")
    begin
        if VATReportLine."Country/Region Code" = '' then begin
            InsertErrorLog(StrSubstNo(FieldShouldBeFilledErr, VATReportLine.FieldCaption("Country/Region Code"), VATReportLine.TableCaption));
            exit;
        end;

        if not CountryRegion.Get(VATReportLine."Country/Region Code") then
            exit;

        if StrLen(CountryRegion."EU Country/Region Code") <> 2 then
            InsertErrorLog(StrSubstNo(EUCountryCodeMustBeTwoCharsErr, VATReportLine."Country/Region Code"));
    end;

    [Scope('OnPrem')]
    procedure ValidateVATReportPeriod(VATReportHeader: Record "VAT Report Header")
    var
        VATReportHeader2: Record "VAT Report Header";
    begin
        if VATReportHeader."Original Report No." = '' then begin
            VATReportHeader2.Reset();
            VATReportHeader2.SetRange("Start Date", VATReportHeader."Start Date");
            VATReportHeader2.SetRange("End Date", VATReportHeader."End Date");
            VATReportHeader2.SetRange("Original Report No.", '');
            VATReportHeader2.SetRange("VAT Report Type", VATReportHeader."VAT Report Type");
            VATReportHeader2.SetRange("Trade Type", VATReportHeader."Trade Type");
            VATReportHeader2.SetFilter("No.", '<>%1', VATReportHeader."No.");
            OnValidateVATReportPeriodOnAfterSetFilters(VATReportHeader2);
            if VATReportHeader2.FindFirst() then
                Error(PeriodAlreadyExistsErr,
                  VATReportHeader."Start Date", VATReportHeader."End Date", VATReportHeader2."No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATReportPeriodOnAfterSetFilters(var VATReportHeader2: Record "VAT Report Header")
    begin
    end;
}

