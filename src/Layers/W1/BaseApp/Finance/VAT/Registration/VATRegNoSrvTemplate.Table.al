// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Foundation.Address;

/// <summary>
/// Defines validation templates for VAT registration number service with country and account-specific configuration.
/// Controls validation behavior and detail handling for different business entity types and jurisdictions.
/// </summary>
table 226 "VAT Reg. No. Srv. Template"
{
    Caption = 'VAT Reg. No. Validation Template';
    LookupPageId = "VAT Reg. No. Srv. Templates";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the VAT registration service validation template.
        /// </summary>
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the template code.';
        }
        /// <summary>
        /// Country/region code that determines the geographical scope for this validation template.
        /// </summary>
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region".Code;
            ToolTip = 'Specifies the country/region code.';
        }
        /// <summary>
        /// Account type that determines which business entity type this template applies to.
        /// </summary>
        field(11; "Account Type"; Enum "VAT Reg. No. Srv. Template Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the account type.';
        }
        /// <summary>
        /// Specific account number to limit template application to a particular business entity.
        /// </summary>
        field(12; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number.';
        }
        /// <summary>
        /// Indicates whether to validate entity name against VIES service response.
        /// </summary>
        field(20; "Validate Name"; Boolean)
        {
            Caption = 'Validate Name';
            ToolTip = 'Specifies if the name value is validated.';
        }
        /// <summary>
        /// Indicates whether to validate street address against VIES service response.
        /// </summary>
        field(21; "Validate Street"; Boolean)
        {
            Caption = 'Validate Street';
            ToolTip = 'Specifies if the street value is validated.';
        }
        /// <summary>
        /// Indicates whether to validate city against VIES service response.
        /// </summary>
        field(22; "Validate City"; Boolean)
        {
            Caption = 'Validate City';
            ToolTip = 'Specifies if the city value is validated.';
        }
        /// <summary>
        /// Indicates whether to validate postal code against VIES service response.
        /// </summary>
        field(23; "Validate Post Code"; Boolean)
        {
            Caption = 'Validate Post Code';
            ToolTip = 'Specifies if the post code value is validated.';
        }
        /// <summary>
        /// Controls whether to ignore detailed validation information from VIES service.
        /// </summary>
        field(24; "Ignore Details"; Boolean)
        {
            Caption = 'Ignore Details';
            ToolTip = 'Specifies if you want to exclude any detailed information that the validation service returns. Choose the field to view all validation details.';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    var
        DefaultTxt: Label 'Default';

    /// <summary>
    /// Finds the most appropriate validation template for the given VAT registration log entry.
    /// Uses hierarchical matching based on country, account type, and account number.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log entry requiring template selection</param>
    /// <returns>Template code for the most specific matching template or default template</returns>
    procedure FindTemplate(VATRegistrationLog: Record "VAT Registration Log") Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindTemplate(VATRegistrationLog, IsHandled, Result, Rec);
        if IsHandled then
            exit(Result);

        SetRange("Country/Region Code", VATRegistrationLog."Country/Region Code");
        SetRange("Account Type", MapVATRegLogAccountType(VATRegistrationLog."Account Type"));
        SetRange("Account No.", VATRegistrationLog."Account No.");
        if FindFirst() then
            exit(Code);

        SetRange("Account No.", '');
        if FindFirst() then
            exit(Code);

        SetRange("Account Type", "Account Type"::None);
        if FindFirst() then
            exit(Code);

        exit(LoadDefaultTempalte());
    end;

    local procedure LoadDefaultTempalte(): Code[20]
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        CheckInitDefaultTemplate(VATRegNoSrvConfig);
        VATRegNoSrvConfig.TestField("Default Template Code");
        Get(VATRegNoSrvConfig."Default Template Code");
        exit(Code);
    end;

    /// <summary>
    /// Initializes default validation template if none exists and updates service configuration.
    /// </summary>
    /// <param name="VATRegNoSrvConfig">VAT registration service configuration to update with default template</param>
    procedure CheckInitDefaultTemplate(var VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config")
    var
        VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template";
    begin
        if (VATRegNoSrvConfig."Default Template Code" = '') and (VATRegNoSrvTemplate.Count() = 0) then begin
            VATRegNoSrvTemplate.Init();
            VATRegNoSrvTemplate.Code := DefaultTxt;
            if VATRegNoSrvTemplate.Insert() then;

            VATRegNoSrvConfig."Default Template Code" := VATRegNoSrvTemplate.Code;
            VATRegNoSrvConfig.Modify();
        end;
    end;

    local procedure MapVATRegLogAccountType(VATRegLogAccountType: Enum "VAT Registration Log Account Type"): Enum "VAT Reg. No. Srv. Template Account Type"
    var
        DummyVATRegistrationLog: Record "VAT Registration Log";
    begin
        case VATRegLogAccountType of
            DummyVATRegistrationLog."Account Type"::Customer:
                exit("Account Type"::Customer);
            DummyVATRegistrationLog."Account Type"::Vendor:
                exit("Account Type"::Vendor);
            DummyVATRegistrationLog."Account Type"::Contact:
                exit("Account Type"::Contact);
            else
                exit("Account Type"::None);
        end;
    end;

    /// <summary>
    /// Integration event raised before finding validation template to allow custom template selection logic.
    /// </summary>
    /// <param name="VATRegistrationLog">VAT registration log entry requiring template</param>
    /// <param name="IsHandled">Set to true to skip standard template selection</param>
    /// <param name="Result">Template code to use when custom logic is applied</param>
    /// <param name="VATRegNoSrvTemplate">Template record for custom processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTemplate(VATRegistrationLog: Record "VAT Registration Log"; var IsHandled: Boolean; var Result: Code[20]; var VATRegNoSrvTemplate: Record "VAT Reg. No. Srv. Template")
    begin
    end;
}
