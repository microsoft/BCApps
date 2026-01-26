// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using System.Utilities;

/// <summary>
/// Automated line generation process for VAT reports based on posted VAT entries.
/// Analyzes VAT ledger entries within specified periods and creates corresponding VAT report lines.
/// </summary>
report 741 "VAT Report Suggest Lines"
{
    Caption = 'VAT Report Suggest Lines';
    Permissions = TableData "VAT Report Line" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem(VATReportHeader; "VAT Report Header")
        {
            DataItemTableView = sorting("No.") order(ascending);
            dataitem(VATEntrySales; "VAT Entry")
            {
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Sale));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
                RequestFilterHeading = 'Sales entries';

                trigger OnAfterGetRecord()
                begin
                    if "EU Service" then
                        if "VAT Reporting Date" < 20100101D then
                            Error(Text11000, FieldCaption("VAT Reporting Date"), 20100101D);

                    UpdateProgressBar();
                    AddVATReportLine(VATEntrySales);
                end;

                trigger OnPreDataItem()
                begin
                    if VATReportHeader."Trade Type" = VATReportHeader."Trade Type"::Purchases then
                        CurrReport.Break();

                    SetFilters(VATEntrySales);

                    RecordNo := 0;
                    NoOfRecords := Count;
                    OldTime := Time;
                end;
            }
            dataitem(VATEntryPurchases; "VAT Entry")
            {
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Purchase));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group";
                RequestFilterHeading = 'Purchase entries';

                trigger OnAfterGetRecord()
                begin
                    UpdateProgressBar();
                    AddVATReportLine(VATEntryPurchases);
                end;

                trigger OnPreDataItem()
                begin
                    if VATReportHeader."Trade Type" = VATReportHeader."Trade Type"::Sales then
                        CurrReport.Break();

                    SetFilters(VATEntryPurchases);

                    RecordNo := 0;
                    NoOfRecords := Count;
                    OldTime := Time;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CheckEditingAllowed();

                VATReportLine.SetRange("VAT Report No.", "No.");
                VATReportLine.SetRange("Line Type", VATReportLine."Line Type"::New);
                if VATReportLine.Count > 0 then begin
                    if not Confirm(Text003, true) then
                        CurrReport.Break();

                    VATReportLine.DeleteAll(true);
                end;
            end;

            trigger OnPostDataItem()
            begin
                case "VAT Report Type" of
                    "VAT Report Type"::Standard:
                        SaveBuffer();
                    "VAT Report Type"::Corrective:
                        SaveCorrBuffer();
                end;

                Window.Close();
            end;

            trigger OnPreDataItem()
            begin
                if GetRangeMin("No.") <> GetRangeMax("No.") then
                    Error(Text006);

                NextLineNo := 0;

                TempVATReportLine.DeleteAll();
                TempVATReportLine.Reset();
                TempVATReportLineRelation.DeleteAll();
                TempVATReportLineRelation.Reset();
                TransBuffer.DeleteAll();

                Window.Open(Text001 + Text002);
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        Text11000: Label '%1 must not be less than %2 for Services.';
        Text001: Label 'VAT Date #1########';
        Text002: Label 'Suggesting lines @2@@@@@@@@@@@@@';
        Text003: Label 'Existing lines will be deleted and new lines will be created. Continue?';
        Text006: Label 'You can process one declaration only.';
        VATReportLine: Record "VAT Report Line";
        TempVATReportLine: Record "VAT Report Line" temporary;
        TempVATReportLineRelation: Record "VAT Report Line Relation" temporary;
        TransBuffer: Record "Integer" temporary;
        Window: Dialog;
        NoOfRecords: Integer;
        RecordNo: Integer;
        NewProgress: Integer;
        OldProgress: Integer;
        NewTime: Time;
        OldTime: Time;
        NextLineNo: Integer;
        KeyAlreadyExistsErr: Label 'When you run the Suggest Lines action, it will add a VAT Report line for VAT Reg. No. %1, but one or more lines already exists for this VAT Reg. No. Delete the existing lines and run the action again.', Comment = 'When you run the Suggest Lines action, it will add a VAT Report line for VAT Reg. No. 123425, but one or more lines already exists for this VAT Reg. No. Delete the existing lines and run the action again.';

    [Scope('OnPrem')]
    procedure AddBuffer(VATEntry: Record "VAT Entry")
    begin
        TempVATReportLine.SetCurrentKey("Trade Type");
        TempVATReportLine.SetRange("Trade Type", VATReportLine."Trade Type");
        TempVATReportLine.SetRange("Country/Region Code", VATReportLine."Country/Region Code");
        TempVATReportLine.SetRange("VAT Registration No.", VATReportLine."VAT Registration No.");
        TempVATReportLine.SetRange("Registration No.", VATReportLine."Registration No.");
        TempVATReportLine.SetRange("Trade Role Type", VATReportLine."Trade Role Type");
        TempVATReportLine.SetRange("EU 3-Party Trade", VATReportLine."EU 3-Party Trade");
        TempVATReportLine.SetRange("EU Service", VATReportLine."EU Service");
        if TempVATReportLine.FindFirst() then begin
            TempVATReportLine.Base += VATReportLine.Base;
            TempVATReportLine.Amount += VATReportLine.Amount;
            UpdateNumberOfSupplies(TempVATReportLine, VATEntry."Transaction No.");
            TempVATReportLine.Modify();
        end else begin
            NextLineNo += 10000;
            TempVATReportLine := VATReportLine;
            TempVATReportLine."Line No." := NextLineNo;
            UpdateNumberOfSupplies(TempVATReportLine, VATEntry."Transaction No.");
            TempVATReportLine.Insert();
        end;
        TempVATReportLineRelation.Init();
        TempVATReportLineRelation."VAT Report No." := TempVATReportLine."VAT Report No.";
        TempVATReportLineRelation."VAT Report Line No." := TempVATReportLine."Line No.";
        TempVATReportLineRelation."Table No." := DATABASE::"VAT Entry";
        TempVATReportLineRelation."Entry No." := VATEntry."Entry No.";
        TempVATReportLineRelation.Insert();
    end;

    [Scope('OnPrem')]
    procedure SaveBuffer()
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        TempVATReportLine.Reset();
        if TempVATReportLine.FindSet() then
            repeat
                VATReportLine := TempVATReportLine;
                VATReportLine.Amount := Round(TempVATReportLine.Amount, 1);
                VATReportLine.Base := Round(TempVATReportLine.Base, 1);
                VATReportLine."Line No." := VATReportLine.GetNextLineNo(VATReportHeader."No.");
                VATReportLine.Insert(true);
                TempVATReportLineRelation.SetRange("VAT Report No.", TempVATReportLine."VAT Report No.");
                TempVATReportLineRelation.SetRange("VAT Report Line No.", TempVATReportLine."Line No.");
                if TempVATReportLineRelation.FindSet() then
                    repeat
                        VATReportLineRelation := TempVATReportLineRelation;
                        VATReportLineRelation."VAT Report Line No." := VATReportLine."Line No.";
                        VATReportLineRelation.Insert();
                    until TempVATReportLineRelation.Next() = 0;
            until TempVATReportLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SaveCorrBuffer()
    var
        VATReportLine2: Record "VAT Report Line";
        VATReportLineRelation: Record "VAT Report Line Relation";
        ExistingVATReportLine: Record "VAT Report Line";
        SkipLine: Boolean;
    begin
        CancelOutOfScopeLines();

        TempVATReportLine.Reset();
        if TempVATReportLine.FindSet() then
            repeat
                SkipLine := false;
                if GetKeyInReport(TempVATReportLine, ExistingVATReportLine, VATReportHeader."No.", false) then
                    if HaveDifferentRelations(ExistingVATReportLine, TempVATReportLine) then
                        Error(KeyAlreadyExistsErr, ExistingVATReportLine."VAT Registration No.")
                    else
                        SkipLine := true;

                if not SkipLine then
                    if not GetKeyInReport(TempVATReportLine, VATReportLine2, VATReportHeader."Original Report No.", true) then begin
                        VATReportLine := TempVATReportLine;
                        VATReportLine.Amount := Round(TempVATReportLine.Amount, 1);
                        VATReportLine.Base := Round(TempVATReportLine.Base, 1);
                        VATReportLine."Line No." := VATReportLine.GetNextLineNo(VATReportHeader."No.");
                        VATReportLine.Insert(true);

                        TempVATReportLineRelation.SetRange("VAT Report No.", TempVATReportLine."VAT Report No.");
                        TempVATReportLineRelation.SetRange("VAT Report Line No.", TempVATReportLine."Line No.");
                        if TempVATReportLineRelation.FindSet() then
                            repeat
                                VATReportLineRelation := TempVATReportLineRelation;
                                VATReportLineRelation."VAT Report Line No." := VATReportLine."Line No.";
                                VATReportLineRelation.Insert();
                            until TempVATReportLineRelation.Next() = 0;
                    end else
                        if HaveDifferentRelations(VATReportLine2, TempVATReportLine) then
                            TempVATReportLine.InsertCorrLine(
                              VATReportHeader, VATReportLine2, TempVATReportLine, TempVATReportLineRelation);
            until TempVATReportLine.Next() = 0;
    end;

    local procedure CancelOutOfScopeLines()
    var
        ExistingVATReportLine: Record "VAT Report Line";
        CancelVATReportLine: Record "VAT Report Line";
        VATReportLineInCurrent: Record "VAT Report Line";
        EmptyVATReportLineRelation: Record "VAT Report Line Relation" temporary;
        VATReportLineRelation: Record "VAT Report Line Relation";
        SkipLine: Boolean;
    begin
        ExistingVATReportLine.Reset();
        ExistingVATReportLine.SetRange("VAT Report to Correct", VATReportHeader."Original Report No.");
        ExistingVATReportLine.SetRange("Able to Correct Line", true);
        if ExistingVATReportLine.FindSet() then
            repeat
                if ExistingVATReportLine.Base <> 0 then
                    if not GetKeyInReport(ExistingVATReportLine, TempVATReportLine, VATReportHeader."No.", false) then begin
                        SkipLine := false;

                        if GetKeyInReport(ExistingVATReportLine, VATReportLineInCurrent, VATReportHeader."No.", false) then begin
                            VATReportLineRelation.SetRange("VAT Report No.", VATReportLineInCurrent."VAT Report No.");
                            VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLineInCurrent."Line No.");
                            if VATReportLineRelation.Count <> 0 then
                                Error(KeyAlreadyExistsErr, ExistingVATReportLine."VAT Registration No.")
                            else
                                SkipLine := true;
                        end;

                        if not SkipLine then begin
                            CancelVATReportLine := ExistingVATReportLine;
                            CancelVATReportLine.Base := 0;
                            CancelVATReportLine.Amount := 0;

                            EmptyVATReportLineRelation.DeleteAll();
                            ExistingVATReportLine.InsertCorrLine(
                              VATReportHeader, ExistingVATReportLine, CancelVATReportLine, EmptyVATReportLineRelation);
                        end;
                    end;
            until ExistingVATReportLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetCountryCode(VATEntry: Record "VAT Entry"): Code[10]
    begin
        exit(VATEntry."Country/Region Code");
    end;

    [Scope('OnPrem')]
    procedure GetTradeRoleType(EU3PartyTrade: Boolean): Integer
    begin
        if EU3PartyTrade then
            exit(VATReportLine."Trade Role Type"::"Intermediate Trade");

        exit(VATReportLine."Trade Role Type"::"Direct Trade");
    end;

    [Scope('OnPrem')]
    procedure UpdateNumberOfSupplies(var VATReportLine: Record "VAT Report Line"; TransactionNo: Integer)
    begin
        if not TransBuffer.Get(TransactionNo) then begin
            if VATReportLine."Line Type" = VATReportLine."Line Type"::Cancellation then
                VATReportLine."Number of Supplies" -= 1
            else
                VATReportLine."Number of Supplies" += 1;
            TransBuffer.Number := TransactionNo;
            TransBuffer.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure IsEUCountry(VATEntry: Record "VAT Entry"): Boolean
    var
        Country: Record "Country/Region";
    begin
        if VATEntry."Country/Region Code" <> '' then begin
            Country.Get(VATEntry."Country/Region Code");
            exit(Country."EU Country/Region Code" <> '');
        end;
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure AddVATReportLine(VATEntry: Record "VAT Entry")
    begin
        if not IsEUCountry(VATEntry) then
            exit;

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeader."No.";
        case VATEntry.Type of
            VATEntry.Type::Sale:
                VATReportLine."Trade Type" := VATReportLine."Trade Type"::Sale;
            VATEntry.Type::Purchase:
                VATReportLine."Trade Type" := VATReportLine."Trade Type"::Purchase;
        end;
        VATReportLine."Country/Region Code" := GetCountryCode(VATEntry);
        VATReportLine."VAT Registration No." := VATEntry."VAT Registration No.";
        VATReportLine.Base := -VATEntry.Base;
        VATReportLine.Amount := -VATEntry.Amount;
        VATReportLine."EU 3-Party Trade" := VATEntry."EU 3-Party Trade";
        VATReportLine."Trade Role Type" := GetTradeRoleType(VATEntry."EU 3-Party Trade");
        VATReportLine."EU Service" := VATEntry."EU Service";
        VATReportLine."System-Created" := true;
        AddBuffer(VATEntry);
    end;

    [Scope('OnPrem')]
    procedure UpdateProgressBar()
    begin
        RecordNo := RecordNo + 1;
        NewTime := Time;
        if (NewTime - OldTime > 100) or (NewTime < OldTime) then begin
            NewProgress := Round(RecordNo / NoOfRecords * 100, 1);
            if NewProgress <> OldProgress then begin
                OldProgress := NewProgress;
                Window.Update(2, NewProgress)
            end;
            OldTime := Time;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetFilters(var VATEntry: Record "VAT Entry")
    begin
        VATEntry.SetRange("EU Service");
        case VATReportHeader."EU Goods/Services" of
            VATReportHeader."EU Goods/Services"::Goods:
                VATEntry.SetRange("EU Service", false);
            VATReportHeader."EU Goods/Services"::Services:
                VATEntry.SetRange("EU Service", true);
        end;
        VATEntry.SetRange("VAT Reporting Date", VATReportHeader."Start Date", VATReportHeader."End Date");
    end;

    local procedure HaveDifferentRelations(VATReportLine: Record "VAT Report Line"; VATReportLineTmp: Record "VAT Report Line"): Boolean
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
    begin
        VATReportLineRelation.SetCurrentKey("VAT Report No.", "VAT Report Line No.", "Table No.", "Entry No.");
        VATReportLineRelation.SetRange("VAT Report No.", VATReportLine."VAT Report No.");
        VATReportLineRelation.SetRange("VAT Report Line No.", VATReportLine."Line No.");

        TempVATReportLineRelation.SetCurrentKey("VAT Report No.", "VAT Report Line No.", "Table No.", "Entry No.");
        TempVATReportLineRelation.SetRange("VAT Report No.", VATReportLineTmp."VAT Report No.");
        TempVATReportLineRelation.SetRange("VAT Report Line No.", VATReportLineTmp."Line No.");

        if VATReportLineRelation.Count <> TempVATReportLineRelation.Count then
            exit(true);

        if VATReportLineRelation.FindSet() and TempVATReportLineRelation.FindSet() then
            repeat
                if VATReportLineRelation."Entry No." <> TempVATReportLineRelation."Entry No." then
                    exit(true);
            until (VATReportLineRelation.Next() = 0) or (TempVATReportLineRelation.Next() = 0);

        exit(false);
    end;

    local procedure GetKeyInReport(VATReportLineToFind: Record "VAT Report Line"; var ExistingVATReportLine: Record "VAT Report Line"; VATReportNo: Code[20]; InOriginalReport: Boolean): Boolean
    begin
        ExistingVATReportLine.Reset();
        ExistingVATReportLine.SetRange("VAT Registration No.", VATReportLineToFind."VAT Registration No.");
        ExistingVATReportLine.SetRange("Country/Region Code", VATReportLineToFind."Country/Region Code");
        ExistingVATReportLine.SetRange("Registration No.", VATReportLineToFind."Registration No.");
        ExistingVATReportLine.SetRange("Trade Role Type", VATReportLineToFind."Trade Role Type");
        ExistingVATReportLine.SetRange("EU 3-Party Trade", VATReportLineToFind."EU 3-Party Trade");
        ExistingVATReportLine.SetRange("EU Service", VATReportLineToFind."EU Service");

        if InOriginalReport then begin
            ExistingVATReportLine.SetRange("VAT Report to Correct", VATReportNo);
            ExistingVATReportLine.SetRange("Able to Correct Line", true);
        end else
            ExistingVATReportLine.SetRange("VAT Report No.", VATReportNo);

        if ExistingVATReportLine.FindLast() then
            exit(true);
        exit(false);
    end;
}

