// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
        VATReportLine: Record "VAT Report Line";
        ErrorID: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot release the VAT report because no lines exist.';
        Text001: Label 'Field %1 should be filled in table %2.';
        Text002: Label 'Period from %1 till %2 already exists on VAT Report %3.';
        Text003: Label 'Each cancellation line should have related corrective line.';
        Text004: Label 'The %1 cannot be earlier than the %1 %2 (VAT Report %3).';
#pragma warning restore AA0470
#pragma warning restore AA0074

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
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.IsEmpty() then begin
            InsertErrorLog(Text000);
            ShowErrorLog();
        end;
    end;

    local procedure ValidateVATReportHeader(VATReportHeader: Record "VAT Report Header")
    var
        OrigVATReport: Record "VAT Report Header";
    begin
        if VATReportHeader."No." = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("No."), VATReportHeader.TableCaption));
        if VATReportHeader."Start Date" = 0D then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Start Date"), VATReportHeader.TableCaption));
        if VATReportHeader."End Date" = 0D then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("End Date"), VATReportHeader.TableCaption));
        if VATReportHeader."Processing Date" = 0D then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Processing Date"), VATReportHeader.TableCaption));
        if VATReportHeader."Report Period Type" = VATReportHeader."Report Period Type"::" " then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Report Period Type"), VATReportHeader.TableCaption));
        if VATReportHeader."Report Period No." = 0 then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Report Period No."), VATReportHeader.TableCaption));
        if VATReportHeader."Report Year" = 0 then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Report Year"), VATReportHeader.TableCaption));
        if VATReportHeader."Company Name" = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Company Name"), VATReportHeader.TableCaption));
        if VATReportHeader."Company Address" = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Company Address"), VATReportHeader.TableCaption));
        if VATReportHeader."Post Code" = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("Post Code"), VATReportHeader.TableCaption));
        if VATReportHeader.City = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption(City), VATReportHeader.TableCaption));
        if VATReportHeader."VAT Registration No." = '' then
            InsertErrorLog(StrSubstNo(Text001, VATReportHeader.FieldCaption("VAT Registration No."), VATReportHeader.TableCaption));
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
                        Error(Text004,
                          VATReportHeader.FieldCaption("Processing Date"), OrigVATReport."Processing Date", OrigVATReport."No.");
                end;
        end;
    end;

    local procedure ValidateVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
        CancelLines: Integer;
        CorrectLines: Integer;
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.FindSet() then
            repeat
                if VATReportLine."Country/Region Code" = '' then
                    InsertErrorLog(StrSubstNo(Text001, VATReportLine.FieldCaption("Country/Region Code"), VATReportLine.TableCaption));
                if VATReportLine."VAT Registration No." = '' then
                    InsertErrorLog(StrSubstNo(Text001, VATReportLine.FieldCaption("VAT Registration No."), VATReportLine.TableCaption));
                case VATReportLine."Line Type" of
                    VATReportLine."Line Type"::Cancellation:
                        CancelLines += 1;
                    VATReportLine."Line Type"::Correction:
                        CorrectLines += 1;
                end;
            until VATReportLine.Next() = 0;
        if CancelLines <> CorrectLines then
            Error(Text003);
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
                Error(Text002,
                  VATReportHeader."Start Date", VATReportHeader."End Date", VATReportHeader2."No.");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVATReportPeriodOnAfterSetFilters(var VATReportHeader2: Record "VAT Report Header")
    begin
    end;
}

