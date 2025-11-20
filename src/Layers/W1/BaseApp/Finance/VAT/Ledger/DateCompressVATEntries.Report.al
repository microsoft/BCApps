// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using System.DataAdministration;
using System.Utilities;

report 95 "Date Compress VAT Entries"
{
    Caption = 'Date Compress VAT Entries';
    Permissions = TableData "G/L Entry" = rimd,
                  TableData "G/L Register" = rimd,
                  TableData "Date Compr. Register" = rimd,
                  TableData "G/L Entry - VAT Entry Link" = rimd,
                  TableData "VAT Entry" = rimd;
    ProcessingOnly = true;

    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            DataItemTableView = sorting(Type, Closed);
            RequestFilterFields = Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Jurisdiction Code", "Use Tax", Closed;

            trigger OnAfterGetRecord()
            begin
                VATEntry2 := "VAT Entry";
                if not VATEntry2.SetCurrentKey(Type, Closed, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") then
                    VATEntry2.SetCurrentKey(Type, Closed, "Tax Jurisdiction Code", "Use Tax", "VAT Reporting Date");
                VATEntry2.CopyFilters("VAT Entry");
                VATEntry2.SetRange(Type, VATEntry2.Type);
                VATEntry2.SetRange(Closed, VATEntry2.Closed);
                VATEntry2.SetRange("VAT Bus. Posting Group", VATEntry2."VAT Bus. Posting Group");
                VATEntry2.SetRange("VAT Prod. Posting Group", VATEntry2."VAT Prod. Posting Group");
                VATEntry2.SetRange("Tax Jurisdiction Code", VATEntry2."Tax Jurisdiction Code");
                VATEntry2.SetRange("Use Tax", VATEntry2."Use Tax");
                VATEntry2.SetFilter("VAT Reporting Date", DateComprMgt.GetDateFilter(VATEntry2."VAT Reporting Date", EntrdDateComprReg, true));
                VATEntry2.SetRange("Document Type", VATEntry2."Document Type");

                LastVATEntryNo := LastVATEntryNo + 1;

                NewVATEntry.Init();
                NewVATEntry."Entry No." := LastVATEntryNo;
                NewVATEntry.Type := VATEntry2.Type;
                NewVATEntry.Closed := VATEntry2.Closed;
                NewVATEntry."VAT Bus. Posting Group" := VATEntry2."VAT Bus. Posting Group";
                NewVATEntry."VAT Prod. Posting Group" := VATEntry2."VAT Prod. Posting Group";
                NewVATEntry."Tax Jurisdiction Code" := VATEntry2."Tax Jurisdiction Code";
                NewVATEntry."Use Tax" := VATEntry2."Use Tax";
                NewVATEntry."VAT Reporting Date" := VATEntry2.GetRangeMin("VAT Reporting Date");
                NewVATEntry."Document Type" := VATEntry2."Document Type";
                NewVATEntry."Source Code" := SourceCodeSetup."Compress VAT Entries";
                NewVATEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(VATEntry2."User ID"));
                NewVATEntry."Transaction No." := NextTransactionNo;
                Window.Update(1, NewVATEntry.Type);
                Window.Update(2, NewVATEntry."VAT Bus. Posting Group");
                Window.Update(3, NewVATEntry."VAT Prod. Posting Group");
                Window.Update(4, NewVATEntry."Tax Jurisdiction Code");
                Window.Update(5, NewVATEntry."Use Tax");
                Window.Update(6, NewVATEntry."VAT Reporting Date");
                DateComprReg."No. of New Records" := DateComprReg."No. of New Records" + 1;
                Window.Update(7, DateComprReg."No. of New Records");

                if DateComprRetainFields."Retain Document No." then begin
                    VATEntry2.SetRange("Document No.", VATEntry2."Document No.");
                    NewVATEntry."Document No." := VATEntry2."Document No.";
                end;
                if DateComprRetainFields."Retain Bill-to/Pay-to No." then begin
                    VATEntry2.SetRange("Bill-to/Pay-to No.", VATEntry2."Bill-to/Pay-to No.");
                    NewVATEntry."Bill-to/Pay-to No." := VATEntry2."Bill-to/Pay-to No.";
                end;
                if DateComprRetainFields."Retain EU 3-Party Trade" then begin
                    VATEntry2.SetRange("EU 3-Party Trade", VATEntry2."EU 3-Party Trade");
                    NewVATEntry."EU 3-Party Trade" := VATEntry2."EU 3-Party Trade";
                end;
                if DateComprRetainFields."Retain Country/Region Code" then begin
                    VATEntry2.SetRange("Country/Region Code", VATEntry2."Country/Region Code");
                    NewVATEntry."Country/Region Code" := VATEntry2."Country/Region Code";
                end;
                if DateComprRetainFields."Retain Internal Ref. No." then begin
                    VATEntry2.SetRange("Internal Ref. No.", VATEntry2."Internal Ref. No.");
                    NewVATEntry."Internal Ref. No." := VATEntry2."Internal Ref. No.";
                end;
                if DateComprRetainFields."Retain Journal Template Name" then begin
                    VATEntry2.SetRange("Journal Templ. Name", VATEntry2."Journal Templ. Name");
                    NewVATEntry."Journal Templ. Name" := VATEntry2."Journal Templ. Name";
                end;
                if VATEntry2.Base >= 0 then
                    VATEntry2.SetFilter(Base, '>=0')
                else
                    VATEntry2.SetFilter(Base, '<0');
                repeat
                    NewVATEntry.Base := NewVATEntry.Base + VATEntry2.Base;
                    NewVATEntry.Amount := NewVATEntry.Amount + VATEntry2.Amount;
                    NewVATEntry."Unrealized Amount" := NewVATEntry."Unrealized Amount" + VATEntry2."Unrealized Amount";
                    NewVATEntry."Unrealized Base" := NewVATEntry."Unrealized Base" + VATEntry2."Unrealized Base";
                    NewVATEntry."Additional-Currency Base" :=
                      NewVATEntry."Additional-Currency Base" + VATEntry2."Additional-Currency Base";
                    NewVATEntry."Additional-Currency Amount" :=
                      NewVATEntry."Additional-Currency Amount" + VATEntry2."Additional-Currency Amount";
                    NewVATEntry."Add.-Currency Unrealized Amt." :=
                      NewVATEntry."Add.-Currency Unrealized Amt." + VATEntry2."Add.-Currency Unrealized Amt.";
                    NewVATEntry."Add.-Currency Unrealized Base" :=
                      NewVATEntry."Add.-Currency Unrealized Base" + VATEntry2."Add.-Currency Unrealized Base";
                    NewVATEntry."Remaining Unrealized Amount" :=
                      NewVATEntry."Remaining Unrealized Amount" + VATEntry2."Remaining Unrealized Amount";
                    NewVATEntry."Remaining Unrealized Base" :=
                      NewVATEntry."Remaining Unrealized Base" + VATEntry2."Remaining Unrealized Base";
                    VATEntry2.Delete();
                    GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry2."Entry No.");
                    if GLEntryVATEntryLink.FindSet() then
                        repeat
                            GLEntryVATEntryLink2 := GLEntryVATEntryLink;
                            GLEntryVATEntryLink2.Delete();
                            GLEntryVATEntryLink2."VAT Entry No." := NewVATEntry."Entry No.";
                            if GLEntryVATEntryLink2.Insert() then;
                        until GLEntryVATEntryLink.Next() = 0;
                    DateComprReg."No. Records Deleted" := DateComprReg."No. Records Deleted" + 1;
                    Window.Update(8, DateComprReg."No. Records Deleted");
                    if UseDataArchive then
                        DataArchive.SaveRecord(VATEntry2);
                until VATEntry2.Next() = 0;
                NewVATEntry.Insert();

                if DateComprReg."No. Records Deleted" >= NoOfDeleted + 10 then begin
                    NoOfDeleted := DateComprReg."No. Records Deleted";
                    InsertRegisters(GLReg, DateComprReg);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if DateComprReg."No. Records Deleted" > NoOfDeleted then
                    InsertRegisters(GLReg, DateComprReg);
                if UseDataArchive then
                    DataArchive.Save();
            end;

            trigger OnPreDataItem()
            var
                LastTransactionNo: Integer;
            begin
                if EntrdDateComprReg."Ending Date" = 0D then
                    Error(Text003, EntrdDateComprReg.FieldCaption("Ending Date"));

                Window.Open(
                  Text004 +
                  Text005 +
                  Text006 +
                  Text007 +
                  Text008 +
                  Text009 +
                  Text010 +
                  Text011 +
                  Text012);

                SourceCodeSetup.Get();
                SourceCodeSetup.TestField("Compress VAT Entries");

                GLEntry.LockTable();
                NewVATEntry.LockTable();
                GLReg.LockTable();
                DateComprReg.LockTable();

                GLEntry.GetLastEntry(LastGLEntryNo, LastTransactionNo);
                NextTransactionNo := LastTransactionNo + 1;
                LastVATEntryNo := NewVATEntry.GetLastEntryNo();
                SetRange("Entry No.", 0, LastVATEntryNo);
                SetRange("VAT Reporting Date", EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");

                InitRegisters();

                if UseDataArchive then
                    DataArchive.Create(DateComprMgt.GetReportName(Report::"Date Compress VAT Entries"));
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Starting Date"""; EntrdDateComprReg."Starting Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the first date to be included in the date compression. The compression affects all VAT entries from this date to the Ending Date field.';
                    }
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Ending Date"""; EntrdDateComprReg."Ending Date")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date to be included in the date compression. The compression affects all VAT entries from the Starting Date field.';

                        trigger OnValidate()
                        var
                            DateCompression: Codeunit "Date Compression";
                        begin
                            DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
                        end;
                    }
#pragma warning disable AA0100
                    field("EntrdDateComprReg.""Period Length"""; EntrdDateComprReg."Period Length")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period Length';
                        OptionCaption = 'Day,Week,Month,Quarter,Year,Period';
                        ToolTip = 'Specifies the length of the period whose entries will be combined. To see the options, choose the field.';
                    }
                    group("Retain Field Contents")
                    {
                        Caption = 'Retain Field Contents';
                        field("Retain[1]"; DateComprRetainFields."Retain Document No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Document No.';
                            ToolTip = 'Specifies if you want to retain the contents of the Document No. field. ';
                        }
                        field("Retain[2]"; DateComprRetainFields."Retain Bill-to/Pay-to No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Bill-to/Pay-to No.';
                            ToolTip = 'Specifies whether you want to retain the contents of the Bill-to/Pay-to No. field. ';
                        }
                        field("Retain[3]"; DateComprRetainFields."Retain EU 3-Party Trade")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'EU 3-Party Trade';
                            ToolTip = 'Specifies if you want to retain the contents of the EU 3-Party Trade field. ';
                        }
                        field("Retain[4]"; DateComprRetainFields."Retain Country/Region Code")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Country/Region Code';
                            ToolTip = 'Specifies if you want to retain the address country/region field contents.';
                        }
                        field("Retain[5]"; DateComprRetainFields."Retain Internal Ref. No.")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Internal Ref. No.';
                            ToolTip = 'Specifies if you want to retain the contents of the Internal Ref. No. field.';
                        }
                        field("Retain[6]"; DateComprRetainFields."Retain Journal Template Name")
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Journal Template Name';
                            ToolTip = 'Specifies the name of the journal template that is used for the posting.';
                        }
                    }
                    field(UseDataArchiveCtrl; UseDataArchive)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Deleted Entries';
                        ToolTip = 'Specifies whether the deleted (compressed) entries will be stored in the data archive for later inspection or export.';
                        Visible = DataArchiveProviderExists;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = Action::Cancel then
                exit;
            if not ConfirmManagement.GetResponseOrDefault(CompressEntriesQst, true) then
                CurrReport.Break();
        end;

        trigger OnOpenPage()
        var
            DateCompression: Codeunit "Date Compression";
        begin
            if EntrdDateComprReg."Ending Date" = 0D then
                EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();

            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
            UseDataArchive := DataArchiveProviderExists;
        end;

        trigger OnInit()
        begin
            DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        VATEntryFilter := CopyStr("VAT Entry".GetFilters, 1, MaxStrLen(DateComprReg.Filter));

        DateCompression.VerifyDateCompressionDates(EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date");
        LogStartTelemetryMessage();
    end;

    trigger OnPostReport()
    begin
        LogEndTelemetryMessage();
    end;

    var
        SourceCodeSetup: Record "Source Code Setup";
        DateComprReg: Record "Date Compr. Register";
        DateComprRetainFields: Record "Date Compr. Retain Fields";
        GLReg: Record "G/L Register";
        NewVATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        GLEntryVATEntryLink2: Record "G/L Entry - VAT Entry Link";
        DateComprMgt: Codeunit DateComprMgt;
        DataArchive: Codeunit "Data Archive";
        Window: Dialog;
        VATEntryFilter: Text[250];
        LastGLEntryNo: Integer;
        LastVATEntryNo: Integer;
        NextTransactionNo: Integer;
        NoOfDeleted: Integer;
        GLRegExists: Boolean;
        UseDataArchive: Boolean;
        DataArchiveProviderExists: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label '%1 must be specified.';
#pragma warning restore AA0470
        Text004: Label 'Date compressing VAT entries...\\';
#pragma warning disable AA0470
        Text005: Label 'Type                     #1##########\';
        Text006: Label 'VAT Bus. Posting Group   #2##########\';
        Text007: Label 'VAT Prod. Posting Group  #3##########\';
        Text008: Label 'Tax Jurisdiction         #4##########\';
        Text009: Label 'Use Tax                  #5##########\';
        Text010: Label 'Date                     #6######\\';
        Text011: Label 'No. of new entries       #7######\';
        Text012: Label 'No. of entries deleted   #8######';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CompressEntriesQst: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        StartDateCompressionTelemetryMsg: Label 'Running date compression report %1 %2.', Locked = true;
        EndDateCompressionTelemetryMsg: Label 'Completed date compression report %1 %2.', Locked = true;

    protected var
        EntrdDateComprReg: Record "Date Compr. Register";

    local procedure InitRegisters()
    begin
        GLReg.Initialize(GLReg.GetLastEntryNo() + 1, LastGLEntryNo + 1, LastVATEntryNo + 1, SourceCodeSetup."Compress Vend. Ledger", '', '');

        DateComprReg.InitRegister(
          DATABASE::"VAT Entry", DateComprReg.GetLastEntryNo() + 1, EntrdDateComprReg."Starting Date", EntrdDateComprReg."Ending Date",
          EntrdDateComprReg."Period Length", VATEntryFilter, GLReg."No.", SourceCodeSetup."Compress VAT Entries");

        if DateComprRetainFields."Retain Document No." then
            AddFieldContent(NewVATEntry.FieldName("Document No."));
        if DateComprRetainFields."Retain Bill-to/Pay-to No." then
            AddFieldContent(NewVATEntry.FieldName("Bill-to/Pay-to No."));
        if DateComprRetainFields."Retain EU 3-Party Trade" then
            AddFieldContent(NewVATEntry.FieldName("EU 3-Party Trade"));
        if DateComprRetainFields."Retain Country/Region Code" then
            AddFieldContent(NewVATEntry.FieldName("Country/Region Code"));
        if DateComprRetainFields."Retain Internal Ref. No." then
            AddFieldContent(NewVATEntry.FieldName("Internal Ref. No."));
        if DateComprRetainFields."Retain Journal Template Name" then
            AddFieldContent(NewVATEntry.FieldName("Journal Templ. Name"));

        DateComprReg."Retain Field Contents" := CopyStr(DateComprReg."Retain Field Contents", 2);

        GLRegExists := false;
        NoOfDeleted := 0;
    end;

    local procedure AddFieldContent(FieldName: Text)
    begin
        DateComprReg."Retain Field Contents" :=
            CopyStr(
                DateComprReg."Retain Field Contents" + ',' + FieldName, 1, MaxStrLen(DateComprReg."Retain Field Contents"));
    end;

    local procedure InsertRegisters(var GLReg: Record "G/L Register"; var DateComprReg: Record "Date Compr. Register")
    var
        FoundLastEntryNo: Integer;
        FoundLastVATEntryNo: Integer;
        LastTransactionNo: Integer;
    begin
        GLEntry.Init();
        LastGLEntryNo := LastGLEntryNo + 1;
        GLEntry."Entry No." := LastGLEntryNo;
        GLEntry."Posting Date" := Today;
        GLEntry."VAT Reporting Date" := Today();
        GLEntry."Source Code" := SourceCodeSetup."Compress VAT Entries";
        GLEntry."System-Created Entry" := true;
        GLEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLEntry."User ID"));
        GLEntry."Transaction No." := NextTransactionNo;
        GLEntry.Insert();
        GLEntry.Consistent(GLEntry.Amount = 0);
        GLReg."To Entry No." := LastGLEntryNo;
        GLReg."To VAT Entry No." := NewVATEntry."Entry No.";

        if GLRegExists then begin
            GLReg.Modify();
            DateComprReg.Modify();
        end else begin
            GLReg.Insert();
            DateComprReg.Insert();
            GLRegExists := true;
        end;
        Commit();

        GLEntry.LockTable();
        NewVATEntry.LockTable();
        GLReg.LockTable();
        DateComprReg.LockTable();

        GLentry.GetLastEntry(FoundLastEntryNo, LastTransactionNo);
        FoundLastVATEntryNo := NewVATEntry.GetLastEntryNo();
        if (LastGLEntryNo <> FoundLastEntryNo) or
           (LastVATEntryNo <> FoundLastVATEntryNo)
        then begin
            LastGLEntryNo := FoundLastEntryNo;
            LastVATEntryNo := FoundLastVATEntryNo;
            NextTransactionNo := LastTransactionNo + 1;
            InitRegisters();
        end;
    end;

    local procedure InitializeParameter()
    var
        DateCompression: Codeunit "Date Compression";
    begin
        if EntrdDateComprReg."Ending Date" = 0D then
            EntrdDateComprReg."Ending Date" := DateCompression.CalcMaxEndDate();
    end;

    procedure InitializeRequest(StartingDate: Date; EndingDate: Date; PeriodLength: Option; NewDateComprRetainFields: Record "Date Compr. Retain Fields"; DoUseDataArchive: Boolean)
    begin
        InitializeParameter();
        EntrdDateComprReg."Starting Date" := StartingDate;
        EntrdDateComprReg."Ending Date" := EndingDate;
        EntrdDateComprReg."Period Length" := PeriodLength;
        DateComprRetainFields := NewDateComprRetainFields;
        DataArchiveProviderExists := DataArchive.DataArchiveProviderExists();
        UseDataArchive := DataArchiveProviderExists and DoUseDataArchive;
    end;

    local procedure LogStartTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('UseRequestPage', Format(CurrReport.UseRequestPage()));
        TelemetryDimensions.Add('StartDate', Format(EntrdDateComprReg."Starting Date", 0, 9));
        TelemetryDimensions.Add('EndDate', Format(EntrdDateComprReg."Ending Date", 0, 9));
        TelemetryDimensions.Add('PeriodLength', Format(EntrdDateComprReg."Period Length", 0, 9));
        TelemetryDimensions.Add('RetainDocumentNo', Format(DateComprRetainFields."Retain Document No.", 0, 9));
        TelemetryDimensions.Add('RetainBilltoPaytoNo', Format(DateComprRetainFields."Retain Bill-to/Pay-to No.", 0, 9));
        TelemetryDimensions.Add('RetainEU3PartyTrade', Format(DateComprRetainFields."Retain EU 3-Party Trade", 0, 9));
        TelemetryDimensions.Add('RetainCountryRegionCode', Format(DateComprRetainFields."Retain Country/Region Code", 0, 9));
        TelemetryDimensions.Add('RetainInternalRefNo', Format(DateComprRetainFields."Retain Internal Ref. No.", 0, 9));
        TelemetryDimensions.Add('RetainJnlTemplateName', Format(DateComprRetainFields."Retain Journal Template Name", 0, 9));
        TelemetryDimensions.Add('UseDataArchive', Format(UseDataArchive));

        Session.LogMessage('0000F4W', StrSubstNo(StartDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

    local procedure LogEndTelemetryMessage()
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('RegisterNo', Format(DateComprReg."Register No.", 0, 9));
        TelemetryDimensions.Add('TableID', Format(DateComprReg."Table ID", 0, 9));
        TelemetryDimensions.Add('NoRecordsDeleted', Format(DateComprReg."No. Records Deleted", 0, 9));
        TelemetryDimensions.Add('NoofNewRecords', Format(DateComprReg."No. of New Records", 0, 9));

        Session.LogMessage('0000F4X', StrSubstNo(EndDateCompressionTelemetryMsg, CurrReport.ObjectId(false), CurrReport.ObjectId(true)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, TelemetryDimensions);
    end;

}

