// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

/// <summary>
/// Configuration settings for VAT registration number validation service integration.
/// Controls service enablement, endpoint configuration, and default validation template selection.
/// </summary>
table 248 "VAT Reg. No. Srv Config"
{
    Caption = 'VAT Reg. No. Srv Config';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Primary key entry number for the configuration record.
        /// </summary>
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Indicates whether VAT registration number validation service is active.
        /// </summary>
        field(2; Enabled; Boolean)
        {
            Caption = 'Enabled';
            ToolTip = 'Specifies if the service is enabled.';
        }
        /// <summary>
        /// URL endpoint for the VAT registration number validation service (typically VIES).
        /// </summary>
        field(3; "Service Endpoint"; Text[250])
        {
            Caption = 'Service Endpoint';
            ToolTip = 'Specifies the endpoint of the VAT registration number validation service.';
        }
        /// <summary>
        /// Default validation template used when no specific template is found for validation requests.
        /// </summary>
        field(10; "Default Template Code"; Code[20])
        {
            Caption = 'Default Template Code';
            TableRelation = "VAT Reg. No. Srv. Template";
            ToolTip = 'Specifies the default template for validation of additional company information.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if not IsEmpty() then
            Error(CannotInsertMultipleSettingsErr);
    end;

    var
        VATRegNoVIESSettingIsNotEnabledErr: Label 'VAT Reg. No. Validation Setup is not enabled.';
        CannotInsertMultipleSettingsErr: Label 'You cannot insert multiple settings.';

    /// <summary>
    /// Determines whether VAT registration number validation service is currently enabled.
    /// </summary>
    /// <returns>True if service is enabled and configured</returns>
    procedure VATRegNoSrvIsEnabled(): Boolean
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.SetRange(Enabled, true);
        exit(VATRegNoSrvConfig.FindFirst() and VATRegNoSrvConfig.Enabled);
    end;

    /// <summary>
    /// Retrieves the configured VAT registration number validation service endpoint URL.
    /// </summary>
    /// <returns>Service endpoint URL for VAT number validation</returns>
    procedure GetVATRegNoURL(): Text
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.SetRange(Enabled, true);
        if not VATRegNoSrvConfig.FindFirst() then
            Error(VATRegNoVIESSettingIsNotEnabledErr);

        VATRegNoSrvConfig.TestField("Service Endpoint");

        exit(VATRegNoSrvConfig."Service Endpoint");
    end;
}

