// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Setup;

using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Intrastat;
using Microsoft.Sales.Customer;
using System.Globalization;
using System.Integration;
using System.Utilities;

table 5079 "Marketing Setup"
{
    Caption = 'Marketing Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "Marketing Setup";
    LookupPageID = "Marketing Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Contact Nos."; Code[20])
        {
            Caption = 'Contact Nos.';
            TableRelation = "No. Series";
        }
        field(3; "Campaign Nos."; Code[20])
        {
            AccessByPermission = TableData Campaign = R;
            Caption = 'Campaign Nos.';
            TableRelation = "No. Series";
        }
        field(4; "Segment Nos."; Code[20])
        {
            Caption = 'Segment Nos.';
            TableRelation = "No. Series";
        }
        field(5; "To-do Nos."; Code[20])
        {
            Caption = 'Task Nos.';
            TableRelation = "No. Series";
        }
        field(6; "Opportunity Nos."; Code[20])
        {
            AccessByPermission = TableData "Sales Cycle" = R;
            Caption = 'Opportunity Nos.';
            TableRelation = "No. Series";
        }
        field(7; "Bus. Rel. Code for Customers"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Customers';
            TableRelation = "Business Relation";
        }
        field(8; "Bus. Rel. Code for Vendors"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Vendors';
            TableRelation = "Business Relation";
        }
        field(9; "Bus. Rel. Code for Bank Accs."; Code[10])
        {
            Caption = 'Bus. Rel. Code for Bank Accs.';
            TableRelation = "Business Relation";
        }
        field(10; "Bus. Rel. Code for Employees"; Code[10])
        {
            Caption = 'Bus. Rel. Code for Employees';
            TableRelation = "Business Relation";
        }
        field(22; "Inherit Salesperson Code"; Boolean)
        {
            Caption = 'Inherit Salesperson Code';
            InitValue = true;
        }
        field(23; "Inherit Territory Code"; Boolean)
        {
            Caption = 'Inherit Territory Code';
            InitValue = true;
        }
        field(24; "Inherit Country/Region Code"; Boolean)
        {
            Caption = 'Inherit Country/Region Code';
            InitValue = true;
        }
        field(25; "Inherit Language Code"; Boolean)
        {
            Caption = 'Inherit Language Code';
            InitValue = true;
        }
        field(26; "Inherit Address Details"; Boolean)
        {
            Caption = 'Inherit Address Details';
            InitValue = true;
        }
        field(27; "Inherit Communication Details"; Boolean)
        {
            Caption = 'Inherit Communication Details';
            InitValue = true;
        }
        field(28; "Default Salesperson Code"; Code[20])
        {
            Caption = 'Default Salesperson Code';
            TableRelation = "Salesperson/Purchaser" where(Blocked = const(false));
        }
        field(29; "Default Territory Code"; Code[10])
        {
            Caption = 'Default Territory Code';
            TableRelation = Territory;
        }
        field(30; "Default Country/Region Code"; Code[10])
        {
            Caption = 'Default Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(31; "Default Language Code"; Code[10])
        {
            Caption = 'Default Language Code';
            TableRelation = Language;
        }
        field(32; "Default Format Region"; Text[80])
        {
            Caption = 'Default Format Region';
            TableRelation = "Language Selection"."Language Tag";
        }
        field(33; "Default Sales Cycle Code"; Code[10])
        {
            Caption = 'Default Sales Cycle Code';
            TableRelation = "Sales Cycle";
        }
        field(35; "Attachment Storage Type"; Enum "Setup Attachment Storage Type")
        {
            Caption = 'Attachment Storage Type';
        }
        field(36; "Attachment Storage Location"; Text[250])
        {
            Caption = 'Attachment Storage Location';
        }
        field(37; "Autosearch for Duplicates"; Boolean)
        {
            Caption = 'Autosearch for Duplicates';
            InitValue = true;

            trigger OnValidate()
            begin
                if "Autosearch for Duplicates" then
                    Validate("Maintain Dupl. Search Strings", true);
            end;
        }
        field(38; "Search Hit %"; Integer)
        {
            Caption = 'Search Hit %';
            InitValue = 60;
            MaxValue = 100;
            MinValue = 1;
            NotBlank = true;
        }
        field(39; "Maintain Dupl. Search Strings"; Boolean)
        {
            Caption = 'Maintain Dupl. Search Strings';
            InitValue = true;
            NotBlank = true;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                "Autosearch for Duplicates" := "Maintain Dupl. Search Strings";
                if "Maintain Dupl. Search Strings" and not xRec."Maintain Dupl. Search Strings" then
                    if ConfirmManagement.GetResponse(DuplicateSearchQst, true) then
                        REPORT.Run(REPORT::"Generate Dupl. Search String");
            end;
        }
        field(50; "Mergefield Language ID"; Integer)
        {
            BlankZero = true;
            Caption = 'Mergefield Language ID';
            TableRelation = "Windows Language";
        }
        field(51; "Def. Company Salutation Code"; Code[10])
        {
            Caption = 'Def. Company Salutation Code';
            TableRelation = Salutation;
        }
        field(52; "Default Person Salutation Code"; Code[10])
        {
            Caption = 'Default Person Salutation Code';
            TableRelation = Salutation;
        }
        field(53; "Default Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Default Correspondence Type';
        }
#if not CLEANSCHEMA25
        field(56; "Queue Folder Path"; Text[250])
        {
            Caption = 'Queue Folder Path';
            Editable = false;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(57; "Queue Folder UID"; BLOB)
        {
            Caption = 'Queue Folder UID';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(59; "Storage Folder Path"; Text[250])
        {
            Caption = 'Storage Folder Path';
            Editable = false;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(60; "Storage Folder UID"; BLOB)
        {
            Caption = 'Storage Folder UID';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(67; "Default To-do Date Calculation"; DateFormula)
        {
            Caption = 'Default Task Date Calculation';
        }
#if not CLEANSCHEMA25
        field(69; "Autodiscovery E-Mail Address"; Text[250])
        {
            Caption = 'Autodiscovery Email Address';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(70; "Email Batch Size"; Integer)
        {
            Caption = 'Email Batch Size';
            MinValue = 0;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(71; "Exchange Service URL"; Text[250])
        {
            Caption = 'Exchange Service URL';
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(72; "Exchange Account User Name"; Text[250])
        {
            Caption = 'Exchange Account User Name';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(73; "Exchange Account Password Key"; Guid)
        {
            Caption = 'Exchange Account Password Key';
        }
        field(75; "WebHook Run Notification As"; Guid)
        {
            Caption = 'WebHook Run Notification As';
        }
        field(76; "Cust. Template Company Code"; Code[10])
        {
            Caption = 'Cust. Template Company Code';
        }
        field(77; "Cust. Template Person Code"; Code[10])
        {
            Caption = 'Cust. Template Person Code';
        }
        field(78; "Exchange Tenant Id Key"; Guid)
        {
            Caption = 'Exchange Tenant Id Key';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
#if not CLEANSCHEMA25
        field(79; "Exchange Client Id"; Text[250])
        {
            Caption = 'Exchange Client Id';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(80; "Exchange Client Secret Key"; Guid)
        {
            Caption = 'Exchange Client Secret Key';
            DataClassification = EndUserPseudonymousIdentifiers;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(81; "Email Logging Enabled"; Boolean)
        {
            Caption = 'Email Logging Enabled';
            DataClassification = CustomerContent;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
        field(82; "Exchange Redirect URL"; Text[2048])
        {
            Caption = 'Exchange Redirect URL';
            DataClassification = EndUserIdentifiableInformation;
            ObsoleteReason = 'Feature EmailLoggingUsingGraphApi will be enabled by default in version 22.0';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(83; "Inherit Format Region"; Boolean)
        {
            Caption = 'Inherit Format Region';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RecordHasBeenRead: Boolean;
        DuplicateSearchQst: Label 'Do you want to generate duplicate search strings?';

    procedure TrySetWebhookSubscriptionUser(UserSecurityID: Guid): Boolean
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        if "WebHook Run Notification As" <> UserSecurityID then
            if WebhookManagement.IsValidNotificationRunAsUser(UserSecurityID) then begin
                "WebHook Run Notification As" := UserSecurityID;
                exit(true);
            end;

        exit(false);
    end;

    procedure GetWebhookSubscriptionUser(): Guid
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if MarketingSetup.Get() then
            exit(MarketingSetup."WebHook Run Notification As");
    end;

    local procedure UserIsNotValidForWebhookSubscription(UserSecurityID: Guid): Boolean
    var
        WebhookManagement: Codeunit "Webhook Management";
    begin
        exit(not WebhookManagement.IsValidNotificationRunAsUser(UserSecurityID));
    end;

    local procedure CurrentUserHasPermissionsForWebhookSubscription(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        Contact: Record Contact;
        [SecurityFiltering(SecurityFilter::Ignored)]
        Customer: Record Customer;
    begin
        exit(Customer.WritePermission and Contact.WritePermission)
    end;

    procedure TrySetWebhookSubscriptionUserAsCurrentUser(): Guid
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        if not MarketingSetup.Get() then
            MarketingSetup.Insert(true);

        if UserIsNotValidForWebhookSubscription(MarketingSetup."WebHook Run Notification As") then
            if CurrentUserHasPermissionsForWebhookSubscription() then
                if MarketingSetup.TrySetWebhookSubscriptionUser(UserSecurityId()) then
                    MarketingSetup.Modify(true);

        exit(MarketingSetup."WebHook Run Notification As");
    end;

    procedure GetCustomerTemplate(ContactType: Option Company,Person): Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();

        case ContactType of
            ContactType::Company:
                exit(MarketingSetup."Cust. Template Company Code");
            ContactType::Person:
                exit(MarketingSetup."Cust. Template Person Code");
        end
    end;

    procedure GetRecordOnce()
    begin
        if RecordHasBeenRead then
            exit;
        Get();
        RecordHasBeenRead := true;
    end;
}
