// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Finance.Currency;
using Microsoft.Service.Comment;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Setup;
using System.Utilities;

codeunit 5944 SignServContractDoc
{
    Permissions = tabledata "Filed Service Contract Header" = rimd;
    TableNo = "Service Contract Header";

    trigger OnRun()
    begin
    end;

    var
        ServHeader: Record "Service Header";
        ServMgtSetup: Record "Service Mgt. Setup";
        FromServContractHeader: Record "Service Contract Header";
        FromServContractLine: Record "Service Contract Line";
        ToServContractLine: Record "Service Contract Line";
        ContractChangeLog: Record "Contract Change Log";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        ServContractMgt: Codeunit ServContractManagement;
        ServLogMgt: Codeunit ServLogManagement;
        Window: Dialog;
        ServHeaderNo: Code[20];
        InvoicingStartingPeriod: Boolean;
        InvoiceNow: Boolean;
        GoOut: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot convert the service contract quote %1 to a contract,\because some Service Contract Lines have a missing %2.';
        Text003: Label '%1 must be the first day of the month.';
        Text004: Label 'You cannot sign service contract %1,\because some Service Contract Lines have a missing %2.';
        Text005: Label '%1 is not the last day of the month.\\Confirm that this is the correct date.';
        Text010: Label 'Do you want to sign service contract %1?';
#pragma warning restore AA0470
        Text011: Label 'Do you want to convert the contract quote into a contract?';
#pragma warning disable AA0470
        Text012: Label 'Signing contract          #1######\';
        Text013: Label 'Processing contract lines #2######\';
#pragma warning restore AA0470
#pragma warning restore AA0074
        WPostLine: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text015: Label 'Do you want to create an invoice for the period %1 .. %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        AppliedEntry: Integer;
        InvoiceFrom: Date;
        InvoiceTo: Date;
        FirstPrepaidPostingDate: Date;
        LastPrepaidPostingDate: Date;
        PostingDate: Date;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text016: Label 'Service Invoice %1 was created.';
#pragma warning restore AA0470
        Text018: Label 'It is not possible to add new lines to this service contract with the current working date\because it will cause a gap in the invoice period.';
#pragma warning restore AA0074
        HideDialog: Boolean;
#pragma warning disable AA0074
        Text019: Label 'You cannot sign service contract with negative annual amount.';
        Text020: Label 'You cannot sign service contract with zero annual amount when invoice period is different from None.';
#pragma warning disable AA0470
        Text021: Label 'One or more service items on contract quote %1 does not belong to customer %2.';
        Text022: Label 'The %1 field is empty on one or more service contract lines, and service orders cannot be created automatically. Do you want to continue?';
        Text023: Label 'You cannot sign a service contract if its %1 is not equal to the %2 value.';
#pragma warning restore AA0470
        Text024: Label 'You cannot sign a canceled service contract.';
#pragma warning restore AA0074

    procedure SignContractQuote(FromServContractHeader: Record "Service Contract Header")
    var
        ToServContractHeader: Record "Service Contract Header";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        FiledServiceContractHeaderToModify: Record "Filed Service Contract Header";
        RecordLinkManagement: Codeunit "Record Link Management";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        OnBeforeSignContractQuote(FromServContractHeader, HideDialog);

        if not HideDialog then
            ClearAll();
        CheckServContractQuote(FromServContractHeader);
        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text011, true) then
                exit;
        if not HideDialog then
            if not CheckServContractNextPlannedServiceDate(FromServContractHeader) then
                exit;

        Window.Open(
          Text012 +
          Text013);

        FiledServiceContractHeader.FileQuotationBeforeSigning(FromServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;
        InvoicingStartingPeriod := false;
        SetInvoicing(FromServContractHeader);

        FirstPrepaidPostingDate := 0D;
        LastPrepaidPostingDate := 0D;

        ToServContractHeader.TransferFields(FromServContractHeader);

        if InvoiceNow then
            PostingDate := InvoiceFrom;

        ToServContractHeader."Contract Type" := ToServContractHeader."Contract Type"::Contract;
        if InvoiceNow then begin
            ToServContractHeader."Last Invoice Date" := ToServContractHeader."Starting Date";
            ToServContractHeader.Validate("Last Invoice Period End", InvoiceTo);
        end;
        OnBeforeToServContractHeaderInsert(ToServContractHeader, FromServContractHeader);
        ToServContractHeader.Insert();
        OnAfterToServContractHeaderInsert(ToServContractHeader, FromServContractHeader);

        if ServMgtSetup."Register Contract Changes" then
            ContractChangeLog.LogContractChange(
              ToServContractHeader."Contract No.", 0, ToServContractHeader.FieldCaption(Status), 0,
              '', Format(ToServContractHeader.Status), '', 0);

        FiledServiceContractHeader.SetCurrentKey("Contract Type Relation", "Contract No. Relation");
        FiledServiceContractHeader.SetRange("Contract Type Relation", FromServContractHeader."Contract Type");
        FiledServiceContractHeader.SetRange("Contract No. Relation", FromServContractHeader."Contract No.");
        if FiledServiceContractHeader.FindSet() then
            repeat
                FiledServiceContractHeaderToModify := FiledServiceContractHeader;
                FiledServiceContractHeaderToModify."Contract Type Relation" := ToServContractHeader."Contract Type";
                FiledServiceContractHeaderToModify."Contract No. Relation" := ToServContractHeader."Contract No.";
                FiledServiceContractHeaderToModify.Modify();
            until FiledServiceContractHeader.Next() = 0;

        OnSignContractQuoteOnBeforeSetFromServContractLineFilters(FromServContractHeader, ToServContractHeader);
        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if FromServContractLine.FindSet() then
            repeat
                ToServContractLine := FromServContractLine;
                ToServContractLine."Contract Type" := ToServContractLine."Contract Type"::Contract;
                ToServContractLine."Contract No." := FromServContractLine."Contract No.";
                ToServContractLine."Contract Status" := FromServContractLine."Contract Status"::Signed;
                ToServContractLine.SuspendStatusCheck(true);
                OnBeforeToServContractLineInsert(ToServContractLine, FromServContractLine);
                ToServContractLine.Insert(true);
                OnAfterToServContractLineInsert(ToServContractLine, FromServContractLine);
                Clear(ServLogMgt);
                WPostLine := WPostLine + 1;
                Window.Update(2, WPostLine);
            until FromServContractLine.Next() = 0;

        CopyServComments(FromServContractHeader, ToServContractHeader);

        if InvoicingStartingPeriod and
           not ToServContractHeader.Prepaid and
           InvoiceNow
        then begin
            ToServContractHeader.Validate("Last Invoice Date", InvoiceTo);
            OnSignContractQuoteOnBeforeToServContractHeaderModify(ToServContractHeader);
            ToServContractHeader.Modify();
        end;

        ToServContractHeader.Status := ToServContractHeader.Status::Signed;
        ToServContractHeader."Change Status" := ToServContractHeader."Change Status"::Locked;
        OnSignContractQuoteOnChangeStatusOnBeforeToServContractHeaderModify(ToServContractHeader);
        ToServContractHeader.Modify();
        RecordLinkManagement.CopyLinks(FromServContractHeader, ToServContractHeader);

        if InvoiceNow then begin
            ServMgtSetup.Get();
            CreateServiceLinesLedgerEntries(ToServContractHeader, false);
        end;

        CopyContractServDiscounts(FromServContractHeader, ToServContractHeader);

        ContractGainLossEntry.CreateEntry(
            "Service Contract Change Type"::"Contract Signed",
            ToServContractHeader."Contract Type", ToServContractHeader."Contract No.", FromServContractHeader."Annual Amount", '');

        ToServContractLine.Reset();
        ToServContractLine.SetRange("Contract Type", ToServContractHeader."Contract Type");
        ToServContractLine.SetRange("Contract No.", ToServContractHeader."Contract No.");
        if ToServContractLine.FindSet() then
            repeat
                ToServContractLine."New Line" := false;
                ToServContractLine.Modify();
            until ToServContractLine.Next() = 0;

        CopyServHours(ToServContractHeader);
        DeleteServContractHeader(FromServContractHeader);

        Window.Close();

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);

        OnAfterSignContractQuote(FromServContractHeader, ToServContractHeader);
    end;

    procedure SignContract(FromServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        ServContractHeader: Record "Service Contract Header";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        LockOpenServContract: Codeunit "Lock-OpenServContract";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSignContract(FromServContractHeader, HideDialog, IsHandled);
        if IsHandled then
            exit;

        if not HideDialog then
            ClearAll();

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text010, FromServContractHeader."Contract No."), true)
            then
                exit;

        ServContractHeader.Get(FromServContractHeader."Contract Type", FromServContractHeader."Contract No.");

        if not CheckServContract(ServContractHeader) then
            exit;

        if ServContractHeader.Status = ServContractHeader.Status::Signed then begin
            LockOpenServContract.LockServContract(ServContractHeader);
            exit;
        end;

        Window.Open(Text012 + Text013);

        FiledServiceContractHeader.FileQuotationBeforeSigning(ServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;
        InvoicingStartingPeriod := false;
        SetInvoicing(ServContractHeader);

        if InvoiceNow then
            PostingDate := InvoiceFrom;

        if InvoiceNow then begin
            ServContractHeader."Last Invoice Date" := ServContractHeader."Starting Date";
            ServContractHeader.Validate("Last Invoice Period End", InvoiceTo);
        end;

        IsHandled := false;
        OnSignContractOnBeforeSetServContractLineFilters(ServContractLine, FromServContractHeader, WPostLine, IsHandled);
        if not IsHandled then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            OnSignContractOnBeforeFindServContractLine(ServContractLine, FromServContractHeader);
            if ServContractLine.FindSet() then
                repeat
                    ServContractLine."Contract Status" := ServContractLine."Contract Status"::Signed;
                    ServContractLine.Modify();
                    Clear(ServLogMgt);
                    WPostLine := WPostLine + 1;
                    Window.Update(2, WPostLine);
                until ServContractLine.Next() = 0;
        end;

        if InvoicingStartingPeriod and
           not ServContractHeader.Prepaid and
           InvoiceNow
        then begin
            ServContractHeader.Validate("Last Invoice Date", InvoiceTo);
            ServContractHeader.Modify();
        end;

        if InvoiceNow then begin
            ServMgtSetup.Get();
            CreateServiceLinesLedgerEntries(ServContractHeader, false);
        end;

        ContractGainLossEntry.CreateEntry(
          "Service Contract Change Type"::"Contract Signed",
          ServContractHeader."Contract Type", ServContractHeader."Contract No.", ServContractHeader."Annual Amount", '');

        ServContractHeader.Status := ServContractHeader.Status::Signed;
        ServContractHeader."Change Status" := ServContractHeader."Change Status"::Locked;

        OnBeforeServContractHeaderModify(ServContractHeader, FromServContractHeader, InvoicingStartingPeriod, InvoiceNow, InvoiceFrom, InvoiceTo);
        ServContractHeader.Modify();
        OnSignContractOnAfterServContractHeaderModify(ServContractHeader, FromServContractHeader);

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        if ServContractLine.FindSet() then
            repeat
                ServContractLine."New Line" := false;
                OnSignContractOnAfterServContractLineNewLineFalse(ServContractLine);
                ServContractLine.Modify();
            until ServContractLine.Next() = 0;

        if ServMgtSetup."Register Contract Changes" then
            ContractChangeLog.LogContractChange(
              ServContractHeader."Contract No.", 0, ServContractHeader.FieldCaption(Status), 0,
              '', Format(ServContractHeader.Status), '', 0);

        Clear(FromServContractHeader);

        Window.Close();

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);

        OnAfterSignContract(ServContractHeader);
    end;

    procedure AddendumToContract(ServContractHeader: Record "Service Contract Header")
    var
        Currency: Record Currency;
        ServContractLine: Record "Service Contract Line";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ConfirmManagement: Codeunit "Confirm Management";
        TempDate: Date;
        StartingDate: Date;
        RemainingAmt: Decimal;
        InvoicePrepaid: Boolean;
        NonExpiredContractLineExists: Boolean;
        NoOfMonthsAndMParts: Decimal;
        CreateInvoiceConfirmed: Boolean;
        ShouldCreateServHeader: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeAddendumToContract(ServContractHeader);

        if not HideDialog then
            ClearAll();

        FromServContractHeader := ServContractHeader;
        if (FromServContractHeader."Invoice Period" = FromServContractHeader."Invoice Period"::None) or
           (FromServContractHeader."Next Invoice Date" = 0D)
        then
            exit;

        ServContractMgt.CheckContractGroupAccounts(ServContractHeader);

        ServMgtSetup.Get();
        Currency.InitRoundingPrecision();

        ServContractLine.Reset();
        ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        ServContractLine.SetRange("New Line", true);
        StartingDate := WorkDate();
        OnAddendumToContractOnAfterSetStartingDate(FromServContractHeader, StartingDate);
        if ServContractLine.FindSet() then
            repeat
                OnAddendumToContractOnBeforeServContractLineLoop(ServContractLine, StartingDate);
                if ServMgtSetup."Contract Rsp. Time Mandatory" then
                    ServContractLine.TestField("Response Time (Hours)");
                ServContractLine."Starting Date" := StartingDate;
                if (ServContractLine."Next Planned Service Date" <> 0D) and
                   (ServContractLine."Next Planned Service Date" < StartingDate)
                then
                    ServContractLine."Next Planned Service Date" := StartingDate;
                ServContractLine.Modify();
                OnAddendumToContractOnAfterServContractLineLoop(ServContractLine, StartingDate);
            until ServContractLine.Next() = 0;

        if not HideDialog then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);
            ServContractLine.SetRange("Next Planned Service Date", 0D);
            if ServContractLine.FindFirst() then
                if not ConfirmManagement.GetResponseOrDefault(
                     StrSubstNo(Text022, ServContractLine.FieldCaption("Next Planned Service Date")), true)
                then
                    Error('');
        end;

        Window.Open(Text012 + Text013);

        FiledServiceContractHeader.FileQuotationBeforeSigning(FromServContractHeader);

        Window.Update(1, 1);
        WPostLine := 0;

        InvoicePrepaid := FromServContractHeader.Prepaid;

        TempDate := FromServContractHeader."Next Invoice Period Start";
        if StartingDate < TempDate then
            TempDate := TempDate - 1
        else begin
            if StartingDate > CalcDate('<CM>', TempDate) then begin
                Window.Close();
                Error(Text018);
            end;
            TempDate := CalcDate('<CM>', StartingDate);
            InvoicePrepaid := true;
        end;

        if StartingDate >= FromServContractHeader."Next Invoice Period Start" then begin
            GoOut := true;
            InvoicePrepaid := false;
        end;

        if not GoOut then begin
            InvoiceFrom := StartingDate;
            InvoiceTo := TempDate;
            InvoicingStartingPeriod := true;
        end;

        if FromServContractHeader.Prepaid and InvoicePrepaid then begin
            FirstPrepaidPostingDate := ServContractMgt.FindFirstPrepaidTransaction(FromServContractHeader."Contract No.");
            if FirstPrepaidPostingDate <> 0D then begin
                if StartingDate < FromServContractHeader."Next Invoice Date" then
                    LastPrepaidPostingDate := FromServContractHeader."Next Invoice Date" - 1
                else
                    LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End";
                case true of
                    InvoiceFrom < FirstPrepaidPostingDate:
                        InvoiceTo := FirstPrepaidPostingDate - 1;
                    InvoiceFrom > FirstPrepaidPostingDate:
                        if LastPrepaidPostingDate = CalcDate('<CM>', InvoiceFrom) then
                            InvoicePrepaid := false
                        else begin
                            InvoiceTo := CalcDate('<CM>', InvoiceFrom);
                            FirstPrepaidPostingDate := InvoiceTo + 1;
                            if InvoiceFrom > LastPrepaidPostingDate
                            then
                                LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End";
                        end;
                end;
            end else
                if InvoiceFrom > FromServContractHeader."Next Invoice Period Start" then begin
                    FirstPrepaidPostingDate := CalcDate('<CM>', InvoiceFrom) + 1;
                    if FirstPrepaidPostingDate < FromServContractHeader."Next Invoice Period End" then
                        LastPrepaidPostingDate := FromServContractHeader."Next Invoice Period End"
                    else
                        InvoicePrepaid := false;
                end else
                    InvoicePrepaid := false;
        end;

        IsHandled := false;
        OnAddendumToContractOnBeforeCalcCreateInvoiceConfirmed(GoOut, HideDialog, InvoiceNow, InvoicePrepaid, LastPrepaidPostingDate, StartingDate, TempDate, IsHandled);
        if not IsHandled then
            if not GoOut then
                if HideDialog then
                    InvoiceNow := true
                else begin
                    if InvoicePrepaid and (LastPrepaidPostingDate <> 0D)
                    then
                        TempDate := LastPrepaidPostingDate;
                    IsHandled := false;
                    OnAddendumToContractOnBeforeConfirmCalcCreateInvoice(ServContractHeader, ServContractHeader, CreateInvoiceConfirmed, IsHandled);
                    if not IsHandled then
                        CreateInvoiceConfirmed := ConfirmManagement.GetResponseOrDefault(StrSubstNo(Text015, StartingDate, TempDate), true);
                    OnAddendumToContractOnAfterCalcCreateInvoiceConfirmed(ServContractHeader, CreateInvoiceConfirmed);
                    if CreateInvoiceConfirmed then
                        InvoiceNow := true
                    else
                        InvoicePrepaid := false;
                end;

        if FromServContractHeader.Prepaid and InvoicePrepaid then
            if InvoiceFrom = ServContractMgt.FindFirstPrepaidTransaction(FromServContractHeader."Contract No.")
            then
                InvoiceNow := false;

        if InvoiceNow then begin
            PostingDate := InvoiceFrom;
            OnAddendumToContractOnAfterAssignPostingDate(PostingDate, InvoiceFrom);
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);
            if ServContractLine.FindSet() then
                repeat
                    if (ServContractLine."Contract Expiration Date" <> 0D) and
                       (ServContractLine."Contract Expiration Date" < InvoiceTo)
                    then
                        NoOfMonthsAndMParts := ServContractMgt.NoOfMonthsAndMPartsInPeriod(
                            InvoiceFrom, ServContractLine."Contract Expiration Date")
                    else
                        if (FromServContractHeader."Expiration Date" <> 0D) and
                           (FromServContractHeader."Expiration Date" < InvoiceTo)
                        then
                            NoOfMonthsAndMParts := ServContractMgt.NoOfMonthsAndMPartsInPeriod(
                                InvoiceFrom, FromServContractHeader."Expiration Date")
                        else
                            NoOfMonthsAndMParts :=
                              ServContractMgt.NoOfMonthsAndMPartsInPeriod(InvoiceFrom, InvoiceTo);
                    RemainingAmt :=
                      RemainingAmt +
                      Round(
                        ServContractLine."Line Amount" / 12 * NoOfMonthsAndMParts, Currency."Amount Rounding Precision");
                until ServContractLine.Next() = 0;
        end;

        if InvoiceNow then begin
            OnAddendumToContractOnBeforeCreateServiceLinesLedgerEntries(FromServContractHeader);
            CreateServiceLinesLedgerEntries(FromServContractHeader, true);
        end;

        if InvoicePrepaid and FromServContractHeader.Prepaid then begin
            ServContractMgt.InitCodeUnit();
            ShouldCreateServHeader := ServHeaderNo = '';
            OnAddendumToContractOnAfterCalcShouldCreateServHeader(ServHeaderNo, ServContractMgt, FromServContractHeader, PostingDate, ShouldCreateServHeader);
            if ShouldCreateServHeader then
                ServHeaderNo := ServContractMgt.CreateServHeader(FromServContractHeader, PostingDate, false);

            RemainingAmt := 0;
            ServContractLine.Reset();
            ServContractLine.SetCurrentKey("Contract Type", "Contract No.", Credited, "New Line");
            ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            ServContractLine.SetRange("New Line", true);

            if ServContractLine.FindSet() then
                repeat
                    InvoiceFrom := FirstPrepaidPostingDate;
                    InvoiceTo := LastPrepaidPostingDate;
                    if (ServContractLine."Contract Expiration Date" <> 0D) and
                       (ServContractLine."Contract Expiration Date" < InvoiceTo)
                    then
                        InvoiceTo := ServContractLine."Contract Expiration Date";
                    if (FromServContractHeader."Expiration Date" <> 0D) and
                       (FromServContractHeader."Expiration Date" < InvoiceTo)
                    then
                        InvoiceTo := FromServContractHeader."Expiration Date";
                    if ServContractLine."Starting Date" > InvoiceFrom then
                        InvoiceFrom := ServContractLine."Starting Date";
                    NoOfMonthsAndMParts :=
                      ServContractMgt.NoOfMonthsAndMPartsInPeriod(InvoiceFrom, InvoiceTo);
                    RemainingAmt :=
                      RemainingAmt +
                      Round(
                        ServContractLine."Line Amount" / 12 * NoOfMonthsAndMParts, Currency."Amount Rounding Precision");
                until ServContractLine.Next() = 0;
            if RemainingAmt <> 0 then
                CreateServiceLinesForRemainingAmt();
            ServContractMgt.FinishCodeunit();
        end;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if ServContractLine.FindSet() then
            repeat
                if (ServContractLine."Contract Expiration Date" <> 0D) and (ServContractHeader."Last Invoice Date" <> 0D) then
                    if ServContractLine."Contract Expiration Date" > ServContractHeader."Last Invoice Date" then
                        NonExpiredContractLineExists := true;
            until ServContractLine.Next() = 0;
        if InvoiceNow and (not NonExpiredContractLineExists) then begin
            if not FromServContractHeader.Prepaid then
                FromServContractHeader."Last Invoice Date" := InvoiceTo
            else
                FromServContractHeader."Last Invoice Date" := FromServContractHeader."Next Invoice Date";
            FromServContractHeader.Modify();
        end;

        FromServContractHeader.Get(ServContractHeader."Contract Type", ServContractHeader."Contract No.");
        FromServContractHeader."Change Status" := FromServContractHeader."Change Status"::Locked;
        FromServContractHeader.Modify();

        ClearServContractLineNewLine();
        Window.Close();

        if not HideDialog then
            if ServHeaderNo <> '' then
                Message(Text016, ServHeaderNo);
    end;

    local procedure CreateServiceLinesForRemainingAmt()
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateServiceLinesForRemainingAmt(ServHeader, FromServContractHeader, FirstPrepaidPostingDate, LastPrepaidPostingDate, AppliedEntry, IsHandled);
        if not IsHandled then begin
            ServHeader.Get(ServHeader."Document Type"::Invoice, ServHeaderNo);
            if FromServContractHeader."Contract Lines on Invoice" then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
                ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
                ServContractLine.SetRange("New Line", true);
                if ServContractLine.FindSet() then
                    repeat
                        if FromServContractHeader."Contract Lines on Invoice" then
                            ServContractMgt.CreateDetailedServiceLine(
                              ServHeader,
                              ServContractLine,
                              FromServContractHeader."Contract Type",
                              FromServContractHeader."Contract No.");

                        AppliedEntry :=
                          ServContractMgt.CreateServiceLedgEntry(
                            ServHeader, FromServContractHeader."Contract Type",
                            FromServContractHeader."Contract No.", FirstPrepaidPostingDate,
                            LastPrepaidPostingDate, false, true,
                            ServContractLine."Line No.");

                        ServContractMgt.CreateServiceLine(
                          ServHeader,
                          FromServContractHeader."Contract Type",
                          FromServContractHeader."Contract No.",
                          FirstPrepaidPostingDate, LastPrepaidPostingDate,
                          AppliedEntry, false);
                    until ServContractLine.Next() = 0;
            end else begin
                ServContractMgt.CreateHeadingServiceLine(
                  ServHeader,
                  FromServContractHeader."Contract Type",
                  FromServContractHeader."Contract No.");

                AppliedEntry :=
                  ServContractMgt.CreateServiceLedgEntry(
                    ServHeader, FromServContractHeader."Contract Type",
                    FromServContractHeader."Contract No.", FirstPrepaidPostingDate,
                    LastPrepaidPostingDate, false, true, 0);

                ServContractMgt.CreateServiceLine(
                  ServHeader,
                  FromServContractHeader."Contract Type",
                  FromServContractHeader."Contract No.",
                  FirstPrepaidPostingDate, LastPrepaidPostingDate,
                  AppliedEntry, false);
            end;
        end;

        OnAfterCreateServiceLinesForRemainingAmt(FromServContractHeader);
    end;

    local procedure ClearServContractLineNewLine()
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeClearServContractLineNewLine(FromServContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        ServContractLine.ModifyAll("New Line", false);
    end;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    procedure GetHideDialog(): Boolean
    begin
        exit(HideDialog);
    end;

    local procedure SetInvoicing(ServContractHeader: Record "Service Contract Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        TempDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetInvoicing(ServContractHeader, IsHandled, InvoiceNow, InvoiceFrom, InvoiceTo, InvoicingStartingPeriod, GoOut, HideDialog);
        if not IsHandled then begin
            if ServContractHeader."Invoice Period" = ServContractHeader."Invoice Period"::None then
                exit;

            if ServContractHeader.Prepaid then begin
                if ServContractHeader."Starting Date" < ServContractHeader."Next Invoice Date" then begin
                    if HideDialog then
                        InvoiceNow := true
                    else
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text015, ServContractHeader."Starting Date", ServContractHeader."Next Invoice Date" - 1), true)
                        then
                            InvoiceNow := true;
                    InvoiceFrom := ServContractHeader."Starting Date";
                    InvoiceTo := ServContractHeader."Next Invoice Date" - 1;
                end
            end else begin
                GoOut := true;
                TempDate := ServContractHeader."Next Invoice Period Start";
                if ServContractHeader."Starting Date" < TempDate then begin
                    TempDate := TempDate - 1;
                    GoOut := false;
                end;
                if not GoOut then begin
                    if HideDialog then
                        InvoiceNow := true
                    else
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text015, ServContractHeader."Starting Date", TempDate), true)
                        then
                            InvoiceNow := true;
                    InvoiceFrom := ServContractHeader."Starting Date";
                    InvoiceTo := TempDate;
                    InvoicingStartingPeriod := true;
                end;
            end;
        end;

        OnAfterSetInvoicing(ServContractHeader, InvoiceNow, InvoiceFrom, InvoiceTo, InvoicingStartingPeriod, GoOut, HideDialog);
    end;

    local procedure CheckServContractQuote(FromServContractHeader: Record "Service Contract Header")
    var
        ServItem: Record "Service Item";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractQuote(FromServContractHeader, HideDialog, IsHandled);
        if not IsHandled then begin

            FromServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
            CheckContractHeaderServicePeriod(FromServContractHeader);
            FromServContractHeader.CalcFields("Calcd. Annual Amount");
            if FromServContractHeader."Calcd. Annual Amount" < 0 then
                Error(Text019);
            FromServContractHeader.TestField("Annual Amount", FromServContractHeader."Calcd. Annual Amount");

            ServContractMgt.CheckContractGroupAccounts(FromServContractHeader);

            CheckMissingServiceContractLines(FromServContractHeader);

            FromServContractHeader.TestField("Starting Date");
            CheckServContractNonZeroAmounts(FromServContractHeader);

            FromServContractLine.Reset();
            FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            FromServContractLine.SetFilter("Service Item No.", '<>%1', '');
            if FromServContractLine.FindSet() then
                repeat
                    ServItem.Get(FromServContractLine."Service Item No.");
                    if ServItem."Customer No." <> FromServContractHeader."Customer No." then
                        Error(
                          Text021,
                          FromServContractHeader."Contract No.",
                          FromServContractHeader."Customer No.");

                    CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(ServItem, FromServContractLine);

                    OnCheckServContractQuoteOnAfterCheckServItemCustomerNo(FromServContractLine, FromServContractHeader, ServItem);
                until FromServContractLine.Next() = 0;

            ServMgtSetup.Get();
            if ServMgtSetup."Salesperson Mandatory" then
                FromServContractHeader.TestField("Salesperson Code");
            CheckServContractNextInvoiceDate(FromServContractHeader);

            FromServContractLine.Reset();
            FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
            FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
            if FromServContractLine.FindSet() then
                repeat
                    if ServMgtSetup."Contract Rsp. Time Mandatory" then
                        FromServContractLine.TestField("Response Time (Hours)");
                until FromServContractLine.Next() = 0;

            ServContractMgt.CopyCheckSCDimToTempSCDim(FromServContractHeader);
        end;

        OnAfterCheckServContractQuote(FromServContractHeader);
    end;

    local procedure CheckMissingServiceContractLines(FromServContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMissingServiceContractLines(FromServContractHeader, IsHandled);
        if IsHandled then
            exit;

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromServContractLine.SetRange("Line Amount", 0);
        FromServContractLine.SetFilter("Line Discount %", '<%1', 100);
        if FromServContractLine.FindFirst() then
            Error(
              Text001,
              FromServContractHeader."Contract No.",
              FromServContractLine.FieldCaption("Line Amount"));
    end;

    procedure CheckServContract(var ServContractHeader: Record "Service Contract Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContract(ServContractHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ServContractHeader.Status = "Service Contract Status"::Signed then
            exit(true);
        if ServContractHeader.Status = "Service Contract Status"::Cancelled then
            Error(Text024);

        ServContractHeader.TestField("Serv. Contract Acc. Gr. Code");
        CheckContractHeaderServicePeriod(ServContractHeader);
        ServContractHeader.CalcFields("Calcd. Annual Amount");

        if ServContractHeader."Annual Amount" <> ServContractHeader."Calcd. Annual Amount" then
            Error(Text023, ServContractHeader.FieldCaption("Annual Amount"),
              ServContractHeader.FieldCaption("Calcd. Annual Amount"));

        if ServContractHeader."Annual Amount" < 0 then
            Error(Text019);

        ServContractMgt.CheckContractGroupAccounts(ServContractHeader);

        CheckServContractHasZeroAmounts(ServContractHeader);

        ServContractHeader.TestField("Starting Date");
        CheckServContractNonZeroAmounts(ServContractHeader);

        ServMgtSetup.Get();
        if ServMgtSetup."Salesperson Mandatory" then
            ServContractHeader.TestField("Salesperson Code");

        CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(ServContractHeader);

        exit(CheckServContractDatesDimensionsAndResponseTime(ServContractHeader));
    end;

    local procedure CheckServContractDatesDimensionsAndResponseTime(var ServContractHeader: Record "Service Contract Header") Result: Boolean
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractDatesDimensionsAndResponseTime(ServContractHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        CheckServContractNextInvoiceDate(ServContractHeader);

        if ServMgtSetup."Contract Rsp. Time Mandatory" then begin
            ServContractLine.Reset();
            ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
            ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
            ServContractLine.SetRange("Response Time (Hours)", 0);
            if ServContractLine.FindFirst() then
                ServContractLine.FieldError("Response Time (Hours)");
        end;
        ServContractMgt.CopyCheckSCDimToTempSCDim(ServContractHeader);

        if not HideDialog then
            exit(CheckServContractNextPlannedServiceDate(ServContractHeader));

        exit(true);
    end;

    local procedure CheckContractHeaderServicePeriod(ServContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContractHeaderServicePeriod(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServContractHeader.TestField("Service Period");
    end;

    local procedure CheckServContractNextInvoiceDate(ServContractHeader: Record "Service Contract Header")
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractNextInvoiceDate(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        if ServContractHeader.IsInvoicePeriodInTimeSegment() then
            if ServContractHeader.Prepaid then begin
                if CalcDate('<-CM>', ServContractHeader."Next Invoice Date") <> ServContractHeader."Next Invoice Date"
                then
                    Error(Text003, ServContractHeader.FieldCaption("Next Invoice Date"));
            end else
                if CalcDate('<CM>', ServContractHeader."Next Invoice Date") <> ServContractHeader."Next Invoice Date" then
                    if not HideDialog then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(Text005, ServContractHeader.FieldCaption("Next Invoice Date")), true)
                        then
                            exit;
    end;

    local procedure CheckServContractNextPlannedServiceDate(ServContractHeader: Record "Service Contract Header"): Boolean
    var
        ServContractLine: Record "Service Contract Line";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServContractLine.SetRange("Next Planned Service Date", 0D);
        OnCheckServContractNextPlannedServiceDateOnAfterServContractLineSetFilters(ServContractLine, ServContractHeader);
        if ServContractLine.FindFirst() then
            if not ConfirmManagement.GetResponseOrDefault(
                 StrSubstNo(Text022, ServContractLine.FieldCaption("Next Planned Service Date")), true)
            then
                exit(false);
        exit(true);
    end;

    local procedure CheckServContractNonZeroAmounts(ServContractHeader: Record "Service Contract Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractNonZeroAmounts(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        if ServContractHeader.IsInvoicePeriodInTimeSegment() then begin
            if ServContractHeader."Annual Amount" = 0 then
                Error(Text020);
            ServContractHeader.TestField("Amount per Period");
        end;
    end;

    local procedure CheckServContractHasZeroAmounts(ServContractHeader: Record "Service Contract Header")
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServContractHasZeroAmounts(ServContractHeader, IsHandled);
        if IsHandled then
            exit;

        ServContractLine.Reset();
        ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
        ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
        ServContractLine.SetRange("Line Amount", 0);
        ServContractLine.SetFilter("Line Discount %", '<%1', 100);
        OnCheckServContractHasZeroAmountsOnAfterServContractLineSetFilters(ServContractLine);
        if not ServContractLine.IsEmpty() then
            Error(
              Text004,
              ServContractHeader."Contract No.",
              ServContractLine.FieldCaption("Line Amount"));
    end;

    local procedure CreateServiceLinesLedgerEntries(var ServContractHeader: Record "Service Contract Header"; NewLine: Boolean)
    var
        ServContractLine: Record "Service Contract Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateServiceLinesLedgerEntries(ServContractHeader, NewLine, IsHandled, ServHeaderNo, PostingDate, InvoiceFrom, InvoiceTo);
        if not IsHandled then begin
            ServContractMgt.InitCodeUnit();
            ServHeaderNo :=
              ServContractMgt.CreateServHeader(ServContractHeader, PostingDate, false);

            ServHeader.Get(ServHeader."Document Type"::Invoice, ServHeaderNo);
            if ServContractHeader."Contract Lines on Invoice" then begin
                ServContractLine.Reset();
                ServContractLine.SetRange("Contract Type", ServContractHeader."Contract Type");
                ServContractLine.SetRange("Contract No.", ServContractHeader."Contract No.");
                if NewLine then
                    ServContractLine.SetRange("New Line", true);
                if ServContractLine.FindSet() then
                    repeat
                        ServContractMgt.CreateDetailedServiceLine(
                          ServHeader, ServContractLine,
                          ServContractHeader."Contract Type",
                          ServContractHeader."Contract No.");

                        AppliedEntry :=
                          ServContractMgt.CreateServiceLedgEntry(
                            ServHeader, ServContractHeader."Contract Type",
                            ServContractHeader."Contract No.", InvoiceFrom,
                            InvoiceTo, not NewLine, NewLine,
                            ServContractLine."Line No.");

                        ServContractMgt.CreateServiceLine(
                          ServHeader,
                          ServContractHeader."Contract Type",
                          ServContractHeader."Contract No.",
                          InvoiceFrom, InvoiceTo, AppliedEntry, not NewLine);
                    until ServContractLine.Next() = 0;
            end else begin
                ServContractMgt.CreateHeadingServiceLine(
                  ServHeader,
                  ServContractHeader."Contract Type",
                  ServContractHeader."Contract No.");

                AppliedEntry :=
                  ServContractMgt.CreateServiceLedgEntry(
                    ServHeader, ServContractHeader."Contract Type",
                    ServContractHeader."Contract No.", InvoiceFrom,
                    InvoiceTo, not NewLine, NewLine, 0);

                ServContractMgt.CreateServiceLine(
                  ServHeader,
                  ServContractHeader."Contract Type",
                  ServContractHeader."Contract No.",
                  InvoiceFrom, InvoiceTo, AppliedEntry, not NewLine);
            end;

            ServContractHeader.Modify();
            ServContractMgt.FinishCodeunit();
        end;

        OnAfterCreateServiceLinesLedgerEntries(ServHeader, ServContractHeader);
    end;

    local procedure CopyServComments(FromServContractHeader: Record "Service Contract Header"; ToServContractHeader: Record "Service Contract Header")
    var
        FromServCommentLine: Record "Service Comment Line";
        ToServCommentLine: Record "Service Comment Line";
    begin
        FromServCommentLine.SetRange("Table Name", FromServCommentLine."Table Name"::"Service Contract");
        FromServCommentLine.SetRange("Table Subtype", FromServContractHeader."Contract Type");
        FromServCommentLine.SetRange("No.", FromServContractHeader."Contract No.");
        if FromServCommentLine.FindSet() then
            repeat
                ToServCommentLine."Table Name" := ToServCommentLine."Table Name"::"Service Contract";
                ToServCommentLine."Table Subtype" := ToServContractHeader."Contract Type"::Contract;
                ToServCommentLine."Table Line No." := FromServCommentLine."Table Line No.";
                ToServCommentLine."No." := ToServContractHeader."Contract No.";
                ToServCommentLine."Line No." := FromServCommentLine."Line No.";
                ToServCommentLine.Comment := FromServCommentLine.Comment;
                ToServCommentLine.Date := FromServCommentLine.Date;
                OnCopyServCommentsOnAfterToServCommentLineInsert(FromServCommentLine, ToServCommentLine);
                ToServCommentLine.Insert();
            until FromServCommentLine.Next() = 0;
    end;

    local procedure CopyServHours(ToServContractHeader: Record "Service Contract Header")
    var
        FromServHour: Record "Service Hour";
        ToServHour: Record "Service Hour";
    begin
        FromServHour.Reset();
        FromServHour.SetRange("Service Contract Type", FromServHour."Service Contract Type"::Quote);
        FromServHour.SetRange("Service Contract No.", ToServContractHeader."Contract No.");
        if FromServHour.FindSet() then
            repeat
                ToServHour := FromServHour;
                ToServHour."Service Contract Type" := FromServHour."Service Contract Type"::Contract;
                ToServHour."Service Contract No." := ToServContractHeader."Contract No.";
                ToServHour.Insert();
            until FromServHour.Next() = 0;
    end;

    local procedure CopyContractServDiscounts(FromServContractHeader: Record "Service Contract Header"; ToServContractHeader: Record "Service Contract Header")
    var
        FromContractServDisc: Record "Contract/Service Discount";
        ToContractServDisc: Record "Contract/Service Discount";
    begin
        FromContractServDisc.Reset();
        FromContractServDisc.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromContractServDisc.SetRange("Contract No.", FromServContractHeader."Contract No.");
        if FromContractServDisc.FindSet() then
            repeat
                ToContractServDisc.Copy(FromContractServDisc);
                ToContractServDisc."Contract Type" := FromContractServDisc."Contract Type"::Contract;
                ToContractServDisc."Contract No." := ToServContractHeader."Contract No.";
                if ToContractServDisc.Insert() then;
            until FromContractServDisc.Next() = 0;
    end;

    local procedure DeleteServContractHeader(FromServContractHeader: Record "Service Contract Header")
    var
        FromContractServDisc: Record "Contract/Service Discount";
        FromServContractLine: Record "Service Contract Line";
        FromServCommentLine: Record "Service Comment Line";
        FromServHour: Record "Service Hour";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteServContractHeader(FromServContractHeader, IsHandled);
        if IsHandled then
            exit;

        FromServContractLine.Reset();
        FromServContractLine.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromServContractLine.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromServContractLine.DeleteAll();
        FromServContractHeader.Delete();

        FromServCommentLine.Reset();
        FromServCommentLine.SetRange("Table Name", FromServCommentLine."Table Name"::"Service Contract");
        FromServCommentLine.SetRange("Table Subtype", FromServContractHeader."Contract Type");
        FromServCommentLine.SetRange("No.", FromServContractHeader."Contract No.");
        FromServCommentLine.DeleteAll();

        FromContractServDisc.Reset();
        FromContractServDisc.SetRange("Contract Type", FromServContractHeader."Contract Type");
        FromContractServDisc.SetRange("Contract No.", FromServContractHeader."Contract No.");
        FromContractServDisc.DeleteAll();

        FromServHour.Reset();
        FromServHour.SetRange("Service Contract Type", FromServHour."Service Contract Type"::Quote);
        FromServHour.SetRange("Service Contract No.", FromServContractHeader."Contract No.");
        FromServHour.DeleteAll();
    end;

    local procedure CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(var ServiceItem: Record "Service Item"; ServiceContractLine: Record "Service Contract Line")
    var
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceItem.ErrorIfBlockedForServiceContract();
        ServContractManagement.CheckItemServiceBlocked(ServiceContractLine);
    end;

    local procedure CheckServiceItemBlockedForServiceContractAndItemServiceBlocked(var ServiceContractHeader: Record "Service Contract Header")
    var
        ServiceContractLine: Record "Service Contract Line";
        ServContractManagement: Codeunit ServContractManagement;
    begin
        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        ServiceContractLine.SetFilter("Service Item No.", '<>%1', '');
        if ServiceContractLine.FindSet() then
            repeat
                ServContractManagement.CheckServiceItemBlockedForServiceContract(ServiceContractLine);
                ServContractManagement.CheckItemServiceBlocked(ServiceContractLine);
            until ServiceContractLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterServContractLineLoop(var ServContractLine: Record "Service Contract Line"; var StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterAssignPostingDate(var PostingDate: Date; var InvoiceFrom: Date);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterSetStartingDate(FromServContractHeader: Record "Service Contract Header"; var StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnBeforeServContractLineLoop(ServContractLine: Record "Service Contract Line"; var StartingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServiceLinesForRemainingAmt(FromServContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterCalcCreateInvoiceConfirmed(ServContractHeader: Record "Service Contract Header"; var CreateInvoiceConfirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnAfterCalcShouldCreateServHeader(var ServiceHeaderNo: Code[20]; var ServContractManagement: Codeunit ServContractManagement; FromServiceContractHeader: Record "Service Contract Header"; PostingDate: Date; var ShouldCreateServHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateServiceLinesLedgerEntries(var ServiceHeader: Record "Service Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToServContractHeaderInsert(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterToServContractLineInsert(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddendumToContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContract(var ServiceContractHeader: Record "Service Contract Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractHasZeroAmounts(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContractHeaderServicePeriod(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMissingServiceContractLines(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeClearServContractLineNewLine(FromServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header"; InvoicingStartingPeriod: Boolean; InvoiceNow: Boolean; InvoiceFrom: Date; InvoiceTo: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToServContractHeaderInsert(var ToServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeToServContractLineInsert(var ToServiceContractLine: Record "Service Contract Line"; FromServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSignContract(var ServiceContractHeader: Record "Service Contract Header"; var HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSignContractQuote(var ServiceContractHeader: Record "Service Contract Header"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetInvoicing(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean; var InvoiceNow: Boolean; var InvoiceFrom: Date; var InvoiceTo: Date; var InvoicingStartingPeriod: Boolean; var GoOut: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetInvoicing(var ServiceContractHeader: Record "Service Contract Header"; var InvoiceNow: Boolean; var InvoiceFrom: Date; var InvoiceTo: Date; var InvoicingStartingPeriod: Boolean; var GoOut: Boolean; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSignContractQuote(var SourceServiceContractHeader: Record "Service Contract Header"; var DestServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractQuoteOnBeforeToServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnBeforeCreateServiceLinesLedgerEntries(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractNextInvoiceDate(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServiceLinesForRemainingAmt(var ServHeader: Record "Service Header"; var FromServContractHeader: Record "Service Contract Header"; var FirstPrepaidPostingDate: Date; var LastPrepaidPostingDate: Date; var AppliedEntry: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractQuote(var ServiceContractHeader: Record "Service Contract Header"; HideDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckServContractQuote(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractNonZeroAmounts(var ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServContractDatesDimensionsAndResponseTime(ServiceContractHeader: Record "Service Contract Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateServiceLinesLedgerEntries(var ServiceContractHeader: Record "Service Contract Header"; NewLine: Boolean; var IsHandled: Boolean; var ServHeaderNo: Code[20]; PostingDate: Date; InvoiceFrom: Date; InvoiceTo: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteServContractHeader(ServiceContractHeader: Record "Service Contract Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServContractQuoteOnAfterCheckServItemCustomerNo(var ServiceContractLine: Record "Service Contract Line"; ServiceContractHeader: Record "Service Contract Header"; ServItem: Record "Service Item")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServContractHasZeroAmountsOnAfterServContractLineSetFilters(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyServCommentsOnAfterToServCommentLineInsert(var FromServCommentLine: Record "Service Comment Line"; var ToServCommentLine: Record "Service Comment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractQuoteOnChangeStatusOnBeforeToServContractHeaderModify(var ToServContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractOnAfterServContractLineNewLineFalse(var ServContractLine: Record "Service Contract Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractOnBeforeFindServContractLine(var ServiceContractLine: Record "Service Contract Line"; var FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractOnAfterServContractHeaderModify(var ServiceContractHeader: Record "Service Contract Header"; FromServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSignContract(var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnBeforeConfirmCalcCreateInvoice(FromServiceContractHeader: Record "Service Contract Header"; ServiceContractHeader: Record "Service Contract Header"; var CreateInvoiceConfirmed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractQuoteOnBeforeSetFromServContractLineFilters(var FromServiceContractHeader: Record "Service Contract Header"; var ToServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSignContractOnBeforeSetServContractLineFilters(var ServiceContractLine: Record "Service Contract Line"; FromServiceContractHeader: Record "Service Contract Header"; var WPostLine: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddendumToContractOnBeforeCalcCreateInvoiceConfirmed(GoOut: Boolean; HideDialog: Boolean; var InvoiceNow: Boolean; var InvoicePrepaid: Boolean; LastPrepaidPostingDate: Date; StartingDate: Date; TempDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckServContractNextPlannedServiceDateOnAfterServContractLineSetFilters(var ServiceContractLine: Record "Service Contract Line"; var ServiceContractHeader: Record "Service Contract Header")
    begin
    end;
}

