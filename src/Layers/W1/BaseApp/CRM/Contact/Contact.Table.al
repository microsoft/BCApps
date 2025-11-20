// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Contact;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Integration.Dataverse;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Source;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System;
using System.DateTime;
using System.Email;
using System.Environment;
using System.Globalization;
using System.Reflection;
using System.Security.User;
using System.Utilities;

table 5050 Contact
{
    Caption = 'Contact';
    DataCaptionFields = "No.", Name;
    DataClassification = CustomerContent;
    DrillDownPageID = "Contact List";
    LookupPageID = "Contact List";
    Permissions = TableData "Sales Header" = rm,
                  TableData "Contact Alt. Address" = rd,
                  TableData "Contact Alt. Addr. Date Range" = rd,
                  TableData "Contact Business Relation" = rid,
                  TableData "Contact Mailing Group" = rd,
                  TableData "Contact Industry Group" = rd,
                  TableData "Contact Web Source" = rd,
                  TableData "Rlshp. Mgt. Comment Line" = rd,
                  TableData "Interaction Log Entry" = rm,
                  TableData "Contact Job Responsibility" = rd,
                  TableData "To-do" = rm,
                  TableData "Contact Profile Answer" = rd,
                  TableData Opportunity = rm,
                  TableData "Opportunity Entry" = rm,
                  tabledata Contact = rm,
                  tabledata Customer = im,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Marketing Setup" = r,
                  tabledata Salutation = r,
                  tabledata "Salutation Formula" = r,
                  tabledata Language = r,
                  tabledata "Language Selection" = r;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateNo(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "No." <> xRec."No." then begin
                    RMSetup.Get();
                    NoSeries.TestManual(RMSetup."Contact Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                NameBreakdown();
                ProcessNameChange();
            end;
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
            OptimizeForTextSearch = true;
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            OptimizeForTextSearch = true;
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            OptimizeForTextSearch = true;
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            OptimizeForTextSearch = true;
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            OptimizeForTextSearch = true;
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupCity(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupCity(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidateCity(Rec, xRec);
            end;
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Phone No.") do
                    if Char.IsLetter("Phone No."[i]) then
                        FieldError("Phone No.", PhoneNoCannotContainLettersErr);
            end;
        }
        field(10; "Telex No."; Text[20])
        {
            Caption = 'Telex No.';
            OptimizeForTextSearch = true;
        }
        field(15; "Territory Code"; Code[10])
        {
            Caption = 'Territory Code';
            TableRelation = Territory;
        }
        field(22; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(24; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;

            trigger OnValidate()
            begin
                UpdateFormatRegion();
            end;
        }
        field(25; "Registration Number"; Text[50])
        {
            Caption = 'Registration No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateRegistrationNumber(Rec, IsHandled);
                if IsHandled then
                    exit;
                if StrLen("Registration Number") > 20 then
                    FieldError("Registration Number", FieldLengthErr);
            end;
        }
        field(29; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
            TableRelation = "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                ValidateSalesPerson();
            end;
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");

                if "Country/Region Code" <> xRec."Country/Region Code" then
                    VATRegistrationValidation();
            end;
        }
        field(38; Comment; Boolean)
        {
            CalcFormula = exist("Rlshp. Mgt. Comment Line" where("Table Name" = const(Contact),
                                                                  "No." = field("No."),
                                                                  "Sub No." = const(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Format Region"; Text[80])
        {
            Caption = 'Format Region';
            OptimizeForTextSearch = true;
            TableRelation = "Language Selection"."Language Tag";
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            OptimizeForTextSearch = true;
        }
        field(85; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
            OptimizeForTextSearch = true;
        }
        field(86; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVATRegistrationNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                "VAT Registration No." := UpperCase("VAT Registration No.");
                if "VAT Registration No." <> xRec."VAT Registration No." then
                    VATRegistrationValidation();
            end;
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                OnBeforeLookupPostCode(Rec, PostCode);

                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");

                OnAfterLookupPostCode(Rec, PostCode);
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);

                OnAfterValidatePostCode(Rec, xRec);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            OptimizeForTextSearch = true;
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            OptimizeForTextSearch = true;
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateEmail(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if "E-Mail" = '' then begin
                    SetSearchEmail();
                    exit;
                end;
                MailManagement.CheckValidEmailAddresses("E-Mail");
                SetSearchEmail();
            end;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(103; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            OptimizeForTextSearch = true;
            ExtendedDatatype = URL;
        }
        field(107; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(140; Image; Media)
        {
            Caption = 'Image';
            ExtendedDatatype = Person;
        }
        field(150; "Privacy Blocked"; Boolean)
        {
            Caption = 'Privacy Blocked';

            trigger OnValidate()
            begin
                if not "Privacy Blocked" then
                    if Minor then
                        if not "Parental Consent Received" then
                            Error(ParentalConsentReceivedErr, "No.");
            end;
        }
        field(151; Minor; Boolean)
        {
            Caption = 'Minor';

            trigger OnValidate()
            begin
                if Minor then
                    Validate("Privacy Blocked", true);
            end;
        }
        field(152; "Parental Consent Received"; Boolean)
        {
            Caption = 'Parental Consent Received';

            trigger OnValidate()
            begin
                Validate("Privacy Blocked", true);
            end;
        }
#if not CLEANSCHEMA26
        field(720; "Coupled to CRM"; Boolean)
        {
            Caption = 'Coupled to Dataverse';
            Editable = false;
            ObsoleteReason = 'Replaced by flow field Coupled to Dataverse';
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
        }
#endif
        field(721; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Dataverse';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Contact)));
        }
        field(5050; Type; Enum "Contact Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and (not IsNullGuid(Rec.SystemId)) then begin
                    TypeChange();
                    Modify();
                end;
            end;
        }
        field(5051; "Company No."; Code[20])
        {
            Caption = 'Company No.';
            TableRelation = Contact where(Type = const(Company));

            trigger OnValidate()
            var
                Cont: Record Contact;
            begin
                if Cont.Get("Company No.") then
                    InheritCompanyToPersonData(Cont)
                else
                    Clear("Company Name");

                if "Company No." = xRec."Company No." then
                    exit;

                CheckContactType(Type::Person);

                CheckUnloggedSegments();

                UpdateBusinessRelation();
                UpdateCompanyNo();
            end;
        }
        field(5052; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            OptimizeForTextSearch = true;
            TableRelation = Contact.Name where(Type = const(Company));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Company No.", GetCompNo("Company Name"));
            end;
        }
        field(5053; "Lookup Contact No."; Code[20])
        {
            Caption = 'Lookup Contact No.';
            Editable = false;
            TableRelation = Contact;

            trigger OnValidate()
            begin
                ValidateLookupContactNo();
            end;
        }
        field(5054; "First Name"; Text[30])
        {
            Caption = 'First Name';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                Name := CalculatedName();
                ProcessNameChange();
            end;
        }
        field(5055; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                Name := CalculatedName();
                ProcessNameChange();
            end;
        }
        field(5056; Surname; Text[30])
        {
            Caption = 'Surname';
            OptimizeForTextSearch = true;

            trigger OnValidate()
            begin
                Name := CalculatedName();
                ProcessNameChange();
            end;
        }
        field(5058; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
            OptimizeForTextSearch = true;
        }
        field(5059; Initials; Text[30])
        {
            Caption = 'Initials';
            OptimizeForTextSearch = true;
        }
        field(5060; "Extension No."; Text[30])
        {
            Caption = 'Extension No.';
            OptimizeForTextSearch = true;
        }
        field(5061; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = PhoneNo;

            trigger OnValidate()
            var
                Char: DotNet Char;
                i: Integer;
            begin
                for i := 1 to StrLen("Mobile Phone No.") do
                    if Char.IsLetter("Mobile Phone No."[i]) then
                        FieldError("Mobile Phone No.", PhoneNoCannotContainLettersErr);
            end;
        }
        field(5062; Pager; Text[30])
        {
            Caption = 'Pager';
            OptimizeForTextSearch = true;
        }
        field(5063; "Organizational Level Code"; Code[10])
        {
            Caption = 'Organizational Level Code';
            TableRelation = "Organizational Level";
        }
        field(5064; "Exclude from Segment"; Boolean)
        {
            Caption = 'Exclude from Segment';
        }
        field(5065; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5066; "Next Task Date"; Date)
        {
            CalcFormula = min("To-do".Date where("Contact Company No." = field("Company No."),
                                                  "Contact No." = field(filter("Lookup Contact No.")),
                                                  Closed = const(false),
                                                  "System To-do Type" = filter(Organizer | "Contact Attendee")));
            Caption = 'Next Task Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5067; "Last Date Attempted"; Date)
        {
            CalcFormula = max("Interaction Log Entry".Date where("Contact Company No." = field("Company No."),
                                                                  "Contact No." = field(filter("Lookup Contact No.")),
                                                                  "Initiated By" = const(Us),
                                                                  Postponed = const(false)));
            Caption = 'Last Date Attempted';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5068; "Date of Last Interaction"; Date)
        {
            CalcFormula = max("Interaction Log Entry".Date where("Contact Company No." = field("Company No."),
                                                                  "Contact No." = field(filter("Lookup Contact No.")),
                                                                  "Attempt Failed" = const(false),
                                                                  Postponed = const(false)));
            Caption = 'Date of Last Interaction';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5069; "No. of Job Responsibilities"; Integer)
        {
            CalcFormula = count("Contact Job Responsibility" where("Contact No." = field("No.")));
            Caption = 'No. of Job Responsibilities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5070; "No. of Industry Groups"; Integer)
        {
            CalcFormula = count("Contact Industry Group" where("Contact No." = field("Company No.")));
            Caption = 'No. of Industry Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5071; "No. of Business Relations"; Integer)
        {
            CalcFormula = count("Contact Business Relation" where("Contact No." = field("Company No.")));
            Caption = 'No. of Business Relations';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5072; "No. of Mailing Groups"; Integer)
        {
            CalcFormula = count("Contact Mailing Group" where("Contact No." = field("No.")));
            Caption = 'No. of Mailing Groups';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5073; "External ID"; Code[20])
        {
            Caption = 'External ID';
        }
        field(5074; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Contact Company No." = field(filter("Company No.")),
                                                               Canceled = const(false),
                                                               "Contact No." = field(filter("Lookup Contact No.")),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5076; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Contact Company No." = field("Company No."),
                                                                          Canceled = const(false),
                                                                          "Contact No." = field(filter("Lookup Contact No.")),
                                                                          Date = field("Date Filter"),
                                                                          Postponed = const(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5077; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Contact Company No." = field("Company No."),
                                                                               Canceled = const(false),
                                                                               "Contact No." = field(filter("Lookup Contact No.")),
                                                                               Date = field("Date Filter"),
                                                                               Postponed = const(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5078; "No. of Opportunities"; Integer)
        {
            CalcFormula = count("Opportunity Entry" where(Active = const(true),
                                                           "Contact Company No." = field("Company No."),
                                                           "Estimated Close Date" = field("Date Filter"),
                                                           "Contact No." = field(filter("Lookup Contact No.")),
                                                           "Action Taken" = field("Action Taken Filter")));
            Caption = 'No. of Opportunities';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5079; "Estimated Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Estimated Value (LCY)" where(Active = const(true),
                                                                                 "Contact Company No." = field("Company No."),
                                                                                 "Estimated Close Date" = field("Date Filter"),
                                                                                 "Contact No." = field(filter("Lookup Contact No.")),
                                                                                 "Action Taken" = field("Action Taken Filter")));
            Caption = 'Estimated Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5080; "Calcd. Current Value (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Opportunity Entry"."Calcd. Current Value (LCY)" where(Active = const(true),
                                                                                      "Contact Company No." = field("Company No."),
                                                                                      "Estimated Close Date" = field("Date Filter"),
                                                                                      "Contact No." = field(filter("Lookup Contact No.")),
                                                                                      "Action Taken" = field("Action Taken Filter")));
            Caption = 'Calcd. Current Value (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5082; "Opportunity Entry Exists"; Boolean)
        {
            CalcFormula = exist("Opportunity Entry" where(Active = const(true),
                                                           "Contact Company No." = field("Company No."),
                                                           "Contact No." = field(filter("Lookup Contact No.")),
                                                           "Sales Cycle Code" = field("Sales Cycle Filter"),
                                                           "Sales Cycle Stage" = field("Sales Cycle Stage Filter"),
                                                           "Salesperson Code" = field("Salesperson Filter"),
                                                           "Campaign No." = field("Campaign Filter"),
                                                           "Action Taken" = field("Action Taken Filter"),
                                                           "Estimated Value (LCY)" = field("Estimated Value Filter"),
                                                           "Calcd. Current Value (LCY)" = field("Calcd. Current Value Filter"),
                                                           "Completed %" = field("Completed % Filter"),
                                                           "Chances of Success %" = field("Chances of Success % Filter"),
                                                           "Probability %" = field("Probability % Filter"),
                                                           "Estimated Close Date" = field("Date Filter"),
                                                           "Close Opportunity Code" = field("Close Opportunity Filter")));
            Caption = 'Opportunity Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5083; "Task Entry Exists"; Boolean)
        {
            CalcFormula = exist("To-do" where("Contact Company No." = field("Company No."),
                                               "Contact No." = field(filter("Lookup Contact No.")),
                                               "Team Code" = field("Team Filter"),
                                               "Salesperson Code" = field("Salesperson Filter"),
                                               "Campaign No." = field("Campaign Filter"),
                                               Date = field("Date Filter"),
                                               Status = field("Task Status Filter"),
                                               Priority = field("Priority Filter"),
                                               Closed = field("Task Closed Filter")));
            Caption = 'Task Entry Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5084; "Salesperson Filter"; Code[20])
        {
            Caption = 'Salesperson Filter';
            FieldClass = FlowFilter;
            TableRelation = "Salesperson/Purchaser";
        }
        field(5085; "Campaign Filter"; Code[20])
        {
            Caption = 'Campaign Filter';
            FieldClass = FlowFilter;
            TableRelation = Campaign;
        }
        field(5086; "Contact Business Relation"; Enum "Contact Business Relation")
        {
            Caption = 'Contact Business Relation';
            Editable = false;
        }
        field(5087; "Action Taken Filter"; Enum "Opportunity Action Taken")
        {
            Caption = 'Action Taken Filter';
            FieldClass = FlowFilter;
        }
        field(5088; "Sales Cycle Filter"; Code[10])
        {
            Caption = 'Sales Cycle Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle";
        }
        field(5089; "Sales Cycle Stage Filter"; Integer)
        {
            Caption = 'Sales Cycle Stage Filter';
            FieldClass = FlowFilter;
            TableRelation = "Sales Cycle Stage".Stage where("Sales Cycle Code" = field("Sales Cycle Filter"));
        }
        field(5090; "Probability % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Probability % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5091; "Completed % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Completed % Filter';
            DecimalPlaces = 1 : 1;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5092; "Estimated Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Estimated Value Filter';
            FieldClass = FlowFilter;
        }
        field(5093; "Calcd. Current Value Filter"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Calcd. Current Value Filter';
            FieldClass = FlowFilter;
        }
        field(5094; "Chances of Success % Filter"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Chances of Success % Filter';
            DecimalPlaces = 0 : 0;
            FieldClass = FlowFilter;
            MaxValue = 100;
            MinValue = 0;
        }
        field(5095; "Task Status Filter"; Enum "Task Status")
        {
            Caption = 'Task Status Filter';
            FieldClass = FlowFilter;
        }
        field(5096; "Task Closed Filter"; Boolean)
        {
            Caption = 'Task Closed Filter';
            FieldClass = FlowFilter;
        }
        field(5097; "Priority Filter"; Option)
        {
            Caption = 'Priority Filter';
            FieldClass = FlowFilter;
            OptionCaption = 'Low,Normal,High';
            OptionMembers = Low,Normal,High;
        }
        field(5098; "Team Filter"; Code[10])
        {
            Caption = 'Team Filter';
            FieldClass = FlowFilter;
            TableRelation = Team;
        }
        field(5099; "Close Opportunity Filter"; Code[10])
        {
            Caption = 'Close Opportunity Filter';
            FieldClass = FlowFilter;
            TableRelation = "Close Opportunity Code";
        }
        field(5100; "Correspondence Type"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type';
        }
        field(5101; "Salutation Code"; Code[10])
        {
            Caption = 'Salutation Code';
            TableRelation = Salutation;
        }
        field(5102; "Search E-Mail"; Code[80])
        {
            Caption = 'Search Email';
        }
        field(5104; "Last Time Modified"; Time)
        {
            Caption = 'Last Time Modified';
        }
        field(5105; "E-Mail 2"; Text[80])
        {
            Caption = 'Email 2';
            OptimizeForTextSearch = true;
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateEmail(Rec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                MailManagement.ValidateEmailAddressField("E-Mail 2");
            end;
        }
        field(5106; "Job Responsibility Filter"; Code[10])
        {
            Caption = 'Job Responsibility Filter';
            FieldClass = FlowFilter;
            TableRelation = "Job Responsibility";
        }
        field(8050; "Xrm Id"; Guid)
        {
            Caption = 'Xrm Id';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Company Name", "Company No.", Type, Name)
        {
            IncludedFields = "Phone No.", "Territory Code", "Salesperson Code", "E-Mail", Address, City, "Post Code", "Contact Business Relation";
        }
        key(Key4; "Company No.")
        {
        }
        key(Key5; "Territory Code")
        {
        }
        key(Key6; "Salesperson Code")
        {
        }
        key(Key7; "VAT Registration No.")
        {
        }
        key(Key8; "Search E-Mail")
        {
        }
        key(Key9; Name)
        {
        }
        key(Key10; City)
        {
        }
        key(Key11; "Post Code")
        {
        }
        key(Key12; "Phone No.")
        {
        }
        key(Key13; SystemModifiedAt)
        {
        }
        key(Key15; "Contact Business Relation")
        {
        }
        key(Key16; "E-Mail")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Name, Type, City, "Post Code", "Phone No.")
        {
        }
        fieldgroup(Brick; "Company Name", Name, Type, "Contact Business Relation", "Phone No.", "E-Mail", Image)
        {
        }
    }

    trigger OnDelete()
    var
        Task: Record "To-do";
        SegLine: Record "Segment Line";
        ContIndustGrp: Record "Contact Industry Group";
        ContactWebSource: Record "Contact Web Source";
        ContJobResp: Record "Contact Job Responsibility";
        ContMailingGrp: Record "Contact Mailing Group";
        ContProfileAnswer: Record "Contact Profile Answer";
        RMCommentLine: Record "Rlshp. Mgt. Comment Line";
        ContAltAddr: Record "Contact Alt. Address";
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        Customer: Record Customer;
        Vendor: Record Vendor;
        CampaignTargetGrMgt: Codeunit "Campaign Target Group Mgt";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        Task.SetCurrentKey("Contact Company No.", "Contact No.", Closed, Date);
        Task.SetRange("Contact Company No.", "Company No.");
        Task.SetRange("Contact No.", "No.");
        Task.SetRange(Closed, false);
        if Task.Find('-') then
            Error(CannotDeleteWithOpenTasksErr, "No.");

        SegLine.SetRange("Contact No.", "No.");
        if not SegLine.IsEmpty() then
            Error(Text001, TableCaption(), "No.");

        Opp.SetCurrentKey("Contact Company No.", "Contact No.");
        Opp.SetRange("Contact Company No.", "Company No.");
        Opp.SetRange("Contact No.", "No.");
        Opp.SetRange(Status, Opp.Status::"Not Started", Opp.Status::"In Progress");
        if Opp.Find('-') then
            Error(Text002, TableCaption(), "No.");

        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.DeleteAll();

        if not Find() then;

        case Type of
            Type::Company:
                begin
                    ContIndustGrp.SetRange("Contact No.", "No.");
                    ContIndustGrp.DeleteAll();
                    ContactWebSource.SetRange("Contact No.", "No.");
                    ContactWebSource.DeleteAll();
                    DuplMgt.RemoveContIndex(Rec, false);
                    InteractLogEntry.SetCurrentKey("Contact Company No.");
                    InteractLogEntry.SetRange("Contact Company No.", "No.");
                    if InteractLogEntry.Find('-') then
                        repeat
                            CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
                            Clear(InteractLogEntry."Contact Company No.");
                            Clear(InteractLogEntry."Contact No.");
                            InteractLogEntry.Modify();
                        until InteractLogEntry.Next() = 0;

                    Cont.Reset();
                    Cont.SetCurrentKey("Company No.");
                    Cont.SetRange("Company No.", "No.");
                    Cont.SetRange(Type, Type::Person);
                    if Cont.Find('-') then
                        repeat
                            Cont.Delete(true);
                        until Cont.Next() = 0;

                    Opp.Reset();
                    Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                    Opp.SetRange("Contact Company No.", "Company No.");
                    Opp.SetRange("Contact No.", "No.");
                    if Opp.Find('-') then
                        repeat
                            Clear(Opp."Contact No.");
                            Clear(Opp."Contact Company No.");
                            Opp.Modify();
                        until Opp.Next() = 0;

                    Task.Reset();
                    Task.SetCurrentKey("Contact Company No.");
                    Task.SetRange("Contact Company No.", "Company No.");
                    if Task.Find('-') then
                        repeat
                            Clear(Task."Contact No.");
                            Clear(Task."Contact Company No.");
                            Task.Modify();
                        until Task.Next() = 0;
                end;
            Type::Person:
                begin
                    ContJobResp.SetRange("Contact No.", "No.");
                    if not ContJobResp.IsEmpty() then
                        ContJobResp.DeleteAll();

                    InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                    InteractLogEntry.SetRange("Contact Company No.", "Company No.");
                    InteractLogEntry.SetRange("Contact No.", "No.");
                    if not InteractLogEntry.IsEmpty() then
                        InteractLogEntry.ModifyAll("Contact No.", "Company No.");

                    Opp.Reset();
                    Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                    Opp.SetRange("Contact Company No.", "Company No.");
                    Opp.SetRange("Contact No.", "No.");
                    if not Opp.IsEmpty() then
                        Opp.ModifyAll("Contact No.", "Company No.");

                    Task.Reset();
                    Task.SetCurrentKey("Contact Company No.", "Contact No.");
                    Task.SetRange("Contact Company No.", "Company No.");
                    Task.SetRange("Contact No.", "No.");
                    if not Task.IsEmpty() then
                        Task.ModifyAll("Contact No.", "Company No.");
                end;
        end;

        ContMailingGrp.SetRange("Contact No.", "No.");
        if not ContMailingGrp.IsEmpty() then
            ContMailingGrp.DeleteAll();

        ContProfileAnswer.SetRange("Contact No.", "No.");
        if not ContProfileAnswer.IsEmpty() then
            ContProfileAnswer.DeleteAll();

        RMCommentLine.SetRange("Table Name", RMCommentLine."Table Name"::Contact);
        RMCommentLine.SetRange("No.", "No.");
        RMCommentLine.SetRange("Sub No.", 0);
        if not RMCommentLine.IsEmpty() then
            RMCommentLine.DeleteAll();

        ContAltAddr.SetRange("Contact No.", "No.");
        if not ContAltAddr.IsEmpty() then
            ContAltAddr.DeleteAll();

        ContAltAddrDateRange.SetRange("Contact No.", "No.");
        if not ContAltAddrDateRange.IsEmpty() then
            ContAltAddrDateRange.DeleteAll();

        VATRegistrationLogMgt.DeleteContactLog(Rec);
        Customer.SetRange("Primary Contact No.", "No.");
        Customer.ModifyAll(Contact, '');
        Customer.ModifyAll("Primary Contact No.", '');

        Vendor.SetRange("Primary Contact No.", "No.");
        Vendor.ModifyAll(Contact, '');
        Vendor.ModifyAll("Primary Contact No.", '');
    end;

    trigger OnInsert()
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();

        if "No." = '' then begin
            RMSetup.TestField("Contact Nos.");
            if NoSeries.AreRelated(RMSetup."Contact Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := RMSetup."Contact Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
            Contact.ReadIsolation(IsolationLevel::ReadUncommitted);
            Contact.SetLoadFields("No.");
            while Contact.Get("No.") do
                "No." := NoSeries.GetNextNo("No. Series");
        end;

        if not SkipDefaults then begin
            if "Salesperson Code" = '' then begin
                "Salesperson Code" := RMSetup."Default Salesperson Code";
                SetDefaultSalesperson();
            end;
            if "Territory Code" = '' then
                "Territory Code" := RMSetup."Default Territory Code";
            if "Country/Region Code" = '' then
                "Country/Region Code" := RMSetup."Default Country/Region Code";
            if "Language Code" = '' then
                "Language Code" := RMSetup."Default Language Code";
            if "Format Region" = '' then
                "Format Region" := RMSetup."Default Format Region";
            if "Correspondence Type" = "Correspondence Type"::" " then
                "Correspondence Type" := RMSetup."Default Correspondence Type";
            if "Salutation Code" = '' then
                if Type = Type::Company then
                    "Salutation Code" := RMSetup."Def. Company Salutation Code"
                else
                    "Salutation Code" := RMSetup."Default Person Salutation Code";
            OnAfterSetDefaults(Rec, RMSetup);
        end;

        UpdateBusinessRelation();
        TypeChange();
        SetLastDateTimeModified();
        SetSearchEmail();
        OnAfterOnInsert(Rec, xRec);
    end;

    trigger OnModify()
    var
        ContactBeforeModify: Record Contact;
    begin
        // If the modify is called from code, Rec and xRec are the same,
        // so find the xRec
        ContactBeforeModify.Copy(xRec);
        if Format(xRec) = Format(Rec) then
            ContactBeforeModify.Find();
        DoModify(ContactBeforeModify);
        SetSearchEmail();
    end;

    trigger OnRename()
    begin
        ValidateLookupContactNo();
    end;

    var
        CannotDeleteWithOpenTasksErr: Label 'You cannot delete contact %1 because there are one or more tasks open.', Comment = '%1 = Contact No.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete the %2 record of the %1 because the contact is assigned one or more unlogged segments.';
        Text002: Label 'You cannot delete the %2 record of the %1 because one or more opportunities are in not started or progress.';
        Text003: Label '%1 cannot be changed because one or more interaction log entries are linked to the contact.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CannotChangeWithOpenTasksErr: Label '%1 cannot be changed because one or more tasks are linked to the contact.', Comment = '%1 = Contact No.';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text006: Label '%1 cannot be changed because one or more opportunities are linked to the contact.';
        Text007: Label '%1 cannot be changed because there are one or more related people linked to the contact.';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0470
        RelatedRecordIsCreatedMsg: Label 'The %1 record has been created.', Comment = 'The Customer record has been created.';
#pragma warning restore AA0470
        RMSetup: Record "Marketing Setup";
        MarketingSetup: Record "Marketing Setup";
        Salesperson: Record "Salesperson/Purchaser";
        PostCode: Record "Post Code";
        DuplMgt: Codeunit DuplicateManagement;
        NoSeries: Codeunit "No. Series";
        UpdateCustVendBank: Codeunit "CustVendBank-Update";
        CampaignMgt: Codeunit "Campaign Target Group Mgt";
        SelectedBusRelationCodes: Text;
        ContChanged: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text012: Label 'You cannot change %1 because one or more unlogged segments are assigned to the contact.';
        Text019: Label 'The %2 record of the %1 already has the %3 with %4 %5.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        CreateCustomerFromContactQst: Label 'Do you want to create a contact as a customer using a customer template?';
#pragma warning disable AA0074
        Text021: Label 'You have to set up the salutation formula of the type %1 in %2 language for the %3 contact.', Comment = '%1 - salutation type, %2 - language code, %3 - contact number.';
        Text022: Label 'The creation of the customer has been aborted.';
#pragma warning restore AA0074
        SelectContactErr: Label 'You must select an existing contact.';
        AlreadyExistErr: Label '%1 %2 already has a %3 with %4 %5.', Comment = '%1=Contact table caption;%2=Contact number;%3=Contact Business Relation table caption;%4=Contact Business Relation Link to Table value;%5=Contact Business Relation number';
        PrivacyBlockedPostErr: Label 'You cannot post this type of document because contact %1 is blocked due to privacy.', Comment = '%1=contact no.';
        PrivacyBlockedCreateErr: Label 'You cannot create this type of document because contact %1 is blocked due to privacy.', Comment = '%1=contact no.';
        PrivacyBlockedGenericErr: Label 'You cannot use contact %1 %2 because they are marked as blocked due to privacy.', Comment = '%1=contact no.;%2=contact name';
        ParentalConsentReceivedErr: Label 'Privacy Blocked cannot be cleared until Parental Consent Received is set to true for minor contact %1.', Comment = '%1=contact no.';
        ProfileForMinorErr: Label 'You cannot use profiles for contacts marked as Minor.';
        MultipleCustomerTemplatesConfirmQst: Label 'Quotes with customer templates different from %1 were assigned to customer %2. Do you want to review the quotes now?', Comment = '%1=Customer Template Code,%2=Customer No.';
        DifferentCustomerTemplateMsg: Label 'Sales quote %1 with original customer template %2 was assigned to the customer created from template %3.', Comment = '%1=Document No.,%2=Original Customer Template Code,%3=Customer Template Code';
        NoOriginalCustomerTemplateMsg: Label 'Sales quote %1 without an original customer template was assigned to the customer created from template %2.', Comment = '%1=Document No.,%2=Customer Template Code';
        PhoneNoCannotContainLettersErr: Label 'must not contain letters';
        FieldLengthErr: Label 'must not have the length more than 20 symbols';
        VendorTemplNotFoundMsg: Label 'You cannot create vendor because there is no vendor template with contact type: %1.', Comment = '%1=Contact Type';
        MultipleVendorTemplatesConfirmQst: Label 'Quotes with vendor templates different from %1 were assigned to vendor %2. Do you want to review the quotes now?', Comment = '%1 = Vendor Template Code, %2 = Vendor No.';
        DifferentVendorTemplateMsg: Label 'Purchase quote %1 with original vendor template %2 was assigned to the vendor created from template %3.', Comment = '%1 = Document No., %2 = Original Vendor Template Code, %3 = Vendor Template Code';
        NoOriginalVendorTemplateMsg: Label 'Purchase quote %1 without an original vendor template was assigned to the vendor created from template %2.', Comment = '%1 = Document No., %2 = Vendor Template Code';

    protected var
        HideValidationDialog: Boolean;
        SkipDefaults: Boolean;

    procedure DoModify(ContactBeforeModify: Record Contact)
    var
        OldCont: Record Contact;
        Cont: Record Contact;
        IsDuplicateCheckNeeded: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeOnModify(Rec, ContactBeforeModify);

        SetLastDateTimeModified();

        if "No." <> '' then
            if IsUpdateNeeded(ContactBeforeModify) then
                UpdateCustVendBank.Run(Rec);

        if Type = Type::Company then begin
            RMSetup.Get();
            Cont.Reset();
            Cont.SetCurrentKey("Company No.");
            Cont.SetRange("Company No.", "No.");
            Cont.SetRange(Type, Type::Person);
            Cont.SetFilter("No.", '<>%1', "No.");
            if Cont.Find('-') then
                repeat
                    ContChanged := false;
                    OldCont := Cont;
                    if Name <> ContactBeforeModify.Name then begin
                        Cont."Company Name" := Name;
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Salesperson Code" and
                       (ContactBeforeModify."Salesperson Code" <> "Salesperson Code") and
                       (ContactBeforeModify."Salesperson Code" = Cont."Salesperson Code")
                    then begin
                        Cont."Salesperson Code" := "Salesperson Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Territory Code" and
                       (ContactBeforeModify."Territory Code" <> "Territory Code") and
                       (ContactBeforeModify."Territory Code" = Cont."Territory Code")
                    then begin
                        Cont."Territory Code" := "Territory Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Country/Region Code" and
                       (ContactBeforeModify."Country/Region Code" <> "Country/Region Code") and
                       (ContactBeforeModify."Country/Region Code" = Cont."Country/Region Code")
                    then begin
                        Cont."Country/Region Code" := "Country/Region Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Language Code" and
                       (ContactBeforeModify."Language Code" <> "Language Code") and
                       (ContactBeforeModify."Language Code" = Cont."Language Code")
                    then begin
                        Cont."Language Code" := "Language Code";
                        ContChanged := true;
                    end;
                    if RMSetup."Inherit Format Region" and
                       (ContactBeforeModify."Format Region" <> "Format Region") and
                       (ContactBeforeModify."Format Region" = Cont."Format Region")
                    then begin
                        Cont."Format Region" := "Format Region";
                        ContChanged := true;
                    end;

                    IsHandled := false;
                    OnModifyOnBeforeInheritAddressDetails(Rec, xRec, RMSetup, Cont, ContChanged, IsHandled);
                    if not IsHandled then
                        if RMSetup."Inherit Address Details" then
                            if ContactBeforeModify.IdenticalAddress(Cont) then begin
                                if ContactBeforeModify.Address <> Address then begin
                                    Cont.Address := Address;
                                    ContChanged := true;
                                end;
                                if ContactBeforeModify."Address 2" <> "Address 2" then begin
                                    Cont."Address 2" := "Address 2";
                                    ContChanged := true;
                                end;
                                if ContactBeforeModify."Post Code" <> "Post Code" then begin
                                    Cont."Post Code" := "Post Code";
                                    ContChanged := true;
                                end;
                                if ContactBeforeModify.City <> City then begin
                                    Cont.City := City;
                                    ContChanged := true;
                                end;
                                if ContactBeforeModify.County <> County then begin
                                    Cont.County := County;
                                    ContChanged := true;
                                end;
                                OnAfterSyncAddress(Cont, Rec, ContChanged, ContactBeforeModify);
                            end;

                    IsHandled := false;
                    OnModifyOnBeforeInheritCommunicationDetails(Rec, xRec, RMSetup, Cont, ContChanged, IsHandled);
                    if not IsHandled then
                        if RMSetup."Inherit Communication Details" then begin
                            if (ContactBeforeModify."Phone No." <> "Phone No.") and (ContactBeforeModify."Phone No." = Cont."Phone No.") then begin
                                Cont."Phone No." := "Phone No.";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Telex No." <> "Telex No.") and (ContactBeforeModify."Telex No." = Cont."Telex No.") then begin
                                Cont."Telex No." := "Telex No.";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Fax No." <> "Fax No.") and (ContactBeforeModify."Fax No." = Cont."Fax No.") then begin
                                Cont."Fax No." := "Fax No.";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Telex Answer Back" <> "Telex Answer Back") and (ContactBeforeModify."Telex Answer Back" = Cont."Telex Answer Back") then begin
                                Cont."Telex Answer Back" := "Telex Answer Back";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."E-Mail" <> "E-Mail") and (ContactBeforeModify."E-Mail" = Cont."E-Mail") then begin
                                Cont.Validate("E-Mail", "E-Mail");
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Home Page" <> "Home Page") and (ContactBeforeModify."Home Page" = Cont."Home Page") then begin
                                Cont."Home Page" := "Home Page";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Extension No." <> "Extension No.") and (ContactBeforeModify."Extension No." = Cont."Extension No.") then begin
                                Cont."Extension No." := "Extension No.";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify."Mobile Phone No." <> "Mobile Phone No.") and (ContactBeforeModify."Mobile Phone No." = Cont."Mobile Phone No.") then begin
                                Cont."Mobile Phone No." := "Mobile Phone No.";
                                ContChanged := true;
                            end;
                            if (ContactBeforeModify.Pager <> Pager) and (ContactBeforeModify.Pager = Cont.Pager) then begin
                                Cont.Pager := Pager;
                                ContChanged := true;
                            end;
                        end;

                    OnBeforeApplyCompanyChangeToPerson(Cont, Rec, ContactBeforeModify, ContChanged, OldCont);
                    if ContChanged then begin
                        Cont.SetHideValidationDialog(HideValidationDialog);
                        Cont.DoModify(OldCont);
                        Cont.Modify();
                    end;
                until Cont.Next() = 0;

            IsDuplicateCheckNeeded :=
              (Name <> ContactBeforeModify.Name) or
              ("Name 2" <> ContactBeforeModify."Name 2") or
              (Address <> ContactBeforeModify.Address) or
              ("Address 2" <> ContactBeforeModify."Address 2") or
              (City <> ContactBeforeModify.City) or
              ("Post Code" <> ContactBeforeModify."Post Code") or
              ("VAT Registration No." <> ContactBeforeModify."VAT Registration No.") or
              ("Phone No." <> ContactBeforeModify."Phone No.");

            OnBeforeDuplicateCheck(Rec, ContactBeforeModify, IsDuplicateCheckNeeded);

            if IsDuplicateCheckNeeded then
                CheckDuplicates();
        end;

        OnAfterOnModify(Rec, ContactBeforeModify);
    end;

    procedure TypeChange()
    var
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        Task: Record "To-do";
        Cont: Record Contact;
        CampaignTargetGrMgt: Codeunit "Campaign Target Group Mgt";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTypeChange(Rec, xRec, InteractLogEntry, Opp, Task, Cont, IsHandled);
        if not IsHandled then begin
            RMSetup.Get();

            if Type <> xRec.Type then begin
                InteractLogEntry.LockTable();
                Cont.LockTable();
                InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                InteractLogEntry.SetRange("Contact Company No.", "Company No.");
                InteractLogEntry.SetRange("Contact No.", "No.");
                if InteractLogEntry.FindFirst() then
                    Error(Text003, FieldCaption(Type));
                OnTypeChangeOnAfterCheckInteractionLog(Rec, xRec);
                Task.SetRange("Contact Company No.", "Company No.");
                Task.SetRange("Contact No.", "No.");
                if not Task.IsEmpty() then
                    Error(CannotChangeWithOpenTasksErr, FieldCaption(Type));
                Opp.SetRange("Contact Company No.", "Company No.");
                Opp.SetRange("Contact No.", "No.");
                if not Opp.IsEmpty() then
                    Error(Text006, FieldCaption(Type));
            end;

            case Type of
                Type::Company:
                    begin
                        if Type <> xRec.Type then begin
                            TestField("Organizational Level Code", '');
                            TestField("No. of Job Responsibilities", 0);
                        end;
                        "First Name" := '';
                        "Middle Name" := '';
                        Surname := '';
                        "Job Title" := '';
                        "Company No." := "No.";
                        "Company Name" := Name;
                        "Salutation Code" := RMSetup."Def. Company Salutation Code";
                    end;
                Type::Person:
                    begin
                        CampaignTargetGrMgt.DeleteContfromTargetGr(InteractLogEntry);
                        Cont.Reset();
                        Cont.SetCurrentKey("Company No.");
                        Cont.SetRange("Company No.", "No.");
                        Cont.SetRange(Type, Type::Person);
                        OnTypeChangeOnAfterContSetFilters(Cont, Rec);
                        if Cont.FindFirst() then
                            Error(Text007, FieldCaption(Type));
                        CheckIfTypeChangePossibleForPerson();

                        if "Company No." = "No." then begin
                            "Company No." := '';
                            "Company Name" := '';
                            "Salutation Code" := RMSetup."Default Person Salutation Code";
                            NameBreakdown();
                        end;
                    end;
            end;
            OnAfterSetTypeForContact(Rec, xRec);
            Validate("Lookup Contact No.");

            if Cont.Get("No.") then
                if Type = Type::Company then
                    CheckDuplicates()
                else
                    DuplMgt.RemoveContIndex(Rec, false);
        end;
        OnAfterTypeChange(Rec);
    end;

    procedure AssistEdit(OldCont: Record Contact) Result: Boolean
    var
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssistEdit(Rec, OldCont, IsHandled, Result);
        if IsHandled then
            exit(Result);

        Cont := Rec;
        RMSetup.Get();
        RMSetup.TestField("Contact Nos.");
        if NoSeries.LookupRelatedNoSeries(RMSetup."Contact Nos.", OldCont."No. Series", Cont."No. Series") then begin
            Cont."No." := NoSeries.GetNextNo(Cont."No. Series");
            OnAssistEditOnAfterNoSeriesMgtSetSeries(Cont, OldCont);
            Rec := Cont;
            exit(true);
        end;
    end;

    local procedure CheckIfTypeChangePossibleForPerson()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTypeChangePossibleForPerson(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if Type <> xRec.Type then begin
            CalcFields("No. of Business Relations", "No. of Industry Groups");
            TestField("No. of Business Relations", 0);
            TestField("No. of Industry Groups", 0);
            TestField("Currency Code", '');
            TestField("VAT Registration No.", '');
            OnTypeChangeOnAfterTypePersonTestFields(Rec);
        end;
    end;

    procedure CreateCustomer(): Code[20];
    var
        CustomerTempl: Record "Customer Templ.";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
    begin
        if CustomerTemplMgt.SelectCustomerTemplateFromContact(CustomerTempl, Rec) then
            exit(CreateCustomerFromTemplate(CustomerTempl.Code))
        else
            if CustomerTemplMgt.TemplatesAreNotEmpty() then
                exit;
    end;

    procedure CreateCustomerFromTemplate(CustomerTemplateCode: Code[20]) CustNo: Code[20]
    var
        Cust: Record Customer;
        CustTemplate: Record "Customer Templ.";
        ContBusRel: Record "Contact Business Relation";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerFromTemplate(Rec, CustNo, IsHandled, CustomerTemplateCode, HideValidationDialog);
        if IsHandled then
            exit;

        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        if CreateCompanyContactCustomerFromTemplate(CustomerTemplateCode, CustNo) then
            exit;
        CheckIfPrivacyBlockedGeneric();
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");

        Clear(Cust);
        Cust.SetInsertFromContact(true);
        if CustomerTemplateCode <> '' then begin
            CustTemplate.Get(CustomerTemplateCode);
            IsHandled := false;
            OnCreateCustomerFromTemplateOnBeforeInitCustomerNo(Cust, Rec, CustTemplate, IsHandled);
            if not IsHandled then // New line
                CustomerTemplMgt.InitCustomerNo(Cust, CustTemplate);
        end;
        Cust."Contact Type" := Type;
        OnCreateCustomerFromTemplateOnBeforeCustomerInsert(Cust, CustomerTemplateCode, Rec);
        Cust.Insert(true);
        Cust.SetInsertFromContact(false);
        CustNo := Cust."No.";

        ContBusRel."Contact No." := "No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Customers";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Customer;
        ContBusRel."No." := Cust."No.";
        OnCreateCustomerFromTemplateOnBeforeContBusRelInsert(Rec, Cust, ContBusRel);
        ContBusRel.Insert(true);

        UpdateCustVendBank.UpdateCustomer(Rec, ContBusRel);

        Cust.Get(ContBusRel."No.");
        if Type = Type::Company then
            Cust.Validate(Name, "Company Name");

        OnCreateCustomerOnBeforeCustomerModify(Cust, Rec);
        Cust.Modify();

        if CustomerTemplateCode <> '' then
            CustomerTemplMgt.ApplyCustomerTemplate(Cust, CustTemplate);
        OnCreateCustomerFromTemplateOnAfterApplyCustomerTemplate(Cust, CustTemplate, Rec);

        IsHandled := false;
        OnCreateCustomerOnBeforeUpdateQuotes(Cust, Rec, IsHandled);
        if not IsHandled then
            UpdateQuotesFromTemplate(Cust, CustomerTemplateCode);
        CampaignMgt.ConverttoCustomer(Rec, Cust);

        ShowResultForCustomer(Cust);

        OnAfterCreateCustomer(Rec, Cust);
    end;

    local procedure ShowResultForCustomer(var Customer: Record Customer);
    var
        OfficeManagement: Codeunit "Office Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResultForCustomer(Customer, Rec, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        if OfficeManagement.IsAvailable() then
            PAGE.Run(PAGE::"Customer Card", Customer)
        else
            if not HideValidationDialog then
                Message(RelatedRecordIsCreatedMsg, Customer.TableCaption());
    end;

    local procedure CreateCompanyContactCustomerFromTemplate(CustomerTemplateCode: Code[20]; var CustNo: Code[20]) CustomerCreated: Boolean
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCompanyContactCustomerFromTemplate(Rec, CustomerTemplateCode, CustNo, HideValidationDialog, CustomerCreated, IsHandled);
        if IsHandled then
            exit(CustomerCreated);

        if (Type = Type::Person) and ("Company No." <> '') and ("No." <> "Company No.") then
            if Contact.Get("Company No.") then begin
                Contact.SetHideValidationDialog(HideValidationDialog);
                CustNo := Contact.CreateCustomerFromTemplate(CustomerTemplateCode);
                exit(true);
            end;

        exit(false);
    end;

    procedure CreateVendor() VendorNo: Code[20]
    var
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        IsHandled: Boolean;
    begin
        if not CheckIfVendorTempleExist() then begin
            IsHandled := false;
            OnCreateVendorOnVendorTemplateNotExist(Rec, VendorNo, IsHandled);
            if IsHandled then
                exit(VendorNo);
            if GuiAllowed() then
                Message(StrSubstNo(VendorTemplNotFoundMsg, Rec.Type));
            exit;
        end;

        if VendorTemplMgt.SelectVendorTemplateFromContact(VendorTempl, Rec) then
            exit(CreateVendorFromTemplate(VendorTempl.Code));
    end;

    local procedure CheckIfVendorTempleExist(): Boolean
    var
        VendorTempl: Record "Vendor Templ.";
    begin
        VendorTempl.SetRange("Contact Type", Rec.Type);
        exit(not VendorTempl.IsEmpty());
    end;

    procedure CreateVendorFromTemplate(VendorTemplateCode: Code[20]) VendorNo: Code[20]
    var
        ContBusRel: Record "Contact Business Relation";
        Vend: Record Vendor;
        ContComp: Record Contact;
        VendorTempl: Record "Vendor Templ.";
        VendorTemplMgt: Codeunit "Vendor Templ. Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateVendor(Rec, VendorNo, IsHandled);
        if IsHandled then
            exit;

        CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);
        if CreateCompanyContactVendor(VendorNo, VendorTemplateCode) then
            exit;
        CheckIfPrivacyBlockedGeneric();
        CheckCompanyNo();
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Vendors");

        Clear(Vend);
        Vend.SetInsertFromContact(true);
        if VendorTemplateCode <> '' then begin
            VendorTempl.Get(VendorTemplateCode);
            IsHandled := false;
            OnCreateVendorFromTemplateOnBeforeInitVendorNo(Vend, Rec, VendorTempl, IsHandled);
            if not IsHandled then
                VendorTemplMgt.InitVendorNo(Vend, VendorTempl);
        end;
        OnBeforeVendorInsert(Vend, Rec, VendorTemplateCode);
        Vend.Insert(true);
        Vend.SetInsertFromContact(false);
        VendorNo := Vend."No.";

        if Type = Type::Company then
            ContComp.Get(Rec."No.")
        else
            ContComp.Get("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Vendors";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::Vendor;
        ContBusRel."No." := Vend."No.";
        OnCreateVendorFromTemplateOnBeforeContBusRelInsert(Rec, Vend, ContBusRel);
        ContBusRel.Insert(true);

        OnAfterVendorInsert(Vend, Rec);

        UpdateCustVendBank.UpdateVendor(ContComp, ContBusRel);
        IsHandled := false;
        OnCreateVendorFromTemplateOnBeforeCommit(Rec, Vend, IsHandled);
        if not IsHandled then
            Commit();
        Vend.Get(Vend."No.");
        if VendorTemplateCode <> '' then
            VendorTemplMgt.ApplyVendorTemplate(Vend, VendorTempl);

        OnCreateVendorOnAfterUpdateVendor(Vend, Rec, ContBusRel);

        UpdateQuotesFromTemplate(Vend, VendorTemplateCode);

        ShowResultForVendor(Vend);

        OnAfterCreateVendor(Rec, Vend);
    end;

    local procedure ShowResultForVendor(var Vendor: Record Vendor);
    var
        OfficeManagement: Codeunit "Office Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResultForVendor(Vendor, Rec, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        if OfficeManagement.IsAvailable() then
            PAGE.Run(PAGE::"Vendor Card", Vendor)
        else
            if not HideValidationDialog then begin
                IsHandled := false;
                OnShowResultForVendorOnBeforeShowrelatedRecordisCreatedMsg(Vendor, IsHandled);
                if not IsHandled then
                    Message(RelatedRecordIsCreatedMsg, Vendor.TableCaption());
            end;
    end;

    local procedure CreateCompanyContactVendor(var VendorNo: Code[20]; VendorTemplateCode: Code[20]) VendorCreated: Boolean
    var
        Contact: Record Contact;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCompanyContactVendor(Rec, VendorNo, HideValidationDialog, VendorCreated, IsHandled);
        if IsHandled then
            exit(VendorCreated);

        if (Type = Type::Person) and ("Company No." <> '') and ("No." <> "Company No.") then
            if Contact.Get("Company No.") then begin
                Contact.SetHideValidationDialog(HideValidationDialog);
                VendorNo := Contact.CreateVendorFromTemplate(VendorTemplateCode);
                exit(true);
            end;

        exit(false);
    end;

    procedure CreateBankAccount() BankAccountNo: Code[20];
    var
        BankAcc: Record "Bank Account";
        ContComp: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateBankAccount(Rec, BankAccountNo, IsHandled);
        if IsHandled then
            exit(BankAccountNo);

        TestField("Company No.");
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");

        Clear(BankAcc);
        BankAcc.SetInsertFromContact(true);
        OnBeforeBankAccountInsert(BankAcc, Rec);
        BankAcc.Insert(true);
        BankAccountNo := BankAcc."No.";
        BankAcc.SetInsertFromContact(false);

        if Type = Type::Company then
            ContComp.Get(Rec."No.")
        else
            ContComp.Get("Company No.");

        ContBusRel."Contact No." := ContComp."No.";
        ContBusRel."Business Relation Code" := RMSetup."Bus. Rel. Code for Bank Accs.";
        ContBusRel."Link to Table" := ContBusRel."Link to Table"::"Bank Account";
        ContBusRel."No." := BankAcc."No.";
        OnCreateBankAccountOnBeforeContBusRelInsert(Rec, BankAcc, ContBusRel);
        ContBusRel.Insert(true);

        CheckIfPrivacyBlockedGeneric();

        UpdateCustVendBank.UpdateBankAccount(ContComp, ContBusRel);

        if not HideValidationDialog then
            Message(RelatedRecordIsCreatedMsg, BankAcc.TableCaption());

        OnAfterCreateBankAccount(Rec, BankAcc);
    end;

    procedure CreateCustomerLink()
    var
        Cust: Record Customer;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateCustomerLink(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        CheckIfPrivacyBlockedGeneric();
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Customers");
        CreateLink(
          PAGE::"Customer Link",
          RMSetup."Bus. Rel. Code for Customers",
          ContBusRel."Link to Table"::Customer);
        OnCreateCustomerLinkOnAfterCreateLink(Rec, xRec, ContBusRel);

        ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("Contact No.", "Company No.");
        if ContBusRel.FindFirst() then
            if Cust.Get(ContBusRel."No.") then
                UpdateQuotesFromTemplate(Cust, '');

        OnAfterCreateCustomerLink(Rec);
    end;

    procedure CreateVendorLink()
    var
        Vendor: Record Vendor;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateVendorLink(Rec, IsHandled);
        if not IsHandled then begin
            CheckForExistingRelationships(ContBusRel."Link to Table"::Vendor);
            CheckIfPrivacyBlockedGeneric();
            TestField("Company No.");
            RMSetup.Get();
            RMSetup.TestField("Bus. Rel. Code for Vendors");
            CreateLink(
              PAGE::"Vendor Link",
              RMSetup."Bus. Rel. Code for Vendors",
              ContBusRel."Link to Table"::Vendor);

            ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
            ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
            ContBusRel.SetRange("Contact No.", "Company No.");
            if ContBusRel.FindFirst() then
                if Vendor.Get(ContBusRel."No.") then
                    UpdateQuotesFromTemplate(Vendor, '');
        end;
        OnAfterCreateVendorLink(Rec, xRec);
    end;

    procedure CreateBankAccountLink()
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateBankAccountLink(Rec, IsHandled);
        if IsHandled then
            exit;

        CheckIfPrivacyBlockedGeneric();
        TestField("Company No.");
        RMSetup.Get();
        RMSetup.TestField("Bus. Rel. Code for Bank Accs.");
        CreateLink(
          PAGE::"Bank Account Link",
          RMSetup."Bus. Rel. Code for Bank Accs.",
          ContBusRel."Link to Table"::"Bank Account");
    end;

    local procedure CreateLink(CreateForm: Integer; BusRelCode: Code[10]; "Table": Enum "Contact Business Relation Link To Table")
    var
        TempContBusRel: Record "Contact Business Relation" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateLink(Rec, TempContBusRel, CreateForm, BusRelCode, Table, IsHandled);
        if not IsHandled then begin
            TempContBusRel."Contact No." := "No.";
            TempContBusRel."Business Relation Code" := BusRelCode;
            TempContBusRel."Link to Table" := Table;
            TempContBusRel.Insert();
            if PAGE.RunModal(CreateForm, TempContBusRel) = ACTION::LookupOK then; // enforce look up mode dialog
            TempContBusRel.DeleteAll();
        end;
        OnAfterCreateLink(Rec, xRec, CreateForm);
    end;

    procedure CreateInteraction()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        CheckIfPrivacyBlockedGeneric();
        TempSegmentLine.CreateSegLineInteractionFromContact(Rec);
        OnAfterCreateInteraction(Rec);
    end;

    procedure GetDefaultPhoneNo(): Text[30]
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone then begin
            if "Mobile Phone No." = '' then
                exit("Phone No.");
            exit("Mobile Phone No.");
        end;
        if "Phone No." = '' then
            exit("Mobile Phone No.");
        exit("Phone No.");
    end;

    procedure ShowBusinessRelation(LinkToTable: Enum "Contact Business Relation Link To Table"; All: Boolean)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        RecSelected: Boolean;
        IsHandled: Boolean;
    begin
        FilterBusinessRelations(ContactBusinessRelation, LinkToTable, All);
        OnShowBusinessRelationOnAfterFilterBusinessRelations(Rec, ContactBusinessRelation, LinkToTable, All);
        if ContactBusinessRelation.IsEmpty() then begin
            ShowBusinessRelations();
            exit;
        end;

        if ContactBusinessRelation.Count() = 1 then
            RecSelected := ContactBusinessRelation.FindFirst()
        else begin
            Page.Run(Page::"Contact Business Relations", ContactBusinessRelation);
            exit;
        end;

        IsHandled := false;
        OnShowCustVendBankOnBeforeRunPage(Rec, RecSelected, ContactBusinessRelation, IsHandled);
        if IsHandled then
            exit;

        if RecSelected then
            ContactBusinessRelation.ShowRelatedCardPage();

        OnAfterShowCustVendBank(Rec, ContactBusinessRelation, RecSelected);
    end;

    procedure ShowBusinessRelations()
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        CheckContactType(Type::Company);
        ContactBusinessRelation.SetRange("Contact No.", "Company No.");
        PAGE.Run(PAGE::"Contact Business Relations", ContactBusinessRelation);
    end;

    local procedure GetBusinessRelation() ResultContactBusinessRelation: Enum "Contact Business Relation";
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        AllBusinessRelationCount, SelectedBusinessRelationCodeCount : Integer;
    begin
        FilterBusinessRelations(ContactBusinessRelation, Enum::"Contact Business Relation Link To Table"::" ", true);
        AllBusinessRelationCount := ContactBusinessRelation.Count();
        if AllBusinessRelationCount = 0 then
            exit(ResultContactBusinessRelation::None);

        ContactBusinessRelation.SetFilter("Business Relation Code", GetSelectedRelationCodes());
        ContactBusinessRelation.SetFilter("No.", '<>''''');
        SelectedBusinessRelationCodeCount := ContactBusinessRelation.Count();
        if SelectedBusinessRelationCodeCount = 0 then begin
            if AllBusinessRelationCount = 1 then
                exit(ResultContactBusinessRelation::Other);

            exit(ResultContactBusinessRelation::Multiple);
        end;

        if (AllBusinessRelationCount = 1) and (SelectedBusinessRelationCodeCount = 1) then begin
            ContactBusinessRelation.SetLoadFields("Link to Table");
            ContactBusinessRelation.FindFirst();
            exit(ContactBusinessRelation."Link to Table");
        end;

        exit(ResultContactBusinessRelation::Multiple);
    end;

    procedure UpdateBusinessRelation(): Boolean;
    var
        OldBusinessRelation: Enum "Contact Business Relation";
    begin
        OldBusinessRelation := "Contact Business Relation";
        "Contact Business Relation" := GetBusinessRelation();
        exit(OldBusinessRelation <> "Contact Business Relation")
    end;

    local procedure GetSelectedRelationCodes() CodeFilter: Text;
    begin
        if SelectedBusRelationCodes <> '' then
            exit(SelectedBusRelationCodes);
        MarketingSetup.GetRecordOnce();
        AppendFilter(CodeFilter, '|', MarketingSetup."Bus. Rel. Code for Customers");
        AppendFilter(CodeFilter, '|', MarketingSetup."Bus. Rel. Code for Vendors");
        AppendFilter(CodeFilter, '|', MarketingSetup."Bus. Rel. Code for Bank Accs.");
        AppendFilter(CodeFilter, '|', MarketingSetup."Bus. Rel. Code for Employees");
        SelectedBusRelationCodes := CodeFilter;
    end;

    local procedure AppendFilter(var FilterValue: Text; Operator: Text; ValueToAdd: Text)
    begin
        if FilterValue = '' then
            FilterValue := ValueToAdd
        else
            if ValueToAdd <> '' then
                FilterValue += Operator + ValueToAdd;
    end;

    procedure HasBusinessRelation(LinkToTable: Enum "Contact Business Relation Link To Table"; BusRelationCode: Code[10]): Boolean;
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        FilterBusinessRelations(ContBusRel, LinkToTable, BusRelationCode = '');
        ContBusRel.SetFilter("Business Relation Code", BusRelationCode);
        exit(not ContBusRel.IsEmpty());
    end;

    procedure HasBusinessRelations(var RelatedCustomerEnabled: Boolean; var RelatedVendorEnabled: Boolean; var RelatedBankEnabled: Boolean; var RelatedEmployeeEnabled: Boolean)
    var
        Contact: Record Contact;
    begin
        Contact.Copy(Rec);
        MarketingSetup.GetRecordOnce();
        RelatedCustomerEnabled :=
            Contact.HasBusinessRelation(
                Enum::"Contact Business Relation Link To Table"::Customer, MarketingSetup."Bus. Rel. Code for Customers");
        RelatedVendorEnabled :=
            Contact.HasBusinessRelation(
                Enum::"Contact Business Relation Link To Table"::Vendor, MarketingSetup."Bus. Rel. Code for Vendors");
        RelatedBankEnabled :=
            Contact.HasBusinessRelation(
                Enum::"Contact Business Relation Link To Table"::"Bank Account", MarketingSetup."Bus. Rel. Code for Bank Accs.");
        RelatedEmployeeEnabled :=
            Contact.HasBusinessRelation(
                Enum::"Contact Business Relation Link To Table"::Employee, MarketingSetup."Bus. Rel. Code for Employees");
    end;

    local procedure FilterBusinessRelations(var ContactBusinessRelation: Record "Contact Business Relation"; ContactBusinessRelationLinkToTable: Enum "Contact Business Relation Link To Table"; All: Boolean)
    begin
        ContactBusinessRelation.Reset();
        if ("Company No." = '') or ("Company No." = "No.") then
            ContactBusinessRelation.SetRange("Contact No.", "No.")
        else
            ContactBusinessRelation.SetFilter("Contact No.", '%1|%2', "No.", "Company No.");

        if not All then
            ContactBusinessRelation.SetFilter("No.", '<>''''');

        if ContactBusinessRelationLinkToTable <> ContactBusinessRelationLinkToTable::" " then
            ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelationLinkToTable);
    end;

    local procedure NameBreakdown()
    var
        NamePart: array[30] of Text[100];
        TempName: Text[250];
        FirstName250: Text[250];
        i: Integer;
        NoOfParts: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNameBreakdown(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Company then
            exit;

        TempName := Name;
        while StrPos(TempName, ' ') > 0 do begin
            if StrPos(TempName, ' ') > 1 then begin
                i := i + 1;
                NamePart[i] := CopyStr(TempName, 1, StrPos(TempName, ' ') - 1);
            end;
            TempName := CopyStr(TempName, StrPos(TempName, ' ') + 1);
        end;
        i := i + 1;
        NamePart[i] := CopyStr(TempName, 1, MaxStrLen(NamePart[i]));
        NoOfParts := i;

        "First Name" := '';
        "Middle Name" := '';
        Surname := '';
        for i := 1 to NoOfParts do
            if (i = NoOfParts) and (NoOfParts > 1) then
                Surname := CopyStr(NamePart[i], 1, MaxStrLen(Surname))
            else
                if (i = NoOfParts - 1) and (NoOfParts > 2) then
                    "Middle Name" := CopyStr(NamePart[i], 1, MaxStrLen("Middle Name"))
                else begin
                    FirstName250 := DelChr("First Name" + ' ' + NamePart[i], '<', ' ');
                    "First Name" := CopyStr(FirstName250, 1, MaxStrLen("First Name"));
                end;
    end;

    procedure SetSkipDefault()
    begin
        SkipDefaults := true;
    end;

    procedure IdenticalAddress(Cont: Record Contact) IsIdentical: Boolean
    begin
        IsIdentical :=
          (Address = Cont.Address) and
          ("Address 2" = Cont."Address 2") and
          ("Post Code" = Cont."Post Code") and
          (City = Cont.City);

        OnAfterIdenticalAddress(Cont, Rec, IsIdentical);
    end;

    procedure ActiveAltAddress(ActiveDate: Date) Result: Code[10]
    var
        ContAltAddrDateRange: Record "Contact Alt. Addr. Date Range";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActiveAltAddress(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ContAltAddrDateRange.SetCurrentKey("Contact No.", "Starting Date");
        ContAltAddrDateRange.SetRange("Contact No.", "No.");
        ContAltAddrDateRange.SetRange("Starting Date", 0D, ActiveDate);
        ContAltAddrDateRange.SetFilter("Ending Date", '>=%1|%2', ActiveDate, 0D);
        if ContAltAddrDateRange.FindLast() then
            exit(ContAltAddrDateRange."Contact Alt. Address Code");

        exit('');
    end;

    procedure CalculatedName() NewName: Text[100]
    var
        NewName92: Text[92];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatedName(Rec, NewName, IsHandled);
        if IsHandled then
            exit(NewName);

        if "First Name" <> '' then
            NewName92 := "First Name";
        if "Middle Name" <> '' then
            NewName92 := NewName92 + ' ' + "Middle Name";
        if Surname <> '' then
            NewName92 := NewName92 + ' ' + Surname;

        NewName92 := DelChr(NewName92, '<', ' ');

        OnAfterCalculatedName(Rec, NewName92);
        NewName := CopyStr(NewName92, 1, MaxStrLen(NewName));
    end;

    procedure UpdateSearchName()
    var
        IsHandled: Boolean;
    begin
        OnBeforeUpdateSearchName(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if ("Search Name" = UpperCase(xRec.Name)) or ("Search Name" = '') then
            "Search Name" := Name;
    end;

    procedure CheckDuplicates()
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckDuplicates(Rec, IsHandled);
        if IsHandled then
            exit;

        RMSetup.Get();
        if RMSetup."Maintain Dupl. Search Strings" then
            DuplMgt.MakeContIndex(Rec);

        if not GuiAllowed then
            exit;

        IsHandled := false;
        OnBeforeLaunchDuplicateForm(Rec, IsHandled);
        if not IsHandled then
            if DuplMgt.DuplicateExist(Rec) then begin
                Modify();
                Commit();
                DuplMgt.LaunchDuplicateForm(Rec);
            end;
    end;

    local procedure CheckCompanyNo()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCompanyNo(Rec, IsHandled);
        if not IsHandled then
            TestField("Company No.");
    end;

    local procedure CheckUnloggedSegments()
    var
        SegLine: Record "Segment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckUnloggedSegments(Rec, IsHandled);
        if IsHandled then
            exit;

        SegLine.SetRange("Contact No.", "No.");
        if not SegLine.IsEmpty() then
            Error(Text012, FieldCaption("Company No."));
    end;

    procedure CheckContactType(ContactType: Enum "Contact Type")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckContactType(Rec, ContactType, IsHandled);
        if not IsHandled then
            TestField(Type, ContactType);
    end;

    procedure FindNewCustomerTemplate(): Code[20]
    var
        CustTemplate: Record "Customer Templ.";
        ContCompany: Record Contact;
        CustTemplateCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindNewCustomerTemplate(Rec, CustTemplateCode, IsHandled);
        if IsHandled then
            exit(CustTemplateCode);

        CustTemplate.Reset();
        CustTemplate.SetRange("Territory Code", "Territory Code");
        CustTemplate.SetRange("Country/Region Code", "Country/Region Code");
        CustTemplate.SetRange("Contact Type", Type);
        if ContCompany.Get("Company No.") then
            CustTemplate.SetRange("Currency Code", ContCompany."Currency Code");

        if CustTemplate.Count = 1 then begin
            CustTemplate.FindFirst();
            exit(CustTemplate.Code);
        end;
    end;

    procedure FindNewVendorTemplate(): Code[20]
    var
        VendorTemplate: Record "Vendor Templ.";
        ContCompany: Record Contact;
    begin
        VendorTemplate.SetRange("Territory Code", "Territory Code");
        VendorTemplate.SetRange("Country/Region Code", "Country/Region Code");
        VendorTemplate.SetRange("Contact Type", Type);
        if ContCompany.Get("Company No.") then
            VendorTemplate.SetRange("Currency Code", ContCompany."Currency Code");

        if VendorTemplate.Count = 1 then begin
            VendorTemplate.FindFirst();

            exit(VendorTemplate.Code);
        end;
    end;

    procedure ChooseNewCustomerTemplate(): Code[20]
    var
        CustTemplate: Record "Customer Templ.";
        ContBusRel: Record "Contact Business Relation";
        CustomerTemplMgt: Codeunit "Customer Templ. Mgt.";
        CustTemplateCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChooseNewCustomerTemplate(Rec, CustTemplateCode, IsHandled);
        if IsHandled then
            exit(CustTemplateCode);

        CheckForExistingRelationships(ContBusRel."Link to Table"::Customer);
        ContBusRel.Reset();
        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        if ContBusRel.FindFirst() then
            Error(
              Text019,
              TableCaption, "No.", ContBusRel.TableCaption(), ContBusRel."Link to Table", ContBusRel."No.");

        IsHandled := false;
        OnChooseNewCustomerTemplateOnBeforeSelectWithConfirm(Rec, CustTemplate, IsHandled);
        if not IsHandled then
            if not HideValidationDialog then
                if Confirm(CreateCustomerFromContactQst, true) then begin
                    CustTemplate.SetRange("Contact Type", Type);
                    if CustomerTemplMgt.SelectCustomerTemplate(CustTemplate) then
                        exit(CustTemplate.Code);

                    Error(Text022);
                end;
    end;

    local procedure UpdateCompanyNo()
    var
        Cont: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        InteractLogEntry: Record "Interaction Log Entry";
        Opp: Record Opportunity;
        OppEntry: Record "Opportunity Entry";
        SalesHeader: Record "Sales Header";
        Task: Record "To-do";
        ContactCompanyNo: Code[20];
        NewCompanyNo: Code[20];
        IsHandled: Boolean;
        SkipModifyOpportunity: Boolean;
        SkipModifyOpportunityEntry: Boolean;
        SkipModifyInteractionLogEntry: Boolean;
        SkipModifySalesHeader: Boolean;
        SkipModifyTask: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateCompanyNo(Rec, xRec, IsHandled, SkipModifyOpportunity, SkipModifyOpportunityEntry, SkipModifyTask, SkipModifyInteractionLogEntry, SkipModifySalesHeader);
        if IsHandled then
            exit;

        if Cont.Get("No.") then begin
            ContactCompanyNo := xRec."Company No.";
            if xRec."Company No." <> '' then
                NewCompanyNo := xRec."Company No."
            else
                NewCompanyNo := Rec."Company No.";


            if not SkipModifyOpportunity then begin
                Opp.SetCurrentKey("Contact Company No.", "Contact No.");
                Opp.SetRange("Contact Company No.", ContactCompanyNo);
                Opp.SetRange("Contact No.", "No.");
                if not Opp.IsEmpty() then
                    Opp.ModifyAll("Contact No.", NewCompanyNo);
            end;

            if not SkipModifyOpportunityEntry then begin
                OppEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                OppEntry.SetRange("Contact Company No.", ContactCompanyNo);
                OppEntry.SetRange("Contact No.", "No.");
                if not OppEntry.IsEmpty() then
                    OppEntry.ModifyAll("Contact No.", NewCompanyNo);
            end;

            if not SkipModifyTask then begin
                Task.SetCurrentKey("Contact Company No.", "Contact No.");
                Task.SetRange("Contact Company No.", ContactCompanyNo);
                Task.SetRange("Contact No.", "No.");
                if not Task.IsEmpty() then
                    Task.ModifyAll("Contact No.", NewCompanyNo);
            end;

            if not SkipModifyInteractionLogEntry then begin
                InteractLogEntry.SetCurrentKey("Contact Company No.", "Contact No.");
                InteractLogEntry.SetRange("Contact Company No.", ContactCompanyNo);
                InteractLogEntry.SetRange("Contact No.", "No.");
                if not InteractLogEntry.IsEmpty() then
                    InteractLogEntry.ModifyAll("Contact No.", NewCompanyNo);
            end;

            if ContactCompanyNo <> '' then
                if not SkipModifySalesHeader then begin
                    ContBusRel.Reset();
                    ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
                    ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
                    ContBusRel.SetRange("Contact No.", ContactCompanyNo);
                    SalesHeader.SetCurrentKey("Sell-to Customer No.", "External Document No.");
                    SalesHeader.SetRange("Sell-to Contact No.", "No.");
                    if ContBusRel.FindFirst() then
                        SalesHeader.SetRange("Sell-to Customer No.", ContBusRel."No.")
                    else
                        SalesHeader.SetRange("Sell-to Customer No.", '');
                    if SalesHeader.Find('-') then
                        repeat
                            SalesHeader."Sell-to Contact No." := NewCompanyNo;
                            if SalesHeader."Sell-to Contact No." = SalesHeader."Bill-to Contact No." then
                                SalesHeader."Bill-to Contact No." := NewCompanyNo;
                            SalesHeader.Modify();
                        until SalesHeader.Next() = 0;
                    SalesHeader.Reset();
                    SalesHeader.SetCurrentKey("Bill-to Contact No.");
                    SalesHeader.SetRange("Bill-to Contact No.", "No.");
                    if not SalesHeader.IsEmpty() then
                        SalesHeader.ModifyAll("Bill-to Contact No.", NewCompanyNo);
                end;

            if CurrFieldNo <> 0 then
                Modify();
        end;
    end;

    procedure UpdateQuotesFromTemplate(Customer: Record Customer; CustomerTemplateCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Cont: Record Contact;
        SalesLine: Record "Sales Line";
        TempErrorMessage: Record "Error Message" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQuotesFromTemplate(Customer, CustomerTemplateCode, IsHandled, Rec);
        if IsHandled then
            exit;

        if "Company No." <> '' then
            Cont.SetRange("Company No.", "Company No.")
        else
            Cont.SetRange("No.", "No.");

        if Cont.FindSet() then
            repeat
                SalesHeader.Reset();
                SalesHeader.SetRange("Sell-to Customer No.", '');
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SetRange("Sell-to Contact No.", Cont."No.");
                if SalesHeader.FindSet() then
                    repeat
                        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");
                        SalesHeader2."Sell-to Customer No." := Customer."No.";
                        SalesHeader2."Sell-to Customer Name" := Customer.Name;
                        CheckNewCustomerTemplate(SalesHeader2, TempErrorMessage, CustomerTemplateCode);
                        SalesHeader2."Sell-to Customer Templ. Code" := '';
                        if SalesHeader2."Sell-to Contact No." = SalesHeader2."Bill-to Contact No." then begin
                            SalesHeader2."Bill-to Customer No." := Customer."No.";
                            SalesHeader2."Bill-to Name" := Customer.Name;
                            SalesHeader2."Bill-to Customer Templ. Code" := '';
                            SalesHeader2."Salesperson Code" := Customer."Salesperson Code";
                            SalesHeader2.Reserve := Customer.Reserve;
                        end;
                        SalesHeader2.Modify();
                        SalesLine.SetRange("Document Type", SalesHeader2."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader2."No.");
                        SalesLine.ModifyAll("Sell-to Customer No.", SalesHeader2."Sell-to Customer No.");
                        if SalesHeader2."Sell-to Contact No." = SalesHeader2."Bill-to Contact No." then
                            SalesLine.ModifyAll("Bill-to Customer No.", SalesHeader2."Bill-to Customer No.");
                        if SalesHeader2.Reserve <> SalesHeader2.Reserve::Optional then
                            UpdateReserveFieldOnSalesLines(SalesHeader2, SalesLine);
                        OnAfterModifySellToCustomerNo(SalesHeader2, SalesLine);
                    until SalesHeader.Next() = 0;

                SalesHeader.Reset();
                SalesHeader.SetRange("Bill-to Customer No.", '');
                SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
                SalesHeader.SetRange("Bill-to Contact No.", Cont."No.");
                if SalesHeader.FindSet() then
                    repeat
                        SalesHeader2.Get(SalesHeader."Document Type", SalesHeader."No.");
                        SalesHeader2."Bill-to Customer No." := Customer."No.";
                        SalesHeader2."Bill-to Customer Templ. Code" := '';
                        SalesHeader2."Salesperson Code" := Customer."Salesperson Code";
                        SalesHeader2.Reserve := Customer.Reserve;
                        SalesHeader2.Modify();
                        SalesLine.SetRange("Document Type", SalesHeader2."Document Type");
                        SalesLine.SetRange("Document No.", SalesHeader2."No.");
                        SalesLine.ModifyAll("Bill-to Customer No.", SalesHeader2."Bill-to Customer No.");
                        if SalesHeader2.Reserve <> SalesHeader2.Reserve::Optional then
                            UpdateReserveFieldOnSalesLines(SalesHeader2, SalesLine);
                        OnAfterModifyBillToCustomerNo(SalesHeader2, SalesLine);
                    until SalesHeader.Next() = 0;
                OnAfterUpdateQuotesForContact(Cont, Customer);
            until Cont.Next() = 0;

        if not TempErrorMessage.IsEmpty() then
            if ConfirmManagement.GetResponse(
                 StrSubstNo(MultipleCustomerTemplatesConfirmQst, CustomerTemplateCode, Customer."No."), true)
            then
                TempErrorMessage.ShowErrorMessages(false);
    end;

    local procedure UpdateReserveFieldOnSalesLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
    begin
        SalesLine.SetLoadFields("No.", "Reserve");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                if Item.Get(SalesLine."No.") then begin
                    if Item.Reserve = Item.Reserve::Optional then
                        SalesLine.Reserve := SalesHeader.Reserve
                    else
                        SalesLine.Reserve := Item.Reserve;
                    SalesLine.Modify(true);
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CheckNewCustomerTemplate(SalesHeader: Record "Sales Header"; var TempErrorMessage: Record "Error Message" temporary; CustomerTemplateCode: Code[20])
    var
        WarningMessage: Text;
    begin
        if CustomerTemplateCode = '' then
            exit;
        if SalesHeader."Sell-to Customer Templ. Code" <> CustomerTemplateCode then begin
            if SalesHeader."Sell-to Customer Templ. Code" <> '' then
                WarningMessage := StrSubstNo(
                    DifferentCustomerTemplateMsg,
                    SalesHeader."No.",
                    SalesHeader."Sell-to Customer Templ. Code",
                    CustomerTemplateCode)
            else
                WarningMessage := StrSubstNo(
                    NoOriginalCustomerTemplateMsg,
                    SalesHeader."No.",
                    CustomerTemplateCode);

            TempErrorMessage.LogMessage(
              SalesHeader,
              SalesHeader.FieldNo("Sell-to Customer Templ. Code"),
              TempErrorMessage."Message Type"::Warning,
              WarningMessage);
        end;
    end;

    procedure GetSalutation(SalutationType: Enum "Salutation Formula Salutation Type"; LanguageCode: Code[10]) Salutation: Text[260]
    var
        SalutationFormula: Record "Salutation Formula";
        NamePart: array[5] of Text[100];
        IsHandled: Boolean;
    begin
        OnBeforeGetSalutation(Rec, SalutationType, LanguageCode, IsHandled, Salutation);
        if IsHandled then
            exit(Salutation);

        if not SalutationFormula.Get("Salutation Code", LanguageCode, SalutationType) then
            Error(Text021, Format(SalutationType), LanguageCode, "No.");
        SalutationFormula.TestField(Salutation);

        case SalutationFormula."Name 1" of
            SalutationFormula."Name 1"::"Job Title":
                NamePart[1] := "Job Title";
            SalutationFormula."Name 1"::"First Name":
                NamePart[1] := "First Name";
            SalutationFormula."Name 1"::"Middle Name":
                NamePart[1] := "Middle Name";
            SalutationFormula."Name 1"::Surname:
                NamePart[1] := Surname;
            SalutationFormula."Name 1"::Initials:
                NamePart[1] := Initials;
            SalutationFormula."Name 1"::"Company Name":
                NamePart[1] := "Company Name";
        end;

        case SalutationFormula."Name 2" of
            SalutationFormula."Name 2"::"Job Title":
                NamePart[2] := "Job Title";
            SalutationFormula."Name 2"::"First Name":
                NamePart[2] := "First Name";
            SalutationFormula."Name 2"::"Middle Name":
                NamePart[2] := "Middle Name";
            SalutationFormula."Name 2"::Surname:
                NamePart[2] := Surname;
            SalutationFormula."Name 2"::Initials:
                NamePart[2] := Initials;
            SalutationFormula."Name 2"::"Company Name":
                NamePart[2] := "Company Name";
        end;

        case SalutationFormula."Name 3" of
            SalutationFormula."Name 3"::"Job Title":
                NamePart[3] := "Job Title";
            SalutationFormula."Name 3"::"First Name":
                NamePart[3] := "First Name";
            SalutationFormula."Name 3"::"Middle Name":
                NamePart[3] := "Middle Name";
            SalutationFormula."Name 3"::Surname:
                NamePart[3] := Surname;
            SalutationFormula."Name 3"::Initials:
                NamePart[3] := Initials;
            SalutationFormula."Name 3"::"Company Name":
                NamePart[3] := "Company Name";
        end;

        case SalutationFormula."Name 4" of
            SalutationFormula."Name 4"::"Job Title":
                NamePart[4] := "Job Title";
            SalutationFormula."Name 4"::"First Name":
                NamePart[4] := "First Name";
            SalutationFormula."Name 4"::"Middle Name":
                NamePart[4] := "Middle Name";
            SalutationFormula."Name 4"::Surname:
                NamePart[4] := Surname;
            SalutationFormula."Name 4"::Initials:
                NamePart[4] := Initials;
            SalutationFormula."Name 4"::"Company Name":
                NamePart[4] := "Company Name";
        end;

        case SalutationFormula."Name 5" of
            SalutationFormula."Name 5"::"Job Title":
                NamePart[5] := "Job Title";
            SalutationFormula."Name 5"::"First Name":
                NamePart[5] := "First Name";
            SalutationFormula."Name 5"::"Middle Name":
                NamePart[5] := "Middle Name";
            SalutationFormula."Name 5"::Surname:
                NamePart[5] := Surname;
            SalutationFormula."Name 5"::Initials:
                NamePart[5] := Initials;
            SalutationFormula."Name 5"::"Company Name":
                NamePart[5] := "Company Name";
        end;

        OnAfterGetSalutation(SalutationType, LanguageCode, NamePart, Rec, SalutationFormula);

        exit(GetSalutationString(SalutationFormula, NamePart));
    end;

    procedure InheritCompanyToPersonData(NewCompanyContact: Record Contact)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInheritCompanyToPersonData(Rec, xRec, NewCompanyContact, IsHandled);
        if IsHandled then
            exit;
        "Company Name" := NewCompanyContact.Name;

        RMSetup.Get();
        if RMSetup."Inherit Salesperson Code" then
            "Salesperson Code" := NewCompanyContact."Salesperson Code";
        if RMSetup."Inherit Territory Code" then
            "Territory Code" := NewCompanyContact."Territory Code";
        if RMSetup."Inherit Country/Region Code" then
            "Country/Region Code" := NewCompanyContact."Country/Region Code";
        if RMSetup."Inherit Language Code" then
            "Language Code" := NewCompanyContact."Language Code";
        if RMSetup."Inherit Format Region" then
            "Format Region" := NewCompanyContact."Format Region";
        if RMSetup."Inherit Address Details" and StaleAddress() then begin
            Address := NewCompanyContact.Address;
            "Address 2" := NewCompanyContact."Address 2";
            "Post Code" := NewCompanyContact."Post Code";
            City := NewCompanyContact.City;
            County := NewCompanyContact.County;
        end;
        if RMSetup."Inherit Communication Details" then begin
            UpdateFieldForNewCompany(FieldNo("Phone No."));
            UpdateFieldForNewCompany(FieldNo("Telex No."));
            UpdateFieldForNewCompany(FieldNo("Fax No."));
            UpdateFieldForNewCompany(FieldNo("Telex Answer Back"));
            UpdateFieldForNewCompany(FieldNo("E-Mail"));
            UpdateFieldForNewCompany(FieldNo("Home Page"));
            UpdateFieldForNewCompany(FieldNo("Extension No."));
            UpdateFieldForNewCompany(FieldNo("Mobile Phone No."));
            UpdateFieldForNewCompany(FieldNo(Pager));
            UpdateFieldForNewCompany(FieldNo("Correspondence Type"));
        end;
        CalcFields("No. of Industry Groups", "No. of Business Relations");

        OnAfterInheritCompanyToPersonData(Rec, xRec, NewCompanyContact);
    end;

    protected procedure StaleAddress() Stale: Boolean
    var
        OldCompanyContact: Record Contact;
        DummyContact: Record Contact;
    begin
        if OldCompanyContact.Get(xRec."Company No.") then
            Stale := IdenticalAddress(OldCompanyContact);
        Stale := Stale or IdenticalAddress(DummyContact);
    end;

    local procedure UpdateFieldForNewCompany(FieldNo: Integer)
    var
        OldCompanyContact: Record Contact;
        NewCompanyContact: Record Contact;
        OldCompanyRecRef: RecordRef;
        NewCompanyRecRef: RecordRef;
        ContactRecRef: RecordRef;
        ContactFieldRef: FieldRef;
        OldCompanyFieldValue: Text;
        ContactFieldValue: Text;
        Stale: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeUpdateFieldForNewCompany(Rec, FieldNo, IsHandled);
        if IsHandled then
            exit;

        ContactRecRef.GetTable(Rec);
        ContactFieldRef := ContactRecRef.Field(FieldNo);
        ContactFieldValue := Format(ContactFieldRef.Value);

        if NewCompanyContact.Get("Company No.") then begin
            NewCompanyRecRef.GetTable(NewCompanyContact);
            if OldCompanyContact.Get(xRec."Company No.") then begin
                OldCompanyRecRef.GetTable(OldCompanyContact);
                OldCompanyFieldValue := Format(OldCompanyRecRef.Field(FieldNo).Value);
                Stale := ContactFieldValue = OldCompanyFieldValue;
            end;
            if Stale or (ContactFieldValue = '') then begin
                ContactFieldRef.Validate(NewCompanyRecRef.Field(FieldNo).Value);
                ContactRecRef.SetTable(Rec);
            end;
        end;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure GetHideValidationDialog(): Boolean
    begin
        exit(HideValidationDialog);
    end;

    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::Contact, GetPosition());
    end;

    procedure ProcessNameChange()
    var
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        UpdateSearchName();

        case Type of
            Type::Company:
                ProcessCompanyNameChange();
            Type::Person:
                ProcessPersonNameChange(Cust, Vend);
        end;

        OnAfterProcessNameChange(Rec, Cust, Vend);
    end;

    local procedure ProcessCompanyNameChange()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessCompanyNameChange(Rec, IsHandled);
        if IsHandled then
            exit;

        "Company Name" := Name;
    end;

    local procedure ProcessPersonNameChange(var Customer: Record Customer; var Vendor: Record Vendor)
    var
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessPersonNameChange(IsHandled, Rec, Customer, Vendor);
        if IsHandled then
            exit;

        ContBusRel.Reset();
        ContBusRel.SetCurrentKey("Link to Table", "Contact No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        ContBusRel.SetRange("Contact No.", "Company No.");
        if ContBusRel.FindFirst() then
            if Customer.Get(ContBusRel."No.") then
                if (("No." <> '') and (Customer."Primary Contact No." = "No.")) then begin
                    IsHandled := false;
                    OnProcessPersonNameChangeOnBeforeAssignCustomerContact(Customer, Rec, IsHandled);
                    if not IsHandled then
                        Customer.Contact := Name;
                    Customer.Modify();
                end;

        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Vendor);
        if ContBusRel.FindFirst() then
            if Vendor.Get(ContBusRel."No.") then
                if (("No." <> '') and (Vendor."Primary Contact No." = "No.")) then begin
                    IsHandled := false;
                    OnProcessPersonNameChangeOnBeforeAssignVendorContact(Vendor, Rec, IsHandled);
                    if not IsHandled then
                        Vendor.Contact := Name;
                    Vendor.Modify();
                end;
    end;

    procedure GetCompNo(ContactText: Text): Text
    var
        Contact: Record Contact;
        ContactWithoutQuote: Text;
        ContactFilterFromStart: Text;
        ContactFilterContains: Text;
        ContactNo: Code[20];
    begin
        if ContactText = '' then
            exit('');

        if StrLen(ContactText) <= MaxStrLen(Contact."Company No.") then
            if Contact.Get(CopyStr(ContactText, 1, MaxStrLen(Contact."Company No."))) then
                exit(Contact."No.");

        ContactWithoutQuote := ConvertStr(ContactText, '''', '?');

        Contact.SetRange(Type, Contact.Type::Company);

        Contact.SetFilter(Name, '''@' + ContactWithoutQuote + '''');
        if Contact.FindFirst() then
            exit(Contact."No.");
        Contact.SetRange(Name);
        ContactFilterFromStart := '''@' + ContactWithoutQuote + '*''';
        Contact.FilterGroup := -1;
        Contact.SetFilter("No.", ContactFilterFromStart);
        Contact.SetFilter(Name, ContactFilterFromStart);
        if Contact.FindFirst() then
            exit(Contact."No.");
        ContactFilterContains := '''@*' + ContactWithoutQuote + '*''';
        Contact.SetFilter("No.", ContactFilterContains);
        Contact.SetFilter(Name, ContactFilterContains);
        Contact.SetFilter(City, ContactFilterContains);
        Contact.SetFilter("Phone No.", ContactFilterContains);
        Contact.SetFilter("Post Code", ContactFilterContains);
        OnGetCompNoOnAfterSetFilters(Contact);
        case Contact.Count of
            1:
                begin
                    Contact.FindFirst();
                    exit(Contact."No.");
                end;
            else begin
                if not GuiAllowed then
                    Error(SelectContactErr);
                ContactNo := SelectContact(Contact);
                if ContactNo <> '' then
                    exit(ContactNo);
            end;
        end;
        Error(SelectContactErr);
    end;

    local procedure SelectContact(var Contact: Record Contact): Code[20]
    var
        ContactList: Page "Contact List";
    begin
        if Contact.FindSet() then
            repeat
                Contact.Mark(true);
            until Contact.Next() = 0;
        if Contact.FindFirst() then;
        Contact.MarkedOnly := true;

        ContactList.SetTableView(Contact);
        ContactList.SetRecord(Contact);
        ContactList.LookupMode := true;
        if ContactList.RunModal() = ACTION::LookupOK then
            ContactList.GetRecord(Contact)
        else
            Clear(Contact);

        exit(Contact."No.");
    end;

    procedure ToPriceSource(var PriceSource: Record "Price Source")
    begin
        PriceSource.Init();
        PriceSource."Price Type" := PriceSource."Price Type"::Sale;
        PriceSource.Validate("Source Type", PriceSource."Source Type"::Contact);
        PriceSource.Validate("Source No.", "No.");
    end;

    procedure LookupCompany()
    var
        Contact: Record Contact;
        CompanyDetails: Page "Company Details";
    begin
        if "Company No." = '' then
            exit;

        Contact.Get("Company No.");
        CompanyDetails.SetRecord(Contact);
        CompanyDetails.Editable := false;
        CompanyDetails.RunModal();
    end;

    procedure LookupNewCustomerTemplate(): Code[20]
    var
        CustomerTemplate: Record "Customer Templ.";
        SelectCustomerTemplList: Page "Select Customer Templ. List";
    begin
        CustomerTemplate.FilterGroup(2);
        CustomerTemplate.SetRange("Contact Type", Type);
        CustomerTemplate.FilterGroup(0);
        SelectCustomerTemplList.LookupMode := true;
        OnLookupNewCustomerTemplateOnBeforeSetTableView(Rec, CustomerTemplate);
        SelectCustomerTemplList.SetTableView(CustomerTemplate);
        if SelectCustomerTemplList.RunModal() = ACTION::LookupOK then begin
            SelectCustomerTemplList.GetRecord(CustomerTemplate);
            exit(CustomerTemplate.Code);
        end;
    end;

    procedure CheckForExistingRelationships(LinkToTable: Enum "Contact Business Relation Link To Table")
    var
        Contact: Record Contact;
        ContBusRel: Record "Contact Business Relation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForExistingRelationships(Rec, LinkToTable.AsInteger(), IsHandled);
        if IsHandled then
            exit;

        Contact := Rec;
        ContBusRel."Link to Table" := LinkToTable;

        if "No." <> '' then begin
            CheckForCompanyContactExistingRelationships(Contact, ContBusRel);

            if ContBusRel.FindByContact(LinkToTable, Contact."No.") then
                Error(
                  AlreadyExistErr,
                  Contact.TableCaption(), "No.", ContBusRel.TableCaption(), ContBusRel."Link to Table", ContBusRel."No.");
        end;
    end;

    local procedure CheckForCompanyContactExistingRelationships(Contact: Record Contact; ContBusRel: Record "Contact Business Relation")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForCompanyContactExistingRelationships(Contact, ContBusRel, IsHandled);
        if IsHandled then
            exit;

        if (Contact.Type = Contact.Type::Person) and (Contact."Company No." <> '') then
            if ContBusRel.FindByContact(ContBusRel."Link to Table", Contact."Company No.") then
                Error(
                  AlreadyExistErr,
                  Contact.TableCaption(), "Company No.", ContBusRel.TableCaption(), ContBusRel."Link to Table", ContBusRel."No.");
    end;

    procedure FindCustomer(var Customer: Record Customer): Boolean
    var
        ContactBusinessRelation: Record "Contact Business Relation";
        ContactBusinessRelationFound: Boolean;
    begin
        Clear(Customer);

        if Rec.Type = Rec.Type::Person then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Rec."No.");

        if not ContactBusinessRelationFound then
            ContactBusinessRelationFound := ContactBusinessRelation.FindByContact(ContactBusinessRelation."Link to Table"::Customer, Rec."Company No.");

        if not ContactBusinessRelationFound then
            exit(false);

        exit(Customer.Get(ContactBusinessRelation."No."));
    end;

    procedure SetLastDateTimeModified()
    var
        UtcNow: DateTime;
        UserTimeZoneOffset: Duration;
    begin
        UtcNow := CurrentDateTime();
        UserTimeZoneOffset := GetTimeZoneOffset();
        UtcNow := UtcNow - UserTimeZoneOffset;
        "Last Date Modified" := DT2Date(UtcNow);
        "Last Time Modified" := DT2Time(UtcNow);

        OnAfterSetLastDateTimeModified(Rec);
    end;

    procedure GetLastDateTimeModified(): DateTime
    var
        Result: DateTime;
        UserTimeZoneOffset: Duration;
    begin
        if "Last Date Modified" = 0D then
            exit(0DT);

        Result := CreateDateTime("Last Date Modified", "Last Time Modified");
        UserTimeZoneOffset := GetTimeZoneOffset();
        exit(Result + UserTimeZoneOffset);
    end;

    local procedure GetTimeZoneOffset() UserTimeZoneOffset: Duration
    var
        TypeHelper: Codeunit "Type Helper";
        DotNet_DateTimeOffset: Codeunit DotNet_DateTimeOffset;
    begin
        if not TypeHelper.GetUserTimezoneOffset(UserTimeZoneOffset) then
            UserTimeZoneOffset := DotNet_DateTimeOffset.GetOffset();
    end;

    procedure SetLastDateTimeFilter(DateFilter: DateTime)
    begin
        SetFilter(systemModifiedAt, '>=%1', DateFilter);
    end;

    procedure TouchContact(ContactNo: Code[20])
    var
        Cont: Record Contact;
        IsHandled: Boolean;
    begin
        OnBeforeTouchContact(ContactNo, IsHandled);
        if IsHandled then
            exit;

        Cont.LockTable();
        if Cont.Get(ContactNo) then begin
            Cont.SetLastDateTimeModified();
            Cont.Modify();
        end;
    end;

    procedure CountNoOfBusinessRelations(LinkToTable: Enum "Contact Business Relation Link To Table"): Integer
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        FilterBusinessRelations(ContactBusinessRelation, LinkToTable, true);
        exit(ContactBusinessRelation.Count);
    end;

    procedure CreateSalesQuoteFromContact()
    var
        SalesHeader: Record "Sales Header";
        IsHandled: Boolean;
    begin
        OnBeforeCreateSalesQuoteFromContact(Rec, SalesHeader);

        CheckIfPrivacyBlockedGeneric();
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Quote);
        OnCreateSalesQuoteFromContactOnBeforeSalesHeaderInsert(Rec, SalesHeader);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Document Date", WorkDate());
        SalesHeader.Validate("Sell-to Contact No.", "No.");
        SalesHeader.Modify();
        IsHandled := false;
        OnCreateSalesQuoteFromContactOnBeforeRunPage(Rec, SalesHeader, IsHandled);
        if IsHandled then
            exit;
        PAGE.Run(PAGE::"Sales Quote", SalesHeader);
        OnCreateSalesQuoteFromContactOnAfterRunPage(Rec, SalesHeader);
    end;

    procedure CreatePurchaseQuoteFromContact()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CheckIfPrivacyBlockedGeneric();

        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Document Date", WorkDate());
        PurchaseHeader.Validate("Buy-from Contact No.", "No.");
        PurchaseHeader.Modify();

        Page.Run(Page::"Purchase Quote", PurchaseHeader);
    end;

    procedure ContactToCustBusinessRelationExist(): Boolean
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        ContBusRel.Reset();
        ContBusRel.SetRange("Contact No.", "No.");
        ContBusRel.SetRange("Link to Table", ContBusRel."Link to Table"::Customer);
        exit(ContBusRel.FindFirst())
    end;

    procedure CheckIfMinorForProfiles()
    begin
        if Minor then
            Error(ProfileForMinorErr);
    end;

    procedure CheckIfPrivacyBlocked(IsPosting: Boolean)
    begin
        if "Privacy Blocked" then begin
            if IsPosting then
                Error(ErrorInfo.Create(StrSubstNo(PrivacyBlockedPostErr, "No."), true, Rec));
            Error(ErrorInfo.Create(StrSubstNo(PrivacyBlockedCreateErr, "No."), true, Rec));
        end;
    end;

    procedure CheckIfPrivacyBlockedGeneric()
    begin
        if "Privacy Blocked" then
            Error(PrivacyBlockedGenericErr, "No.", Name);
    end;

    local procedure ValidateSalesPerson()
    begin
        if "Salesperson Code" <> '' then
            if Salesperson.Get("Salesperson Code") then
                if Salesperson.VerifySalesPersonPurchaserPrivacyBlocked(Salesperson) then
                    Error(Salesperson.GetPrivacyBlockedGenericText(Salesperson, true))
    end;

    protected procedure SetDefaultSalesperson()
    var
        UserSetup: Record "User Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSalesperson(Rec, IsHandled);
        if IsHandled then
            exit;

        if UserSetup.Get(UserId) and (UserSetup."Salespers./Purch. Code" <> '') then
            "Salesperson Code" := UserSetup."Salespers./Purch. Code";

        OnAfterSetDefaultSalesperson(Rec);
    end;

    procedure VATRegistrationValidation()
    var
        VATRegistrationNoFormat: Record "VAT Registration No. Format";
        VATRegistrationLog: Record "VAT Registration Log";
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
        VATRegistrationLogMgt: Codeunit "VAT Registration Log Mgt.";
        ResultRecordRef: RecordRef;
        ApplicableCountryCode: Code[10];
        IsHandled: Boolean;
        LogNotVerified: Boolean;
    begin
        IsHandled := false;
        OnBeforeVATRegistrationValidation(Rec, IsHandled);
        if IsHandled then
            exit;

        if not VATRegistrationNoFormat.Test("VAT Registration No.", "Country/Region Code", "No.", DATABASE::Contact) then
            exit;

        LogNotVerified := true;
        if ("Country/Region Code" <> '') or (VATRegistrationNoFormat."Country/Region Code" <> '') then begin
            ApplicableCountryCode := "Country/Region Code";
            if ApplicableCountryCode = '' then
                ApplicableCountryCode := VATRegistrationNoFormat."Country/Region Code";
            if VATRegNoSrvConfig.VATRegNoSrvIsEnabled() then begin
                LogNotVerified := false;
                VATRegistrationLogMgt.ValidateVATRegNoWithVIES(
                    ResultRecordRef, Rec, "No.", VATRegistrationLog."Account Type"::Contact.AsInteger(), ApplicableCountryCode);
                ResultRecordRef.SetTable(Rec);
            end;
        end;

        if LogNotVerified then
            VATRegistrationLogMgt.LogContact(Rec);
    end;

    procedure GetContNo(ContactText: Text): Code[20]
    var
        Contact: Record Contact;
        ContactWithoutQuote: Text;
        ContactFilterFromStart: Text;
        ContactFilterContains: Text;
    begin
        if ContactText = '' then
            exit('');

        if StrLen(ContactText) <= MaxStrLen(Contact."No.") then
            if Contact.Get(CopyStr(ContactText, 1, MaxStrLen(Contact."No."))) then
                exit(Contact."No.");

        Contact.SetRange(Name, ContactText);
        if Contact.FindFirst() then
            exit(Contact."No.");

        Contact.SetCurrentKey(Name);

        ContactWithoutQuote := ConvertStr(ContactText, '''', '?');
        Contact.SetFilter(Name, '''@' + ContactWithoutQuote + '''');
        if Contact.FindFirst() then
            exit(Contact."No.");

        Contact.SetRange(Name);

        ContactFilterFromStart := '''@' + ContactWithoutQuote + '*''';
        Contact.FilterGroup := -1;
        Contact.SetFilter("No.", ContactFilterFromStart);
        Contact.SetFilter(Name, ContactFilterFromStart);
        if Contact.FindFirst() then
            exit(Contact."No.");

        ContactFilterContains := '''@*' + ContactWithoutQuote + '*''';
        Contact.SetFilter("No.", ContactFilterContains);
        Contact.SetFilter(Name, ContactFilterContains);
        Contact.SetFilter(City, ContactFilterContains);
        Contact.SetFilter("Phone No.", ContactFilterContains);
        Contact.SetFilter("Post Code", ContactFilterContains);
        if Contact.Count = 0 then
            MarkContactsWithSimilarName(Contact, ContactText);

        if Contact.Count = 1 then begin
            Contact.FindFirst();
            exit(Contact."No.");
        end;

        exit('');
    end;

    protected procedure MarkContactsWithSimilarName(var Contact: Record Contact; ContactText: Text)
    var
        TypeHelper: Codeunit "Type Helper";
        ContactCount: Integer;
        ContactTextLength: Integer;
        Treshold: Integer;
    begin
        if ContactText = '' then
            exit;
        if StrLen(ContactText) > MaxStrLen(Contact.Name) then
            exit;

        ContactTextLength := StrLen(ContactText);
        Treshold := ContactTextLength div 5;
        if Treshold = 0 then
            exit;

        Contact.Reset();
        Contact.Ascending(false); // most likely to search for newest contacts
        if Contact.FindSet() then
            repeat
                ContactCount += 1;
                if Abs(ContactTextLength - StrLen(Contact.Name)) <= Treshold then
                    if TypeHelper.TextDistance(UpperCase(ContactText), UpperCase(Contact.Name)) <= Treshold then
                        Contact.Mark(true);
            until Contact.Mark() or (Contact.Next() = 0) or (ContactCount > 1000);
        Contact.MarkedOnly(true);
    end;

    local procedure IsUpdateNeeded(ContactBeforeModify: Record Contact): Boolean
    var
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (Name <> ContactBeforeModify.Name) or
          ("Search Name" <> ContactBeforeModify."Search Name") or
          ("Name 2" <> ContactBeforeModify."Name 2") or
          (Address <> ContactBeforeModify.Address) or
          ("Address 2" <> ContactBeforeModify."Address 2") or
          (City <> ContactBeforeModify.City) or
          ("Phone No." <> ContactBeforeModify."Phone No.") or
          ("Mobile Phone No." <> ContactBeforeModify."Mobile Phone No.") or
          ("Telex No." <> ContactBeforeModify."Telex No.") or
          ("Territory Code" <> ContactBeforeModify."Territory Code") or
          ("Currency Code" <> ContactBeforeModify."Currency Code") or
          ("Language Code" <> ContactBeforeModify."Language Code") or
          ("Format Region" <> ContactBeforeModify."Format Region") or
          ("Salesperson Code" <> ContactBeforeModify."Salesperson Code") or
          ("Country/Region Code" <> ContactBeforeModify."Country/Region Code") or
          ("Fax No." <> ContactBeforeModify."Fax No.") or
          ("Telex Answer Back" <> ContactBeforeModify."Telex Answer Back") or
          ("Registration Number" <> ContactBeforeModify."Registration Number") or
          ("VAT Registration No." <> ContactBeforeModify."VAT Registration No.") or
          ("Post Code" <> ContactBeforeModify."Post Code") or
          (County <> ContactBeforeModify.County) or
          ("E-Mail" <> ContactBeforeModify."E-Mail") or
          ("Search E-Mail" <> ContactBeforeModify."Search E-Mail") or
          ("Home Page" <> ContactBeforeModify."Home Page") or
          (Type <> ContactBeforeModify.Type);

        OnBeforeIsUpdateNeeded(Rec, ContactBeforeModify, UpdateNeeded);
        exit(UpdateNeeded);
    end;

    local procedure GetSalutationString(SalutationFormula: Record "Salutation Formula"; NamePart: array[5] of Text[100]) SalutationString: Text[260]
    var
        SubStr: Text;
        i: Integer;
    begin
        for i := 1 to 5 do
            if NamePart[i] = '' then begin
                SubStr := '%' + Format(i) + ' ';
                if StrPos(SalutationFormula.Salutation, SubStr) > 0 then
                    SalutationFormula.Salutation :=
                      DelStr(SalutationFormula.Salutation, StrPos(SalutationFormula.Salutation, SubStr), 3);
            end;
        SalutationString := CopyStr(StrSubstNo(SalutationFormula.Salutation, NamePart[1], NamePart[2], NamePart[3], NamePart[4], NamePart[5]), 1, MaxStrLen(SalutationString));

        OnGetSalutationString(SalutationString, SalutationFormula, NamePart);
    end;

    procedure GetContactsSelectionFromContactList(SelectMode: Boolean): Boolean
    var
        ContactList: Page "Contact List";
    begin
        ContactList.LookupMode(SelectMode);
        ContactList.SetTableView(Rec);
        if ContactList.RunModal() = Action::LookupOK then begin
            SetFilter("No.", ContactList.GetSelectionFilter());
            exit(FindSet());
        end;
        exit(false);
    end;

    protected procedure SetSearchEmail()
    begin
        if "Search E-Mail" <> "E-Mail".ToUpper() then
            "Search E-Mail" := "E-Mail";
    end;

    procedure CreateEmployee() EmployeeNo: Code[20];
    var
        Employee: Record Employee;
        ContBusRel: Record "Contact Business Relation";
        EmployeeTempl: Record "Employee Templ.";
        CustVendBankUpdate: Codeunit "CustVendBank-Update";
        EmployeeTemplMgt: Codeunit "Employee Templ. Mgt.";
        TemplateSelected: Boolean;
        IsHandled: Boolean;
    begin
        CheckContactType(Type::Person);
        CheckIfPrivacyBlockedGeneric();

        if EmployeeTemplMgt.IsEnabled() then begin
            TemplateSelected := EmployeeTemplMgt.SelectEmployeeTemplateFromContact(EmployeeTempl);
            if not TemplateSelected then
                if EmployeeTemplMgt.TemplatesAreNotEmpty() then
                    exit;
        end;

        Employee.Init();
        IsHandled := false;
        OnCreateEmployeeOnBeforeInitEmployeeNo(Employee, Rec, EmployeeTempl, IsHandled);
        if not IsHandled then
            EmployeeTemplMgt.InitEmployeeNo(Employee, EmployeeTempl);
        Employee.Insert(true);
        EmployeeNo := Employee."No.";

        ContBusRel.CreateRelation("No.", Employee."No.", ContBusRel."Link to Table"::Employee);
        CustVendBankUpdate.UpdateEmployee(Rec, ContBusRel);
        Commit();
        Employee.Get(Employee."No.");
        if TemplateSelected then
            EmployeeTemplMgt.ApplyEmployeeTemplate(Employee, EmployeeTempl);

        if not HideValidationDialog then
            Message(RelatedRecordIsCreatedMsg, Employee.TableCaption());

        OnAfterCreateEmployee(Employee, ContBusRel);
    end;

    procedure CreateEmployeeLink()
    var
        ContBusRel: Record "Contact Business Relation";
    begin
        CheckContactType(Type::Person);
        CheckIfPrivacyBlockedGeneric();

        MarketingSetup.GetRecordOnce();
        MarketingSetup.TestField("Bus. Rel. Code for Employees");
        CreateLink(Page::"Employee Link", MarketingSetup."Bus. Rel. Code for Employees", ContBusRel."Link to Table"::Employee);
    end;

    procedure GetOrClear(ContactNo: Code[20])
    begin
        if not Rec.Get(ContactNo) then
            Clear(Rec);
    end;

    local procedure ValidateLookupContactNo()
    begin
        if Type = Type::Company then
            "Lookup Contact No." := ''
        else
            "Lookup Contact No." := "No.";
    end;

    local procedure UpdateFormatRegion();
    var
        Language: Record Language;
        LanguageSelection: Record "Language Selection";
    begin
        if (Rec."Format Region" <> '') then
            exit;
        if not Language.Get("Language Code") then
            exit;

        LanguageSelection.SetRange("Language ID", Language."Windows Language ID");
        if LanguageSelection.FindFirst() then
            Rec.Validate("Format Region", LanguageSelection."Language Tag");
    end;

    local procedure UpdateQuotesFromTemplate(Vendor: Record Vendor; VendorTemplateCode: Code[20])
    var
        Contact: Record Contact;
        TempErrorMessage: Record "Error Message" temporary;
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if "Company No." <> '' then
            Contact.SetRange("Company No.", "Company No.")
        else
            Contact.SetRange("No.", "No.");

        if Contact.FindSet() then
            repeat
                AssignVendorToQuotesByBuyFromContact(Contact, Vendor, TempErrorMessage, VendorTemplateCode);
                AssignVendorToQuotesByPayToContact(Contact, Vendor);
            until Contact.Next() = 0;

        if not TempErrorMessage.IsEmpty() then
            if ConfirmManagement.GetResponse(StrSubstNo(MultipleVendorTemplatesConfirmQst, VendorTemplateCode, Vendor."No."), true) then
                TempErrorMessage.ShowErrorMessages(false);
    end;

    local procedure AssignVendorToQuotesByBuyFromContact(Contact: Record Contact; Vendor: Record Vendor; var TempErrorMessage: Record "Error Message" temporary; VendorTemplateCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", '');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("Buy-from Contact No.", Contact."No.");
        if PurchaseHeader.FindSet() then
            repeat
                PurchaseHeader2.LockTable();
                PurchaseHeader2.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
                PurchaseHeader2."Buy-from Vendor No." := Vendor."No.";
                PurchaseHeader2."Buy-from Vendor Name" := Vendor.Name;
                CheckNewVendorTemplate(PurchaseHeader2, TempErrorMessage, VendorTemplateCode);

                PurchaseHeader2."Buy-from Vendor Templ. Code" := '';
                if PurchaseHeader2."Buy-from Contact No." = PurchaseHeader2."Pay-to Contact No." then begin
                    PurchaseHeader2."Pay-to Vendor No." := Vendor."No.";
                    PurchaseHeader2."Pay-to Name" := Vendor.Name;
                    PurchaseHeader2."Pay-to Vendor Templ. Code" := '';
                    PurchaseHeader2."Purchaser Code" := Vendor."Purchaser Code";
                end;
                PurchaseHeader2.Modify();

                PurchaseLine.LockTable();
                PurchaseLine.SetRange("Document Type", PurchaseHeader2."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader2."No.");
                PurchaseLine.ModifyAll("Buy-from Vendor No.", PurchaseHeader2."Buy-from Vendor No.");

                if PurchaseHeader2."Buy-from Contact No." = PurchaseHeader2."Pay-to Contact No." then
                    PurchaseLine.ModifyAll("Pay-to Vendor No.", PurchaseHeader2."Pay-to Vendor No.");
            until PurchaseHeader.Next() = 0;
    end;

    local procedure AssignVendorToQuotesByPayToContact(Contact: Record Contact; Vendor: Record Vendor)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.SetRange("Pay-to Vendor No.", '');
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("Pay-to Contact No.", Contact."No.");
        if PurchaseHeader.FindSet() then
            repeat
                PurchaseHeader2.LockTable();
                PurchaseHeader2.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
                PurchaseHeader2."Pay-to Vendor No." := Vendor."No.";
                PurchaseHeader2."Pay-to Vendor Templ. Code" := '';
                PurchaseHeader2."Purchaser Code" := Vendor."Purchaser Code";
                PurchaseHeader2.Modify();

                PurchaseLine.LockTable();
                PurchaseLine.SetRange("Document Type", PurchaseHeader2."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader2."No.");
                PurchaseLine.ModifyAll("Pay-to Vendor No.", PurchaseHeader2."Pay-to Vendor No.");
            until PurchaseHeader.Next() = 0;
    end;

    local procedure CheckNewVendorTemplate(PurchaseHeader: Record "Purchase Header"; var TempErrorMessage: Record "Error Message" temporary; VendorTemplateCode: Code[20])
    var
        WarningMessage: Text;
    begin
        if VendorTemplateCode = '' then
            exit;

        if PurchaseHeader."Buy-from Vendor Templ. Code" = VendorTemplateCode then
            exit;

        if PurchaseHeader."Buy-from Vendor Templ. Code" <> '' then
            WarningMessage := StrSubstNo(
                DifferentVendorTemplateMsg,
                PurchaseHeader."No.",
                PurchaseHeader."Buy-from Vendor Templ. Code",
                VendorTemplateCode)
        else
            WarningMessage := StrSubstNo(
                NoOriginalVendorTemplateMsg,
                PurchaseHeader."No.",
                VendorTemplateCode);

        TempErrorMessage.LogMessage(
          PurchaseHeader,
          PurchaseHeader.FieldNo("Buy-from Vendor Templ. Code"),
          TempErrorMessage."Message Type"::Warning,
          WarningMessage);
    end;

    internal procedure LookupNewVendorTemplate(): Code[20]
    var
        VendorTemplate: Record "Vendor Templ.";
        SelectVendorTemplList: Page "Select Vendor Templ. List";
    begin
        VendorTemplate.FilterGroup(2);
        VendorTemplate.SetRange("Contact Type", Type);
        VendorTemplate.FilterGroup(0);
        SelectVendorTemplList.LookupMode := true;

        SelectVendorTemplList.SetTableView(VendorTemplate);
        if SelectVendorTemplList.RunModal() = Action::LookupOK then begin
            SelectVendorTemplList.GetRecord(VendorTemplate);

            exit(VendorTemplate.Code);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalutation(var SalutationType: Enum "Salutation Formula Salutation Type"; var LanguageCode: Code[10]; var NamePart: array[5] of Text[100]; var Contact: Record Contact; var SalutationFormula: Record "Salutation Formula")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInheritCompanyToPersonData(var Contact: Record Contact; xContact: Record Contact; NewCompanyContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQuotesForContact(Contact: Record Contact; Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterVendorInsert(var Vendor: Record Vendor; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeVendorInsert(var Vend: Record Vendor; var Contact: Record Contact; VendorTemplateCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTypeChangePossibleForPerson(var Contact: Record Contact; xContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChooseNewCustomerTemplate(var Contact: Record Contact; var CustTemplateCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateLink(var Contact: Record Contact; var TempContBusRel: Record "Contact Business Relation"; var CreateForm: Integer; var BusRelCode: Code[10]; var Table: Enum "Contact Business Relation Link To Table"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChooseNewCustomerTemplateOnBeforeSelectWithConfirm(var Contact: Record Contact; var CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnBeforeCustomerInsert(var Cust: Record Customer; CustomerTemplate: Code[20]; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindNewCustomerTemplate(var Contact: Record Contact; var CustTemplateCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInheritCompanyToPersonData(var Contact: Record Contact; xContact: Record Contact; var NewCompanyContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsUpdateNeeded(var Contact: Record Contact; xContact: Record Contact; var UpdateNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerOnBeforeCustomerModify(var Customer: Record Customer; Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnAfterApplyCustomerTemplate(var Customer: Record Customer; CustomerTemplate: Record "Customer Templ."; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerLinkOnAfterCreateLink(var Contact: Record Contact; xContact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatedName(var Contact: Record Contact; var NewName92: Text[92])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateBankAccount(var Contact: Record Contact; var BankAccount: Record "Bank Account");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomer(var Contact: Record Contact; var Customer: Record Customer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateCustomerLink(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInteraction(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateLink(var Contact: Record Contact; xContact: Record Contact; CreateFrom: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendor(var Contact: Record Contact; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIdenticalAddress(Contact: Record Contact; RecContact: Record Contact; var IsIdentical: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifySellToCustomerNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterModifyBillToCustomerNo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnInsert(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnModify(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessNameChange(var Contact: Record Contact; Customer: Record Customer; Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaults(var Contact: Record Contact; MarketingSetup: Record "Marketing Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLastDateTimeModified(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultSalesperson(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTypeForContact(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowCustVendBank(var Contact: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; FormSelected: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSyncAddress(var Contact: Record Contact; RecContact: Record Contact; var ContChanged: Boolean; var ContactBeforeModify: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTypeChange(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateCity(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidatePostCode(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssistEditOnAfterNoSeriesMgtSetSeries(var Contact: Record Contact; OldContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActiveAltAddress(var Contact: Record Contact; var Result: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeApplyCompanyChangeToPerson(var PersonContact: Record Contact; Contact: Record Contact; xContact: Record Contact; var ContChanged: Boolean; OldContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssistEdit(var Contact: record Contact; OldContact: Record Contact; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBankAccountInsert(var BankAccount: Record "Bank Account"; var Contact: Record Contact);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDuplicateCheck(Contact: Record Contact; xContact: Record Contact; var IsDuplicateCheckNeeded: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatedName(var Contact: Record Contact; var NewName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForExistingRelationships(var Contact: Record Contact; LinkToTable: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForCompanyContactExistingRelationships(var Contact: Record Contact; var ContBusRel: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCompanyNo(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckDuplicates(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckContactType(var Contact: Record Contact; ContactType: enum "Contact Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckUnloggedSegments(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerFromTemplate(var Contact: Record Contact; var CustNo: Code[20]; var IsHandled: Boolean; CustomerTemplate: Code[20]; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCompanyContactCustomerFromTemplate(var Contact: Record Contact; CustomerTemplate: Code[20]; var CustNo: Code[20]; HideValidationDialog: Boolean; var CustomerCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCompanyContactVendor(var Contact: Record Contact; var VendorNo: Code[20]; HideValidationDialog: Boolean; var VendorCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCustomerLink(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateBankAccount(var Contact: Record Contact; var BankAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateSalesQuoteFromContact(var Contact: Record Contact; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendor(var Contact: Record Contact; var VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalutation(var Contact: Record Contact; var SalutationType: Enum "Salutation Formula Salutation Type"; var LanguageCode: Code[10]; var IsHandled: Boolean; var Salutation: Text[260])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupCity(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupPostCode(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNameBreakdown(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var Contact: Record Contact; xContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeProcessPersonNameChange(var IsHandled: Boolean; var Contact: Record Contact; var Customer: Record Customer; var Vendor: Record Vendor)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTypeChange(var Contact: Record Contact; xContact: Record Contact; var InteractLogEntry: Record "Interaction Log Entry"; var Opp: Record Opportunity; var Task: Record "To-do"; var Cont: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVATRegistrationValidation(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Contact: Record Contact; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateNo(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVATRegistrationNo(var Contact: Record Contact; xContact: Record Contact; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLaunchDuplicateForm(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateCompanyNo(var Contact: Record Contact; xContact: Record Contact; var IsHandled: Boolean; var SkipModifyOpportunity: Boolean; var SkipModifyOpportunityEntry: Boolean; var SkipModifyTask: Boolean; var SkipModifyInteractionLogEntry: Boolean; var SkipModifySalesHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQuotesFromTemplate(Customer: Record Customer; CustomerTemplateCode: Code[20]; var IsHandled: Boolean; var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateFieldForNewCompany(var Contact: Record Contact; var FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateSearchName(var Contact: Record Contact; xContact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Contact: Record Contact; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesQuoteFromContactOnBeforeSalesHeaderInsert(var Contact: Record Contact; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerOnBeforeUpdateQuotes(var Customer: Record Customer; Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorOnAfterUpdateVendor(var Vendor: Record Vendor; Contact: Record Contact; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupNewCustomerTemplateOnBeforeSetTableView(Contact: Record Contact; var CustomerTemplate: Record "Customer Templ.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetCompNoOnAfterSetFilters(var Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalutationString(var SalutationString: Text[260]; SalutationFormula: Record "Salutation Formula"; NamePart: array[5] of Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCustVendBankOnBeforeRunPage(var Contact: Record Contact; FormSelected: Boolean; var ContBusRel: Record "Contact Business Relation"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEmployee(var Employee: Record Employee; var ContBusRel: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupPostCode(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTypeChangeOnAfterCheckInteractionLog(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTypeChangeOnAfterContSetFilters(var Contact: Record Contact; CurrentContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTypeChangeOnAfterTypePersonTestFields(Contact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSalesperson(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResultForCustomer(var Customer: Record Customer; var Contact: Record Contact; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResultForVendor(var Vendor: Record Vendor; var Contact: Record Contact; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeCommit(Contact: Record Contact; Vend: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendorLink(var Contact: Record Contact; xContact: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateVendorLink(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnBeforeInitCustomerNo(var Customer: Record Customer; var Contact: Record Contact; CustomerTempl: Record "Customer Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeInitVendorNo(var Vendor: Record Vendor; var Contact: Record Contact; VendorTempl: Record "Vendor Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessCompanyNameChange(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPersonNameChangeOnBeforeAssignCustomerContact(var Customer: Record Customer; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessPersonNameChangeOnBeforeAssignVendorContact(var Vendor: Record Vendor; var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var Contact: Record Contact; ContactBeforeModify: Record Contact)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateEmail(var Contact: Record Contact; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowResultForVendorOnBeforeShowrelatedRecordisCreatedMsg(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRegistrationNumber(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupCity(var Contact: Record Contact; var PostCode: Record "Post Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesQuoteFromContactOnBeforeRunPage(Contact: Record Contact; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateSalesQuoteFromContactOnAfterRunPage(Contact: Record Contact; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeInheritAddressDetails(var RecContact: Record Contact; var xRecContact: Record Contact; MarketingSetup: Record "Marketing Setup"; Contact: Record Contact; var ContChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnModifyOnBeforeInheritCommunicationDetails(var RecContact: Record Contact; var xRecContact: Record Contact; MarketingSetup: Record "Marketing Setup"; Contact: Record Contact; var ContChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEmployeeOnBeforeInitEmployeeNo(var Employee: Record Employee; var Contact: Record Contact; EmployeeTempl: Record "Employee Templ."; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateCustomerFromTemplateOnBeforeContBusRelInsert(var Contact: Record Contact; var Customer: Record Customer; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorFromTemplateOnBeforeContBusRelInsert(var Contact: Record Contact; var Vendor: Record Vendor; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateBankAccountOnBeforeContBusRelInsert(var Contact: Record Contact; var BankAccount: Record "Bank Account"; var ContactBusinessRelation: Record "Contact Business Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateBankAccountLink(var Contact: Record Contact; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTouchContact(ContactNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowBusinessRelationOnAfterFilterBusinessRelations(var Rec: Record Contact; var ContactBusinessRelation: Record "Contact Business Relation"; ContactBusinessRelationLinkToTable: Enum "Contact Business Relation Link To Table"; All: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateVendorOnVendorTemplateNotExist(var Contact: Record Contact; var VendorNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}