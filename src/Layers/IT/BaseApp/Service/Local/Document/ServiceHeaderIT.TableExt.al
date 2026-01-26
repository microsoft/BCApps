// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.CRM.Contact;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;

tableextension 12152 "Service Header IT" extends "Service Header"
{
    fields
    {
        field(12100; "Operation Type"; Code[20])
        {
            Caption = 'Operation Type';
            DataClassification = CustomerContent;
            TableRelation = "No. Series" where("No. Series Type" = filter(Sales));

            trigger OnLookup()
            begin
                if PAGE.RunModal(PAGE::"Operation Types", GlobalNoSeries) = ACTION::LookupOK then
                    Validate("Operation Type", GlobalNoSeries.Code);
            end;

            trigger OnValidate()
            begin
                if "Posting No." <> '' then
                    Error(CannotChangeErr, FieldCaption("Operation Type"), FieldCaption("Posting No."));

                if "Operation Type" <> '' then begin
                    GlobalNoSeries.Get("Operation Type");

                    if GlobalNoSeries."No. Series Type" <> GlobalNoSeries."No. Series Type"::Sales then
                        if not Confirm(HasPurchaseTypeVATRegisterQst, false, FieldCaption("Operation Type")) then
                            FieldError("Operation Type");

                    "Posting No. Series" := "Operation Type";
                end;
            end;
        }
        field(12101; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Operation Occurred Date" <> xRec."Operation Occurred Date" then
                    UpdateServLinesByFieldNo(FieldNo("Customer No."), false);
            end;
        }
        field(12123; "Activity Code"; Code[6])
        {
            Caption = 'Activity Code';
            DataClassification = CustomerContent;
            TableRelation = "Activity Code".Code;
        }
        field(12125; "Service Tariff No."; Code[10])
        {
            Caption = 'Service Tariff No.';
            DataClassification = CustomerContent;
            TableRelation = "Service Tariff Number";

            trigger OnValidate()
            begin
                if ("Service Tariff No." <> xRec."Service Tariff No.") and
                   (xRec."Customer No." = "Customer No.")
                then
                    MessageIfServLinesExist(CopyStr(FieldCaption("Service Tariff No."), 1, 100));
            end;
        }
        field(12130; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                LocalAppMgt: Codeunit LocalApplicationManagement;
            begin
                TestField(Resident, Resident::Resident);
                if "Fiscal Code" <> '' then
                    LocalAppMgt.CheckDigit("Fiscal Code");
            end;
        }
        field(12131; "Refers to Period"; Option)
        {
            Caption = 'Refers to Period';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Current,Current Calendar Year,Previous Calendar Year';
            OptionMembers = " ",Current,"Current Calendar Year","Previous Calendar Year";

            trigger OnValidate()
            begin
                if xRec."Refers to Period" <> "Refers to Period" then
                    MessageIfServLinesExist(CopyStr(FieldCaption("Refers to Period"), 1, 100));
            end;
        }
        field(12132; Resident; Option)
        {
            Caption = 'Resident';
            DataClassification = CustomerContent;
            OptionCaption = 'Resident,Non-Resident';
            OptionMembers = Resident,"Non-Resident";

            trigger OnValidate()
            begin
                TestField("Tax Representative Type", "Tax Representative Type"::" ");
                if Resident = Resident::Resident then
                    InitFields()
                else
                    "Fiscal Code" := '';
            end;
        }
        field(12133; "First Name"; Text[30])
        {
            Caption = 'First Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12134; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12135; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
            DataClassification = CustomerContent;
        }
        field(12136; "Individual Person"; Boolean)
        {
            Caption = 'Individual Person';
            DataClassification = CustomerContent;
        }
        field(12138; "Place of Birth"; Text[30])
        {
            Caption = 'Place of Birth';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
#pragma warning disable AA0232
        field(12170; "Payment %"; Decimal)
        {
            CalcFormula = sum("Payment Lines"."Payment %" where("Sales/Purchase" = const(Sales),
                                                                 Type = field("Document Type"),
                                                                 Code = field("No.")));
            Caption = 'Payment %';
            Editable = false;
            FieldClass = FlowField;
        }
#pragma warning restore AA0232
        field(12171; "Applies-to Occurrence No."; Integer)
        {
            Caption = 'Applies-to Occurrence No.';
            DataClassification = CustomerContent;
        }
        field(12172; "Bank Account"; Code[20])
        {
            Caption = 'Bank Account';
            DataClassification = CustomerContent;
            TableRelation = "Customer Bank Account".Code where("Customer No." = field("Bill-to Customer No."));
        }
        field(12173; "Cumulative Bank Receipts"; Boolean)
        {
            Caption = 'Cumulative Bank Receipts';
            DataClassification = CustomerContent;
        }
        field(12174; "3rd Party Loader Type"; Option)
        {
            Caption = '3rd Party Loader Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Vendor,Contact';
            OptionMembers = " ",Vendor,Contact;

            trigger OnValidate()
            begin
                if "3rd Party Loader Type" <> "3rd Party Loader Type"::" " then
                    ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
                if "3rd Party Loader Type" <> xRec."3rd Party Loader Type" then
                    "3rd Party Loader No." := '';
            end;
        }
        field(12175; "3rd Party Loader No."; Code[20])
        {
            Caption = '3rd Party Loader No.';
            DataClassification = CustomerContent;
            TableRelation = if ("3rd Party Loader Type" = const(Vendor)) Vendor
            else
            if ("3rd Party Loader Type" = const(Contact)) Contact where(Type = filter(Company));

            trigger OnValidate()
            begin
                ShipmentMethod.CheckShipMethod3rdPartyLoader("Shipment Method Code");
            end;
        }
        field(12176; "Additional Information"; Text[50])
        {
            Caption = 'Additional Information';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12177; "Additional Notes"; Text[50])
        {
            Caption = 'Additional Notes';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12178; "Additional Instructions"; Text[50])
        {
            Caption = 'Additional Instructions';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12179; "TDD Prepared By"; Text[50])
        {
            Caption = 'TDD Prepared By';
            OptimizeForTextSearch = true;
            DataClassification = EndUserIdentifiableInformation;
        }
        field(12180; "Tax Representative Type"; Option)
        {
            Caption = 'Tax Representative Type';
            DataClassification = CustomerContent;
            OptionCaption = ' ,Customer,Contact';
            OptionMembers = " ",Customer,Contact;

            trigger OnValidate()
            begin
                if "Tax Representative Type" <> "Tax Representative Type"::" " then begin
                    TestField("Individual Person", false);
                    TestField(Resident, Resident::"Non-Resident");
                end;
                if "Tax Representative Type" <> xRec."Tax Representative Type" then
                    "Tax Representative No." := '';
            end;
        }
        field(12181; "Tax Representative No."; Code[20])
        {
            Caption = 'Tax Representative No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Tax Representative Type" = filter(Customer)) Customer
            else
            if ("Tax Representative Type" = filter(Contact)) Contact;

            trigger OnValidate()
            begin
                if "Tax Representative No." <> '' then
                    TestField("Tax Representative Type");
            end;
        }
        field(12182; "Fattura Project Code"; Code[15])
        {
            Caption = 'Fattura Project Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Project));
        }
        field(12183; "Fattura Tender Code"; Code[15])
        {
            Caption = 'Fattura Tender Code';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Project Info".Code where(Type = filter(Tender));
        }
        field(12184; "Customer Purchase Order No."; Text[35])
        {
            Caption = 'Customer Purchase Order No.';
            DataClassification = CustomerContent;
            OptimizeForTextSearch = true;
        }
        field(12185; "Fattura Stamp"; Boolean)
        {
            Caption = 'Fattura Stamp';
            DataClassification = CustomerContent;
        }
        field(12186; "Fattura Stamp Amount"; Decimal)
        {
            Caption = 'Fattura Stamp Amount';
            DataClassification = CustomerContent;
        }
        field(12187; "Fattura Document Type"; Code[20])
        {
            Caption = 'Fattura Document Type';
            DataClassification = CustomerContent;
            TableRelation = "Fattura Document Type";
        }
    }

    keys
    {
        key(Key8; "Document Type", "Posting Date")
        {
        }
    }

    var
        ShipmentMethod: Record "Shipment Method";
        RecreateLinesQst: Label 'If you change %1, the existing service lines will be deleted and the program will create new service lines based on the new information on the header.\Do you want to change the %1?', Comment = '%1 - field caption';
        MustBeContactVendorErr: Label ' %1 %2 must be Vendor/Contact for %3 %4 3rd-Party Loader.', Comment = '%1 %2 - Shipping Agent, %3 %4 - Shippment Method';
        CustomerActiveVATExemptionQst: Label 'The customer has an active VAT exemption and VAT Bus. Posting Group hasn''t "Check VAT Exemption". Do you want to continue?';
        CannotInsertWithVATExemptionErr: Label 'It is not possible to insert a customer with VAT exemption if an active VAT exemption doesn''t exist.';
        HasPurchaseTypeVATRegisterQst: Label 'This %1 has a purchase type VAT register. Continue anyway?', Comment = '%1 - operation type';
        CannotChangeErr: Label 'You cannot change %1 because %2 is not blank', Comment = '%1 - operation type, %2 - posting no.';
        DeletingSplitVATLinesMsg: Label 'If you change %1, the existing service lines will be deleted and new service lines based on the new information on the header will be created.\\Automatically generated split VAT lines will be removed. If necessary, you can recreate them by choosing Generate Split VAT Lines.\\Do you want to change %1?', Comment = '%1=a field name or a table name whose value is just being changed';
        NothingToGenerateMsg: Label 'There are no invoice lines to be used for generating split VAT lines.';
        RegenerateSplitVATLinesQst: Label 'Split VAT Lines have already been generated automatically. Do you want to delete and regenerate them?';
        GenerateSplitVATLinesQst: Label 'Do you want to generate split VAT lines automatically?';
        MissingVATPostingSetupErr: Label 'To use the Split VAT function when %1 is %2, you must create a line in %3 with:\\%4 = %5\%6 = %2.', Comment = '%1=VAT Prod. Posting Group,%2=the value in VAT Prod. Posting Group,%3=VAT Posting Setup,%4=Reversed VAT Bus. Post. Group,%5=the value of Reversed VAT Bus. Post. Group,%6=Reversed VAT Prod. Post. Group';

    procedure CheckShipAgentMethodComb()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") and
           not ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code")
        then
            Error(
              MustBeContactVendorErr, FieldCaption("Shipping Agent Code"), "Shipping Agent Code",
              FieldCaption("Shipment Method Code"), "Shipment Method Code");
    end;

    [Scope('OnPrem')]
    procedure CheckTDDData()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        CheckShipAgentMethodComb();
        if ShipmentMethod.ThirdPartyLoader("Shipment Method Code") then begin
            TestField("3rd Party Loader Type");
            TestField("3rd Party Loader No.");
        end else begin
            TestField("3rd Party Loader Type", "3rd Party Loader Type"::" ");
            TestField("3rd Party Loader No.", '');
        end;
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then
            TestField("TDD Prepared By");
    end;

    procedure UpdateTDDPreparedBy()
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        if ShippingAgent.ShippingAgentVendorOrContact("Shipping Agent Code") then begin
            if "TDD Prepared By" = '' then
                "TDD Prepared By" := CopyStr(UserId(), 1, 50);
        end else
            "TDD Prepared By" := '';
    end;

    [Scope('OnPrem')]
    procedure CheckVATExemption() Confirmed: Boolean
    var
        VATExemption: Record "VAT Exemption";
        Check: Boolean;
    begin
        if "Document Type" in
           ["Document Type"::Order,
            "Document Type"::Invoice,
            "Document Type"::"Credit Memo"]
        then
            if FindVATExemption(VATExemption, Check, false) then begin
                if not Check then begin
                    if HideValidationDialog or not GuiAllowed then
                        Confirmed := true
                    else
                        Confirmed := Confirm(CustomerActiveVATExemptionQst, true);
                    exit(Confirmed);
                end;
            end else
                if Check then
                    Error(CannotInsertWithVATExemptionErr);

        exit(true);
    end;

    procedure AskUser(SplitVATLinesExist: Boolean; ChangedFieldName: Text[100]): Boolean
    var
        UserMessage: Text;
    begin
        UserMessage := ComposeUserMessage(SplitVATLinesExist, ChangedFieldName);
        exit(Confirm(UserMessage, false));
    end;

    [Scope('OnPrem')]
    procedure ComposeUserMessage(SplitVATLinesExist: Boolean; ChangedFieldName: Text[100]) UserMessage: Text
    begin
        if SplitVATLinesExist then
            UserMessage := StrSubstNo(DeletingSplitVATLinesMsg, ChangedFieldName)
        else
            UserMessage := StrSubstNo(RecreateLinesQst, ChangedFieldName);
    end;

    [Scope('OnPrem')]
    procedure RemoveSplitVATLines(var SplitServiceLine: Record "Service Line")
    begin
        SplitServiceLine.DeleteAll();
    end;

    procedure RemoveSplitVATLinesIfExist(var SplitServiceLine: Record "Service Line"; LinesExist: Boolean)
    begin
        if LinesExist then
            SplitServiceLine.DeleteAll();
    end;

    procedure SetOperationType()
    var
        VATBusPostingGroup: Record "VAT Business Posting Group";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetOperationType(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Document Type" <> "Document Type"::"Credit Memo" then
            if "VAT Bus. Posting Group" <> '' then begin
                VATBusPostingGroup.Get("VAT Bus. Posting Group");
                if VATBusPostingGroup."Default Sales Operation Type" <> '' then
                    Validate("Operation Type", VATBusPostingGroup."Default Sales Operation Type");
            end;

        OnAfterSetOperationType(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetOperationType(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetOperationType(var ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;

    procedure FindVATExemption(var VATExemption: Record "VAT Exemption"; var Check: Boolean; CheckFirst: Boolean): Boolean
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        Check := false;
        if VATBusinessPostingGroup.Get("VAT Bus. Posting Group") then
            Check := VATBusinessPostingGroup."Check VAT Exemption";
        if CheckFirst and not Check then
            exit(false);

        VATExemption.Reset();
        VATExemption.SetRange(Type, VATExemption.Type::Customer);
        VATExemption.SetRange("No.", "Bill-to Customer No.");
        VATExemption.SetFilter("VAT Exempt. Starting Date", '<=%1', "Document Date");
        VATExemption.SetFilter("VAT Exempt. Ending Date", '>=%1', "Document Date");
        exit(VATExemption.FindFirst())
    end;

    [Scope('OnPrem')]
    procedure InitFields()
    begin
        "First Name" := '';
        "Last Name" := '';
        "Date of Birth" := 0D;
        "Place of Birth" := '';
    end;

    procedure GenerateSplitVATLines()
    var
        SplitServiceLine: Record "Service Line";
    begin
        if not GuiAllowed then
            exit;

        if not ServiceLinesExist() then begin
            Message(NothingToGenerateMsg);
            exit;
        end;

        if GetSplitVATLines(SplitServiceLine) then begin
            if DIALOG.Confirm(RegenerateSplitVATLinesQst, true) then begin
                SplitServiceLine.DeleteAll();
                AddSplitVATLines();
            end;
            exit;
        end;

        if DIALOG.Confirm(GenerateSplitVATLinesQst, true) then
            AddSplitVATLines();
    end;

    [Scope('OnPrem')]
    procedure AddSplitVATLines()
    var
        DummyServiceLine: Record "Service Line";
    begin
        AddSplitVATLinesIgnoringALine(DummyServiceLine);
    end;

    [Scope('OnPrem')]
    procedure AddSplitVATLinesIgnoringALine(ServiceLineToIgnore: Record "Service Line")
    var
        SplitServiceLine: Record "Service Line";
        TotalingServiceLine: Record "Service Line";
        VATProdPostingGroupIterator: Code[20];
        CurrentLineNo: Integer;
    begin
        // Group lines per VAT Prod. Posting Group
        SplitServiceLine.SetCurrentKey("Document Type", "Document No.", "VAT Prod. Posting Group");
        // Select only lines that are not auto-generated
        SplitServiceLine.SetRange("Automatically Generated", false);
        SplitServiceLine.SetRange("Document Type", "Document Type");
        SplitServiceLine.SetRange("Document No.", "No.");
        SplitServiceLine.SetFilter(Type, '<>''''');
        if (ServiceLineToIgnore."Document No." = "No.") and (ServiceLineToIgnore."Document Type" = "Document Type") then
            SplitServiceLine.SetFilter("Line No.", '<>%1', ServiceLineToIgnore."Line No.");

        OnAddSplitVATLinesIgnoringALineOnAfterSetSplitServiceLineFilters(SplitServiceLine, Rec);

        if not SplitServiceLine.FindSet() then
            exit;

        CurrentLineNo := IncrementLineNo(GetHighestLineNo(SplitServiceLine));
        InitializeTotalingServiceLine(SplitServiceLine, TotalingServiceLine, CurrentLineNo);
        VATProdPostingGroupIterator := SplitServiceLine."VAT Prod. Posting Group";

        repeat
            if VATProdPostingGroupIterator <> SplitServiceLine."VAT Prod. Posting Group" then begin
                // Insert curent totaling split vat line

                TotalingServiceLine.Insert(true);
                // Reset totaling line

                CurrentLineNo := IncrementLineNo(CurrentLineNo);
                InitializeTotalingServiceLine(SplitServiceLine, TotalingServiceLine, CurrentLineNo);
                VATProdPostingGroupIterator := SplitServiceLine."VAT Prod. Posting Group";
            end;
            UpdateTotalingServiceLine(SplitServiceLine, TotalingServiceLine);
        until SplitServiceLine.Next() = 0;
        TotalingServiceLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure GetSplitVATLines(var SplitServiceLine: Record "Service Line"): Boolean
    begin
        SplitServiceLine.SetRange("Document Type", "Document Type");
        SplitServiceLine.SetRange("Document No.", "No.");
        SplitServiceLine.SetRange("Automatically Generated", true);
        exit(SplitServiceLine.FindSet());
    end;

    [Scope('OnPrem')]
    procedure UpdateTotalingServiceLine(SplitServiceLine: Record "Service Line"; var TotalingServiceLine: Record "Service Line")
    var
        TotalLineAmount: Decimal;
    begin
        TotalLineAmount := TotalingServiceLine."Unit Price" + SplitServiceLine."Amount Including VAT" - SplitServiceLine.Amount;
        TotalingServiceLine.Validate("Unit Price", TotalLineAmount);
    end;

    [Scope('OnPrem')]
    procedure InitializeTotalingServiceLine(SplitServiceLine: Record "Service Line"; var TotalingServiceLine: Record "Service Line"; LineNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        TotalingServiceLine.Init();
        TotalingServiceLine."Document No." := SplitServiceLine."Document No.";
        TotalingServiceLine.Validate("Document Type", SplitServiceLine."Document Type");
        TotalingServiceLine.Validate("Customer No.", SplitServiceLine."Customer No.");
        TotalingServiceLine.Validate(Type, TotalingServiceLine.Type::"G/L Account");

        // Get parameters from VAT Posting Setup
        GetVATPostingSetup(VATPostingSetup, SplitServiceLine);
        TotalingServiceLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        TotalingServiceLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        TotalingServiceLine."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type";
        TotalingServiceLine."No." := VATPostingSetup."Sales VAT Account";
        if GLAccount.Get(VATPostingSetup."Sales VAT Account") then
            TotalingServiceLine.Description := GLAccount.Name;

        // The field 'Quantity' is -1 because the auto-generated line is intended to reverse the VAT corresponsing to the group of
        // other lines
        TotalingServiceLine.Quantity := -1;
        TotalingServiceLine.Validate("Line No.", LineNo);
        TotalingServiceLine.Validate("Automatically Generated", true);
        TotalingServiceLine."Qty. to Invoice" := -1;
        if "Document Type" = "Document Type"::"Credit Memo" then
            TotalingServiceLine."Qty. to Ship" := 0
        else
            TotalingServiceLine."Qty. to Ship" := -1;
        TotalingServiceLine."Gen. Bus. Posting Group" := SplitServiceLine."Gen. Bus. Posting Group";
        TotalingServiceLine."Gen. Prod. Posting Group" := SplitServiceLine."Gen. Prod. Posting Group";
        TotalingServiceLine."VAT Identifier" := SplitServiceLine."VAT Identifier";
        TotalingServiceLine."Posting Date" := "Posting Date";
        TotalingServiceLine.CreateDimFromDefaultDim(0);
    end;

    [Scope('OnPrem')]
    procedure GetVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; SplitServiceLine: Record "Service Line")
    begin
        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("Reversed VAT Bus. Post. Group", SplitServiceLine."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("Reversed VAT Prod. Post. Group", SplitServiceLine."VAT Prod. Posting Group");

        if not VATPostingSetup.FindFirst() then
            Error(MissingVATPostingSetupErr,
              SplitServiceLine.FieldCaption("VAT Prod. Posting Group"),
              SplitServiceLine."VAT Prod. Posting Group",
              VATPostingSetup.TableCaption(),
              VATPostingSetup.FieldCaption("Reversed VAT Bus. Post. Group"),
              SplitServiceLine."VAT Bus. Posting Group",
              VATPostingSetup.FieldCaption("Reversed VAT Prod. Post. Group"));
    end;

    [Scope('OnPrem')]
    procedure GetHighestLineNo(SplitServiceLine: Record "Service Line"): Integer
    var
        LocalServiceLine: Record "Service Line";
    begin
        LocalServiceLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        LocalServiceLine.SetRange("Document Type", SplitServiceLine."Document Type");
        LocalServiceLine.SetRange("Document No.", SplitServiceLine."Document No.");
        if LocalServiceLine.FindLast() then;
        exit(LocalServiceLine."Line No.");
    end;

    [Scope('OnPrem')]
    procedure IncrementLineNo(LineNo: Integer): Integer
    begin
        exit(LineNo + 10000);
    end;

    [Scope('OnPrem')]
    procedure ServiceLinesExist(): Boolean
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", "Document Type");
        ServiceLine.SetRange("Document No.", "No.");
        exit(not ServiceLine.IsEmpty())
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddSplitVATLinesIgnoringALineOnAfterSetSplitServiceLineFilters(var SplitServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;
}