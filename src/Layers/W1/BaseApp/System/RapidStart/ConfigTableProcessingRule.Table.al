namespace System.IO;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using System.Reflection;

table 8631 "Config. Table Processing Rule"
{
    Caption = 'Config. Table Processing Rule';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Package Code"; Code[20])
        {
            Caption = 'Package Code';
            TableRelation = "Config. Package";
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Rule No."; Integer)
        {
            Caption = 'Rule No.';
        }
        field(4; "Action"; Option)
        {
            Caption = 'Action';
            OptionCaption = ',Custom,Post,Invoice,Ship,Receive';
            OptionMembers = ,Custom,Post,Invoice,Ship,Receive;

            trigger OnValidate()
            begin
                if not IsActionAllowed() then
                    FieldError(Action);
            end;
        }
        field(5; "Custom Processing Codeunit ID"; Integer)
        {
            Caption = 'Custom Processing Codeunit ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Codeunit));

            trigger OnValidate()
            begin
                if "Custom Processing Codeunit ID" <> 0 then
                    TestField(Action, Action::Custom)
                else
                    if Action = Action::Custom then
                        TestField("Custom Processing Codeunit ID");
            end;
        }
    }

    keys
    {
        key(Key1; "Package Code", "Table ID", "Rule No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
    begin
        ConfigPackageFilter.SetRange("Package Code", "Package Code");
        ConfigPackageFilter.SetRange("Table ID", "Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", "Rule No.");
        ConfigPackageFilter.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        CheckAction();
    end;

    trigger OnModify()
    begin
        CheckAction();
    end;

    local procedure CheckAction()
    begin
        TestField(Action);
        if Action = Action::Custom then
            TestField("Custom Processing Codeunit ID")
        else
            TestField("Custom Processing Codeunit ID", 0);
    end;

    local procedure FilterProcessingFilters(var ConfigPackageFilter: Record "Config. Package Filter")
    begin
        ConfigPackageFilter.SetRange("Package Code", "Package Code");
        ConfigPackageFilter.SetRange("Table ID", "Table ID");
        ConfigPackageFilter.SetRange("Processing Rule No.", "Rule No.");
    end;

    procedure FindTableRules(ConfigPackageTable: Record "Config. Package Table"): Boolean
    begin
        Reset();
        SetRange("Package Code", ConfigPackageTable."Package Code");
        SetRange("Table ID", ConfigPackageTable."Table ID");
        exit(FindSet());
    end;

    procedure GetFilterInfo() FilterInfo: Text
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        Separator: Text[2];
    begin
        if "Rule No." = 0 then
            exit('');

        FilterProcessingFilters(ConfigPackageFilter);
        ConfigPackageFilter.SetAutoCalcFields("Field Caption");
        if ConfigPackageFilter.FindSet() then
            repeat
                FilterInfo := FilterInfo + Separator + ConfigPackageFilter."Field Caption" + '=' + ConfigPackageFilter."Field Filter";
                Separator := ', ';
            until ConfigPackageFilter.Next() = 0
    end;

    local procedure IsActionAllowed(): Boolean
    begin
        if Action = Action::Custom then
            exit(true);

        case "Table ID" of
            Database::"Sales Header":
                exit(Action in [Action::Invoice, Action::Ship]);
            Database::"Purchase Header":
                exit(Action in [Action::Invoice, Action::Receive]);
            Database::"Gen. Journal Line", Database::"Gen. Journal Batch":
                exit(Action = Action::Post);
            Database::"Custom Report Layout":
                exit(Action = Action::Post);
            Database::"Transfer Header":
                exit(Action in [Action::Ship, Action::Receive]);
            Database::Item:
                exit(Action in [Action::Post]);
        end;
        exit(false);
    end;

    local procedure DoesTableHaveCustomRuleInRapidStart() Result: Boolean
    begin
        OnDoesTableHaveCustomRuleInRapidStart("Table ID", Result);
    end;

    procedure Process(ConfigRecordForProcessing: Record "Config. Record For Processing"): Boolean
    var
        ConfigPackageRecord: Record "Config. Package Record";
        RecRef: RecordRef;
    begin
        ConfigRecordForProcessing.FindConfigRule(Rec);
        if (Action = Action::Custom) and not DoesTableHaveCustomRuleInRapidStart() then begin
            if ConfigRecordForProcessing.FindConfigRecord(ConfigPackageRecord) then
                exit(CODEUNIT.Run("Custom Processing Codeunit ID", ConfigPackageRecord));
            exit(false);
        end;
        if ConfigRecordForProcessing.FindInsertedRecord(RecRef) then
            exit(RunActionOnInsertedRecord(RecRef));
    end;

    procedure RunActionOnInsertedRecord(RecRef: RecordRef): Boolean
    begin
        case "Table ID" of
            Database::"Sales Header":
                exit(RunActionOnSalesHeader(RecRef));
            Database::"Purchase Header":
                exit(RunActionOnPurchHeader(RecRef));
            Database::"Gen. Journal Line":
                exit(RunActionOnGenJnlLine(RecRef));
            Database::"Gen. Journal Batch":
                exit(RunActionOnGenJnlBatch(RecRef));
            Database::"Custom Report Layout":
                exit(RunActionOnCustomReportLayout(RecRef));
            Database::"Transfer Header":
                exit(RunActionOnTransferHeader(RecRef));
            Database::Item:
                exit(RunActionOnItem(RecRef));
            else
                exit(RunCustomActionOnRecRef(RecRef));
        end;
        exit(false);
    end;

    local procedure RunCustomActionOnRecRef(RecRef: RecordRef): Boolean
    var
        RecRefVariant: Variant;
    begin
        if Action = Action::Custom then begin
            RecRefVariant := RecRef;
            exit(CODEUNIT.Run("Custom Processing Codeunit ID", RecRefVariant));
        end;
    end;

    local procedure RunActionOnGenJnlBatch(RecRef: RecordRef): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if Action = Action::Post then begin
            RecRef.SetTable(GenJnlBatch);
            GenJnlLine.Reset();
            GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
            if GenJnlLine.FindFirst() then
                exit(CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine));
        end;
        exit(false);
    end;

    local procedure RunActionOnGenJnlLine(RecRef: RecordRef): Boolean
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if Action = Action::Post then begin
            RecRef.SetTable(GenJnlLine);
            GenJnlLine.Reset();
            GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
            GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
            GenJnlLine.SetRange("Line No.", GenJnlLine."Line No.");
            exit(CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post Batch", GenJnlLine));
        end;
        exit(false);
    end;

    local procedure RunActionOnPurchHeader(RecRef: RecordRef): Boolean
    var
        PurchHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchHeader);
        case Action of
            Action::Custom:
                exit(CODEUNIT.Run("Custom Processing Codeunit ID", PurchHeader));
            Action::Invoice:
                begin
                    PurchHeader.Validate(Invoice, true);
                    PurchHeader.Validate(Receive, true);
                    exit(CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchHeader));
                end;
            Action::Receive:
                begin
                    PurchHeader.TestField("Document Type", PurchHeader."Document Type"::Order);
                    PurchHeader.Validate(Invoice, false);
                    PurchHeader.Validate(Receive, true);
                    exit(CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchHeader));
                end;
        end;
        exit(false);
    end;

    local procedure RunActionOnSalesHeader(RecRef: RecordRef): Boolean
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        case Action of
            Action::Custom:
                exit(CODEUNIT.Run("Custom Processing Codeunit ID", SalesHeader));
            Action::Invoice:
                begin
                    SalesHeader.Validate(Invoice, true);
                    SalesHeader.Validate(Ship, true);
                    exit(CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader));
                end;
            Action::Ship:
                begin
                    SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);
                    SalesHeader.Validate(Invoice, false);
                    SalesHeader.Validate(Ship, true);
                    exit(CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader));
                end;
        end;
        exit(false);
    end;

    local procedure RunActionOnTransferHeader(RecRef: RecordRef): Boolean
    var
        TransferHeader: Record "Transfer Header";
        TransferOrderPostShipment: Codeunit "TransferOrder-Post Shipment";
        TransferOrderPostReceipt: Codeunit "TransferOrder-Post Receipt";
    begin
        RecRef.SetTable(TransferHeader);
        case Action of
            Action::Ship:
                begin
                    TransferOrderPostShipment.SetHideValidationDialog(true);
                    exit(TransferOrderPostShipment.Run(TransferHeader));
                end;
            Action::Receive:
                begin
                    TransferOrderPostReceipt.SetHideValidationDialog(true);
                    exit(TransferOrderPostReceipt.Run(TransferHeader));
                end;
        end;
        exit(false);
    end;

    procedure ShowFilters()
    var
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageFilters: Page "Config. Package Filters";
    begin
        ConfigPackageFilter.FilterGroup(2);
        FilterProcessingFilters(ConfigPackageFilter);
        ConfigPackageFilter.FilterGroup(0);
        ConfigPackageFilters.SetTableView(ConfigPackageFilter);
        ConfigPackageFilters.RunModal();
        Clear(ConfigPackageFilters);
    end;

    local procedure RunActionOnCustomReportLayout(RecRef: RecordRef): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        RecRef.SetTable(CustomReportLayout);
        case Action of
            Action::Custom:
                exit(CODEUNIT.Run("Custom Processing Codeunit ID", CustomReportLayout));
            Action::Post:
                begin
                    ReportLayoutSelection.Validate("Report ID", CustomReportLayout."Report ID");
                    ReportLayoutSelection.Validate("Company Name", CompanyName);
                    ReportLayoutSelection.Validate(Type, ReportLayoutSelection.Type::"Custom Layout");
                    ReportLayoutSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);
                    if ReportLayoutSelection.Insert(true) then;
                    exit(true);
                end;
        end;
        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDoesTableHaveCustomRuleInRapidStart(TableID: Integer; var Result: Boolean)
    begin
    end;

    local procedure RunActionOnItem(RecRef: RecordRef): Boolean
    var
        Item: Record Item;
    begin
        if Action = Action::Post then begin
            RecRef.SetTable(Item);
            exit(CODEUNIT.Run(CODEUNIT::"Setup Item Costing Method", Item));
        end;
        exit(false);
    end;
}

