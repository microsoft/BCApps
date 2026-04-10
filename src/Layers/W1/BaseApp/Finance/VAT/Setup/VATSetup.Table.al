// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Registration;
using System.Security.User;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Stores global VAT configuration settings including non-deductible VAT setup, VAT date controls, and alternative customer VAT registration handling.
/// Central configuration table that controls VAT behavior across all Business Central VAT processes.
/// </summary>
/// <remarks>
/// Key features: Non-deductible VAT enablement, VAT date range validation, item/fixed asset/project cost integration.
/// Extensibility: VAT setup changes trigger system-wide validation and configuration updates.
/// Related objects: VAT Posting Setup, General Ledger Setup, User Setup Management.
/// </remarks>
table 189 "VAT Setup"
{
    Caption = 'VAT Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "VAT Setup";
    LookupPageID = "VAT Setup";

    fields
    {
        /// <summary>
        /// Single record identifier for global VAT setup configuration.
        /// </summary>
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        /// <summary>
        /// Enables non-deductible VAT functionality across the system with one-way activation control.
        /// </summary>
        field(2; "Enable Non-Deductible VAT"; Boolean)
        {
            Caption = 'Enable Non-Deductible VAT';
            ToolTip = 'Specifies if the Non-Deductible VAT feature is enabled.';

            trigger OnValidate()
            var
                ConfirmMgt: Codeunit "Confirm Management";
                FeatureTelemetry: Codeunit "Feature Telemetry";
            begin
                if "Non-Deductible VAT Is Enabled" then
                    Error(NotPossibleToDisableNonDedVATErr);
                if not ConfirmMgt.GetResponse(OneWayWarningMsg, false) then
                    error('');
                if GuiAllowed and "Enable Non-Deductible VAT" then
                    ShowEnableNonDeductibleVATNotification();
                "Non-Deductible VAT Is Enabled" := true;
                FeatureTelemetry.LogUsage('0000KI4', 'Non-Deductible VAT', 'The feature is enabled');
            end;
        }
        /// <summary>
        /// Controls whether non-deductible VAT amounts are included in item cost calculations.
        /// </summary>
        field(3; "Use For Item Cost"; Boolean)
        {
            Caption = 'Use For Item Cost';
            ToolTip = 'Specifies if the non-deductible VAT must be added to the item cost.';
        }
        /// <summary>
        /// Controls whether non-deductible VAT amounts are included in fixed asset cost calculations.
        /// </summary>
        field(4; "Use For Fixed Asset Cost"; Boolean)
        {
            Caption = 'Use For Fixed Asset Cost';
            ToolTip = 'Specifies if the non-deductible VAT must be added to the fixed asset cost.';
        }
        /// <summary>
        /// Controls whether non-deductible VAT amounts are included in project cost calculations.
        /// </summary>
        field(5; "Use For Job Cost"; Boolean)
        {
            Caption = 'Use For Project Cost';
            ToolTip = 'Specifies if the non-deductible VAT must be added to the project cost.';
        }
        /// <summary>
        /// Controls visibility of non-deductible VAT information in transaction line details.
        /// </summary>
        field(10; "Show Non-Ded. VAT In Lines"; Boolean)
        {
            Caption = 'Show Non-Ded. VAT In Lines';
            ToolTip = 'Specifies if the non-deductible VAT must be shown in document lines pages.';
        }
        /// <summary>
        /// Read-only indicator showing non-deductible VAT feature activation status.
        /// </summary>
        field(11; "Non-Deductible VAT Is Enabled"; Boolean)
        {
            Caption = 'Non-Deductible VAT Is Enabled';
            Editable = false;
        }
        /// <summary>
        /// Starting date for allowed VAT date range validation across VAT transactions.
        /// </summary>
        field(12; "Allow VAT Date From"; Date)
        {
            Caption = 'Allow VAT Date From';
            ToolTip = 'Specifies the earliest date on which VAT posting to the company books is allowed.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From", "Allow VAT Date To", 0, Database::"General Ledger Setup");
            end;
        }
        /// <summary>
        /// Ending date for allowed VAT date range validation across VAT transactions.
        /// </summary>
        field(13; "Allow VAT Date To"; Date)
        {
            Caption = 'Allow VAT Date To';
            ToolTip = 'Specifies the last date on which VAT posting to the company books is allowed.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From", "Allow VAT Date To", 0, Database::"General Ledger Setup");
            end;
        }
        /// <summary>
        /// Controls alternative customer VAT registration number consistency validation behavior.
        /// </summary>
        field(21; "Alt. Cust. VAT Reg. Consistent"; Enum "Alt. Cust. VAT Reg. Consist.")
        {
            Caption = 'Alt. Cust. VAT Reg. Consistente';
        }
        /// <summary>
        /// Defines document handling for alternative customer VAT registration numbers.
        /// </summary>
        field(22; "Alt. Cust. VAT Reg. Doc."; Enum "Alt. Cust VAT Reg. Doc.")
        {
            Caption = 'Alt. Cust. VAT Reg. Doc.';
        }
        /// <summary>
        /// Controls ship-to address alternative VAT registration number validation rules.
        /// </summary>
        field(23; "Ship-To Alt. Cust. VAT Reg."; Enum "Ship-To Alt. Cust. VAT Reg.")
        {
            Caption = 'Ship-To Alt. Cust. VAT Reg.';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        UserSetupManagement: Codeunit "User Setup Management";
        OneWayWarningMsg: Label 'After you enable this feature, you cannot turn it off again. This is because the feature may include changes to your data and may initiate an upgrade of some database tables as soon as you enable it.\\We strongly recommend that you first enable and test this feature on a sandbox environment that has a copy of production data before doing this on a production environment.\\For detailed information about the impact of enabling this feature, you should choose No and use the Learn more link.\\Are you sure you want to enable this feature?';
        NotPossibleToDisableNonDedVATErr: Label 'It is not possible to disable the Non-Deductible VAT';
        CompleteVATPostingSetupLbl: Label 'Choose Complete to open the VAT Posting Setup page where you can allow certain VAT Posting Setup for Non-Deductible VAT and set Non-Deductible VAT %';
        CompleteLbl: Label 'Complete';

    /// <summary>
    /// Displays notification to complete VAT Posting Setup configuration for non-deductible VAT.
    /// </summary>
    procedure ShowEnableNonDeductibleVATNotification()
    var
        EnableNonDedVATNotification: Notification;
    begin
        EnableNonDedVATNotification.Message := CompleteVATPostingSetupLbl;
        EnableNonDedVATNotification.Scope := NotificationScope::LocalScope;
        EnableNonDedVATNotification.AddAction(CompleteLbl, Codeunit::"Non-Ded. VAT Impl.", 'OpenVATPostingSetupPage');
        EnableNonDedVATNotification.Send();
    end;

    /// <summary>
    /// Validates VAT date range against allowed dates setup and triggers appropriate notifications or errors.
    /// </summary>
    /// <param name="NotificationType">Type of notification to display - Error or Notification</param>
    procedure CheckAllowedVATDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From",
          "Allow VAT Date To", NotificationType, DATABASE::"General Ledger Setup");
    end;
}

