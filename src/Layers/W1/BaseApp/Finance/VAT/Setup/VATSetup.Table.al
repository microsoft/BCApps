// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Calculation;
using System.Security.User;
using System.Telemetry;
using System.Utilities;

table 189 "VAT Setup"
{
    Caption = 'VAT Setup';
    DataClassification = CustomerContent;
    DrillDownPageID = "VAT Setup";
    LookupPageID = "VAT Setup";

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Enable Non-Deductible VAT"; Boolean)
        {
            Caption = 'Enable Non-Deductible VAT';

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
        field(3; "Use For Item Cost"; Boolean)
        {
            Caption = 'Use For Item Cost';
        }
        field(4; "Use For Fixed Asset Cost"; Boolean)
        {
            Caption = 'Use For Fixed Asset Cost';
        }
        field(5; "Use For Job Cost"; Boolean)
        {
            Caption = 'Use For Project Cost';
        }
        field(10; "Show Non-Ded. VAT In Lines"; Boolean)
        {
            Caption = 'Show Non-Ded. VAT In Lines';
        }
        field(11; "Non-Deductible VAT Is Enabled"; Boolean)
        {
            Caption = 'Non-Deductible VAT Is Enabled';
            Editable = false;
        }
        field(12; "Allow VAT Date From"; Date)
        {
            Caption = 'Allow VAT Date From';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From", "Allow VAT Date To", 0, Database::"General Ledger Setup");
            end;
        }
        field(13; "Allow VAT Date To"; Date)
        {
            Caption = 'Allow VAT Date To';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From", "Allow VAT Date To", 0, Database::"General Ledger Setup");
            end;
        }
        field(21; "Alt. Cust. VAT Reg. Consistent"; Enum "Alt. Cust. VAT Reg. Consist.")
        {
            Caption = 'Alt. Cust. VAT Reg. Consistente';
        }
        field(22; "Alt. Cust. VAT Reg. Doc."; Enum "Alt. Cust VAT Reg. Doc.")
        {
            Caption = 'Alt. Cust. VAT Reg. Doc.';
        }
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

    procedure ShowEnableNonDeductibleVATNotification()
    var
        EnableNonDedVATNotification: Notification;
    begin
        EnableNonDedVATNotification.Message := CompleteVATPostingSetupLbl;
        EnableNonDedVATNotification.Scope := NotificationScope::LocalScope;
        EnableNonDedVATNotification.AddAction(CompleteLbl, Codeunit::"Non-Ded. VAT Impl.", 'OpenVATPostingSetupPage');
        EnableNonDedVATNotification.Send();
    end;

    procedure CheckAllowedVATDates(NotificationType: Option Error,Notification)
    begin
        UserSetupManagement.CheckAllowedVATDatesRange("Allow VAT Date From",
          "Allow VAT Date To", NotificationType, DATABASE::"General Ledger Setup");
    end;
}

