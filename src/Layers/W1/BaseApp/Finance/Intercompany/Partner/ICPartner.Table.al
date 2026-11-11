// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Partner;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Outbox;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;

/// <summary>
/// Stores intercompany partner information for managing transactions between related companies.
/// Defines communication methods, account mappings, and authentication settings for intercompany operations.
/// </summary>
/// <remarks>
/// Key relationships: Customer and Vendor records, G/L accounts for receivables/payables.
/// Supports multiple communication types: database, file location, email, and API-based exchanges.
/// Extensible via table extensions for custom partner attributes and integration requirements.
/// </remarks>
table 413 "IC Partner"
{
    Caption = 'IC Partner';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Unique identifier for the intercompany partner used in all intercompany transactions.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the intercompany partner for identification and reporting purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        /// <summary>
        /// Currency code used for transactions with this intercompany partner.
        /// </summary>
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        /// <summary>
        /// Communication method for receiving intercompany transactions from this partner.
        /// </summary>
        field(4; "Inbox Type"; Enum "IC Partner Inbox Type")
        {
            Caption = 'Inbox Type';
            InitValue = Database;
        }
        /// <summary>
        /// Communication details for the selected inbox type, such as file path, company name, or email address.
        /// </summary>
        field(5; "Inbox Details"; Text[250])
        {
            Caption = 'Inbox Details';
            TableRelation =
            if ("Inbox Type" = const(Database)) Company.Name;
        }
        /// <summary>
        /// G/L account for posting intercompany receivables from this partner.
        /// </summary>
        field(6; "Receivables Account"; Code[20])
        {
            Caption = 'Receivables Account';
            TableRelation = "G/L Account"."No.";
        }
        /// <summary>
        /// G/L account for posting intercompany payables to this partner.
        /// </summary>
        field(7; "Payables Account"; Code[20])
        {
            Caption = 'Payables Account';
            TableRelation = "G/L Account"."No.";
        }
        /// <summary>
        /// Country/region code of the intercompany partner for localization and reporting purposes.
        /// </summary>
        field(8; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        /// <summary>
        /// Indicates whether transactions with this intercompany partner are blocked.
        /// </summary>
        field(10; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Indicates whether comments exist for this intercompany partner.
        /// </summary>
        field(11; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("IC Partner"),
                                                      "No." = field(Code)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Customer number linked to this intercompany partner for sales transactions.
        /// </summary>
        field(12; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            TableRelation = Customer;
        }
        /// <summary>
        /// Vendor number linked to this intercompany partner for purchase transactions.
        /// </summary>
        field(13; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        /// <summary>
        /// Item number type used for outbound sales documents to this partner.
        /// </summary>
        field(14; "Outbound Sales Item No. Type"; Enum "IC Outb. Sales Item No. Type")
        {
            Caption = 'Outbound Sales Item No. Type';
        }
        /// <summary>
        /// Item number type used for outbound purchase documents to this partner.
        /// </summary>
        field(15; "Outbound Purch. Item No. Type"; Enum "IC Outb. Purch. Item No. Type")
        {
            Caption = 'Outbound Purch. Item No. Type';
        }
        /// <summary>
        /// Indicates whether cost distribution for this partner should be in local currency.
        /// </summary>
        field(16; "Cost Distribution in LCY"; Boolean)
        {
            Caption = 'Cost Distribution in LCY';
        }
        /// <summary>
        /// Indicates whether intercompany transactions from this partner are automatically accepted without approval.
        /// </summary>
        field(17; "Auto. Accept Transactions"; Boolean)
        {
            Caption = 'Auto. Accept Transactions';
        }
        /// <summary>
        /// Data exchange type determining the communication method for intercompany transactions.
        /// </summary>
        field(18; "Data Exchange Type"; Enum "IC Data Exchange Type")
        {
            Caption = 'Data Exchange Type';
            Description = 'Specifies the type of data exchange with the partner, enabling the system to determine the appropriate communication method for intercompany transactions.';
            Editable = false;
            InitValue = Database;
        }
        /// <summary>
        /// Encrypted connection URL key for API-based intercompany communication.
        /// </summary>
        field(100; "Connection Url Key"; Guid)
        {
            Caption = 'Connection URL Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Encrypted company ID key for identifying the partner company in API communication.
        /// </summary>
        field(101; "Company Id Key"; Guid)
        {
            Caption = 'Company ID Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Encrypted client ID key for OAuth authentication with the partner.
        /// </summary>
        field(102; "Client Id Key"; Guid)
        {
            Caption = 'Client ID Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Encrypted client secret key for OAuth authentication with the partner.
        /// </summary>
        field(103; "Client Secret Key"; Guid)
        {
            Caption = 'Client Secret Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
#if not CLEANSCHEMA27
        /// <summary>
        /// Encrypted authority URL key for OAuth authentication (obsolete, replaced by token endpoint).
        /// </summary>
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
        /// <summary>
        /// Encrypted redirect URL key for OAuth authentication flow with the partner.
        /// </summary>
        field(105; "Redirect Url key"; Guid)
        {
            Caption = 'Redirect URL Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Encrypted authentication token key for secure communication with the partner.
        /// </summary>
        field(106; "Token Key"; Guid)
        {
            Caption = 'Client Secret Key';
            ExtendedDatatype = Masked;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Expiration date and time for the current authentication token.
        /// </summary>
        field(107; "Token Expiration Time"; DateTime)
        {
            Caption = 'Token Expiration Time';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Encrypted token endpoint key for OAuth token refresh operations.
        /// </summary>
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
}
#endif
