// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using Microsoft.Utilities;
using System.Email;
using System.IO;
using System.Reflection;
using System.Threading;
using System.Utilities;

table 77 "Report Selections"
{
    Caption = 'Report Selections';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Usage; Enum "Report Selection Usage")
        {
            Caption = 'Usage';
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
            ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
            ToolTip = 'Specifies the object ID of the report.';

            trigger OnValidate()
            begin
                Calcfields("Report Caption");
                Validate("Use for Email Body", false);
                Validate("Report Layout Name", '');
            end;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = lookup("Report Metadata".Caption where(ID = field("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = Flowfield;
            ToolTip = 'Specifies the display name of the report.';
        }
        field(7; "Custom Report Layout Code"; Code[20])
        {
            Caption = 'Custom Report Layout Code';
            Editable = false;
            TableRelation = "Custom Report Layout".Code where(Code = field("Custom Report Layout Code"), "Built-In" = const(false));
        }
        field(19; "Use for Email Attachment"; Boolean)
        {
            Caption = 'Use for Email Attachment';
            InitValue = true;
            ToolTip = 'Specifies that the related document will be attached to the email.';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then begin
                    "Email Body Layout Code" := '';
                    "Email Body Layout Name" := '';
                end;
            end;
        }
        field(20; "Use for Email Body"; Boolean)
        {
            Caption = 'Use for Email Body';
            ToolTip = 'Specifies that summarized information, such as invoice number, due date, and payment service link, will be inserted in the body of the email that you send.';

            trigger OnValidate()
            begin
                if not "Use for Email Body" then begin
                    "Email Body Layout Code" := '';
                    "Email Body Layout Name" := '';
                end;
            end;
        }
        field(21; "Email Body Layout Code"; Code[20])
        {
            Caption = 'Email Body Custom Layout Code';
            TableRelation = if ("Email Body Layout Type" = const("Custom Report Layout")) "Custom Report Layout".Code where(Code = field("Email Body Layout Code"), "Report ID" = field("Report ID"), "Built-In" = const(false))
            else
            if ("Email Body Layout Type" = const("HTML Layout")) "O365 HTML Template".Code;
            ToolTip = 'Specifies the ID of the custom email body layout that is used.';

            trigger OnValidate()
            begin
                if "Email Body Layout Code" <> '' then begin
                    Testfield("Use for Email Body", true);
                    "Email Body Layout Name" := '';
                end;
                Calcfields("Email Body Layout Description");
            end;
        }
        field(22; "Email Body Layout Description"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Email Body Layout Code")));
            Caption = 'Email Body Custom Layout Description';
            Editable = false;
            FieldClass = Flowfield;
            ToolTip = 'Specifies a description of the custom email body layout that is used.';

            trigger OnLookup()
            var
                CustomReportLayout: Record "Custom Report Layout";
            begin
                if "Email Body Layout Type" = "Email Body Layout Type"::"Custom Report Layout" then
                    if CustomReportLayout.LookupLayoutOK("Report ID") then
                        Validate("Email Body Layout Code", CustomReportLayout.Code);
            end;
        }
        field(25; "Email Body Layout Type"; Enum "Email Body Layout Type")
        {
            Caption = 'Email Body Layout Type';
        }
        field(26; "Email Body Layout Name"; Text[250])
        {
            Caption = 'Email Body Layout Name';
            TableRelation = "Report Layout List".Name where("Report ID" = field("Report ID"));
            ToolTip = 'Specifies the name of the email body layout that is used.';

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Email Body Layout Name" := ReportLayoutList.Name;
                "Email Body Layout AppID" := ReportLayoutList."Application ID";
            end;

            trigger OnValidate()
            var
                ReportLayoutList: Record "Report Layout List";
            begin
                if "Email Body Layout Name" <> '' then begin
                    "Use for Email Body" := true;
                    "Email Body Layout Code" := '';
                    "Email Body Layout Description" := '';
                    ReportLayoutList.SetRange(Name, "Email Body Layout Name");
                    ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                    if not IsNullGuid("Email Body Layout AppID") then
                        ReportLayoutList.SetRange("Application ID", "Email Body Layout AppID");
                    if not ReportLayoutList.FindFirst() then begin
                        ReportLayoutList.SetRange("Application ID");
                        ReportLayoutList.FindFirst();
                    end;
                    if IsNullGuid("Email Body Layout AppID") then
                        Rec."Email Body Layout AppID" := ReportLayoutList."Application ID";
                end;
            end;
        }
        field(27; "Email Body Layout AppID"; Guid)
        {
            Caption = 'Email Body Layout AppID';
            TableRelation = "Report Layout List"."Application ID" where("Report ID" = field("Report ID"));
        }
        field(28; "Email Body Layout Publisher"; Text[250])
        {
            Caption = 'Email Body Layout Publisher';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Layout List"."Layout Publisher" where("Report ID" = field("Report ID"), Name = field("Email Body Layout Name")));
            Editable = false;
            ToolTip = 'Specifies the publisher of the email body layout that is used.';
        }
        field(29; "Email Body Layout Caption"; Text[250])
        {
            Caption = 'Email Body Layout';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Layout List".Caption where("Report ID" = field("Report ID"), Name = field("Email Body Layout Name")));

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Email Body Layout Name" := ReportLayoutList.Name;
                "Email Body Layout AppID" := ReportLayoutList."Application ID";
            end;
        }
        field(30; "Report Layout Name"; Text[250])
        {
            Caption = 'Report Layout name';
            TableRelation = "Report Layout List".Name where("Report ID" = field("Report ID"));
            ToolTip = 'Specifies the name of the report layout that is used.';

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Report Layout Name" := ReportLayoutList.Name;
                "Report Layout AppID" := ReportLayoutList."Application ID";
            end;

            trigger OnValidate()
            var
                ReportLayoutList: Record "Report Layout List";
            begin
                Clear("Report Layout AppID");
                if "Report Layout Name" <> '' then begin
                    "Use for Email Attachment" := true;
                    ReportLayoutList.SetRange(Name, "Report Layout Name");
                    ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                    if not IsNullGuid("Report Layout AppID") then
                        ReportLayoutList.SetRange("Application ID", "Report Layout AppID");
                    if not ReportLayoutList.FindFirst() then begin
                        ReportLayoutList.SetRange("Application ID");
                        ReportLayoutList.FindFirst();
                    end;
                    if IsNullGuid("Report Layout AppID") then
                        Rec."Report Layout AppID" := ReportLayoutList."Application ID";
                end;
            end;
        }
        field(31; "Report Layout AppID"; Guid)
        {
            Caption = 'Report Layout App ID';
            Editable = false;
        }
        field(32; "Report Layout Caption"; Text[250])
        {
            Caption = 'Report Layout';
            ToolTip = 'Specifies the Name of the report layout that is used.';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Layout List".Caption where("Report ID" = field("Report ID"), Name = field("Report Layout Name")));

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Rec."Report ID");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Report Layout Name" := ReportLayoutList.Name;
                "Report Layout AppID" := ReportLayoutList."Application ID";
                if "Report Layout Name" <> '' then
                    "Use for Email Attachment" := true;
            end;
        }
        field(33; "Report Layout Publisher"; Text[250])
        {
            Caption = 'Report Layout Publisher';
            ToolTip = 'Specifies the publisher of the email Attachment layout that is used.';
            FieldClass = FlowField;
            CalcFormula = lookup("Report Layout List"."Layout Publisher" where("Report ID" = field("Report ID"), "Application ID" = field("Report Layout AppID")));
            Editable = false;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Testfield("Report ID");
        CheckEmailBodyUsage();
    end;

    trigger OnModify()
    begin
        Testfield("Report ID");
        CheckEmailBodyUsage();
    end;

    var
        ReportSelection2: Record "Report Selections";
        ReportLayoutSelection: Record "Report Layout Selection";
        FileManagement: Codeunit "File Management";
        MustSelectAndEmailBodyOrAttahmentErr: Label 'You must select an email body or attachment in report selection for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        EmailBodyIsAlreadyDefinedErr: Label 'An email body is already defined for %1.', Comment = '%1 = Usage, for example Sales Invoice';
        CannotBeUsedAsAnEmailBodyErr: Label 'Report %1 uses the %2 which cannot be used as an email body.', Comment = '%1 = Report ID,%2 = Type';
        AccountNoTok: Label '''%1''', Locked = true;
        MailingJobCategoryTok: Label 'Sending invoices via email';
        MailingJobCategoryCodeTok: Label 'SENDINV', Comment = 'Must be max. 10 chars and no spacing. (Send Invoice)';
        RecordDoesNotMatchErr: Label 'The record that will be sent does not match the original record. The original record was changed or deleted. Please verify that the record exists, or try to re-send the remittance advice from the vendor ledger entries.';
        JobQueueParameterStringTok: Label '%1|%2|%3|%4|%5|%6', Locked = true;
        ReportSelectionsMustBeTemporaryErr: Label 'The Report Selections parameter must be temporary.';
        ReminderAndSalesInvoiceErr: Label 'The Reminder report cannot be used with Sales Invoices';

    procedure NewRecord()
    begin
        OnBeforeNewRecord(Rec, ReportSelection2);

        ReportSelection2.SetRange(Usage, Usage);
        if ReportSelection2.FindLast() and (ReportSelection2.Sequence <> '') then
            Sequence := IncStr(ReportSelection2.Sequence)
        else
            Sequence := '1';
    end;

    procedure InsertRecord(NewUsage: Enum "Report Selection Usage"; NewSequence: Code[10]; NewReportID: Integer)
    begin
        Init();
        Usage := NewUsage;
        Sequence := NewSequence;
        "Report ID" := NewReportID;
        Insert();
    end;

    local procedure CheckEmailBodyUsage()
    var
        ReportSelections: Record "Report Selections";
        ShowEmailBodyDefinedError: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmailBodyUsage(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Use for Email Body" then begin
            ReportSelections.SetEmailBodyUsageFilters(Usage);
            ReportSelections.SetFilter(Sequence, '<>%1', Sequence);
            ShowEmailBodyDefinedError := not ReportSelections.IsEmpty();
            OnCheckEmailBodyUsageOnAfterCalcShowEmailBodyDefinedError(Rec, ReportSelections, ShowEmailBodyDefinedError);
            if ShowEmailBodyDefinedError then
                Error(EmailBodyIsAlreadyDefinedErr, Usage);

            if ("Email Body Layout Code" = '') and ("Email Body Layout Name" = '') then
                if ReportLayoutSelection.GetDefaultType("Report ID") =
                   ReportLayoutSelection.Type::"RDLC (built-in)"
                then
                    Error(CannotBeUsedAsAnEmailBodyErr, "Report ID", ReportLayoutSelection.Type);
        end;
    end;

    procedure DrillDownToSelectLayout(var SelectedLayoutName: Text[250]; var SelectedLayoutAppID: Guid)
    var
        ReportLayoutListSelection: Record "Report Layout List";
        ReportManagementCodeunit: Codeunit ReportManagement;
        IsReportLayoutSelected: Boolean;
    begin
        ReportLayoutListSelection.SetRange("Report ID", Rec."Report ID");
        ReportManagementCodeunit.OnSelectReportLayout(ReportLayoutListSelection, IsReportLayoutSelected);
        if IsReportLayoutSelected then begin
            SelectedLayoutName := ReportLayoutListSelection."Name";
            SelectedLayoutAppID := ReportLayoutListSelection."Application ID";
        end;
    end;

    procedure SetEmailUsageFilters(ReportUsage: Enum "Report Selection Usage")
    begin
        Reset();
        SetRange(Usage, ReportUsage);
        SetRange("Use for Email Body", true);

        OnAfterSetEmailUsageFilters(Rec, ReportUsage);
    end;

    procedure SetEmailBodyUsageFilters(ReportUsage: Enum "Report Selection Usage")
    begin
        Reset();
        SetRange(Usage, ReportUsage);
        SetRange("Use for Email Body", true);

        OnAfterSetEmailBodyUsageFilters(Rec, ReportUsage);
    end;

    procedure SetEmailAttachmentUsageFilters(ReportUsage: Enum "Report Selection Usage")
    begin
        Reset();
        SetRange(Usage, ReportUsage);
        SetRange("Use for Email Attachment", true);

        OnAfterSetEmailAttachmentUsageFilters(Rec, ReportUsage);
    end;

    procedure FindReportUsageForCust(ReportUsage: Enum "Report Selection Usage"; CustNo: Code[20]; var ReportSelections: Record "Report Selections" temporary)
    begin
        FindPrintUsageInternal(ReportUsage, CustNo, ReportSelections, Database::Customer);
    end;

    procedure FindReportUsageForVend(ReportUsage: Enum "Report Selection Usage"; VendorNo: Code[20]; var ReportSelections: Record "Report Selections" temporary)
    begin
        FindPrintUsageInternal(ReportUsage, VendorNo, ReportSelections, Database::Vendor);
    end;

    local procedure FindPrintUsageInternal(ReportUsage: Enum "Report Selection Usage"; AccountNo: Code[20]; var TempReportSelections: Record "Report Selections" temporary; TableNo: Integer)
    begin
        Reset();
        SetRange(Usage, ReportUsage);
        SetFilter("Report ID", '<>0');
        FindReportSelections(TempReportSelections, AccountNo, TableNo);
        TempReportSelections.FindSet();
    end;

    procedure FindEmailAttachmentUsageForCust(ReportUsage: Enum "Report Selection Usage"; CustNo: Code[20]; var TempReportSelections: Record "Report Selections" temporary): Boolean
    begin
        SetEmailAttachmentUsageFilters(ReportUsage);
        SetFilter("Report ID", '<>0');
        SetRange("Use for Email Attachment", true);
        FindReportSelections(TempReportSelections, CustNo, Database::Customer);
        exit(TempReportSelections.FindSet());
    end;

    procedure FindEmailAttachmentUsageForVend(ReportUsage: Enum "Report Selection Usage"; VendorNo: Code[20]; var TempReportSelections: Record "Report Selections" temporary): Boolean
    begin
        SetEmailAttachmentUsageFilters(ReportUsage);
        SetFilter("Report ID", '<>0');
        SetRange("Use for Email Attachment", true);
        FindReportSelections(TempReportSelections, VendorNo, Database::Vendor);
        exit(TempReportSelections.FindSet());
    end;

    procedure FindEmailBodyUsageForCust(ReportUsage: Enum "Report Selection Usage"; CustNo: Code[20]; var TempReportSelections: Record "Report Selections" temporary): Boolean
    begin
        SetEmailBodyUsageFilters(ReportUsage);
        SetFilter("Report ID", '<>0');
        FindReportSelections(TempReportSelections, CustNo, Database::Customer);
        exit(TempReportSelections.FindSet());
    end;

    procedure FindEmailBodyUsageForVend(ReportUsage: Enum "Report Selection Usage"; VendorNo: Code[20]; var TempReportSelections: Record "Report Selections" temporary): Boolean
    begin
        SetEmailBodyUsageFilters(ReportUsage);
        SetFilter("Report ID", '<>0');
        FindReportSelections(TempReportSelections, VendorNo, Database::Vendor);
        exit(TempReportSelections.FindSet());
    end;

    procedure PrintWithCheckForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithCheck(ReportUsage.AsInteger(), RecordVariant, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintWithDialogWithCheckForCust(ReportUsage, RecordVariant, true, CustomerNoFieldNo);
    end;

    procedure PrintWithDialogWithCheckForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNoWithCheck(ReportUsage.AsInteger(), RecordVariant, IsGUI, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintDocumentsWithCheckDialogCommon(
          ReportUsage, RecordVariant, IsGUI, CustomerNoFieldNo, true, Database::Customer);
    end;

    procedure PrintWithCheckForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; VendorNoFieldNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintWithCheckForVend(ReportUsage, RecordVariant, VendorNoFieldNo, IsHandled);
        if IsHandled then
            exit;

        PrintWithDialogWithCheckForVend(ReportUsage, RecordVariant, true, VendorNoFieldNo);
    end;

    procedure PrintWithDialogWithCheckForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; IsGUI: Boolean; VendorNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNoWithCheckVendor(ReportUsage.AsInteger(), RecordVariant, IsGUI, VendorNoFieldNo, Handled);
        if Handled then
            exit;

        PrintDocumentsWithCheckDialogCommon(
          ReportUsage, RecordVariant, IsGUI, VendorNoFieldNo, true, Database::Vendor);
    end;

    procedure PrintReport(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant)
    begin
        PrintForCust(ReportUsage, RecordVariant, 0);
    end;

    procedure PrintForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrint(ReportUsage.AsInteger(), RecordVariant, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintWithDialogForCust(ReportUsage, RecordVariant, true, CustomerNoFieldNo);
    end;

    procedure PrintWithDialogForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNo(ReportUsage.AsInteger(), RecordVariant, IsGUI, CustomerNoFieldNo, Handled);
        if Handled then
            exit;

        PrintDocumentsWithCheckDialogCommon(
          ReportUsage, RecordVariant, IsGUI, CustomerNoFieldNo, false, Database::Customer);
    end;

    procedure PrintWithDialogForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; IsGUI: Boolean; VendorNoFieldNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforePrintWithGUIYesNoVendor(ReportUsage.AsInteger(), RecordVariant, IsGUI, VendorNoFieldNo, Handled);
        if Handled then
            exit;

        PrintDocumentsWithCheckDialogCommon(
          ReportUsage, RecordVariant, IsGUI, VendorNoFieldNo, false, Database::Vendor);
    end;

    local procedure PrintDocumentsWithCheckDialogCommon(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; IsGUI: Boolean; AccountNoFieldNo: Integer; WithCheck: Boolean; TableNo: Integer)
    var
        TempReportSelections: Record "Report Selections" temporary;
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        RecVarToPrint: Variant;
        AccountNoFilter: Text;
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());

        RecRef.GetTable(RecordVariant);
        GetUniqueAccountNos(TempNameValueBuffer, RecRef, AccountNoFieldNo);

        SelectTempReportSelectionsToPrint(TempReportSelections, TempNameValueBuffer, WithCheck, ReportUsage, TableNo);
        OnPrintDocumentsOnAfterSelectTempReportSelectionsToPrint(
          RecordVariant, TempReportSelections, TempNameValueBuffer, WithCheck, ReportUsage.AsInteger(), TableNo);
        if TempReportSelections.FindSet() then
            repeat
                ReportLayoutSelection.ClearTempLayoutSelected();
                if TempReportSelections."Report Layout Name" <> '' then
                    ReportLayoutSelection.SetTempLayoutSelectedName(TempReportSelections."Report Layout Name", TempReportSelections."Report Layout AppID")
                else
                    if TempReportSelections."Custom Report Layout Code" <> '' then
                        ReportLayoutSelection.SetTempLayoutSelected(TempReportSelections."Custom Report Layout Code");

                TempNameValueBuffer.FindSet();
                AccountNoFilter := GetAccountNoFilterForCustomReportLayout(TempReportSelections, TempNameValueBuffer, TableNo);
                GetFilteredRecordRef(RecRefToPrint, RecRef, AccountNoFieldNo, AccountNoFilter);
                RecVarToPrint := RecRefToPrint;

                IsHandled := false;
                OnBeforePrintDocument(TempReportSelections, IsGUI, RecVarToPrint, IsHandled);
                if not IsHandled then begin
                    if IsGUI then
                        Commit();
                    REPORT.RunModal(TempReportSelections."Report ID", IsGUI, false, RecVarToPrint);
                end;

                OnAfterPrintDocument(TempReportSelections, IsGUI, RecVarToPrint, IsHandled);

                ReportLayoutSelection.ClearTempLayoutSelected();
            until TempReportSelections.Next() = 0;

        OnAfterPrintDocumentsWithCheckGUIYesNoCommon(ReportUsage.AsInteger(), RecVarToPrint);
    end;

    procedure GetFilteredRecordRef(var RecRefToPrint: RecordRef; RecRefSource: RecordRef; AccountNoFieldNo: Integer; AccountNoFilter: Text)
    var
        AccountNofieldRef: FieldRef;
    begin
        RecRefToPrint := RecRefSource.Duplicate();

        if (AccountNoFieldNo <> 0) and (AccountNoFilter <> '') then begin
            AccountNofieldRef := RecRefToPrint.field(AccountNoFieldNo);
            AccountNofieldRef.SetFilter(AccountNoFilter);
        end;

        if RecRefToPrint.FindSet() then;
    end;

    procedure GetAccountNoFilterForCustomReportLayout(var TempReportSelections: Record "Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; TableNo: Integer): Text
    var
        CustomReportSelection: Record "Custom Report Selection";
        AccountNo: Code[20];
        AccountNoFilter: Text;
        AccountHasCustomSelection: Boolean;
        ReportInvolvedInCustomSelection: Boolean;
    begin
        CustomReportSelection.SetRange("Source Type", TableNo);
        CustomReportSelection.SetRange(Usage, TempReportSelections.Usage);
        CustomReportSelection.SetRange("Report ID", TempReportSelections."Report ID");
        OnGetAccountNoFilterForCustomReportLayoutOnAfterSetCustomReportSelectionFilters(CustomReportSelection, TempReportSelections);

        ReportInvolvedInCustomSelection := not CustomReportSelection.IsEmpty();

        AccountNoFilter := '';

        TempNameValueBuffer.FindSet();
        repeat
            AccountNo := CopyStr(TempNameValueBuffer.Name, 1, MaxStrLen(AccountNo));
            CustomReportSelection.SetRange("Source No.", AccountNo);

            if ReportInvolvedInCustomSelection then begin
                CustomReportSelection.SetRange("Custom Report Layout Code", TempReportSelections."Custom Report Layout Code");

                AccountHasCustomSelection := not CustomReportSelection.IsEmpty();
                if AccountHasCustomSelection then
                    AccountNoFilter += StrSubstNo(AccountNoTok, AccountNo) + '|';

                CustomReportSelection.SetRange("Custom Report Layout Code");
            end else begin
                CustomReportSelection.SetRange("Report ID");

                AccountHasCustomSelection := not CustomReportSelection.IsEmpty();
                if not AccountHasCustomSelection then
                    AccountNoFilter += StrSubstNo(AccountNoTok, AccountNo) + '|';

                CustomReportSelection.SetRange("Report ID", TempReportSelections."Report ID");
            end;

        until TempNameValueBuffer.Next() = 0;

        AccountNoFilter := DelChr(AccountNoFilter, '>', '|');
        exit(AccountNoFilter);
    end;

    procedure SelectTempReportSelections(var TempReportSelections: Record "Report Selections" temporary; AccountNo: Code[20]; WithCheck: Boolean; ReportUsage: Enum "Report Selection Usage"; TableNo: Integer)
    begin
        if WithCheck then begin
            Reset();
            SetRange(Usage, ReportUsage);
            FindReportSelections(TempReportSelections, AccountNo, TableNo);
            if not TempReportSelections.FindSet() then
                FindSet();
        end else
            FindPrintUsageInternal(ReportUsage, AccountNo, TempReportSelections, TableNo);
    end;

    procedure SelectTempReportSelectionsToPrint(var TempReportSelections: Record "Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; WithCheck: Boolean; ReportUsage: Enum "Report Selection Usage"; TableNo: Integer)
    var
        TempReportSelectionsAccount: Record "Report Selections" temporary;
        AccountNo: Code[20];
        LastSequence: Code[10];
    begin
        if TempNameValueBuffer.FindSet() then
            repeat
                AccountNo := CopyStr(TempNameValueBuffer.Name, 1, MaxStrLen(AccountNo));
                TempReportSelectionsAccount.Reset();
                TempReportSelectionsAccount.DeleteAll();
                SelectTempReportSelections(TempReportSelectionsAccount, AccountNo, WithCheck, ReportUsage, TableNo);
                if TempReportSelectionsAccount.FindSet() then
                    repeat
                        LastSequence := GetLastSequenceNo(TempReportSelections, ReportUsage);
                        if not HasReportWithUsage(TempReportSelections, ReportUsage, TempReportSelectionsAccount."Report ID") then begin
                            TempReportSelections := TempReportSelectionsAccount;
                            if LastSequence = '' then
                                TempReportSelections.Sequence := '1'
                            else
                                TempReportSelections.Sequence := IncStr(LastSequence);
                            TempReportSelections.Insert();
                        end;
                    until TempReportSelectionsAccount.Next() = 0;
            until TempNameValueBuffer.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure GetHtmlReportForCust(var DocumentContent: Text; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        EmailBody: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        IsHandled: Boolean;
        FileInStream: InStream;
    begin
        IsHandled := false;
        OnBeforeGetHtmlReport(DocumentContent, ReportUsage.AsInteger(), RecordVariant, CustNo, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnGetHtmlReportForCustOnBeforeFindReportUsage(Rec, ReportUsage, RecordVariant, CustNo, TempBodyReportSelections, IsHandled);
        if not IsHandled then
            FindReportUsageForCust(ReportUsage, CustNo, TempBodyReportSelections);

        SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Custom Report Layout Code", ReportUsage, EmailBody);

        DocumentContent := '';
        if EmailBody.HasValue() then begin
            EmailBody.CreateInStream(FileInStream, TextEncoding::UTF8);
            DocumentContent := TypeHelper.ReadAsTextWithSeparator(FileInStream, '');
        end;
    end;

    [Scope('OnPrem')]
    procedure GetPdfReportForCust(var ServerEmailBodyFilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
    begin
        ServerEmailBodyFilePath := '';

        FindReportUsageForCust(ReportUsage, CustNo, TempBodyReportSelections);

        ServerEmailBodyFilePath :=
            SaveReportAsPDF(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Custom Report Layout Code", ReportUsage);
    end;

    procedure GetPdfReportForCust(var TempBlob: Codeunit "Temp Blob"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20])
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
    begin
        FindReportUsageForCust(ReportUsage, CustNo, TempBodyReportSelections);

        SaveReportAsPDFInTempBlob(TempBlob, TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Custom Report Layout Code", ReportUsage);
    end;

#if not CLEAN27
    [Scope('OnPrem')]
    [Obsolete('Replaced with GetEmailBodyForCust that accepts a TempBlob as parameter.', '27.0')]
    procedure GetEmailBodyForCust(var ServerEmailBodyFilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text[250]): Boolean
    begin
        exit(
            GetEmailBodyTextForCust(
                ServerEmailBodyFilePath, ReportUsage, RecordVariant, CustNo, CustEmailAddress, ''));
    end;

    [Scope('OnPrem')]
    [Obsolete('Replaced with GetEmailBodyTextForCust that accepts a TempBlob as parameter.', '27.0')]
    procedure GetEmailBodyTextForCust(var ServerEmailBodyFilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text[250]; EmailBodyText: Text) Result: Boolean
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        IsHandled: Boolean;
        EmailBodyUsageFound: Boolean;
        EmailBody: Codeunit "Temp Blob";
    begin
        ServerEmailBodyFilePath := '';

        IsHandled := false;
        OnBeforeGetEmailBodyCustomer(
            ReportUsage.AsInteger(), RecordVariant, TempBodyReportSelections, CustNo, CustEmailAddress, EmailBodyText, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if CustEmailAddress = '' then
            CustEmailAddress := GetEmailAddressIgnoringLayout(ReportUsage, RecordVariant, CustNo);

        IsHandled := false;
        OnGetEmailBodyTextForCustOnBeforeFindEmailBodyUsageForCust(Rec, ReportUsage, RecordVariant, CustNo, TempBodyReportSelections, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FindEmailBodyUsageForCust(ReportUsage, CustNo, TempBodyReportSelections) then begin
            IsHandled := false;
            EmailBodyUsageFound := false;
            OnGetEmailBodyCustomerTextOnAfterNotFindEmailBodyUsage(
                ReportUsage.AsInteger(), RecordVariant, CustNo, TempBodyReportSelections, IsHandled, EmailBodyUsageFound);
            if not EmailBodyUsageFound then begin
                if IsHandled then
                    exit(true);
                exit(false);
            end;
        end;

        case "Email Body Layout Type" of
            "Email Body Layout Type"::"Custom Report Layout":
                if TempBodyReportSelections."Email Body Layout Code" <> '' then
                    SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Code", ReportUsage, EmailBody)
                else
                    SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Name", TempBodyReportSelections."Email Body Layout AppID", ReportUsage, EmailBody);
            "Email Body Layout Type"::"HTML Layout":
                O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(Rec, RecordVariant, CustEmailAddress, EmailBodyText, EmailBody);
        end;
        ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBody, 'html');

        CustEmailAddress := GetEmailAddress(ReportUsage, RecordVariant, CustNo, TempBodyReportSelections);

        IsHandled := false;
        OnAfterGetEmailBodyCustomer(CustEmailAddress, ServerEmailBodyFilePath, RecordVariant, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(true);
    end;
#endif

    /// <summary>
    /// Gets the email body for a customer into tempblob.
    /// </summary>
    /// <param name="EmailBody">Return value: TempBlob containing the email body</param>
    /// <param name="ReportUsage">Report usage enum</param>
    /// <param name="RecordVariant">Related record variant</param>
    /// <param name="CustNo">Customer number</param>
    /// <param name="CustEmailAddress">Return Customer email adddress.</param>
    /// <returns>True if email body was successfully generated, false if no report selection template was found</returns>
    procedure GetEmailBodyForCust(var EmailBody: Codeunit "Temp Blob"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text[250]): Boolean
    begin
        exit(GetEmailBodyTextForCust(EmailBody, ReportUsage, RecordVariant, CustNo, CustEmailAddress, ''));
    end;

    /// <summary>
    /// Gets the email body for a customer into tempblob.
    /// </summary>
    /// <param name="EmailBody">Return value: TempBlob containing the email body</param>
    /// <param name="ReportUsage">Report usage enum</param>
    /// <param name="RecordVariant">Related record variant</param>
    /// <param name="CustNo">Customer number</param>
    /// <param name="CustEmailAddress">Return value: Customer email adddress.</param>
    /// <param name="EmailBodyText">Email body text added to an email</param>
    /// <returns>True if email body was successfully generated, false if no report selection template was found.</returns>
    procedure GetEmailBodyTextForCust(var EmailBody: Codeunit "Temp Blob"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var CustEmailAddress: Text[250]; EmailBodyText: Text) Result: Boolean
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        O365HTMLTemplMgt: Codeunit "O365 HTML Templ. Mgt.";
        IsHandled: Boolean;
        EmailBodyUsageFound: Boolean;
#if not CLEAN27
        ServerEmailBodyFileCreated: Boolean;
        ServerEmailBodyFilePath: Text[250];
#endif
    begin
        Clear(EmailBody);

        IsHandled := false;
        OnBeforeGetEmailBodyCustomer(
            ReportUsage.AsInteger(), RecordVariant, TempBodyReportSelections, CustNo, CustEmailAddress, EmailBodyText, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if CustEmailAddress = '' then
            CustEmailAddress := GetEmailAddressIgnoringLayout(ReportUsage, RecordVariant, CustNo);

        IsHandled := false;
        OnGetEmailBodyTextForCustOnBeforeFindEmailBodyUsageForCust(Rec, ReportUsage, RecordVariant, CustNo, TempBodyReportSelections, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not FindEmailBodyUsageForCust(ReportUsage, CustNo, TempBodyReportSelections) then begin
            IsHandled := false;
            EmailBodyUsageFound := false;
            OnGetEmailBodyCustomerTextOnAfterNotFindEmailBodyUsage(
                ReportUsage.AsInteger(), RecordVariant, CustNo, TempBodyReportSelections, IsHandled, EmailBodyUsageFound);
            if not EmailBodyUsageFound then begin
                if IsHandled then
                    exit(true);
                exit(false);
            end;
        end;

        case "Email Body Layout Type" of
            "Email Body Layout Type"::"Custom Report Layout":
                if TempBodyReportSelections."Email Body Layout Code" <> '' then
                    SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Code", ReportUsage, EmailBody)
                else
                    SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Name", TempBodyReportSelections."Email Body Layout AppID", ReportUsage, EmailBody);
            "Email Body Layout Type"::"HTML Layout":
                O365HTMLTemplMgt.CreateEmailBodyFromReportSelections(Rec, RecordVariant, CustEmailAddress, EmailBodyText, EmailBody);
        end;

        CustEmailAddress := GetEmailAddress(ReportUsage, RecordVariant, CustNo, TempBodyReportSelections);

        IsHandled := false;
#if not CLEAN27
        if EmailBody.HasValue() then begin
            ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBody, 'html');
            ServerEmailBodyFileCreated := true;
        end;
        OnAfterGetEmailBodyCustomer(CustEmailAddress, ServerEmailBodyFilePath, RecordVariant, Result, IsHandled);
        if ServerEmailBodyFileCreated then
            Clear(EmailBody);
        if ServerEmailBodyFilePath <> '' then begin
            FileManagement.BLOBImportFromServerFile(EmailBody, ServerEmailBodyFilePath);
            FileManagement.DeleteServerFile(ServerEmailBodyFilePath);
        end;
        if IsHandled then
            exit(Result);
#endif
        OnAfterGetEmailBodyCustomerProcedure(CustEmailAddress, EmailBody, RecordVariant, Result, IsHandled);

        if IsHandled then
            exit(Result);

        exit(true);
    end;

    procedure GetEmailAddressIgnoringLayout(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]): Text[250]
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        EmailAddress: Text[250];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetEmailAddressIgnoringLayout(ReportUsage, RecordVariant, TempBodyReportSelections, CustNo, EmailAddress, IsHandled);
        if IsHandled then
            exit(EmailAddress);

        EmailAddress := GetEmailAddress(ReportUsage, RecordVariant, CustNo, TempBodyReportSelections);
        exit(EmailAddress);
    end;

    procedure GetEmailAddressExt(ReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var TempBodyReportSelections: Record "Report Selections" temporary): Text[250]
    begin
        exit(GetEmailAddress("Report Selection Usage".FromInteger(ReportUsage), RecordVariant, CustNo, TempBodyReportSelections));
    end;

    local procedure GetEmailAddress(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var TempBodyReportSelections: Record "Report Selections" temporary): Text[250]
    var
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        FieldRef: FieldRef;
        DocumentNo: Code[20];
        EmailAddress: Text[250];
        IsHandled: Boolean;
    begin
        OnBeforeGetEmailAddress(ReportUsage.AsInteger(), RecordVariant, TempBodyReportSelections, EmailAddress, IsHandled, CustNo);
        if IsHandled then
            exit(EmailAddress);

        RecordRef.GetTable(RecordVariant);
        if not RecordRef.IsEmpty() then
            if DataTypeManagement.FindfieldByName(RecordRef, FieldRef, 'No.') then begin
                DocumentNo := FieldRef.Value();
                EmailAddress := GetEmailAddressForDoc(DocumentNo, ReportUsage);
                if EmailAddress <> '' then
                    exit(EmailAddress);
            end;

        if not TempBodyReportSelections.IsEmpty() then begin
            EmailAddress :=
              FindEmailAddressForEmailLayout(TempBodyReportSelections."Email Body Layout Code", CustNo, ReportUsage, Database::Customer);
            if EmailAddress <> '' then
                exit(EmailAddress);
        end;

        if not RecordRef.IsEmpty() then
            if IsSalesDocument(RecordRef) then
                if DataTypeManagement.FindfieldByName(RecordRef, FieldRef, 'Sell-to E-Mail') then begin
                    EmailAddress := FieldRef.Value();
                    if EmailAddress <> '' then
                        exit(EmailAddress);
                end;

        EmailAddress := GetEmailAddressForCust(CustNo, ReportUsage);
        OnGetEmailAddressOnAfterGetEmailAddressForCust(ReportUsage, RecordVariant, TempBodyReportSelections, EmailAddress, CustNo);
        if EmailAddress <> '' then
            exit(EmailAddress);

        exit(EmailAddress);
    end;

#if not CLEAN27
    [Scope('OnPrem')]
    [Obsolete('Replaced with GetEmailBodyForVend that accepts a TempBlob as parameter.', '27.0')]
    procedure GetEmailBodyForVend(var ServerEmailBodyFilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; VendorNo: Code[20]; var VendorEmailAddress: Text[250]) Result: Boolean
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        FoundVendorEmailAddress: Text[250];
        IsHandled, EmailBodyUsageFound : Boolean;
        EMailBody: Codeunit "Temp Blob";
    begin
        ServerEmailBodyFilePath := '';

        IsHandled := false;
        OnBeforeGetEmailBodyVendor(
          ReportUsage.AsInteger(), RecordVariant, TempBodyReportSelections, VendorNo, VendorEmailAddress, IsHandled);
        if IsHandled then
            exit;

        VendorEmailAddress := GetEmailAddressForVend(VendorNo, RecordVariant, ReportUsage);

        if not FindEmailBodyUsageForVend(ReportUsage, VendorNo, TempBodyReportSelections) then begin
            IsHandled := false;
            EmailBodyUsageFound := false;
            OnGetEmailBodyVendorTextOnAfterNotFindEmailBodyUsage(
              ReportUsage.AsInteger(), RecordVariant, VendorNo, TempBodyReportSelections, IsHandled, EmailBodyUsageFound);
            if not EmailBodyUsageFound then begin
                if IsHandled then
                    exit(true);
                exit(false);
            end;
        end;

        if TempBodyReportSelections."Email Body Layout Code" <> '' then
            SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Code", ReportUsage, EMailBody)
        else
            SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Name", TempBodyReportSelections."Email Body Layout AppID", ReportUsage, EMailBody);

        ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBody, 'html');

        FoundVendorEmailAddress :=
          FindEmailAddressForEmailLayout(TempBodyReportSelections."Email Body Layout Code", VendorNo, ReportUsage, Database::Vendor);
        if FoundVendorEmailAddress <> '' then
            VendorEmailAddress := FoundVendorEmailAddress;

        IsHandled := false;
        OnAfterGetEmailBodyVendor(VendorEmailAddress, ServerEmailBodyFilePath, RecordVariant, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(true);
    end;
#endif

    procedure GetEmailBodyForVend(var EmailBody: Codeunit "Temp Blob"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                     VendorNo: Code[20]; var VendorEmailAddress: Text[250]) Result: Boolean
    var
        TempBodyReportSelections: Record "Report Selections" temporary;
        FoundVendorEmailAddress: Text[250];
        IsHandled, EmailBodyUsageFound : Boolean;
#if not CLEAN27
        ServerEmailBodyFileCreated: Boolean;
        ServerEmailBodyFilePath: Text[250];
#endif
    begin
        Clear(EmailBody);

        IsHandled := false;
        OnBeforeGetEmailBodyVendor(
          ReportUsage.AsInteger(), RecordVariant, TempBodyReportSelections, VendorNo, VendorEmailAddress, IsHandled);
        if IsHandled then
            exit;

        VendorEmailAddress := GetEmailAddressForVend(VendorNo, RecordVariant, ReportUsage);

        if not FindEmailBodyUsageForVend(ReportUsage, VendorNo, TempBodyReportSelections) then begin
            IsHandled := false;
            EmailBodyUsageFound := false;
            OnGetEmailBodyVendorTextOnAfterNotFindEmailBodyUsage(
              ReportUsage.AsInteger(), RecordVariant, VendorNo, TempBodyReportSelections, IsHandled, EmailBodyUsageFound);
            if not EmailBodyUsageFound then
                if IsHandled then
                    exit(true);
            exit(false);
        end;

        if TempBodyReportSelections."Email Body Layout Code" <> '' then
            SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Code", ReportUsage, EmailBody)
        else
            SaveReportAsHTML(TempBodyReportSelections."Report ID", RecordVariant, TempBodyReportSelections."Email Body Layout Name", TempBodyReportSelections."Email Body Layout AppID", ReportUsage, EmailBody);

        FoundVendorEmailAddress :=
          FindEmailAddressForEmailLayout(TempBodyReportSelections."Email Body Layout Code", VendorNo, ReportUsage, Database::Vendor);
        if FoundVendorEmailAddress <> '' then
            VendorEmailAddress := FoundVendorEmailAddress;

        IsHandled := false;
#if not CLEAN27
        if EmailBody.HasValue() then begin
            ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBody, 'html');
            ServerEmailBodyFileCreated := true;
        end;
        OnAfterGetEmailBodyVendor(VendorEmailAddress, ServerEmailBodyFilePath, RecordVariant, Result, IsHandled);
        if ServerEmailBodyFileCreated then
            Clear(EmailBody);
        if ServerEmailBodyFilePath <> '' then begin
            FileManagement.BLOBImportFromServerFile(EmailBody, ServerEmailBodyFilePath);
            FileManagement.DeleteServerFile(ServerEmailBodyFilePath);
        end;
        if IsHandled then
            exit(Result);
#endif
        OnAfterGetEmailBodyVendorProcedure(VendorEmailAddress, EmailBody, RecordVariant, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SendEmailInBackground(JobQueueEntry: Record "Job Queue Entry")
    var
        RecRef: RecordRef;
        ReportUsage: Integer;
        DocNo: Code[20];
        DocName: Text[150];
        No: Code[20];
        ParamString: Text;
    begin
        // Called from codeunit 260 OnRun trigger - in a background process.
        RecRef.Get(JobQueueEntry."Record ID to Process");
        RecRef.LockTable();
        RecRef.Find();
        RecRef.SetRecFilter();
        ParamString := JobQueueEntry."Parameter String";  // Are set in function SendEmailToCust
        GetJobQueueParameters(ParamString, ReportUsage, DocNo, DocName, No);
        VerifyRecordBySystemId(ParamString, ReportUsage, RecRef);
        OnSendEmailInBackgroundOnAfterGetJobQueueParameters(RecRef, ParamString);

        ParamString := ParamString.TrimStart('|');
        if ParamString = 'Vendor' then
            SendEmailToVendorDirectly("Report Selection Usage".FromInteger(ReportUsage), RecRef, DocNo, DocName, false, No)
        else
            SendEmailToCustDirectly("Report Selection Usage".FromInteger(ReportUsage), RecRef, DocNo, DocName, false, No);
    end;

    procedure GetJobQueueParameters(var ParameterString: Text; var ReportUsage: Integer; var DocNo: Code[20]; var DocName: Text[150]; var CustNo: Code[20]) WasSuccessful: Boolean
    begin
        WasSuccessful := Evaluate(ReportUsage, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(DocNo, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(DocName, GetNextJobQueueParam(ParameterString));
        WasSuccessful := WasSuccessful and Evaluate(CustNo, GetNextJobQueueParam(ParameterString));
    end;

    procedure RunGetNextJobQueueParam(var Parameter: Text): Text
    begin
        exit(GetNextJobQueueParam(Parameter));
    end;

    local procedure GetNextJobQueueParam(var Parameter: Text): Text
    var
        I: Integer;
        Result: Text;
    begin
        I := StrPos(Parameter, '|');
        if I > 0 then
            Result := CopyStr(Parameter, 1, I - 1);
        if (I + 1) < StrLen(Parameter) then
            Parameter := CopyStr(Parameter, I + 1);
        exit(Result);
    end;

    procedure EnqueueMailingJob(RecordIdToProcess: RecordID; ParameterString: Text; Description: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
        IsHandled: Boolean;
    begin
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Document-Mailing";
        JobQueueEntry."Job Queue Category Code" := GetMailingJobCategory();
        JobQueueEntry."Maximum No. of Attempts to Run" := 0; // So that the job runs only once
        JobQueueEntry."Record ID to Process" := RecordIdToProcess;
        JobQueueEntry."Parameter String" := CopyStr(ParameterString, 1, MaxStrLen(JobQueueEntry."Parameter String"));
        JobQueueEntry.Description := CopyStr(Description, 1, MaxStrLen(JobQueueEntry.Description));
        IsHandled := false;
        OnEnqueueMailingJobOnBeforeRunJobQueueEnqueue(RecordIdToProcess, ParameterString, Description, JobQueueEntry, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    procedure GetMailingJobCategory(): Code[10]
    var
        JobQueueCategory: Record "Job Queue Category";
        MailingJobCategoryCode: Code[10];
    begin
        MailingJobCategoryCode := GetMailingJobCategoryCode();
        if not JobQueueCategory.Get(MailingJobCategoryCode) then begin
            JobQueueCategory.Init();
            JobQueueCategory.Code := MailingJobCategoryCode;
            JobQueueCategory.Description := CopyStr(MailingJobCategoryTok, 1, MaxStrLen(JobQueueCategory.Description));
            JobQueueCategory.Insert();
        end;

        exit(JobQueueCategory.Code);
    end;

    local procedure GetMailingJobCategoryCode(): Code[10]
    begin
        exit(CopyStr(MailingJobCategoryCodeTok, 1, 10));
    end;

    procedure SaveAsDocumentAttachment(ReportUsage: Integer; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    var
        TempAttachReportSelections: Record "Report Selections" temporary;
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        NumberOfReportsAttached: Integer;
        IsHandled: Boolean;
    begin
        OnBeforeSaveAsDocumentAttachment(
            Enum::"Report Selection Usage".FromInteger(ReportUsage), RecordVariant, DocumentNo, AccountNo, ShowNotificationAction);

        RecRef.GETTABLE(RecordVariant);
        if not RecRef.Find() then
            exit;

        FindPrintUsageInternal(
            "Report Selection Usage".FromInteger(ReportUsage), AccountNo, TempAttachReportSelections, GetAccountTableId(RecRef.Number()));
        repeat
            OnSaveAsDocumentAttachmentOnBeforeCanSaveReportAsPDF(TempAttachReportSelections, RecRef, DocumentNo, AccountNo, NumberOfReportsAttached);
            if CanSaveReportAsPDF(TempAttachReportSelections."Report ID") then begin
                Clear(TempBlob);
                TempAttachReportSelections.SaveReportAsPDFInTempBlob(TempBlob, TempAttachReportSelections."Report ID", RecordVariant, TempAttachReportSelections."Custom Report Layout Code", "Report Selection Usage".FromInteger(ReportUsage));
                SaveDocumentAttachmentFromRecRef(RecRef, TempAttachReportSelections, DocumentNo, AccountNo, TempBlob, NumberOfReportsAttached);
            end;
        until TempAttachReportSelections.Next() = 0;

        IsHandled := false;
        OnSaveAsDocumentAttachmentOnBeforeShowNotification(RecordVariant, NumberOfReportsAttached, ShowNotificationAction, IsHandled);
        if not IsHandled then
            DocumentAttachmentMgmt.ShowNotification(RecordVariant, NumberOfReportsAttached, ShowNotificationAction)
    end;

    local procedure SaveDocumentAttachmentFromRecRef(RecRef: RecordRef; var TempAttachReportSelections: Record "Report Selections"; DocumentNo: Code[20]; AccountNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; var NumberOfReportsAttached: Integer)
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        FileName: Text[250];
        ReportCaption: Text[250];
        DocumentLanguageCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveDocumentAttachmentFromRecRef(RecRef, TempAttachReportSelections, DocumentNo, AccountNo, TempBlob, IsHandled, NumberOfReportsAttached);
        if IsHandled then
            exit;
        DocumentAttachment.InitFieldsFromRecRef(RecRef);
        DocumentAttachment."Document Flow Sales" := DocumentAttachmentMgmt.IsSalesDocumentFlow(RecRef.Number);
        DocumentAttachment."Document Flow Purchase" := DocumentAttachmentMgmt.IsPurchaseDocumentFlow(RecRef.Number);
        DocumentAttachment."Document Flow Service" := DocumentAttachmentMgmt.IsServiceDocumentFlow(RecRef.Number);
        DocumentLanguageCode := ReportDistributionMgt.GetDocumentLanguageCode(RecRef);
        ReportCaption := ReportDistributionMgt.GetReportCaption(TempAttachReportSelections."Report ID", DocumentLanguageCode);
        FileName :=
            DocumentAttachment.FindUniqueFileName(
                StrSubstNo('%1 %2 %3', TempAttachReportSelections."Report ID", ReportCaption, DocumentNo), 'pdf');
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        NumberOfReportsAttached += 1;
    end;

    local procedure GetAccountTableId(DocumentTableId: Integer): Integer
    begin
        case true of
            IsCustomerAccount(DocumentTableId):
                exit(Database::Customer);
            IsVendorAccount(DocumentTableId):
                exit(Database::Vendor);
        end;
    end;

    local procedure IsCustomerAccount(DocumentTableId: Integer) IsCustomer: Boolean
    begin
        IsCustomer := DocumentTableId in [
                                            Database::"Sales Header",
                                            Database::"Sales Invoice Header",
                                            Database::"Sales Cr.Memo Header",
                                            Database::"Sales Shipment Header",
                                            Database::"Return Receipt Header",
                                            Database::"Issued Reminder Header"];

        OnAfterIsCustomerAccount(DocumentTableId, IsCustomer);
    end;

    local procedure IsVendorAccount(DocumentTableId: Integer) IsVendor: Boolean
    begin
        IsVendor := DocumentTableId in [
                                            Database::"Purchase Header",
                                            Database::"Purch. Inv. Header",
                                            Database::"Purch. Cr. Memo Hdr.",
                                            Database::"Purch. Rcpt. Header",
                                            Database::"Return Shipment Header",
                                            Database::"Vendor Ledger Entry"];

        OnAfterIsVendorAccount(DocumentTableId, IsVendor);
    end;


    local procedure CanSaveReportAsPDF(ReportId: Integer) Result: Boolean
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
    begin
        Result := ReportLayoutSelectionLocal.HasLayoutOfType(ReportId, ReportLayoutType::RDLC) or ReportLayoutSelectionLocal.HasLayoutOfType(ReportId, ReportLayoutType::Word);
        OnAfterCanSaveReportAsPDF(ReportId, Result);
    end;

    procedure SendEmailToCust(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; CustNo: Code[20])
    var
        RecRef: RecordRef;
        ReportUsageEnum: Enum "Report Selection Usage";
        Handled: Boolean;
        ParameterString: Text;
        SendEmailToCustomerDirectly: Boolean;
        SendEmailToCustomerDirectlyHandled: Boolean;
    begin
        OnBeforeSendEmailToCust(ReportUsage, RecordVariant, DocNo, DocName, ShowDialog, CustNo, Handled);
        if Handled then
            exit;

        RecRef.GetTable(RecordVariant);
        ReportUsageEnum := "Report Selection Usage".FromInteger(ReportUsage);

        OnGetSendToCustomerDirectly(ReportUsageEnum, RecordVariant, CustNo, ShowDialog, SendEmailToCustomerDirectly, SendEmailToCustomerDirectlyHandled);
        if not SendEmailToCustomerDirectlyHandled then
            SendEmailToCustomerDirectly := ShouldSendToCustDirectly(ReportUsageEnum, RecordVariant, CustNo);

        if ShowDialog or SendEmailToCustomerDirectly then begin
            SendEmailToCustDirectly(ReportUsageEnum, RecordVariant, DocNo, DocName, ShowDialog, CustNo);
            exit;
        end;

        RecRef.GetTable(RecordVariant);
        if RecRef.FindSet() then
            repeat
                ParameterString := StrSubstNo('%1|%2|%3|%4|', ReportUsage, DocNo, DocName, CustNo);
                OnSendEmailToCustOnAfterSetParameterString(RecRef, ParameterString);
                EnqueueMailingJob(RecRef.RecordId, ParameterString, DocName);
            until RecRef.Next() = 0;
    end;

    procedure ShouldSendToCustDirectly(ReportUsageEnum: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]): Boolean
    var
        TempAttachReportSelections: Record "Report Selections" temporary;
        EmailAddress: Text[250];
    begin
        FindEmailAttachmentUsageForCust(ReportUsageEnum, CustNo, TempAttachReportSelections);
        EmailAddress := GetEmailAddress(ReportUsageEnum, RecordVariant, CustNo, TempAttachReportSelections);
        exit((not MailManagementEnabled()) or (EmailAddress = '') or OfficeMgtAvailable());
    end;

    local procedure ShouldSendToVendorDirectly(ReportUsageEnum: Enum "Report Selection Usage"; RecordVariant: Variant; VendorNo: Code[20]): Boolean
    var
        TempAttachReportSelections: Record "Report Selections" temporary;
        EmailAddress: Text[250];
    begin
        EmailAddress := GetEmailAddressForVend(VendorNo, RecordVariant, ReportUsageEnum);
        if EmailAddress = '' then begin
            FindEmailAttachmentUsageForVend(ReportUsageEnum, VendorNo, TempAttachReportSelections);
            if not TempAttachReportSelections.IsEmpty() then
                EmailAddress := FindEmailAddressForEmailLayout(TempAttachReportSelections."Email Body Layout Code", VendorNo, ReportUsageEnum, Database::Vendor);
        end;

        exit((not MailManagementEnabled()) or (EmailAddress = '') or OfficeMgtAvailable());
    end;

    local procedure OfficeMgtAvailable(): Boolean
    var
        OfficeMgt: Codeunit "Office Management";
    begin
        exit(OfficeMgt.IsAvailable());
    end;

    local procedure MailManagementEnabled(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(MailManagement.IsEnabled());
    end;

    procedure SendEmailToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; ShowDialog: Boolean; VendorNo: Code[20])
    var
        RecRef: RecordRef;
        ReportUsageEnum: Enum "Report Selection Usage";
        Handled: Boolean;
        ParameterString: Text;
    begin
        OnBeforeSendEmailToVendor(ReportUsage, RecordVariant, DocNo, DocName, ShowDialog, VendorNo, Handled);
        if Handled then
            exit;

        RecRef.GetTable(RecordVariant);
        ReportUsageEnum := "Report Selection Usage".FromInteger(ReportUsage);

        if ShowDialog or ShouldSendToVendorDirectly(ReportUsageEnum, RecordVariant, VendorNo) then begin
            SendEmailToVendorDirectly(ReportUsageEnum, RecordVariant, DocNo, DocName, true, VendorNo);
            exit;
        end;

        RecRef.GetTable(RecordVariant);
        if RecRef.FindSet() then
            repeat
                if IsRecordSystemIdVerificationRequired(ReportUsage, RecRef.Number) then
                    ParameterString := StrSubstNo(JobQueueParameterStringTok, ReportUsage, DocNo, DocName, VendorNo, RecRef.field(RecRef.SystemIdNo).Value, 'Vendor')
                else
                    ParameterString := StrSubstNo('%1|%2|%3|%4|%5', ReportUsage, DocNo, DocName, VendorNo, 'Vendor');
                OnSendEmailToVendorOnAfterSetParameterString(RecRef, ParameterString);
                EnqueueMailingJob(RecRef.RecordId, ParameterString, DocName);
            until RecRef.Next() = 0;
    end;

    local procedure SendEmailToCustDirectly(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                             DocNo: Code[20];
                                                             DocName: Text[150];
                                                             ShowDialog: Boolean;
                                                             CustNo: Code[20]): Boolean
    var
        TempAttachReportSelections: Record "Report Selections" temporary;
        CustomReportSelection: Record "Custom Report Selection";
        EmailParameter: Record "Email Parameter";
        MailManagement: Codeunit "Mail Management";
        EmailBody: Codeunit "Temp Blob";
        FoundBody: Boolean;
        FoundAttachment: Boolean;
        EmailAddress: Text[250];
        EmailBodyText: Text;
        IsHandled: Boolean;
    begin
        if EmailParameter.GetParameterWithReportUsage(DocNo, ReportUsage, EmailParameter."Parameter Type"::Body) then
            EmailBodyText := EmailParameter.GetParameterValue();

        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        BindSubscription(MailManagement);
        FoundBody := GetEmailBodyTextForCust(EmailBody, ReportUsage, RecordVariant, CustNo, EmailAddress, EmailBodyText);
        UnbindSubscription(MailManagement);

        IsHandled := false;
        OnSendEmailToCustDirectlyOnBeforeFindEmailAttachmentUsageForCust(Rec, ReportUsage, RecordVariant, CustNo, TempAttachReportSelections, FoundAttachment, IsHandled);
        if not IsHandled then
            FoundAttachment := FindEmailAttachmentUsageForCust(ReportUsage, CustNo, TempAttachReportSelections);

        CustomReportSelection.SetRange("Source Type", Database::Customer);
        CustomReportSelection.SetRange("Source No.", CustNo);
        exit(SendEmailDirectly(
            ReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, EmailBody, EmailAddress, ShowDialog,
            TempAttachReportSelections, CustomReportSelection));
    end;

    local procedure SendEmailToVendorDirectly(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                               DocNo: Code[20];
                                                               DocName: Text[150];
                                                               ShowDialog: Boolean;
                                                               VendorNo: Code[20]): Boolean
    var
        TempAttachReportSelections: Record "Report Selections" temporary;
        CustomReportSelection: Record "Custom Report Selection";
        MailManagement: Codeunit "Mail Management";
        EmailBody: Codeunit "Temp Blob";
        FoundBody: Boolean;
        FoundAttachment: Boolean;
        EmailAddress: Text[250];
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        BindSubscription(MailManagement);
        FoundBody := GetEmailBodyForVend(EmailBody, ReportUsage, RecordVariant, VendorNo, EmailAddress);
        UnbindSubscription(MailManagement);
        FoundAttachment := FindEmailAttachmentUsageForVend(ReportUsage, VendorNo, TempAttachReportSelections);

        CustomReportSelection.SetRange("Source Type", Database::Vendor);
        CustomReportSelection.SetRange("Source No.", VendorNo);
        exit(SendEmailDirectly(
            ReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, EmailBody, EmailAddress, ShowDialog,
            TempAttachReportSelections, CustomReportSelection));
    end;

    local procedure SendEmailDirectly(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                       DocNo: Code[20];
                                                       DocName: Text[150];
                                                       FoundBody: Boolean;
                                                       FoundAttachment: Boolean;
                                                       EmailBodyTempBlob: Codeunit "Temp Blob"; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection") AllEmailsWereSuccessful: Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Reminder: Record "Issued Reminder Header";
        ReminderLines: Record "Issued Reminder Line";
        SalesInvoice: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        DocumentMailing: Codeunit "Document-Mailing";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        DataTypeManagement: Codeunit "Data Type Management";
        DocumentRecord: RecordRef;
        FieldRef: FieldRef;
        FieldName: Text;
        EmailAddress: Text[250];
#if not CLEAN27
        ServerEmailBodyFilePath: Text[250];
#endif
        SourceTableIDs, SourceRelationTypes : List of [Integer];
        SourceIDs: List of [Guid];
        IsHandled: Boolean;
#if not CLEAN27
        ServerEmailBodyFileCreated: Boolean;
#endif
        AttachmentStream: InStream;
        TableId: Integer;
    begin
        IsHandled := false;
        DocumentRecord.GetTable(RecordVariant);

        // Primary Source - Document being sent by email
        SourceTableIDs.Add(DocumentRecord.Number());
        SourceIDs.Add(DocumentRecord.field(DocumentRecord.SystemIdNo).Value());
        SourceRelationTypes.Add(Enum::"Email Relation Type"::"Primary Source".AsInteger());

        // Add any invoice in the reminder lines as a related source
        if DocumentRecord.Number() = Database::"Issued Reminder Header" then
            if Reminder.GetBySystemId(DocumentRecord.field(DocumentRecord.SystemIdNo).Value()) then begin
                ReminderLines.SetFilter("Reminder No.", Reminder."No.");
                if ReminderLines.FindSet() then
                    repeat
                        if ReminderLines."Document Type" = ReminderLines."Document Type"::Invoice then
                            if SalesInvoice.Get(ReminderLines."Document No.") then begin
                                SourceTableIDs.Add(Database::"Sales Invoice Header");
                                SourceIDs.Add(SalesInvoice.SystemId);
                                SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
                            end;
                    until ReminderLines.Next() = 0;
            end;

        // Related Source - Customer or vendor receiving the document
        TableId := GetAccountTableId(DocumentRecord.Number());
        if TableId = Database::Customer then begin
            if DocumentRecord.Number() = Database::"Issued Reminder Header" then
                FieldName := 'Customer No.'
            else
                FieldName := 'Sell-to Customer No.';
            OnSendEmailDirectlyOnAfterSetFieldName(DocumentRecord.Number(), FieldName);
            if DataTypeManagement.FindfieldByName(DocumentRecord, FieldRef, FieldName) and Customer.Get(Format(FieldRef.Value())) then begin
                SourceTableIDs.Add(Database::Customer);
                SourceIDs.Add(Customer.SystemId);
                SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
            end;
        end;

        if TableId = Database::Vendor then begin
            if DocumentRecord.Number() = Database::"Vendor Ledger Entry" then
                FieldName := 'Vendor No.'
            else
                FieldName := 'Buy-from Vendor No.';
            if DataTypeManagement.FindfieldByName(DocumentRecord, FieldRef, FieldName) and Vendor.Get(Format(FieldRef.Value())) then begin
                SourceTableIDs.Add(Database::Vendor);
                SourceIDs.Add(Vendor.SystemId);
                SourceRelationTypes.Add(Enum::"Email Relation Type"::"Related Entity".AsInteger());
            end;
        end;
#if not CLEAN27
        if EmailBodyTempBlob.HasValue() then begin
            ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBodyTempBlob, 'html');
            ServerEmailBodyFileCreated := true;
        end;
        OnBeforeSendEmailDirectly(Rec, ReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, ServerEmailBodyFilePath, DefaultEmailAddress, ShowDialog, TempAttachReportSelections, CustomReportSelection, AllEmailsWereSuccessful, IsHandled, SourceTableIDs, SourceIDs, SourceRelationTypes);
        if ServerEmailBodyFileCreated then
            Clear(ServerEmailBodyFileCreated);
        if ServerEmailBodyFilePath <> '' then begin
            FileManagement.BLOBImportFromServerFile(EmailBodyTempBlob, ServerEmailBodyFilePath);
            FileManagement.DeleteServerFile(ServerEmailBodyFilePath);
        end;
        if IsHandled then
            exit(AllEmailsWereSuccessful);
#endif
        OnSendEmailDirectlyOnBeforeSend(Rec, ReportUsage, RecordVariant, DocNo, DocName, FoundBody, FoundAttachment, EmailBodyTempBlob, DefaultEmailAddress, ShowDialog, TempAttachReportSelections, CustomReportSelection, AllEmailsWereSuccessful, IsHandled, SourceTableIDs, SourceIDs, SourceRelationTypes);
        if IsHandled then
            exit(AllEmailsWereSuccessful);

        AllEmailsWereSuccessful := true;

        ShowNoBodyNoAttachmentError(ReportUsage, FoundBody, FoundAttachment);

        if FoundBody and not FoundAttachment then begin
            TempBlob.CreateInStream(AttachmentStream);
            EmailAddress := CopyStr(
                GetNextEmailAddressFromCustomReportSelection(CustomReportSelection, DefaultEmailAddress, Usage, Sequence), 1, MaxStrLen(EmailAddress));
            AllEmailsWereSuccessful := DocumentMailing.EmailFile(AttachmentStream, '', EmailBodyTempBlob, DocNo, EmailAddress, DocName, not ShowDialog, ReportUsage.AsInteger(),
                                            SourceTableIDs, SourceIDs, SourceRelationTypes);
        end;

        if FoundAttachment then begin
            if ReportUsage = Usage::JQ then begin
                Usage := ReportUsage;
                CustomReportSelection.SetFilter(Usage, GetFilter(Usage));
                if CustomReportSelection.FindFirst() then
                    if CustomReportSelection.GetSendToEmail(true) <> '' then
                        DefaultEmailAddress := CustomReportSelection."Send To Email";
            end;

            OnSendEmailDirectlyOnBeforeSendFiles(
              ReportUsage.AsInteger(), RecordVariant, DefaultEmailAddress, TempAttachReportSelections, CustomReportSelection, Rec);
            OfficeAttachmentManager.IncrementCount(TempAttachReportSelections.Count - 1);
            repeat
                if (TempAttachReportSelections."Report ID" = Report::Reminder) and (ReportUsage = "Report Selection Usage"::"S.Invoice") then
                    Error(ReminderAndSalesInvoiceErr);

                IsHandled := false;
#if not CLEAN27
                ServerEmailBodyFileCreated := false;
                if EmailBodyTempBlob.HasValue() then begin
                    ServerEmailBodyFilePath := FileManagement.TempBlobToServerFile(EmailBodyTempBlob, 'html');
                    ServerEmailBodyFileCreated := true;
                end;
                OnSendEmailDirectlyOnBeforeSendFileLoop(ReportUsage, RecordVariant, DocNo, DocName, DefaultEmailAddress, ShowDialog, TempAttachReportSelections, CustomReportSelection, IsHandled, ServerEmailBodyFilePath);
                if ServerEmailBodyFileCreated then
                    Clear(EmailBodyTempBlob);
                if ServerEmailBodyFilePath <> '' then begin
                    FileManagement.BLOBImportFromServerFile(EmailBodyTempBlob, ServerEmailBodyFilePath);
                    FileManagement.DeleteServerFile(ServerEmailBodyFilePath);
                end;
#endif
                OnSendEmailDirectlyOnBeforeSendSingleFile(ReportUsage, RecordVariant, DocNo, DocName, DefaultEmailAddress, ShowDialog, TempAttachReportSelections, CustomReportSelection, IsHandled, EmailBodyTempBlob);

                if not IsHandled then begin
                    EmailAddress := CopyStr(
                        GetNextEmailAddressFromCustomReportSelection(CustomReportSelection, DefaultEmailAddress, TempAttachReportSelections.Usage, TempAttachReportSelections.Sequence),
                        1, MaxStrLen(EmailAddress));
                    Clear(TempBlob);
                    IsHandled := false;
                    OnSendEmailDirectlyOnBeforeSaveReportAsPDFInTempBlob(TempAttachReportSelections, DocumentRecord, ReportUsage, TempBlob, IsHandled);
                    if not IsHandled then
                        TempAttachReportSelections.SaveReportAsPDFInTempBlob(TempBlob, TempAttachReportSelections."Report ID", DocumentRecord, TempAttachReportSelections."Custom Report Layout Code", ReportUsage);
                    TempBlob.CreateInStream(AttachmentStream);

                    OnSendEmailDirectlyOnBeforeEmailWithAttachment(RecordVariant, TempAttachReportSelections, TempBlob, DocumentMailing, DocNo, DocName, EmailAddress);

                    AllEmailsWereSuccessful :=
                        AllEmailsWereSuccessful and
                        DocumentMailing.EmailFile(
                            AttachmentStream, '', EmailBodyTempBlob,
                            DocNo, EmailAddress, DocName, not ShowDialog, ReportUsage.AsInteger(),
                            SourceTableIDs, SourceIDs, SourceRelationTypes);
                    OnSendEmailDirectlyOnAfterEmailWithAttachment(RecordVariant, TempAttachReportSelections, TempBlob, DocumentMailing, DocNo, DocName, EmailAddress, AllEmailsWereSuccessful);
                end;
            until TempAttachReportSelections.Next() = 0;
        end;

        OnAfterSendEmailDirectly(ReportUsage.AsInteger(), RecordVariant, AllEmailsWereSuccessful);
        exit(AllEmailsWereSuccessful);
    end;

    [Scope('OnPrem')]
    procedure SendToDiskForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                 DocNo: Code[20];
                                                 DocName: Text;
                                                 CustNo: Code[20])
    var
        TempReportSelections: Record "Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        ClientAttachmentFileName: Text;
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());

        IsHandled := false;
        OnSendToDiskForCustOnBeforeFindReportUsage(Rec, ReportUsage, RecordVariant, CustNo, TempReportSelections, IsHandled);
        if not IsHandled then
            FindReportUsageForCust(ReportUsage, CustNo, TempReportSelections);
        repeat
            OnSendToDiskForCustOnBeforeSendFileLoop(TempReportSelections, RecordVariant);
            Clear(TempBlob);
            TempReportSelections.SaveReportAsPDFInTempBlob(TempBlob, TempReportSelections."Report ID", RecordVariant, TempReportSelections."Custom Report Layout Code", ReportUsage);
            TempBlob.CreateInStream(AttachmentInStream);
            ClientAttachmentFileName := ElectronicDocumentFormat.GetAttachmentFileName(RecordVariant, DocNo, DocName, 'pdf');
            DownloadAttachmentFromStream(TempReportSelections, RecordVariant, AttachmentInStream, ClientAttachmentFileName);
        until TempReportSelections.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SendToDiskForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant;
                                                 DocNo: Code[20];
                                                 DocName: Text;
                                                 VendorNo: Code[20])
    var
        TempReportSelections: Record "Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        ClientAttachmentFileName: Text;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        FindReportUsageForVend(ReportUsage, VendorNo, TempReportSelections);
        repeat
            OnSendToDiskForVendOnBeforeSendFileLoop(TempReportSelections, RecordVariant);
            Clear(TempBlob);
            TempReportSelections.SaveReportAsPDFInTempBlob(TempBlob, TempReportSelections."Report ID", RecordVariant, TempReportSelections."Custom Report Layout Code", ReportUsage);
            TempBlob.CreateInStream(AttachmentInStream);
            ClientAttachmentFileName := ElectronicDocumentFormat.GetAttachmentFileName(RecordVariant, DocNo, DocName, 'pdf');
            DownloadAttachmentFromStream(TempReportSelections, RecordVariant, AttachmentInStream, ClientAttachmentFileName);
        until TempReportSelections.Next() = 0;
    end;

    local procedure DownloadAttachmentFromStream(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDownloadAttachmentFromStream(TempReportSelections, RecordVariant, AttachmentInStream, ClientAttachmentFileName, IsHandled);
        if IsHandled then
            exit;

        DownloadFromStream(AttachmentInStream, '', '', FileManagement.GetToFilterText('', ClientAttachmentFileName), ClientAttachmentFileName);
    end;

    [Scope('OnPrem')]
    procedure SendToZipForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; CustNo: Code[20]; var DataCompression: Codeunit "Data Compression")
    var
        TempReportSelections: Record "Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        AttachmentTempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());

        IsHandled := false;
        OnSendToZipForCustOnBeforeFindReportUsageForCust(Rec, ReportUsage, RecordVariant, CustNo, TempReportSelections, IsHandled);
        if not IsHandled then
            FindReportUsageForCust(ReportUsage, CustNo, TempReportSelections);
        repeat
            OnSendToZipForCustOnBeforeSendFileLoop(TempReportSelections, RecordVariant);
            Clear(AttachmentTempBlob);
            TempReportSelections.SaveReportAsPDFInTempBlob(
                AttachmentTempBlob, TempReportSelections."Report ID", RecordVariant, TempReportSelections."Custom Report Layout Code", ReportUsage);
            AttachmentTempBlob.CreateInStream(AttachmentInStream);
            DataCompression.AddEntry(
                AttachmentInStream, ElectronicDocumentFormat.GetAttachmentFileName(RecordVariant, DocNo, Format(TempReportSelections.Usage), 'pdf'));
        until TempReportSelections.Next() = 0;

        OnAfterSendToZipForCust(ReportUsage, RecordVariant, DataCompression);
    end;

    [Scope('OnPrem')]
    procedure SendToZipForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; VendorNo: Code[20]; var DataCompression: Codeunit "Data Compression")
    var
        TempReportSelections: Record "Report Selections" temporary;
        ElectronicDocumentFormat: Record "Electronic Document Format";
        AttachmentTempBlob: Codeunit "Temp Blob";
        AttachmentInStream: InStream;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        FindReportUsageForVend(ReportUsage, VendorNo, TempReportSelections);
        repeat
            OnSendToZipForVendOnBeforeSendFileLoop(TempReportSelections, RecordVariant);
            Clear(AttachmentTempBlob);
            TempReportSelections.SaveReportAsPDFInTempBlob(
                AttachmentTempBlob, TempReportSelections."Report ID", RecordVariant, TempReportSelections."Custom Report Layout Code", ReportUsage);
            AttachmentTempBlob.CreateInStream(AttachmentInStream);
            DataCompression.AddEntry(
                AttachmentInStream, ElectronicDocumentFormat.GetAttachmentFileName(RecordVariant, DocNo, Format(TempReportSelections.Usage), 'pdf'));
        until TempReportSelections.Next() = 0;

        OnAfterSendToZipForVend(ReportUsage, RecordVariant, DataCompression);
    end;

    procedure GetEmailAddressForDoc(DocumentNo: Code[20]; ReportUsage: Enum "Report Selection Usage"): Text[250]
    var
        EmailParameter: Record "Email Parameter";
        ToAddress: Text[250];
    begin
        if EmailParameter.GetParameterWithReportUsage(DocumentNo, ReportUsage, EmailParameter."Parameter Type"::Address) then
            ToAddress := EmailParameter.GetParameterValue();

        exit(ToAddress);
    end;

    procedure GetEmailAddressForCust(BillToCustomerNo: Code[20]; ReportUsage: Enum "Report Selection Usage"): Text[250]
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ToAddress: Text[250];
        IsHandled: Boolean;
    begin
        OnBeforeGetCustEmailAddress(BillToCustomerNo, ToAddress, ReportUsage.AsInteger(), IsHandled);
        if IsHandled then
            exit(ToAddress);

        if Customer.Get(BillToCustomerNo) then
            ToAddress := Customer."E-Mail"
        else
            if Contact.Get(BillToCustomerNo) then
                ToAddress := Contact."E-Mail";
        exit(ToAddress);
    end;

    procedure GetEmailAddressForVend(BuyFromVendorNo: Code[20]; RecVar: Variant; ReportUsage: Enum "Report Selection Usage"): Text[250]
    var
        Contact: Record Contact;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        RecRef: RecordRef;
        ToAddress: Text[250];
        IsHandled: Boolean;
    begin
        OnBeforeGetVendorEmailAddress(BuyFromVendorNo, ToAddress, ReportUsage.AsInteger(), IsHandled, RecVar);
        if IsHandled then
            exit(ToAddress);

        ToAddress := GetPurchaseOrderEmailAddress(BuyFromVendorNo, RecVar, ReportUsage);

        if ToAddress = '' then begin
            RecRef.GetTable(RecVar);
            if RecRef.Number = Database::"Purchase Header" then begin
                PurchaseHeader := RecVar;
                if Contact.Get(PurchaseHeader."Buy-from Contact No.") then
                    ToAddress := Contact."E-Mail";
            end;
        end;

        if ToAddress = '' then
            if Vendor.Get(BuyFromVendorNo) then
                ToAddress := Vendor."E-Mail";

        exit(ToAddress);
    end;

    local procedure GetPurchaseOrderEmailAddress(BuyFromVendorNo: Code[20]; RecVar: Variant; ReportUsage: Enum "Report Selection Usage") EmailAddress: Text[250]
    var
        PurchaseHeader: Record "Purchase Header";
        OrderAddress: Record "Order Address";
        RecRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPurchaseOrderEmailAddress(BuyFromVendorNo, RecVar, ReportUsage, OrderAddress, EmailAddress, IsHandled);
        if IsHandled then
            exit(EmailAddress);

        if BuyFromVendorNo = '' then
            exit('');

        if ReportUsage <> Usage::"P.Order" then
            exit('');

        RecRef.GetTable(RecVar);
        if RecRef.Number <> Database::"Purchase Header" then
            exit('');

        PurchaseHeader := RecVar;
        if PurchaseHeader."Order Address Code" = '' then
            exit('');

        if not OrderAddress.Get(BuyFromVendorNo, PurchaseHeader."Order Address Code") then
            exit('');

        exit(OrderAddress."E-Mail");
    end;

    local procedure SaveReportAsPDF(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage") FilePath: Text[250]
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
        FileMgt: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        IsHandled: Boolean;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        FilePath := CopyStr(FileMgt.ServerTempFileName('pdf'), 1, 250);

        ReportLayoutSelectionLocal.SetTempLayoutSelected(LayoutCode);
        OnBeforeSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, IsHandled, FilePath, ReportUsage, false, TempBlob, Rec);
        if not IsHandled then begin
            Report.SaveAsPdf(ReportID, FilePath, RecordVariant);
            FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
        end;
        OnAfterSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, FilePath, false, TempBlob, Rec, ReportUsage);

        ReportLayoutSelectionLocal.ClearTempLayoutSelected();

        Commit();
    end;

    procedure SaveReportAsPDFInTempBlob(var TempBlob: Codeunit "Temp Blob"; ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage")
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        CustomerStatementSub: codeunit "Customer Statement Subscr";
        LastUsedParameters: Text;
        IsHandled: Boolean;
        OutStream: OutStream;
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        if Rec."Report Layout Name" <> '' then
            ReportLayoutSelectionLocal.SetTempLayoutSelectedName(Rec."Report Layout Name", Rec."Report Layout AppID")
        else
            ReportLayoutSelectionLocal.SetTempLayoutSelected(LayoutCode);
        BindSubscription(CustomerStatementSub);
        OnBeforeSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, IsHandled, '', ReportUsage, true, TempBlob, Rec);
        UnbindSubscription(CustomerStatementSub);

        if not IsHandled then begin
            TempBlob.CreateOutStream(OutStream);
            LastUsedParameters := CustomLayoutReporting.GetReportRequestPageParameters(ReportID);
            Report.SaveAs(ReportID, LastUsedParameters, ReportFormat::Pdf, OutStream, GetRecRef(RecordVariant));
        end;
        OnAfterSaveReportAsPDF(ReportID, RecordVariant, LayoutCode, '', true, TempBlob, Rec, ReportUsage);

        ReportLayoutSelectionLocal.ClearTempLayoutSelected();

        Commit();
    end;

    local procedure GetRecRef(RecVariant: Variant) RecRef: RecordRef
    begin
        if RecVariant.IsRecordRef() then
            exit(RecVariant);
        if RecVariant.IsRecord() then
            RecRef.GetTable(RecVariant);
    end;

    local procedure SaveReportAsHTML(ReportID: Integer; RecordVariant: Variant; LayoutName: Text[250]; AppdID: Guid; ReportUsage: Enum "Report Selection Usage"; var TempBlob: Codeunit "Temp Blob")
    begin
        SaveReportAsHTMLImpl(ReportID, RecordVariant, '', LayoutName, AppdID, ReportUsage, TempBlob);
    end;

    local procedure SaveReportAsHTML(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; ReportUsage: Enum "Report Selection Usage"; var TempBlob: Codeunit "Temp Blob")
    var
        NullGuid: Guid;
    begin
        SaveReportAsHTMLImpl(ReportID, RecordVariant, LayoutCode, '', NullGuid, ReportUsage, TempBlob);
    end;

    local procedure SaveReportAsHTMLImpl(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; LayoutName: Text[250]; AppdID: Guid; ReportUsage: Enum "Report Selection Usage"; var TempBlob: Codeunit "Temp Blob")
    var
        ReportLayoutSelectionLocal: Record "Report Layout Selection";
    begin
        OnBeforeSetReportLayout(RecordVariant, ReportUsage.AsInteger());
        OnSaveReportAsHTMLOnBeforeSetTempLayoutSelected(RecordVariant, ReportUsage, ReportID, LayoutCode, LayoutName);
        if LayoutCode <> '' then
            ReportLayoutSelectionLocal.SetTempLayoutSelected(LayoutCode)
        else
            ReportLayoutSelectionLocal.SetTempLayoutSelectedName(LayoutName, AppdID);

        DoSaveReportAsHTMLInTempBlob(ReportID, RecordVariant, TempBlob);
        ReportLayoutSelectionLocal.ClearTempLayoutSelected();
    end;

    local procedure DoSaveReportAsHTMLInTempBlob(ReportID: Integer; var RecordVariant: Variant; var TempBlob: Codeunit "Temp Blob")
    var
        IsHandled: Boolean;
#if not CLEAN27
        FilePath: Text;
#endif
        FileOutStream: OutStream;
    begin
        IsHandled := false;
#if not CLEAN27
        OnBeforeDoSaveReportAsHTML(ReportID, FilePath, RecordVariant, IsHandled);
        if FilePath <> '' then
            FileManagement.BLOBImportFromServerFile(TempBlob, FilePath);
#endif
        OnBeforeDoSaveReportAsHTMLInTempBlob(ReportID, TempBlob, RecordVariant, IsHandled);
        if IsHandled then
            exit;
        TempBlob.CreateOutStream(FileOutStream, TextEncoding::UTF8);
        Report.SaveAs(ReportID, '', ReportFormat::Html, FileOutStream, GetRecRef(RecordVariant));
#if not CLEAN27
        FilePath := FileManagement.ServerTempFileName('html');
        FileManagement.BLOBExportToServerFile(TempBlob, FilePath);
        OnReplaceHTMLText(ReportID, FilePath, RecordVariant, IsHandled);
        if FilePath <> '' then
            FileManagement.BLOBImportFromServerFile(TempBlob, FilePath)
        else
            Clear(TempBlob);
#endif
        OnAfterDoSaveReportAsHTMLInTempBlob(ReportID, TempBlob, RecordVariant);
    end;

    procedure FindReportSelections(var TempReportSelections: Record "Report Selections" temporary; AccountNo: Code[20]; TableNo: Integer): Boolean
    var
        Handled: Boolean;
    begin
        OnFindReportSelections(TempReportSelections, Handled, Rec, AccountNo, TableNo);
        if Handled then
            exit(true);
        if not TempReportSelections.IsTemporary() then
            Error(ReportSelectionsMustBeTemporaryErr); // Avoid deleting actual entries in report selections

        if CopyCustomReportSectionToReportSelection(AccountNo, TempReportSelections, TableNo) then
            exit(true);

        exit(CopyReportSelectionToReportSelection(TempReportSelections));
    end;

    procedure CopyCustomReportSectionToReportSelection(AccountNo: Code[20]; var TempToReportSelections: Record "Report Selections" temporary; TableNo: Integer) Result: Boolean
    var
        CustomReportSelection: Record "Custom Report Selection";
        IsHandled: Boolean;
    begin
        OnBeforeCopyCustomReportSectionToReportSelection(Rec, IsHandled, Result);
        if IsHandled then
            exit(Result);

        GetCustomReportSelectionByUsageFilter(CustomReportSelection, AccountNo, GetFilter(Usage), TableNo);
        CopyToReportSelection(TempToReportSelections, CustomReportSelection);

        if not TempToReportSelections.FindSet() then
            exit(false);
        exit(true);
    end;

    local procedure CopyToReportSelection(var TempToReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection")
    begin
        TempToReportSelections.Reset();
        TempToReportSelections.DeleteAll();
        if CustomReportSelection.FindSet() then
            repeat
                TempToReportSelections.Usage := CustomReportSelection.Usage;
                TempToReportSelections.Sequence := Format(CustomReportSelection.Sequence);
                TempToReportSelections."Report ID" := CustomReportSelection."Report ID";
                TempToReportSelections."Custom Report Layout Code" := CustomReportSelection."Custom Report Layout Code";
                TempToReportSelections."Email Body Layout Code" := CustomReportSelection."Email Body Layout Code";
                TempToReportSelections."Email Body Layout Name" := CustomReportSelection."Email Body Layout Name";
                TempToReportSelections."Email Body Layout AppID" := CustomReportSelection."Email Body Layout AppID";
                TempToReportSelections."Use for Email Attachment" := CustomReportSelection."Use for Email Attachment";
                TempToReportSelections."Use for Email Body" := CustomReportSelection."Use for Email Body";
                TempToReportSelections."Report Layout Name" := CustomReportSelection."Email Attachment Layout Name";
                TempToReportSelections."Report Layout AppID" := CustomReportSelection."Email Attachment Layout AppID";
                OnCopyToReportSelectionOnBeforInsertToReportSelections(TempToReportSelections, CustomReportSelection);
                TempToReportSelections.Insert();
            until CustomReportSelection.Next() = 0;
    end;

    procedure CopyReportSelectionToReportSelection(var TempToReportSelections: Record "Report Selections" temporary): Boolean
    begin
        TempToReportSelections.Reset();
        TempToReportSelections.DeleteAll();
        if FindSet() then
            repeat
                TempToReportSelections := Rec;
                if TempToReportSelections.Insert() then;
            until Next() = 0;

        OnAfterCopyReportSelectionToReportSelection(Rec, TempToReportSelections);
        exit(TempToReportSelections.FindSet());
    end;

    local procedure GetCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustomReportSelection(Rec, CustomReportSelection, AccountNo, TableNo, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        CustomReportSelection.SetRange("Source Type", TableNo);
        CustomReportSelection.SetRange("Source No.", AccountNo);
        if CustomReportSelection.IsEmpty() then
            exit(false);

        CustomReportSelection.SetFilter("Use for Email Attachment", GetFilter("Use for Email Attachment"));
        CustomReportSelection.SetFilter("Use for Email Body", GetFilter("Use for Email Body"));

        OnAfterGetCustomReportSelection(CustomReportSelection, AccountNo, TableNo);
    end;

    local procedure GetCustomReportSelectionByUsageFilter(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; ReportUsageFilter: Text; TableNo: Integer): Boolean
    begin
        CustomReportSelection.SetFilter(Usage, ReportUsageFilter);
        exit(GetCustomReportSelection(CustomReportSelection, AccountNo, TableNo));
    end;

    procedure GetCustomReportSelectionByUsageOption(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; ReportUsage: Enum "Report Selection Usage"; TableNo: Integer): Boolean
    begin
        CustomReportSelection.SetRange(Usage, ReportUsage);
        exit(GetCustomReportSelection(CustomReportSelection, AccountNo, TableNo));
    end;

    local procedure GetNextEmailAddressFromCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; DefaultEmailAddress: Text; ReportUsage: Enum "Report Selection Usage"; SequenceText: Text): Text
    var
        SequenceInteger: Integer;
    begin
        if Evaluate(SequenceInteger, SequenceText) then begin
            CustomReportSelection.SetRange(Usage, ReportUsage);
            CustomReportSelection.SetRange(Sequence, SequenceInteger);
            OnGetNextEmailAddressFromCustomReportSelectionOnAfterCustomReportSelectionSetFilters(CustomReportSelection);
            if CustomReportSelection.FindFirst() then
                if CustomReportSelection.GetSendToEmail(true) <> '' then
                    exit(CustomReportSelection."Send To Email");
        end;
        exit(DefaultEmailAddress);
    end;

    procedure GetUniqueAccountNos(var TempNameValueBuffer: Record "Name/Value Buffer" temporary; RecRef: RecordRef; AccountNoFieldNo: Integer)
    var
        TempCustomer: Record Customer temporary;
        AccountNofieldRef: FieldRef;
    begin
        if AccountNoFieldNo <> 0 then begin
            AccountNofieldRef := RecRef.field(AccountNoFieldNo);
            if RecRef.FindSet() then
                repeat
                    TempNameValueBuffer.ID += 1;
                    TempNameValueBuffer.Name := AccountNofieldRef.Value();
                    TempCustomer."No." := AccountNofieldRef.Value(); // to avoid duplicate No. insertion into Name/Value buffer
                    if TempCustomer.Insert() then
                        TempNameValueBuffer.Insert();
                until RecRef.Next() = 0;
        end else begin
            TempNameValueBuffer.Init();
            TempNameValueBuffer.Insert();
        end;
    end;

    procedure PrintReportsForUsage(ReportUsage: Enum "Report Selection Usage")
    var
        ReportUsageInt: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        ReportUsageInt := ReportUsage.AsInteger();
        OnBeforePrintForUsage(ReportUsageInt, IsHandled);
        ReportUsage := "Report Selection Usage".FromInteger(ReportUsageInt);
        if IsHandled then
            exit;

        Reset();
        SetRange(Usage, ReportUsage);
        if FindSet() then
            repeat
                REPORT.RunModal("Report ID", true);
            until Next() = 0;
    end;

    local procedure FindEmailAddressForEmailLayout(LayoutCode: Code[20]; AccountNo: Code[20]; ReportUsage: Enum "Report Selection Usage"; TableNo: Integer): Text[200]
    var
        CustomReportSelection: Record "Custom Report Selection";
    begin
        // Search for a potential email address from Custom Report Selections
        GetCustomReportSelectionByUsageOption(CustomReportSelection, AccountNo, ReportUsage, TableNo);
        CustomReportSelection.UpdateSendtoEmail(false);
        CustomReportSelection.SetFilter("Send To Email", '<>%1', '');
        CustomReportSelection.SetRange("Email Body Layout Code", LayoutCode);
        if CustomReportSelection.FindFirst() then
            exit(CustomReportSelection."Send To Email");

        // Relax the filter and search for an email address
        CustomReportSelection.SetFilter("Use for Email Body", '');
        CustomReportSelection.SetRange("Email Body Layout Code", '');
        if CustomReportSelection.FindFirst() then
            exit(CustomReportSelection."Send To Email");
        exit('');
    end;

    procedure ShowNoBodyNoAttachmentError(ReportUsage: Enum "Report Selection Usage"; FoundBody: Boolean;
                                                           FoundAttachment: Boolean)
    begin
        if not (FoundBody or FoundAttachment) then begin
            Usage := ReportUsage;
            Error(MustSelectAndEmailBodyOrAttahmentErr, Usage);
        end;
    end;

    procedure ConvertReportUsageToSalesDocumentType(var DocumentType: Enum "Sales Document Type"; ReportUsage: Enum "Report Selection Usage"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeConvertReportUsageToSalesDocumentType(Rec, DocumentType, ReportUsage, IsHandled, Result);
        if IsHandled then
            exit(Result);

        case ReportUsage of
            Usage::"S.Invoice", Usage::"S.Invoice Draft", Usage::"P.Invoice":
                DocumentType := "Sales Document Type"::Invoice;
            Usage::"S.Quote", Usage::"P.Quote":
                DocumentType := "Sales Document Type"::Quote;
            Usage::"S.Cr.Memo", Usage::"P.Cr.Memo":
                DocumentType := "Sales Document Type"::"Credit Memo";
            Usage::"S.Order", Usage::"P.Order":
                DocumentType := "Sales Document Type"::Order;
            else
                exit(false);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure SendEmailInForeground(DocRecordID: RecordID; DocNo: Code[20]; DocName: Text[150]; ReportUsage: Integer; SourceIsCustomer: Boolean; SourceNo: Code[20]): Boolean
    var
        RecRef: RecordRef;
    begin
        // Blocks the user until the email is sent; use SendEmailInBackground for normal purposes.

        if not RecRef.Get(DocRecordID) then
            exit(false);

        RecRef.LockTable();
        RecRef.Find();
        RecRef.SetRecFilter();

        if SourceIsCustomer then
            exit(SendEmailToCustDirectly("Report Selection Usage".FromInteger(ReportUsage), RecRef, DocNo, DocName, false, SourceNo));

        exit(SendEmailToVendorDirectly("Report Selection Usage".FromInteger(ReportUsage), RecRef, DocNo, DocName, false, SourceNo));
    end;

    local procedure GetLastSequenceNo(var TempReportSelectionsSource: Record "Report Selections" temporary; ReportUsage: Enum "Report Selection Usage"): Code[10]
    var
        TempReportSelections: Record "Report Selections" temporary;
        IsHandled: Boolean;
    begin
        TempReportSelections.Copy(TempReportSelectionsSource, true);
        TempReportSelections.SetRange(Usage, ReportUsage);
        if TempReportSelections.FindLast() then;

        IsHandled := false;
        OnGetLastSequenceNoOnBeforeFillEmptySequence(TempReportSelections, IsHandled);
        if not IsHandled then
            if TempReportSelections.Sequence = '' then
                TempReportSelections.Sequence := '1';
        exit(TempReportSelections.Sequence);
    end;

    procedure IsSalesDocument(RecordRef: RecordRef): Boolean
    begin
        if RecordRef.Number in
           [Database::"Sales Header", Database::"Sales Shipment Header",
            Database::"Sales Cr.Memo Header", Database::"Sales Invoice Header"]
        then
            exit(true);
        exit(false);
    end;

    local procedure HasReportWithUsage(var TempReportSelectionsSource: Record "Report Selections" temporary; ReportUsage: Enum "Report Selection Usage"; ReportID: Integer): Boolean
    var
        TempReportSelections: Record "Report Selections" temporary;
    begin
        TempReportSelections.Copy(TempReportSelectionsSource, true);
        TempReportSelections.SetRange(Usage, ReportUsage);
        TempReportSelections.SetRange("Report ID", ReportID);
        exit(TempReportSelections.FindFirst());
    end;

    local procedure VerifyRecordBySystemId(var ParamString: Text; ReportUsage: Integer; RecRef: RecordRef)
    var
        SrcRecSysId: Guid;
    begin
        if not IsRecordSystemIdVerificationRequired(ReportUsage, RecRef.Number) then
            exit;

        Evaluate(SrcRecSysId, GetNextJobQueueParam(ParamString));
        if not RecRef.GetBySystemId(SrcRecSysId) then
            Error(RecordDoesNotMatchErr);
    end;

    local procedure IsRecordSystemIdVerificationRequired(ReportUsage: Integer; TableId: Integer): Boolean
    begin
        exit((ReportUsage = "Report Selection Usage"::"V.Remittance".AsInteger()) and (TableId = Database::"Gen. Journal Line"));
    end;

    internal procedure DoesAnyCustomLayotExist(): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
    begin
        CustomReportLayout.SetRange("Built-In", false);
        exit(not CustomReportLayout.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomReportSelection(var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetEmailBodyUsageFilters(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetEmailAttachmentUsageFilters(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetEmailUsageFilters(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveReportAsPDF(ReportID: Integer; RecordVariant: Variant; LayoutCode: Code[20]; FilePath: Text[250]; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob"; var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCanSaveReportAsPDF(ReportId: Integer; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmailBodyUsage(var ReportSelections: Record "Report Selections"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event will be removed. Please use Event OnBeforeDoSaveReportAsHTMLInTempBlob instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoSaveReportAsHTML(ReportID: Integer; var FilePath: Text[250]; var RecordVariant: Variant; var IsHandled: Boolean)
    begin
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoSaveReportAsHTMLInTempBlob(ReportID: Integer; var TemBlob: Codeunit "Temp Blob"; var RecordVariant: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustEmailAddress(BillToCustomerNo: Code[20]; var ToAddress: Text; ReportUsage: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetHtmlReport(var DocumentContent: Text; ReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetVendorEmailAddress(BuyFromVendorNo: Code[20]; var ToAddress: Text; ReportUsage: Option; var IsHandled: Boolean; RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailAddress(ReportUsage: Option; RecordVariant: Variant; var TempBodyReportSelections: Record "Report Selections" temporary; var EmailAddress: Text[250]; var IsHandled: Boolean; CustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailAddressIgnoringLayout(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var TempBodyReportSelections: Record "Report Selections" temporary; CustNo: Code[20]; var EmailAddress: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustomReportSelection(var ReportSelections: Record "Report Selections"; var CustomReportSelection: Record "Custom Report Selection"; AccountNo: Code[20]; TableNo: Integer; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrint(ReportUsage: Integer; RecordVariant: Variant; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintForUsage(var ReportUsage: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithCheck(ReportUsage: Integer; RecordVariant: Variant; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithCheckForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; VendorNoFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNoWithCheck(ReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNoWithCheckVendor(ReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; VendorNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNo(ReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; CustomerNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintWithGUIYesNoVendor(ReportUsage: Integer; RecordVariant: Variant; IsGUI: Boolean; VendorNoFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveReportAsPDF(var ReportID: Integer; RecordVariant: Variant; var LayoutCode: Code[20]; var IsHandled: Boolean; FilePath: Text[250]; ReportUsage: Enum "Report Selection Usage"; SaveToBlob: Boolean; var TempBlob: Codeunit "Temp Blob"; var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetReportLayout(RecordVariant: Variant; ReportUsage: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailToCust(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; var ShowDialog: Boolean; CustNo: Code[20]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text[150]; var ShowDialog: Boolean; VendorNo: Code[20]; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnqueueMailingJobOnBeforeRunJobQueueEnqueue(RecordIdToProcess: RecordID; ParameterString: Text; Description: Text; var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnFindReportSelections(var FilterReportSelections: Record "Report Selections"; var IsHandled: Boolean; var ReturnReportSelections: Record "Report Selections"; AccountNo: Code[20]; TableNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailBodyCustomer(ReportUsage: Integer; RecordVariant: Variant; var TempBodyReportSelections: Record "Report Selections" temporary; CustNo: Code[20]; var CustEmailAddress: Text[250]; var EmailBodyText: Text; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Use new Event OnAfterGetEmailBodyCustomerProcedure instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmailBodyCustomer(var CustomerEmailAddress: Text[250]; ServerEmailBodyFilePath: Text[250]; RecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmailBodyCustomerProcedure(var CustomerEmailAddress: Text[250]; var EmailBody: Codeunit "Temp Blob"; RecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetEmailBodyVendor(ReportUsage: Integer; RecordVariant: Variant; var TempBodyReportSelections: Record "Report Selections" temporary; VendorNo: Code[20]; var VendorEmailAddress: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPurchaseOrderEmailAddress(BuyFromVendorNo: Code[20]; RecVar: Variant; ReportUsage: Enum "Report Selection Usage"; var OrderAddress: Record "Order Address"; var EmailAddress: Text[250]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Use new Event OnAfterGetEmailBodyVendorProcedure instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmailBodyVendor(var VendorEmailAddress: Text[250]; ServerEmailBodyFilePath: Text[250]; RecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetEmailBodyVendorProcedure(var VendorEmailAddress: Text[250]; var EmailBody: Codeunit "Temp Blob"; RecordVariant: Variant; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendEmailDirectly(ReportUsage: Integer; RecordVariant: Variant; var AllEmailsWereSuccessful: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintDocument(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; RecVarToPrint: Variant; PrintDocumentWasHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintDocumentsWithCheckGUIYesNoCommon(ReportUsage: Integer; RecVarToPrint: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadAttachmentFromStream(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveDocumentAttachmentFromRecRef(RecRef: RecordRef; var TempAttachReportSelections: Record "Report Selections"; DocumentNo: Code[20]; AccountNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean; var NumberOfReportsAttached: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; var RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('Use new Event OnSendEmailDirectlyOnBeforeSend instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendEmailDirectly(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var DocNo: Code[20]; var DocName: Text[150]; FoundBody: Boolean; FoundAttachment: Boolean; ServerEmailBodyFilePath: Text[250]; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var AllEmailsWereSuccessful: Boolean; var IsHandled: Boolean; var SourceTableIDs: List of [Integer]; var SourceIDs: List of [Guid]; var SourceRelationTypes: List of [Integer])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSend(var ReportSelections: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var DocNo: Code[20]; var DocName: Text[150]; FoundBody: Boolean; FoundAttachment: Boolean; var EmailBody: Codeunit "Temp Blob"; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var AllEmailsWereSuccessful: Boolean; var IsHandled: Boolean; var SourceTableIDs: List of [Integer]; var SourceIDs: List of [Guid]; var SourceRelationTypes: List of [Integer])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckEmailBodyUsageOnAfterCalcShowEmailBodyDefinedError(var Rec: Record "Report Selections"; var ReportSelections: Record "Report Selections"; var ShowEmailBodyDefinedError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyToReportSelectionOnBeforInsertToReportSelections(var ReportSelections: Record "Report Selections"; CustomReportSelection: Record "Custom Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailAddressOnAfterGetEmailAddressForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var TempBodyReportSelections: Record "Report Selections" temporary; var EmailAddress: Text[250]; CustNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailBodyCustomerTextOnAfterNotFindEmailBodyUsage(ReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var TempBodyReportSelections: Record "Report Selections" temporary; var IsHandled: Boolean; var EmailBodyUsageFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailBodyVendorTextOnAfterNotFindEmailBodyUsage(ReportUsage: Integer; RecordVariant: Variant; CustNo: Code[20]; var TempBodyReportSelections: Record "Report Selections" temporary; var IsHandled: Boolean; var EmailBodyUsageFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintDocumentsOnAfterSelectTempReportSelectionsToPrint(RecordVariant: Variant; var TempReportSelections: Record "Report Selections" temporary; var TempNameValueBuffer: Record "Name/Value Buffer" temporary; var WithCheck: Boolean; ReportUsage: Integer; TableNo: Integer)
    begin
    end;

#if not CLEAN27
    [Obsolete('Use new Event OnSendEmailDirectlyOnBeforeSendSingleFile instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSendFileLoop(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; var DocName: Text[150]; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var IsHandled: Boolean; var ServerEmailBodyFilePath: Text[250])
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSendSingleFile(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocNo: Code[20]; var DocName: Text[150]; var DefaultEmailAddress: Text[250]; ShowDialog: Boolean; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var IsHandled: Boolean; var EmailBody: Codeunit "Temp Blob")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSendFiles(ReportUsage: Integer; RecordVariant: Variant; var DefaultEmailAddress: Text[250]; var TempAttachReportSelections: Record "Report Selections" temporary; var CustomReportSelection: Record "Custom Report Selection"; var ReportSelections: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeEmailWithAttachment(RecordVariant: Variant; ReportSelection: Record "Report Selections"; var TempBlob: Codeunit "Temp Blob"; var DocumentMailing: Codeunit "Document-Mailing"; DocumentNo: Code[20]; DocumentName: Text[150]; EmailAddress: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnBeforeSaveReportAsPDFInTempBlob(ReportSelection: Record "Report Selections"; RecordVariant: Variant; ReportUsage: Enum "Report Selection Usage"; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailInBackgroundOnAfterGetJobQueueParameters(var RecRef: RecordRef; var ParamString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailToCustOnAfterSetParameterString(var RecRef: RecordRef; var ParameterString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailToVendorOnAfterSetParameterString(var RecRef: RecordRef; var ParameterString: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToDiskForCustOnBeforeSendFileLoop(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToDiskForVendOnBeforeSendFileLoop(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToZipForCustOnBeforeSendFileLoop(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToZipForVendOnBeforeSendFileLoop(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsDocumentAttachmentOnBeforeShowNotification(RecordVariant: Variant; NumberOfReportsAttached: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveReportAsHTMLOnBeforeSetTempLayoutSelected(RecordVariant: Variant; ReportUsage: Enum "Report Selection Usage"; var ReportID: Integer; var LayoutCode: Code[20]; var LayoutName: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNextEmailAddressFromCustomReportSelectionOnAfterCustomReportSelectionSetFilters(var CustomReportSelection: Record "Custom Report Selection")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendToZipForCust(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var DataCompression: Codeunit "Data Compression")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSendToZipForVend(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; var DataCompression: Codeunit "Data Compression")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveAsDocumentAttachment(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSaveAsDocumentAttachmentOnBeforeCanSaveReportAsPDF(var TempAttachReportSelections: Record "Report Selections" temporary; RecRef: RecordRef; DocumentNo: Code[20]; AccountNo: Code[20]; NumberOfReportsAttached: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountNoFilterForCustomReportLayoutOnAfterSetCustomReportSelectionFilters(var CustomReportSelection: Record "Custom Report Selection"; var TempReportSelections: Record "Report Selections" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewRecord(var ReportSelections: Record "Report Selections"; var ReportSelections2: Record "Report Selections")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyCustomReportSectionToReportSelection(var ReportSelectionsOrg: Record "Report Selections"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetLastSequenceNoOnBeforeFillEmptySequence(var TempReportSelections: Record "Report Selections"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailBodyTextForCustOnBeforeFindEmailBodyUsageForCust(var ReportSelectionsOrg: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ReportSelections: Record "Report Selections"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetHtmlReportForCustOnBeforeFindReportUsage(var ReportSelectionsOrg: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ReportSelectionsPart: Record "Report Selections"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToZipForCustOnBeforeFindReportUsageForCust(var ReportSelectionsOrg: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ReportSelectionsPart: Record "Report Selections"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToDiskForCustOnBeforeFindReportUsage(var ReportSelectionsOrg: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ReportSelectionsPart: Record "Report Selections"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailToCustDirectlyOnBeforeFindEmailAttachmentUsageForCust(var ReportSelectionsOrg: Record "Report Selections"; ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ReportSelectionsPart: Record "Report Selections"; var FoundAttachment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSendToCustomerDirectly(ReportUsageEnum: Enum "Report Selection Usage"; RecordVariant: Variant; CustNo: Code[20]; var ShowDialog: Boolean; var SendToCustomerDirectly: Boolean; var Handled: Boolean)
    begin
    end;

#if not CLEAN27
    [Obsolete('This event will be removed. Please use Event OnBeforeDoSaveReportAsHTMLInTempBlob instead.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnReplaceHTMLText(ReportID: Integer; var FilePath: Text[250]; var RecordVariant: Variant; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterDoSaveReportAsHTMLInTempBlob(ReportID: Integer; var TempBlob: Codeunit "Temp Blob"; var RecordVariant: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsCustomerAccount(DocumentTableId: Integer; var IsCustomer: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsVendorAccount(DocumentTableId: Integer; var IsVendor: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnAfterSetFieldName(DocumentTableID: Integer; var FieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertReportUsageToSalesDocumentType(var ReportSelections: Record "Report Selections"; var DocumentType: Enum "Sales Document Type"; ReportUsage: Enum "Report Selection Usage"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendEmailDirectlyOnAfterEmailWithAttachment(RecordVariant: Variant; var TempReportSelections: Record "Report Selections" temporary; var TempBlob: Codeunit "Temp Blob"; var DocumentMailing: Codeunit "Document-Mailing"; DocumentNo: Code[20]; DocumentName: Text[150]; EmailAddress: Text[250]; AllEmailsWereSuccessful: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyReportSelectionToReportSelection(ReportSelections: Record "Report Selections"; var TempToReportSelections: Record "Report Selections" temporary)
    begin
    end;
}
