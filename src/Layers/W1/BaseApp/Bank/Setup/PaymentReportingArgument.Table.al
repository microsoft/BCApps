// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using System.Integration;

/// <summary>
/// Temporary table for passing payment service arguments and configuration data.
/// Used for communication between payment processing and external payment service providers.
/// </summary>
/// <remarks>
/// Supports integration with PayPal, Microsoft Wallet, WorldPay, and other payment services.
/// Contains logos, URLs, and service-specific configuration for payment provider integration.
/// </remarks>
table 1062 "Payment Reporting Argument"
{
    Caption = 'Payment Reporting Argument';
    Permissions = TableData "Payment Reporting Argument" = rimd;
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Auto-incrementing unique identifier for each payment reporting argument record.
        /// </summary>
        field(1; "Key"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Key';
        }
        /// <summary>
        /// Record ID of the source document being processed for payment.
        /// Links the payment argument to the originating transaction record.
        /// </summary>
        field(3; "Document Record ID"; RecordID)
        {
            Caption = 'Document Record ID';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Record ID of the payment setup configuration being used.
        /// References the payment service setup that defines processing parameters.
        /// </summary>
        field(4; "Setup Record ID"; RecordID)
        {
            Caption = 'Setup Record ID';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Payment service provider logo stored as binary data.
        /// Used for branding in payment forms and customer communications.
        /// </summary>
        field(10; Logo; BLOB)
        {
            Caption = 'Logo';
        }
        /// <summary>
        /// Display caption for the payment service URL link.
        /// Shown to users as the clickable text for payment service access.
        /// </summary>
        field(12; "URL Caption"; Text[250])
        {
            Caption = 'URL Caption';
        }
        /// <summary>
        /// Target URL for the payment service stored as binary data.
        /// Contains the actual web address for payment processing.
        /// </summary>
        field(13; "Target URL"; BLOB)
        {
            Caption = 'Service URL';
        }
        /// <summary>
        /// Language code for localization of payment service interface.
        /// Determines the language used in payment provider communications.
        /// </summary>
        field(30; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
        }
        /// <summary>
        /// Identifier for the specific payment service provider.
        /// Maps to predefined payment service types (PayPal, Microsoft Wallet, WorldPay).
        /// </summary>
        field(35; "Payment Service ID"; Integer)
        {
            Caption = 'Payment Service ID';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PaymentServiceID: Option ,PayPal,"MS Wallet",WorldPay;

    /// <summary>
    /// Retrieves the target URL from the BLOB field as a text string.
    /// Extracts the payment service URL for use in web requests and redirects.
    /// </summary>
    /// <returns>The target URL as a text string, or empty string if no URL is stored</returns>
    procedure GetTargetURL() TargetURL: Text
    var
        InStream: InStream;
    begin
        CalcFields("Target URL");
        if "Target URL".HasValue() then begin
            "Target URL".CreateInStream(InStream);
            InStream.Read(TargetURL);
        end;
    end;

    /// <summary>
    /// Sets the target URL by storing it in the BLOB field after validation.
    /// Validates that the URL is properly formatted and uses HTTP/HTTPS protocol.
    /// </summary>
    /// <param name="ServiceURL">The payment service URL to store</param>
    procedure SetTargetURL(ServiceURL: Text)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        OutStream: OutStream;
    begin
        WebRequestHelper.IsValidUri(ServiceURL);
        WebRequestHelper.IsHttpUrl(ServiceURL);

        "Target URL".CreateOutStream(OutStream);
        OutStream.Write(ServiceURL);
        Modify();
    end;

    /// <summary>
    /// Attempts to set the target URL with error handling.
    /// Returns success/failure status without throwing exceptions.
    /// </summary>
    /// <param name="ServiceURL">The payment service URL to store</param>
    /// <returns>True if URL was successfully set, false if validation failed</returns>
    [TryFunction]
    procedure TrySetTargetURL(ServiceURL: Text)
    begin
        SetTargetURL(ServiceURL);
    end;

    /// <summary>
    /// Returns the currency code, defaulting to local currency if not specified.
    /// Ensures a valid currency code is always available for payment processing.
    /// </summary>
    /// <param name="CurrencyCode">Input currency code that may be empty</param>
    /// <returns>The input currency code if specified, otherwise the local currency code</returns>
    procedure GetCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.GetCurrencyCode(CurrencyCode);
        exit(GeneralLedgerSetup."LCY Code");
    end;

    /// <summary>
    /// Returns the service identifier for PayPal payment processing.
    /// Used to identify PayPal as the selected payment service provider.
    /// </summary>
    /// <returns>Integer identifier for PayPal service</returns>
    procedure GetPayPalServiceID(): Integer
    begin
        exit(PaymentServiceID::PayPal);
    end;

    /// <summary>
    /// Returns the service identifier for Microsoft Wallet payment processing.
    /// Used to identify Microsoft Wallet as the selected payment service provider.
    /// </summary>
    /// <returns>Integer identifier for Microsoft Wallet service</returns>
    procedure GetMSWalletServiceID(): Integer
    begin
        exit(PaymentServiceID::"MS Wallet");
    end;

    /// <summary>
    /// Returns the service identifier for WorldPay payment processing.
    /// Used to identify WorldPay as the selected payment service provider.
    /// </summary>
    /// <returns>Integer identifier for WorldPay service</returns>
    procedure GetWorldPayServiceID(): Integer
    begin
        exit(PaymentServiceID::WorldPay);
    end;

    /// <summary>
    /// Returns the filename for the PayPal logo image resource.
    /// Used for displaying PayPal branding in payment interfaces.
    /// </summary>
    /// <returns>Filename of the PayPal logo image</returns>
    procedure GetPayPalLogoFile(): Text
    begin
        exit('Payment service - PayPal-logo.png');
    end;

    /// <summary>
    /// Returns the filename for the Microsoft Wallet logo image resource.
    /// Used for displaying Microsoft branding in payment interfaces.
    /// </summary>
    /// <returns>Filename of the Microsoft Wallet logo image</returns>
    procedure GetMSWalletLogoFile(): Text
    begin
        exit('Payment service - Microsoft-logo.png');
    end;

    /// <summary>
    /// Returns the filename for the WorldPay logo image resource.
    /// Used for displaying WorldPay branding in payment interfaces.
    /// </summary>
    /// <returns>Filename of the WorldPay logo image</returns>
    procedure GetWorldPayLogoFile(): Text
    begin
        exit('Payment service - WorldPay-logo.png');
    end;
}

