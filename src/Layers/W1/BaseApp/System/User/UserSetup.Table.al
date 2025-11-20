namespace System.Security.User;

using Microsoft.CRM.Team;
using Microsoft.Inventory.Location;
using System;
using System.Automation;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;

table 91 "User Setup"
{
    Caption = 'User Setup';
    DrillDownPageID = "User Setup";
    LookupPageID = "User Setup";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Allow Posting From"; Date)
        {
            Caption = 'Allow Posting From';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(3; "Allow Posting To"; Date)
        {
            Caption = 'Allow Posting To';

            trigger OnValidate()
            begin
                CheckAllowedPostingDates(0);
            end;
        }
        field(4; "Register Time"; Boolean)
        {
            Caption = 'Register Time';
        }
        field(5; "Allow Deferral Posting From"; Date)
        {
            Caption = 'Allow Deferral Posting From';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        field(6; "Allow Deferral Posting To"; Date)
        {
            Caption = 'Allow Deferral Posting To';

            trigger OnValidate()
            begin
                CheckAllowedDeferralPostingDates(0);
            end;
        }
        field(10; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));

            trigger OnValidate()
            begin
                if "Salespers./Purch. Code" <> '' then begin
                    ValidateSalesPersonPurchOnUserSetup(Rec);
                    EnsureUniqueSalesPersonPurchCode();
                    UpdateSalesPerson(FieldNo("Salespers./Purch. Code"));
                end;
            end;
        }
        field(11; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                UserSetup.SetFilter("User ID", '<>%1', "User ID");
                if PAGE.RunModal(PAGE::"Approval User Setup", UserSetup) = ACTION::LookupOK then
                    Validate("Approver ID", UserSetup."User ID");
            end;

            trigger OnValidate()
            begin
                if "Approver ID" = "User ID" then
                    FieldError("Approver ID");
            end;
        }
        field(12; "Sales Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Sales Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Sales Approval" and ("Sales Amount Approval Limit" <> 0) then
                    Error(ConflictingApprovalsErr, FieldCaption("Sales Amount Approval Limit"), FieldCaption("Unlimited Sales Approval"));
                if "Sales Amount Approval Limit" < 0 then
                    Error(NegativeApprovalLimitErr);
            end;
        }
        field(13; "Purchase Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Purchase Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Purchase Approval" and ("Purchase Amount Approval Limit" <> 0) then
                    Error(ConflictingApprovalsErr, FieldCaption("Purchase Amount Approval Limit"), FieldCaption("Unlimited Purchase Approval"));
                if "Purchase Amount Approval Limit" < 0 then
                    Error(NegativeApprovalLimitErr);
            end;
        }
        field(14; "Unlimited Sales Approval"; Boolean)
        {
            Caption = 'Unlimited Sales Approval';

            trigger OnValidate()
            begin
                if "Unlimited Sales Approval" then
                    "Sales Amount Approval Limit" := 0;
            end;
        }
        field(15; "Unlimited Purchase Approval"; Boolean)
        {
            Caption = 'Unlimited Purchase Approval';

            trigger OnValidate()
            begin
                if "Unlimited Purchase Approval" then
                    "Purchase Amount Approval Limit" := 0;
            end;
        }
        field(16; Substitute; Code[50])
        {
            Caption = 'Substitute';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup"."User ID";

            trigger OnLookup()
            var
                UserSetup: Record "User Setup";
            begin
                UserSetup.SetFilter("User ID", '<>%1', "User ID");
                if PAGE.RunModal(PAGE::"Approval User Setup", UserSetup) = ACTION::LookupOK then
                    Validate(Substitute, UserSetup."User ID");
            end;

            trigger OnValidate()
            begin
                if Substitute = "User ID" then
                    FieldError(Substitute);
            end;
        }
        field(17; "E-Mail"; Text[100])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                UpdateSalesPerson(FieldNo("E-Mail"));
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(18; "Phone No."; text[30])
        {
            Caption = 'Phone No.';
            DataClassification = CustomerContent;
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Phone No.") do
                    if Char.IsLetter("Phone No."[i]) then
                        FieldError("Phone No.", PhoneNoCannotContainLettersErr);

                UpdateSalesPerson(FieldNo("Phone No."));
            end;
        }
        field(19; "Request Amount Approval Limit"; Integer)
        {
            BlankZero = true;
            Caption = 'Request Amount Approval Limit';

            trigger OnValidate()
            begin
                if "Unlimited Request Approval" and ("Request Amount Approval Limit" <> 0) then
                    Error(ConflictingApprovalsErr, FieldCaption("Request Amount Approval Limit"), FieldCaption("Unlimited Request Approval"));
                if "Request Amount Approval Limit" < 0 then
                    Error(NegativeApprovalLimitErr);
            end;
        }
        field(20; "Unlimited Request Approval"; Boolean)
        {
            Caption = 'Unlimited Request Approval';

            trigger OnValidate()
            begin
                if "Unlimited Request Approval" then
                    "Request Amount Approval Limit" := 0;
            end;
        }
        field(21; "Approval Administrator"; Boolean)
        {
            Caption = 'Approval Administrator';

            trigger OnValidate()
            var
                UserSetup: Record "User Setup";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateApprovalAdministrator(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Approval Administrator" then begin
                    UserSetup.SetRange("Approval Administrator", true);
                    if not UserSetup.IsEmpty() then
                        FieldError("Approval Administrator");
                end;
            end;
        }
        field(22; "Allow VAT Date From"; Date)
        {
            Caption = 'Allow VAT Date From';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckAllowedVATDates(0);
            end;
        }
        field(23; "Allow VAT Date To"; Date)
        {
            Caption = 'Allow VAT Date To';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                CheckAllowedVATDates(0);
            end;
        }
        field(31; "License Type"; Option)
        {
            CalcFormula = lookup(User."License Type" where("User Name" = field("User ID")));
            Caption = 'License Type';
            FieldClass = FlowField;
            OptionMembers = "Full User","Limited User","Device Only User","Windows Group","External User","External Administrator","External Accountant","Application","AAD Group";
            OptionCaption = 'Full User,Limited User,Device Only User,Windows Group,External User,External Administrator,External Accountant,Application,Microsoft Entra group';
        }
        field(80; "Sales Invoice Posting Policy"; Enum "Invoice Posting Policy")
        {
            Caption = 'Sales Invoice Posting Policy';
        }
        field(90; "Purch. Invoice Posting Policy"; Enum "Invoice Posting Policy")
        {
            Caption = 'Purch. Invoice Posting Policy';
        }
        field(950; "Time Sheet Admin."; Boolean)
        {
            Caption = 'Time Sheet Admin.';
        }
        field(5600; "Allow FA Posting From"; Date)
        {
            Caption = 'Allow FA Posting From';
        }
        field(5601; "Allow FA Posting To"; Date)
        {
            Caption = 'Allow FA Posting To';
        }
        field(5700; "Sales Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Sales Resp. Ctr. Filter';
            TableRelation = "Responsibility Center".Code;
        }
        field(5701; "Purchase Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Purchase Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(5900; "Service Resp. Ctr. Filter"; Code[10])
        {
            Caption = 'Service Resp. Ctr. Filter';
            TableRelation = "Responsibility Center";
        }
        field(5980; "Service Invoice Posting Policy"; Enum "Invoice Posting Policy")
        {
            Caption = 'Service Invoice Posting Policy';
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
        key(Key2; "Salespers./Purch. Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "User ID")
        {
        }
    }

    trigger OnDelete()
    var
        NotificationSetup: Record "Notification Setup";
    begin
        NotificationSetup.SetRange("User ID", "User ID");
        NotificationSetup.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        SetEmailOnRecord();
    end;

    var
        SalesPersonPurchaser: Record "Salesperson/Purchaser";
        UserSetupManagement: Codeunit "User Setup Management";

#pragma warning disable AA0470
        DuplicateSalesPersonErr: Label 'The %1 Salesperson/Purchaser code is already assigned to another User ID %2.';
        ConflictingApprovalsErr: Label 'You cannot have both a %1 and %2. ';
#pragma warning restore AA0470
        NegativeApprovalLimitErr: Label 'You cannot have approval limits less than zero.';
        PrivacyBlockedGenericErr: Label 'Privacy Blocked must not be true for Salesperson / Purchaser %1.', Comment = '%1 = salesperson / purchaser code.';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';

    procedure CreateApprovalUserSetup(User: Record User)
    var
        UserSetup: Record "User Setup";
        ApprovalUserSetup: Record "User Setup";
    begin
        ApprovalUserSetup.Init();
        ApprovalUserSetup.Validate("User ID", User."User Name");
        ApprovalUserSetup.Validate("Sales Amount Approval Limit", GetDefaultSalesAmountApprovalLimit());
        ApprovalUserSetup.Validate("Purchase Amount Approval Limit", GetDefaultPurchaseAmountApprovalLimit());
        ApprovalUserSetup.Validate("E-Mail", User."Contact Email");
        UserSetup.SetRange("Sales Amount Approval Limit", UserSetup.GetDefaultSalesAmountApprovalLimit());
        if UserSetup.FindFirst() then
            ApprovalUserSetup.Validate("Approver ID", UserSetup."Approver ID");
        if ApprovalUserSetup.Insert() then;
    end;

    local procedure EnsureUniqueSalesPersonPurchCode()
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeEnsureUniqueSalesPersonPurchCode(Rec, IsHandled);
        if IsHandled then
            exit;

        UserSetup.SetCurrentKey("Salespers./Purch. Code");
        UserSetup.SetRange("Salespers./Purch. Code", "Salespers./Purch. Code");
        if UserSetup.FindFirst() then
            Error(DuplicateSalesPersonErr, "Salespers./Purch. Code", UserSetup."User ID");
    end;

    procedure GetDefaultSalesAmountApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        UserSetup.SetRange("Unlimited Sales Approval", false);

        if UserSetup.FindFirst() then begin
            DefaultApprovalLimit := UserSetup."Sales Amount Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Sales Amount Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    procedure GetDefaultPurchaseAmountApprovalLimit(): Integer
    var
        UserSetup: Record "User Setup";
        DefaultApprovalLimit: Integer;
        LimitedApprovers: Integer;
    begin
        UserSetup.SetRange("Unlimited Purchase Approval", false);

        if UserSetup.FindFirst() then begin
            DefaultApprovalLimit := UserSetup."Purchase Amount Approval Limit";
            LimitedApprovers := UserSetup.Count();
            UserSetup.SetRange("Purchase Amount Approval Limit", DefaultApprovalLimit);
            if LimitedApprovers = UserSetup.Count then
                exit(DefaultApprovalLimit);
        end;

        // Return 0 if no user setup exists or no default value is found
        exit(0);
    end;

    procedure HideExternalUsers()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        OriginalFilterGroup: Integer;
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        OriginalFilterGroup := FilterGroup;
        FilterGroup := 2;
        CalcFields("License Type");
        SetFilter("License Type", '<>%1&<>%2', "License Type"::"External User", "License Type"::"AAD Group");
        FilterGroup := OriginalFilterGroup;
    end;

    procedure UpdateSalesPerson(FieldNumber: Integer)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        xSalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if "Salespers./Purch. Code" = '' then
            exit;
        if SalespersonPurchaser.Get("Salespers./Purch. Code") then begin
            xSalespersonPurchaser := SalespersonPurchaser;
            if FieldNumber in [fieldno("E-Mail"), FieldNo("Salespers./Purch. Code")] then begin
                SalespersonPurchaser."E-Mail" := CopyStr("E-Mail", 1, MaxStrLen(SalespersonPurchaser."E-Mail"));
                SalespersonPurchaser."Search E-Mail" := SalespersonPurchaser."E-Mail";
            end;
            if FieldNumber in [fieldno("Phone No."), FieldNo("Salespers./Purch. Code")] then
                SalespersonPurchaser."Phone No." := "Phone No.";

            if (SalespersonPurchaser."E-Mail" <> xSalespersonPurchaser."E-Mail") or
                (SalespersonPurchaser."Search E-Mail" <> xSalespersonPurchaser."Search E-Mail") or
                (SalespersonPurchaser."Phone No." <> xSalespersonPurchaser."Phone No.")
            then
                SalespersonPurchaser.Modify();
        end;
    end;

    local procedure ValidateSalesPersonPurchOnUserSetup(UserSetup2: Record "User Setup")
    begin
        if UserSetup2."Salespers./Purch. Code" <> '' then
            if SalesPersonPurchaser.Get(UserSetup2."Salespers./Purch. Code") then
                if SalesPersonPurchaser.VerifySalesPersonPurchaserPrivacyBlocked(SalesPersonPurchaser) then
                    Error(PrivacyBlockedGenericErr, UserSetup2."Salespers./Purch. Code")
    end;

    local procedure SetEmailOnRecord()
    var
        User: Record User;
        MailManagement: Codeunit "Mail Management";
        UserSetupEmail: Text[100];
    begin
        if "E-Mail" <> '' then
            exit;

        if "User ID" = '' then
            exit;

        User.SetRange("User Name", "User ID");
        if not User.FindFirst() then
            exit;

        UserSetupEmail := CopyStr(User."Contact Email", 1, MaxStrLen("E-Mail"));

        if not MailManagement.CheckValidEmailAddress(UserSetupEmail) then
            exit;

        "E-Mail" := UserSetupEmail;
    end;

    procedure CheckAllowedVATDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From", "Allow VAT Date To", NotificationType, Database::"User Setup");
    end;

    procedure CheckAllowedPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange(
          "Allow Posting From", "Allow Posting To", NotificationType, DATABASE::"User Setup");
    end;

    procedure CheckAllowedDeferralPostingDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedPostingDatesRange(
          "Allow Deferral Posting From", "Allow Deferral Posting To", NotificationType, DATABASE::"User Setup",
          FieldCaption("Allow Deferral Posting From"), FieldCaption("Allow Deferral Posting To"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnsureUniqueSalesPersonPurchCode(var UserSetup: Record "User Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateApprovalAdministrator(var UserSetup: Record "User Setup"; var IsHandled: Boolean)
    begin
    end;
}

