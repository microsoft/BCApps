// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Partner;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Telemetry;

table 413 "IC Partner"
{
    Caption = 'IC Partner';
    LookupPageID = "IC Partner List";
    Permissions = TableData "G/L Entry" = rm;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(4; "Inbox Type"; Enum "IC Partner Inbox Type")
        {
            Caption = 'Inbox Type';
            InitValue = Database;

            trigger OnValidate()
            var
                Cust: Record Customer;
                Vend: Record Vendor;
            begin
                if "Inbox Type" <> xRec."Inbox Type" then
                    "Inbox Details" := '';
                if "Inbox Type" = "Inbox Type"::Email then
                    if "Customer No." <> '' then begin
                        if Cust.Get("Customer No.") then
                            "Inbox Details" := Cust."E-Mail";
                    end else
                        if "Vendor No." <> '' then
                            if Vend.Get("Vendor No.") then
                                "Inbox Details" := Vend."E-Mail";
            end;
        }
        field(5; "Inbox Details"; Text[250])
        {
            Caption = 'Inbox Details';
            TableRelation = if ("Inbox Type" = const(Database)) Company.Name;

            trigger OnLookup()
            var
                Company: Record Company;
                Companies: Page Companies;
                FileName: Text;
            begin
                case "Inbox Type" of
                    "Inbox Type"::Database:
                        begin
                            Company.SetFilter(Name, '<>%1', CompanyName);
                            Companies.SetTableView(Company);
                            Companies.LookupMode := true;
                            if Companies.RunModal() = ACTION::LookupOK then begin
                                Companies.GetRecord(Company);
                                "Inbox Details" := Company.Name;
                            end;
                        end;
                    "Inbox Type"::"File Location":
                        if "Inbox Details" = '' then
                            FileName := StrSubstNo('%1.xml', Code)
                        else
                            FileName := "Inbox Details" + StrSubstNo('\%1.xml', Code);
                end;
                AutosetICPartnerDetails();
            end;
        }
        field(6; "Receivables Account"; Code[20])
        {
            Caption = 'Receivables Account';
            TableRelation = "G/L Account"."No.";
        }
        field(7; "Payables Account"; Code[20])
        {
            Caption = 'Payables Account';
            TableRelation = "G/L Account"."No.";
        }
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("IC Partner"),
                                                      "No." = field(Code)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        field(13; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(14; "Outbound Sales Item No. Type"; Enum "IC Outb. Sales Item No. Type")
        {
            Caption = 'Outbound Sales Item No. Type';
        }
        field(15; "Outbound Purch. Item No. Type"; Enum "IC Outb. Purch. Item No. Type")
        {
            Caption = 'Outbound Purch. Item No. Type';
        }
        field(16; "Cost Distribution in LCY"; Boolean)
        {
            Caption = 'Cost Distribution in LCY';
        }
        field(17; "Auto. Accept Transactions"; Boolean)
        {
            Caption = 'Auto. Accept Transactions';
        }
        field(18; "Data Exchange Type"; Enum "IC Data Exchange Type")
        {
            Caption = 'Data Exchange Type';
            Description = 'Specifies the type of data exchange with the partner, enabling the system to determine the appropriate communication method for intercompany transactions.';
            Editable = false;
            InitValue = Database;
        }
        field(100; "Connection Url Key"; Guid)
        {
            Caption = 'Connection URL Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(101; "Company Id Key"; Guid)
        {
            Caption = 'Company ID Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(102; "Client Id Key"; Guid)
        {
            Caption = 'Client ID Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(103; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA27
        field(104; "Authority Url Key"; Guid)
        {
            Caption = 'Authority URL Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
            ObsoleteReason = 'Usage of authority url is moved to token endpoint.';
        }
#endif
        field(105; "Redirect Url key"; Guid)
        {
            Caption = 'Redirect URL Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(106; "Token Key"; Guid)
        {
            Caption = 'Client Secret Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        field(107; "Token Expiration Time"; DateTime)
        {
            Caption = 'Token Expiration Time';
            DataClassification = SystemMetadata;
        }
        field(108; "Token Endpoint Key"; Guid)
        {
            Caption = 'Token Endpoint Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
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

    trigger OnDelete()
    var
        GLEntry: Record "G/L Entry";
        GLSetup: Record "General Ledger Setup";
        AccountingPeriod: Record "Accounting Period";
        Cust: Record Customer;
        Vend: Record Vendor;
        ICInbox: Record "IC Inbox Transaction";
        ICOutbox: Record "IC Outbox Transaction";
        ICBankAccount: Record "IC Bank Account";
    begin
        GLEntry.SetRange("IC Partner Code", Code);
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            GLEntry.SetFilter("Posting Date", '>=%1', AccountingPeriod."Starting Date");
        if (not GLEntry.IsEmpty()) and (Rec.Code <> '') then
            Error(Text000, xRec.Code);

        GLSetup.Get();
        if GLSetup."Allow G/L Acc. Deletion Before" <> 0D then begin
            GLEntry.SetFilter("Posting Date", '>=%1', GLSetup."Allow G/L Acc. Deletion Before");
            if not GLEntry.IsEmpty() then
                Error(Text001, Code, GLSetup."Allow G/L Acc. Deletion Before");
        end;

        if "Customer No." <> '' then
            if Cust.Get("Customer No.") then
                Error(Text002, Code, Cust.TableCaption(), Cust."No.");

        if "Vendor No." <> '' then
            if Vend.Get("Vendor No.") then
                Error(Text002, Code, Vend.TableCaption(), Vend."No.");

        ICInbox.SetRange("IC Partner Code", Code);
        if (not ICInbox.IsEmpty()) and (Rec.Code <> '') then
            Error(Text003, Code, ICInbox.TableCaption());

        ICOutbox.SetRange("IC Partner Code", Code);
        if (not ICOutbox.IsEmpty()) and (Rec.Code <> '') then
            Error(Text003, Code, ICOutbox.TableCaption());

        if Rec.Code <> '' then begin
            GLEntry.Reset();
            GLEntry.SetCurrentKey("IC Partner Code");
            GLEntry.SetRange("IC Partner Code", Code);
            GLEntry.ModifyAll("IC Partner Code", '');

            CommentLine.SetRange("Table Name", CommentLine."Table Name"::"IC Partner");
            CommentLine.SetRange("No.", Code);
            CommentLine.DeleteAll();

            ICBankAccount.SetRange("IC Partner Code", Code);
            if not ICBankAccount.IsEmpty() then
                ICBankAccount.DeleteAll();

            DimMgt.DeleteDefaultDim(DATABASE::"IC Partner", Code);
        end;
    end;

    trigger OnRename()
    begin
        DimMgt.RenameDefaultDim(DATABASE::"IC Partner", xRec.Code, Code);
        CommentLine.RenameCommentLine(CommentLine."Table Name"::"IC Partner", xRec.Code, Code);
    end;

    var
        CommentLine: Record "Comment Line";
        DimMgt: Codeunit DimensionManagement;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete IC Partner %1 because it has ledger entries in a fiscal year that has not been closed yet.';
        Text001: Label 'You cannot delete IC Partner %1 because it has ledger entries after %2.';
        Text002: Label 'You cannot delete IC Partner %1 because it is used for %2 %3';
        Text003: Label 'You cannot delete IC Partner %1 because it is used in %2';
        Text004: Label '%1 %2 is linked to a blocked IC Partner.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CantFindCompanyErr: Label 'The selected company cannot be found.';
        CompanyNotICConfiguredErr: Label 'The selected company has not been configured for using intercompany.';
        PartnerCompanySameICSetupCodeErr: Label 'The partner company has been configured with the same Intercompany code as this company. This can cause issues when using intercompany features.';

    procedure CheckICPartner()
    begin
        TestField(Blocked, false);
    end;

    procedure CheckICPartnerIndirect(AccountType: Text[250]; AccountNo: Code[20])
    begin
        if Blocked then
            Error(Text004, AccountType, AccountNo);
    end;

    procedure PropagateCustomerICPartner(PreviousCustomerNo: Code[20]; NewCustomerNo: Code[20]; ICPartnerCode: Code[20])
    var
        Customer: Record Customer;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJ0', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IJ2', ICMapping.GetFeatureTelemetryName(), 'Propagate Customer IC Partner');

        if (PreviousCustomerNo <> NewCustomerNo) and Customer.Get(PreviousCustomerNo) then begin
            Customer.Validate("IC Partner Code", '');
            Customer.Modify();
        end;

        if Customer.Get(NewCustomerNo) then begin
            Customer.Validate("IC Partner Code", ICPartnerCode);
            Customer.Modify();
        end;
    end;

    procedure PropagateVendorICPartner(PreviousVendorNo: Code[20]; NewVendorNo: Code[20]; ICPartnerCode: Code[20])
    var
        Vendor: Record Vendor;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ICMapping: Codeunit "IC Mapping";
    begin
        FeatureTelemetry.LogUptake('0000IJ1', ICMapping.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUsage('0000IJ3', ICMapping.GetFeatureTelemetryName(), 'Propagate Vendor IC Partner');

        if (PreviousVendorNo <> NewVendorNo) and Vendor.Get(PreviousVendorNo) then begin
            Vendor.Validate("IC Partner Code", '');
            Vendor.Modify();
        end;

        if Vendor.Get(NewVendorNo) then begin
            Vendor.Validate("IC Partner Code", ICPartnerCode);
            Vendor.Modify();
        end;
    end;

    local procedure AutosetICPartnerDetails()
    var
        Company: Record Company;
    begin
        if Rec."Inbox Type" <> Rec."Inbox Type"::Database then
            exit;
        if not Company.Get(Rec."Inbox Details") then
            Error(CantFindCompanyErr);

        AutosetICPartnerName(Company);
        AutosetICPartnerCurrency(Company);
        AutosetICPartnerCountry(Company);
    end;

    local procedure AutosetICPartnerName(Company: Record Company)
    var
        MyICSetup: Record "IC Setup";
        TempPartnerICSetup: Record "IC Setup" temporary;
        ICDataExchange: Interface "IC Data Exchange";
    begin
        if not MyICSetup.Get() then begin
            MyICSetup.Init();
            MyICSetup.Insert();
        end;

        ICDataExchange := Rec."Data Exchange Type";
        ICDataExchange.GetICPartnerICSetup(Company.Name, TempPartnerICSetup);

        if TempPartnerICSetup."IC Partner Code" = '' then begin
            if System.GuiAllowed() then
                Message(CompanyNotICConfiguredErr);
            exit;
        end;
        if TempPartnerICSetup."IC Partner Code" = MyICSetup."IC Partner Code" then
            if System.GuiAllowed() then
                Message(PartnerCompanySameICSetupCodeErr);
        Rec.Code := TempPartnerICSetup."IC Partner Code";
        Rec.Name := CopyStr(Company."Display Name", 1, MaxStrLen(Rec.Name));
        if Rec.Name = '' then
            Rec.Name := Company.Name;
    end;

    local procedure AutosetICPartnerCurrency(Company: Record Company)
    var
        TempPartnerGeneralLedgerSetup: Record "General Ledger Setup" temporary;
        CurrentCompanyGeneralLedgerSetup: Record "General Ledger Setup";
        ICDataExchange: Interface "IC Data Exchange";
    begin
        if not CurrentCompanyGeneralLedgerSetup.Get() then
            exit;

        ICDataExchange := Rec."Data Exchange Type";
        ICDataExchange.GetICPartnerGeneralLedgerSetup(Company.Name, TempPartnerGeneralLedgerSetup);

        if CurrentCompanyGeneralLedgerSetup."LCY Code" <> TempPartnerGeneralLedgerSetup."LCY Code" then
            Rec."Currency Code" := TempPartnerGeneralLedgerSetup."LCY Code";
    end;

    local procedure AutosetICPartnerCountry(Company: Record Company)
    var
        TempCompanyInformation: Record "Company Information" temporary;
        ICDataExchange: Interface "IC Data Exchange";
    begin
        ICDataExchange := Rec."Data Exchange Type";
        ICDataExchange.GetICPartnerCompanyInformation(Company.Name, TempCompanyInformation);
        Rec."Country/Region Code" := TempCompanyInformation."Country/Region Code";
    end;

    internal procedure SetSecret(SecretKey: Guid; ClientSecretText: SecretText): Guid
    var
        NewSecretKey: Guid;
    begin
        if not IsNullGuid(SecretKey) then
            if not IsolatedStorage.Delete(SecretKey, DataScope::Company) then;

        NewSecretKey := CreateGuid();

        if (not EncryptionEnabled() or (SecretLength(ClientSecretText) > 215)) then
            IsolatedStorage.Set(NewSecretKey, ClientSecretText, DataScope::Company)
        else
            IsolatedStorage.SetEncrypted(NewSecretKey, ClientSecretText, DataScope::Company);

        exit(NewSecretKey);
    end;

    [NonDebuggable]
    local procedure SecretLength(SecretValue: SecretText): Integer
    begin
        exit(StrLen(SecretValue.Unwrap()));
    end;

    internal procedure GetSecret(SecretKey: Guid): SecretText
    var
        ClientSecretText: SecretText;
    begin
        if not IsNullGuid(SecretKey) then
            if not IsolatedStorage.Get(SecretKey, DataScope::Company, ClientSecretText) then;

        exit(ClientSecretText);
    end;
}
