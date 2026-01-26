// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

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

        ValidateVATReportHeader(Rec);
        ValidateVATReportLines(Rec);

        ShowErrorLog();
    end;

    var
        TempVATReportErrorLog: Record "VAT Report Error Log" temporary;
        VATReportLine: Record "VAT Report Line";
        ErrorID: Integer;

#pragma warning disable AA0470
        EmptyFieldErr: Label 'The %1 field in the %2 window must not be empty.';
        SpecifyFieldErr: Label 'You must specify the %1 field for the %2 %3.', Comment = 'You must specify the Fiscal Code No. for Vendor 10000.';
        SpecifyEitherFieldErr: Label 'You must specify the %1 or %2 field for %3 %4.', Comment = 'You must specify the Fiscal Code or VAT Registration No. for Vendor 10000.';
        LineNumberErr: Label 'The error is related to line no. %1.';
        PleaseFillFieldErr: Label 'You must specify the %1 field for the country/region code %2.';
        EmptyFieldOriginalReportErr: Label 'The field %1 must be filled out the original report %2. Original Report No.=%3';
#pragma warning restore AA0470

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

    local procedure ValidateVATReportHeader(VATReportHeader: Record "VAT Report Header")
    var
        OrgVATReportHeader: Record "VAT Report Header";
    begin
        if VATReportHeader."VAT Report Config. Code" = VATReportHeader."VAT Report Config. Code"::" " then
            InsertErrorLog(StrSubstNo(EmptyFieldErr, VATReportHeader.FieldCaption("VAT Report Config. Code"), VATReportHeader.TableCaption()));

        if VATReportHeader."VAT Report Type" <> VATReportHeader."VAT Report Type"::Standard then
            if VATReportHeader."Original Report No." = '' then
                InsertErrorLog(StrSubstNo(EmptyFieldErr, VATReportHeader.FieldCaption("Original Report No."), VATReportHeader.TableCaption()))
            else begin
                OrgVATReportHeader.Get(VATReportHeader."Original Report No.");
                if OrgVATReportHeader."Tax Auth. Receipt No." = '' then
                    InsertErrorLog(
                      StrSubstNo(
                        EmptyFieldOriginalReportErr, VATReportHeader.FieldCaption("Tax Auth. Receipt No."), VATReportHeader.TableCaption(),
                        VATReportHeader."Original Report No."));
                if OrgVATReportHeader."Tax Auth. Document No." = '' then
                    InsertErrorLog(
                      StrSubstNo(
                        EmptyFieldOriginalReportErr, VATReportHeader.FieldCaption("Tax Auth. Document No."), VATReportHeader.TableCaption(),
                        VATReportHeader."Original Report No."));
            end;
    end;

    local procedure ValidateVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Incl. in Report", true);
        if VATReportLine.FindSet() then
            repeat
                VATEntry.Get(VATReportLine."VAT Entry No.");
                case VATReportLine.Type of
                    VATReportLine.Type::Purchase:
                        CheckVendor(VATReportLine, VATEntry);
                    VATReportLine.Type::Sale:
                        CheckCust(VATReportLine, VATEntry);
                end;
            until VATReportLine.Next() = 0;
        OnAfterValidateVATReportLines(VATReportLine);
    end;

    [Scope('OnPrem')]
    procedure CheckVendor(var VATReportLine: Record "VAT Report Line"; var VATEntry: Record "VAT Entry")
    var
        Vendor: Record Vendor;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVendor(VATReportLine, VATEntry, TempVATReportErrorLog, IsHandled);
        if IsHandled then
            exit;

        if Vendor.Get(VATReportLine."Bill-to/Pay-to No.") then begin
            if (VATEntry.Resident = VATEntry.Resident::"Non-Resident") and (not VATEntry."Individual Person") then begin
                if Vendor.Name = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Vendor.FieldCaption(Name),
                          Vendor.TableCaption(),
                          Vendor."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));

                if Vendor.City = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Vendor.FieldCaption(City),
                          Vendor.TableCaption(),
                          Vendor."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));

                if Vendor.Address = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Vendor.FieldCaption(Address),
                          Vendor.TableCaption(),
                          Vendor."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));
            end;

            if VATEntry.Resident = VATEntry.Resident::"Non-Resident" then
                if Vendor."Country/Region Code" = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Vendor.FieldCaption("Country/Region Code"),
                          Vendor.TableCaption(),
                          Vendor."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")))
                else
                    CheckForeignCountryCode(Vendor."Country/Region Code");

            if (VATEntry.Resident = VATEntry.Resident::Resident) and (VATReportLine."VAT Group Identifier" = 'NR') then
                if (Vendor."VAT Registration No." = '') and (VATEntry."VAT Registration No." = '') then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Vendor.FieldCaption("VAT Registration No."),
                          Vendor.TableCaption(),
                          Vendor."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")))
                else
                    if VATReportLine."VAT Group Identifier" = '' then
                        VATReportLine."VAT Group Identifier" := Vendor."VAT Registration No.";
            VATReportLine.Modify(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckCust(var VATReportLine: Record "VAT Report Line"; var VATEntry: Record "VAT Entry")
    var
        Cust: Record Customer;
    begin
        if Cust.Get(VATReportLine."Bill-to/Pay-to No.") then begin
            if (VATEntry.Resident = VATEntry.Resident::"Non-Resident") and (not VATEntry."Individual Person") then begin
                if Cust.Name = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Cust.FieldCaption(Name),
                          Cust.TableCaption(),
                          Cust."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));

                if Cust.City = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Cust.FieldCaption(City),
                          Cust.TableCaption(),
                          Cust."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));

                if Cust.Address = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Cust.FieldCaption(Address),
                          Cust.TableCaption(),
                          Cust."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")));
            end;

            if VATEntry.Resident = VATEntry.Resident::"Non-Resident" then
                if Cust."Country/Region Code" = '' then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyFieldErr,
                          Cust.FieldCaption("Country/Region Code"),
                          Cust.TableCaption(),
                          Cust."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")))
                else
                    CheckForeignCountryCode(Cust."Country/Region Code");

            if (VATEntry.Resident = VATEntry.Resident::Resident) and (VATReportLine."VAT Group Identifier" = 'NE') then
                if (Cust."Fiscal Code" = '') and (VATEntry."Fiscal Code" = '') and
                  (Cust."VAT Registration No." = '') and (VATEntry."VAT Registration No." = '') then
                    InsertErrorLog(
                      StrSubstNo('%1 %2',
                        StrSubstNo(
                          SpecifyEitherFieldErr,
                          Cust.FieldCaption("Fiscal Code"),
                          Cust.FieldCaption("VAT Registration No."),
                          Cust.TableCaption(),
                          Cust."No."),
                        StrSubstNo(LineNumberErr, VATReportLine."Line No.")))
                else
                    if VATReportLine."VAT Group Identifier" = '' then
                        if Cust."VAT Registration No." <> '' then
                            VATReportLine."VAT Group Identifier" := Cust."VAT Registration No."
                        else
                            VATReportLine."VAT Group Identifier" := Cust."Fiscal Code";

            VATReportLine.Modify(false);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckForeignCountryCode(CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(CountryRegionCode);
        if CountryRegion."Foreign Country/Region Code" = '' then
            InsertErrorLog(
              StrSubstNo('%1 %2',
                StrSubstNo(
                  PleaseFillFieldErr,
                  CountryRegion.FieldCaption("Foreign Country/Region Code"),
                  CountryRegionCode),
                StrSubstNo(LineNumberErr, VATReportLine."Line No.")));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateVATReportLines(var VATReportLine: Record "VAT Report Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVendor(var VATReportLine: Record "VAT Report Line"; var VATEntry: Record "VAT Entry"; var TempVATReportErrorLog: Record "VAT Report Error Log" temporary; var IsHandled: Boolean)
    begin
    end;
}
