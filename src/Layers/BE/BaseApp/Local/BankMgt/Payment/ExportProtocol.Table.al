// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;
using System.Reflection;
using System.Text;

table 2000005 "Export Protocol"
{
    Caption = 'Export Protocol';
    LookupPageID = "Export Protocols";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(21; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(25; "Check Object ID"; Integer)
        {
            Caption = 'Check Object ID';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Codeunit));

            trigger OnValidate()
            begin
                CalcFields("Check Object Name");
            end;
        }
        field(26; "Check Object Name"; Text[30])
        {
            CalcFormula = lookup(AllObj."Object Name" where("Object Type" = const(Codeunit),
                                                             "Object ID" = field("Check Object ID")));
            Caption = 'Check Object Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Export Object ID"; Integer)
        {
            Caption = 'Export Object ID';
            TableRelation = if ("Export Object Type" = const(Report)) AllObj."Object ID" where("Object Type" = const(Report))
            else
            if ("Export Object Type" = const(XMLPort)) AllObj."Object ID" where("Object Type" = const(XMLport));
        }
        field(32; "Export No. Series"; Code[20])
        {
            Caption = 'Export No. Series';
            TableRelation = "No. Series".Code;
        }
        field(33; "Export Object Type"; Option)
        {
            Caption = 'Export Object Type';
            OptionCaption = 'Report,XMLPort';
            OptionMembers = "Report","XMLPort";
        }
        field(40; "Code Expenses"; Option)
        {
            Caption = 'Code Expenses';
            OptionCaption = ' ,SHA,BEN,OUR';
            OptionMembers = " ",SHA,BEN,OUR;
        }
        field(41; "Grouped Payment"; Boolean)
        {
            Caption = 'SEPA Batch Booking';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ExportAgainQst: Label 'The selected items have already been exported. Do you want to export again?';

    procedure CheckPaymentLines(var PmtJnlLine: Record "Payment Journal Line"): Boolean
    var
        PmtJnlLineToCheck: Record "Payment Journal Line";
    begin
        if ("Export Object Type" = "Export Object Type"::XMLPort) and ("Check Object ID" = 0) then
            exit(true);

        TestField("Check Object ID");
        PmtJnlLineToCheck.Copy(PmtJnlLine);
        PmtJnlLineToCheck.SetRange(Status, PmtJnlLineToCheck.Status::Created);
        exit(CODEUNIT.Run("Check Object ID", PmtJnlLineToCheck));
    end;

    [Scope('OnPrem')]
    procedure ExportPaymentLines(var PaymentJnlLine: Record "Payment Journal Line")
    var
        PmtJnlLineToExport: Record "Payment Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
        SEPACTExportFile: Codeunit "SEPA CT-Export File";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        IsHandled: Boolean;
        ShowRequestPage: Boolean;
    begin
        IsHandled := false;
        OnBeforeExportPaymentLines(Rec, PaymentJnlLine, IsHandled);
        if IsHandled then
            exit;

        if CheckPaymentLines(PaymentJnlLine) then begin
            TestField("Export Object ID");
            PmtJnlLineToExport.Copy(PaymentJnlLine);
            PmtJnlLineToExport.SetRange(Status, PmtJnlLineToExport.Status::Created);
            PmtJnlLineToExport.SetRange("Export Protocol Code", Code);
            PmtJnlLineToExport.SetRange("Journal Batch Name", PaymentJnlLine."Journal Batch Name");
            PmtJnlLineToExport.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");

            if "Export Object Type" = "Export Object Type"::Report then begin
                ShowRequestPage := true;
                OnBeforeExportPaymentLinesOnRunReport(Rec, PmtJnlLineToExport, ShowRequestPage);
                REPORT.RunModal("Export Object ID", ShowRequestPage, false, PmtJnlLineToExport);
            end else begin
                if PaymentJnlLine."Exported To File" then
                    if not Confirm(ExportAgainQst) then
                        exit;

                GenJnlLine.Reset();
                GenJnlLine.SetRange("Journal Batch Name", PaymentJnlLine."Journal Batch Name");
                GenJnlLine.SetRange("Journal Template Name", PaymentJnlLine."Journal Template Name");
                GenJnlLine.SetFilter("Line No.", SelectionFilterManagement.GetSelectionFilterForEBPaymentJournal(PmtJnlLineToExport));
                SEPACTExportFile.Export(GenJnlLine, "Export Object ID");
                PaymentJnlLine."Exported To File" := true;
                PaymentJnlLine.Modify();
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportPaymentLines(var ExportProtocol: Record "Export Protocol"; var PaymentJnlLine: Record "Payment Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportPaymentLinesOnRunReport(var ExportProtocol: Record "Export Protocol"; var PaymentJournalLine: Record "Payment Journal Line"; var ShowRequestPage: Boolean)
    begin
    end;
}

