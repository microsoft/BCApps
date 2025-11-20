// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Comment;
using Microsoft.Service.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

table 5970 "Filed Service Contract Header"
{
    Caption = 'Filed Service Contract Header';
    DrillDownPageID = "Filed Service Contract List";
    LookupPageID = "Filed Service Contract List";
    Permissions = tabledata "Filed Service Contract Header" = rimd,
                  tabledata "Filed Contract Line" = rimd,
                  tabledata "Filed Serv. Contract Cmt. Line" = rimd,
                  tabledata "Filed Contract Service Hour" = rimd,
                  tabledata "Filed Contract/Serv. Discount" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contract No."; Code[20])
        {
            Caption = 'Contract No.';
        }
        field(2; "Contract Type"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = ' ,Signed,Canceled';
            OptionMembers = " ",Signed,Canceled;
        }
        field(6; "Change Status"; Enum "Service Contract Change Status")
        {
            Caption = 'Change Status';
        }
        field(7; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            NotBlank = true;
            TableRelation = Customer;
        }
        field(8; Name; Text[100])
        {
            Caption = 'Name';
            Editable = false;
        }
        field(9; Address; Text[100])
        {
            Caption = 'Address';
            Editable = false;
        }
        field(10; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            Editable = false;
        }
        field(11; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            Editable = false;
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(12; City; Text[30])
        {
            Caption = 'City';
            Editable = false;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(13; "Contact Name"; Text[100])
        {
            Caption = 'Contact Name';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(16; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            TableRelation = Customer;
        }
        field(17; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
            Editable = false;
        }
        field(18; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
            Editable = false;
        }
        field(19; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
            Editable = false;
        }
        field(20; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
            Editable = false;
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(21; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
            Editable = false;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(22; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(23; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
            Editable = false;
        }
        field(24; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
            Editable = false;
        }
        field(25; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
            Editable = false;
        }
        field(26; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
            Editable = false;
            TableRelation = "Post Code";
            ValidateTableRelation = false;
        }
        field(27; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
            Editable = false;
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;
        }
        field(28; "Serv. Contract Acc. Gr. Code"; Code[10])
        {
            Caption = 'Serv. Contract Acc. Gr. Code';
            TableRelation = "Service Contract Account Group".Code;
        }
        field(32; "Invoice Period"; Enum "Service Contract Header Invoice Period")
        {
            Caption = 'Invoice Period';
        }
        field(33; "Last Invoice Date"; Date)
        {
            Caption = 'Last Invoice Date';
            Editable = false;
        }
        field(34; "Next Invoice Date"; Date)
        {
            Caption = 'Next Invoice Date';
        }
        field(35; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(36; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(38; "First Service Date"; Date)
        {
            Caption = 'First Service Date';
        }
        field(39; "Max. Labor Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Max. Labor Unit Price';
        }
        field(40; "Calcd. Annual Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Calcd. Annual Amount';
        }
        field(42; "Annual Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Annual Amount';
            MinValue = 0;
        }
        field(43; "Amount per Period"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount per Period';
            Editable = false;
        }
        field(44; "Combine Invoices"; Boolean)
        {
            Caption = 'Combine Invoices';
        }
        field(45; Prepaid; Boolean)
        {
            Caption = 'Prepaid';
        }
        field(46; "Next Invoice Period"; Text[30])
        {
            Caption = 'Next Invoice Period';
            Editable = false;
        }
        field(47; "Service Zone Code"; Code[10])
        {
            Caption = 'Service Zone Code';
            TableRelation = "Service Zone";
        }
        field(48; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(49; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(50; "Cancel Reason Code"; Code[10])
        {
            Caption = 'Cancel Reason Code';
            TableRelation = "Reason Code";
        }
        field(51; "Last Price Update Date"; Date)
        {
            Caption = 'Last Price Update Date';
            Editable = false;
        }
        field(52; "Next Price Update Date"; Date)
        {
            Caption = 'Next Price Update Date';
        }
        field(53; "Last Price Update %"; Decimal)
        {
            Caption = 'Last Price Update %';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(55; "Response Time (Hours)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Response Time (Hours)';
            DecimalPlaces = 0 : 5;
        }
        field(56; "Contract Lines on Invoice"; Boolean)
        {
            Caption = 'Contract Lines on Invoice';
        }
        field(59; "Service Period"; DateFormula)
        {
            Caption = 'Service Period';
        }
        field(60; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(62; "Invoice after Service"; Boolean)
        {
            Caption = 'Invoice after Service';
        }
        field(63; "Quote Type"; Option)
        {
            Caption = 'Quote Type';
            OptionCaption = 'Quote 1.,Quote 2.,Quote 3.,Quote 4.,Quote 5.,Quote 6.,Quote 7.,Quote 8.';
            OptionMembers = "Quote 1.","Quote 2.","Quote 3.","Quote 4.","Quote 5.","Quote 6.","Quote 7.","Quote 8.";
        }
        field(64; "Allow Unbalanced Amounts"; Boolean)
        {
            Caption = 'Allow Unbalanced Amounts';
        }
        field(65; "Contract Group Code"; Code[10])
        {
            Caption = 'Contract Group Code';
            TableRelation = "Contract Group";
        }
        field(66; "Service Order Type"; Code[10])
        {
            Caption = 'Service Order Type';
            TableRelation = "Service Order Type";
        }
        field(67; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(68; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(69; "Accept Before"; Date)
        {
            Caption = 'Accept Before';
        }
        field(71; "Automatic Credit Memos"; Boolean)
        {
            Caption = 'Automatic Credit Memos';
        }
        field(74; "Template No."; Code[20])
        {
            Caption = 'Template No.';
        }
        field(75; "Price Update Period"; DateFormula)
        {
            Caption = 'Price Update Period';
            InitValue = '1Y';
        }
        field(79; "Price Inv. Increase Code"; Code[20])
        {
            Caption = 'Price Inv. Increase Code';
            TableRelation = "Standard Text";
        }
        field(80; "Print Increase Text"; Boolean)
        {
            Caption = 'Print Increase Text';
        }
        field(81; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(82; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(83; Probability; Decimal)
        {
            Caption = 'Probability';
            DecimalPlaces = 0 : 5;
            InitValue = 100;
        }
        field(84; Comment; Boolean)
        {
            CalcFormula = exist("Filed Serv. Contract Cmt. Line" where("Entry No." = field("Entry No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
            TableRelation = "Responsibility Center";
        }
        field(86; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(87; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(88; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                if "E-Mail" = '' then
                    exit;
                MailManagement.CheckValidEmailAddresses("E-Mail");
            end;
        }
        field(89; "Bill-to County"; Text[30])
        {
            CaptionClass = '5,3,' + "Bill-to Country/Region Code";
            Caption = 'Bill-to County';
        }
        field(90; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(91; "Ship-to County"; Text[30])
        {
            CaptionClass = '5,4,' + "Ship-to Country/Region Code";
            Caption = 'Ship-to County';
        }
        field(92; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(93; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(94; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(95; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            Editable = false;
        }
        field(96; "Bill-to Name 2"; Text[50])
        {
            Caption = 'Bill-to Name 2';
            Editable = false;
        }
        field(97; "Ship-to Name 2"; Text[50])
        {
            Caption = 'Ship-to Name 2';
            Editable = false;
        }
        field(98; "Next Invoice Period Start"; Date)
        {
            Caption = 'Next Invoice Period Start';
            Editable = false;
        }
        field(99; "Next Invoice Period End"; Date)
        {
            Caption = 'Next Invoice Period End';
            Editable = false;
        }
        field(100; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the unique number of filed service contract or service contract quote.';
        }
        field(101; "File Date"; Date)
        {
            Caption = 'File Date';
        }
        field(102; "File Time"; Time)
        {
            Caption = 'File Time';
        }
        field(103; "Filed By"; Code[50])
        {
            Caption = 'Filed By';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(104; "Reason for Filing"; Option)
        {
            Caption = 'Reason for Filing';
            OptionCaption = ' ,Contract Signed,Contract Canceled';
            OptionMembers = " ","Contract Signed","Contract Canceled";
        }
        field(105; "Contract Type Relation"; Enum "Service Contract Type")
        {
            Caption = 'Contract Type Relation';
        }
        field(106; "Contract No. Relation"; Code[20])
        {
            Caption = 'Contract No. Relation';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = field("Contract Type Relation"));
        }
#pragma warning disable AA0232
        field(109; "No. of Filed Versions"; Integer)
#pragma warning restore AA0232
        {
            Caption = 'No. of Filed Versions';
            FieldClass = FlowField;
            CalcFormula = max("Filed Service Contract Header"."Entry No." where("Contract Type Relation" = field("Contract Type Relation"),
                                                                                "Contract No. Relation" = field("Contract No. Relation")));
            Editable = false;
        }
        field(110; "Restorable"; Boolean)
        {
            Caption = 'Restorable';
        }
        field(111; "Source Contract Exists"; Boolean)
        {
            Caption = 'Source Contract Exists';
            FieldClass = FlowField;
            CalcFormula = exist("Service Contract Header" where("Contract Type" = field("Contract Type Relation"),
                                                                "Contract No." = field("Contract No. Relation")));
            Editable = false;
        }
        field(112; "Last Filed DateTime"; DateTime)
        {
            Caption = 'Last Filed DateTime';
            FieldClass = FlowField;
            CalcFormula = max("Filed Service Contract Header".SystemCreatedAt where("Contract Type Relation" = field("Contract Type Relation"),
                                                                                    "Contract No. Relation" = field("Contract No. Relation")));
            Editable = false;
        }
        field(204; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(210; "Ship-to Phone No."; Text[30])
        {
            Caption = 'Ship-to Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions();
            end;
        }
        field(1200; "Direct Debit Mandate ID"; Code[35])
        {
            Caption = 'Direct Debit Mandate ID';
            TableRelation = "SEPA Direct Debit Mandate" where("Customer No." = field("Bill-to Customer No."));
            DataClassification = SystemMetadata;
        }
        field(5050; "Contact No."; Code[20])
        {
            Caption = 'Contact No.';
            TableRelation = Contact;
        }
        field(5051; "Bill-to Contact No."; Code[20])
        {
            Caption = 'Bill-to Contact No.';
            TableRelation = Contact;
        }
        field(5052; "Bill-to Contact"; Text[100])
        {
            Caption = 'Bill-to Contact';
        }
        field(5053; "Last Invoice Period End"; Date)
        {
            Caption = 'Last Invoice Period End';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Contract Type Relation", "Contract No. Relation", "File Date", "File Time")
        {
        }
        key(Key3; "Contract Type", "Contract No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        FiledContractLine: Record "Filed Contract Line";
        FiledServContractCmtLine: Record "Filed Serv. Contract Cmt. Line";
        FiledContractServiceHour: Record "Filed Contract Service Hour";
        FiledContractServDiscount: Record "Filed Contract/Serv. Discount";
    begin
        FiledContractLine.SetRange("Entry No.", "Entry No.");
        FiledContractLine.DeleteAll();

        FiledServContractCmtLine.SetRange("Entry No.", "Entry No.");
        if not FiledServContractCmtLine.IsEmpty() then
            FiledServContractCmtLine.DeleteAll();

        FiledContractServiceHour.SetRange("Entry No.", "Entry No.");
        if not FiledContractServiceHour.IsEmpty() then
            FiledContractServiceHour.DeleteAll();

        FiledContractServDiscount.SetRange("Entry No.", "Entry No.");
        if not FiledContractServDiscount.IsEmpty() then
            FiledContractServDiscount.DeleteAll();
    end;

    var
        SigningQuotation: Boolean;
        CancelContract: Boolean;
        InvocePeriodRangeLbl: Label '%1 to %2', Comment = '%1 = Next Invoice Period Start, %2 = Next Invoice Period End';

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure FileContract(ServiceContractHeader: Record "Service Contract Header")
    var
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        ServiceContractLine: Record "Service Contract Line";
        FiledContractLine: Record "Filed Contract Line";
        RecordLinkManagement: Codeunit "Record Link Management";
        NextEntryNo: Integer;
    begin
        ServiceContractHeader.TestField("Contract No.");

        FiledServiceContractHeader.LockTable();
        NextEntryNo := FiledServiceContractHeader.GetLastEntryNo() + 1;

        FiledServiceContractHeader.Init();
        ServiceContractHeader.CalcFields(
          Name, Address, "Address 2", "Post Code", City, County, "Country/Region Code", "Name 2",
          "Bill-to Name", "Bill-to Address", "Bill-to Address 2", "Bill-to Post Code",
          "Bill-to City", "Bill-to County", "Bill-to Country/Region Code", "Bill-to Name 2",
          "Calcd. Annual Amount");
        if ServiceContractHeader."Ship-to Code" = '' then begin
            ServiceContractHeader."Ship-to Name" := ServiceContractHeader.Name;
            ServiceContractHeader."Ship-to Address" := ServiceContractHeader.Address;
            ServiceContractHeader."Ship-to Address 2" := ServiceContractHeader."Address 2";
            ServiceContractHeader."Ship-to Post Code" := ServiceContractHeader."Post Code";
            ServiceContractHeader."Ship-to City" := ServiceContractHeader.City;
            ServiceContractHeader."Ship-to County" := ServiceContractHeader.County;
            ServiceContractHeader."Ship-to Country/Region Code" := ServiceContractHeader."Country/Region Code";
            ServiceContractHeader."Ship-to Name 2" := ServiceContractHeader."Name 2";
            ServiceContractHeader."Ship-to Phone No." := ServiceContractHeader."Phone No.";
        end else
            ServiceContractHeader.CalcFields(
              "Ship-to Name", "Ship-to Address", "Ship-to Address 2", "Ship-to Post Code", "Ship-to City",
              "Ship-to County", "Ship-to Country/Region Code", "Ship-to Name 2", "Ship-to Phone No.");

        FiledServiceContractHeader.TransferFields(ServiceContractHeader);

        if SigningQuotation then
            FiledServiceContractHeader."Reason for Filing" :=
              FiledServiceContractHeader."Reason for Filing"::"Contract Signed";

        if CancelContract then
            FiledServiceContractHeader."Reason for Filing" :=
              FiledServiceContractHeader."Reason for Filing"::"Contract Canceled";

        FiledServiceContractHeader."Contract Type Relation" := ServiceContractHeader."Contract Type";
        FiledServiceContractHeader."Contract No. Relation" := ServiceContractHeader."Contract No.";
        FiledServiceContractHeader."Entry No." := NextEntryNo;
        FiledServiceContractHeader."File Date" := Today();
        FiledServiceContractHeader."File Time" := Time();
        FiledServiceContractHeader."Filed By" := CopyStr(UserId(), 1, MaxStrLen(FiledServiceContractHeader."Filed By"));
        FiledServiceContractHeader.Restorable := true;
        FiledServiceContractHeader.Name := ServiceContractHeader.Name;
        FiledServiceContractHeader.Address := ServiceContractHeader.Address;
        FiledServiceContractHeader."Address 2" := ServiceContractHeader."Address 2";
        FiledServiceContractHeader."Post Code" := ServiceContractHeader."Post Code";
        FiledServiceContractHeader.City := ServiceContractHeader.City;
        FiledServiceContractHeader."Bill-to Name" := ServiceContractHeader."Bill-to Name";
        FiledServiceContractHeader."Bill-to Address" := ServiceContractHeader."Bill-to Address";
        FiledServiceContractHeader."Bill-to Address 2" := ServiceContractHeader."Bill-to Address 2";
        FiledServiceContractHeader."Bill-to Post Code" := ServiceContractHeader."Bill-to Post Code";
        FiledServiceContractHeader."Bill-to City" := ServiceContractHeader."Bill-to City";
        FiledServiceContractHeader."Ship-to Name" := ServiceContractHeader."Ship-to Name";
        FiledServiceContractHeader."Ship-to Address" := ServiceContractHeader."Ship-to Address";
        FiledServiceContractHeader."Ship-to Address 2" := ServiceContractHeader."Ship-to Address 2";
        FiledServiceContractHeader."Ship-to Post Code" := ServiceContractHeader."Ship-to Post Code";
        FiledServiceContractHeader."Ship-to City" := ServiceContractHeader."Ship-to City";
        FiledServiceContractHeader."Calcd. Annual Amount" := ServiceContractHeader."Calcd. Annual Amount";
        FiledServiceContractHeader."Bill-to County" := ServiceContractHeader."Bill-to County";
        FiledServiceContractHeader.County := ServiceContractHeader.County;
        FiledServiceContractHeader."Ship-to County" := ServiceContractHeader."Ship-to County";
        FiledServiceContractHeader."Country/Region Code" := ServiceContractHeader."Country/Region Code";
        FiledServiceContractHeader."Bill-to Country/Region Code" := ServiceContractHeader."Bill-to Country/Region Code";
        FiledServiceContractHeader."Ship-to Country/Region Code" := ServiceContractHeader."Ship-to Country/Region Code";
        FiledServiceContractHeader."Ship-to Phone No." := ServiceContractHeader."Ship-to Phone No.";
        FiledServiceContractHeader."Name 2" := ServiceContractHeader."Name 2";
        FiledServiceContractHeader."Bill-to Name 2" := ServiceContractHeader."Bill-to Name 2";
        FiledServiceContractHeader."Ship-to Name 2" := ServiceContractHeader."Ship-to Name 2";
        RecordLinkManagement.CopyLinks(ServiceContractHeader, FiledServiceContractHeader);
        OnFileContractOnBeforeFiledServContractHeaderInsert(ServiceContractHeader, FiledServiceContractHeader);
        FiledServiceContractHeader.Insert();

        ServiceContractLine.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ServiceContractLine.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        if ServiceContractLine.FindSet() then
            repeat
                FiledContractLine.Init();
                FiledContractLine."Entry No." := FiledServiceContractHeader."Entry No.";
                OnFileContractOnBeforeFiledContractLineTransferFields(ServiceContractLine);
                FiledContractLine.TransferFields(ServiceContractLine);
                RecordLinkManagement.CopyLinks(ServiceContractLine, FiledContractLine);
                FiledContractLine.Insert();
            until ServiceContractLine.Next() = 0;

        FileServiceContractComments(ServiceContractHeader, FiledServiceContractHeader);
        FileServiceContractServiceHours(ServiceContractHeader, FiledServiceContractHeader);
        FileServiceContractContractServDiscounts(ServiceContractHeader, FiledServiceContractHeader);

        OnAfterFileContract(FiledServiceContractHeader, ServiceContractHeader);
    end;

    procedure FileQuotationBeforeSigning(ServiceContractHeader: Record "Service Contract Header")
    begin
        SigningQuotation := true;
        FileContract(ServiceContractHeader);
        SigningQuotation := false;
    end;

    procedure FileContractBeforeCancellation(ServiceContractHeader: Record "Service Contract Header")
    begin
        CancelContract := true;
        FileContract(ServiceContractHeader);
        CancelContract := false;
    end;

    procedure NextInvoicePeriod(): Text[250]
    begin
        if ("Next Invoice Period Start" <> 0D) and ("Next Invoice Period End" <> 0D) then
            exit(StrSubstNo(InvocePeriodRangeLbl, "Next Invoice Period Start", "Next Invoice Period End"));
    end;

    local procedure ShowDimensions()
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Contract No."), 1, 250));
    end;

    internal procedure SetSecurityFilterOnResponsibilityCenter()
    var
        UserSetupManagement: Codeunit "User Setup Management";
    begin
        if UserSetupManagement.GetServiceFilter() <> '' then begin
            FilterGroup(2);
            SetRange("Responsibility Center", UserSetupManagement.GetServiceFilter());
            FilterGroup(0);
        end;
    end;

    local procedure FileServiceContractComments(ServiceContractHeader: Record "Service Contract Header"; var FiledServiceContractHeader: Record "Filed Service Contract Header")
    var
        ServiceCommentLine: Record "Service Comment Line";
        FiledServContractCmtLine: Record "Filed Serv. Contract Cmt. Line";
    begin
        ServiceCommentLine.SetRange("Table Name", ServiceCommentLine."Table Name"::"Service Contract");
        ServiceCommentLine.SetRange("Table Subtype", ServiceContractHeader."Contract Type");
        ServiceCommentLine.SetRange("No.", ServiceContractHeader."Contract No.");
        if ServiceCommentLine.FindSet() then
            repeat
                FiledServContractCmtLine.Init();
                FiledServContractCmtLine.TransferFields(ServiceCommentLine);
                FiledServContractCmtLine."Entry No." := FiledServiceContractHeader."Entry No.";
                FiledServContractCmtLine.Insert();
            until ServiceCommentLine.Next() = 0;
    end;

    local procedure FileServiceContractServiceHours(ServiceContractHeader: Record "Service Contract Header"; var FiledServiceContractHeader: Record "Filed Service Contract Header")
    var
        ServiceHour: Record "Service Hour";
        FiledContractServiceHour: Record "Filed Contract Service Hour";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        case ServiceContractHeader."Contract Type" of
            ServiceContractHeader."Contract Type"::Quote:
                ServiceHour.SetRange("Service Contract Type", ServiceHour."Service Contract Type"::Quote);
            ServiceContractHeader."Contract Type"::Contract:
                ServiceHour.SetRange("Service Contract Type", ServiceHour."Service Contract Type"::Contract);
        end;
        ServiceHour.SetRange("Service Contract No.", ServiceContractHeader."Contract No.");
        if ServiceHour.FindSet() then
            repeat
                FiledContractServiceHour.Init();
                FiledContractServiceHour.TransferFields(ServiceHour);
                FiledContractServiceHour."Entry No." := FiledServiceContractHeader."Entry No.";
                RecordLinkManagement.CopyLinks(ServiceHour, FiledContractServiceHour);
                FiledContractServiceHour.Insert();
            until ServiceHour.Next() = 0;
    end;

    local procedure FileServiceContractContractServDiscounts(ServiceContractHeader: Record "Service Contract Header"; var FiledServiceContractHeader: Record "Filed Service Contract Header")
    var
        ContractServiceDiscount: Record "Contract/Service Discount";
        FiledContractServDiscount: Record "Filed Contract/Serv. Discount";
        RecordLinkManagement: Codeunit "Record Link Management";
    begin
        ContractServiceDiscount.SetRange("Contract Type", ServiceContractHeader."Contract Type");
        ContractServiceDiscount.SetRange("Contract No.", ServiceContractHeader."Contract No.");
        if ContractServiceDiscount.FindSet() then
            repeat
                FiledContractServDiscount.Init();
                FiledContractServDiscount.TransferFields(ContractServiceDiscount);
                FiledContractServDiscount."Entry No." := FiledServiceContractHeader."Entry No.";
                RecordLinkManagement.CopyLinks(ContractServiceDiscount, FiledContractServDiscount);
                FiledContractServDiscount.Insert();
            until ContractServiceDiscount.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFileContract(var FiledServiceContractHeader: Record "Filed Service Contract Header"; ServiceContractHeader: Record "Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFileContractOnBeforeFiledServContractHeaderInsert(var ServiceContractHeader: Record "Service Contract Header"; var FiledServiceContractHeader: Record "Filed Service Contract Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFileContractOnBeforeFiledContractLineTransferFields(var ServiceContractLine: Record "Service Contract Line")
    begin
    end;
}
