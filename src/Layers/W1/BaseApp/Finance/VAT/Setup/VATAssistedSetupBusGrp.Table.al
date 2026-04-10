// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Temporary table used during VAT Setup Wizard to manage VAT business posting group selections and defaults.
/// Stores user selections and configuration options for creating VAT business posting groups during assisted setup.
/// </summary>
/// <remarks>
/// Usage context: VAT Setup Wizard temporary data storage and user interaction management.
/// Lifecycle: Created and populated during wizard execution, not persisted in database.
/// Integration: Works with VAT Setup Wizard to create permanent VAT business posting groups.
/// </remarks>
table 1879 "VAT Assisted Setup Bus. Grp."
{
    Caption = 'VAT Assisted Setup Bus. Grp.';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// VAT business posting group code for wizard selection and configuration.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive text explaining the VAT business posting group's purpose.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the VAT business posting group.';
        }
        /// <summary>
        /// User selection indicator for including this VAT business posting group in setup.
        /// </summary>
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            ToolTip = 'Specifies if the VAT business posting group is included on the part.';
        }
        /// <summary>
        /// Indicates whether this VAT business posting group is the default selection.
        /// </summary>
        field(4; Default; Boolean)
        {
            Caption = 'Default';
        }
    }

    keys
    {
        key(Key1; "Code", Default)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Code001Tok: Label 'DOMESTIC', Comment = 'the same as values in Bus. posting group';
        Code002Tok: Label 'EU', Comment = 'the same as values in Bus. posting group';
        Code003Tok: Label 'EXPORT', Comment = 'the same as values in Bus. posting group';
        Text001Txt: Label 'Domestic customers and vendors';
        Text002Txt: Label 'Customers and vendors in EU';
        Text003Txt: Label 'Other customers and vendors (not EU)';

    /// <summary>
    /// Populates the table with standard VAT business posting groups for wizard selection.
    /// Creates default entries for Domestic, EU, and Export VAT business posting groups.
    /// </summary>
    procedure PopulateVATBusGrp()
    begin
        SetRange(Default, false);
        DeleteAll();

        SetRange(Default, true);
        if not FindSet() then begin
            InitWithStandardValues();
            FindSet();
        end;

        repeat
            InsertBusPostingGrp(Code, Description, false);
        until Next() = 0;
    end;

    /// <summary>
    /// Inserts a VAT business posting group entry for wizard selection with specified parameters.
    /// Creates temporary record for user selection during VAT setup wizard process.
    /// </summary>
    /// <param name="GrpCode">VAT business posting group code</param>
    /// <param name="GrpDesc">Descriptive text for the VAT business posting group</param>
    /// <param name="IsDefault">Whether this is a default template entry</param>
    procedure InsertBusPostingGrp(GrpCode: Code[20]; GrpDesc: Text[100]; IsDefault: Boolean)
    var
        VATAssistedSetupBusGrp: Record "VAT Assisted Setup Bus. Grp.";
    begin
        VATAssistedSetupBusGrp.Init();
        VATAssistedSetupBusGrp.Code := GrpCode;
        VATAssistedSetupBusGrp.Description := GrpDesc;
        VATAssistedSetupBusGrp.Selected := true;
        VATAssistedSetupBusGrp.Default := IsDefault;
        VATAssistedSetupBusGrp.Insert();
    end;

    /// <summary>
    /// Validates that at least one VAT business posting group is selected for creation.
    /// Checks user selections to ensure wizard can proceed with VAT business posting group setup.
    /// </summary>
    /// <returns>True if at least one non-default VAT business posting group is selected</returns>
    procedure ValidateVATBusGrp(): Boolean
    begin
        SetRange(Selected, true);
        SetRange(Default, false);
        exit(not IsEmpty);
    end;

    /// <summary>
    /// Checks whether customers or vendors already exist with the specified VAT business posting group.
    /// Validates data dependencies before allowing VAT business posting group modifications.
    /// </summary>
    /// <param name="VATBusPostingGroupCode">VAT business posting group code to check</param>
    /// <returns>True if customers or vendors use the specified VAT business posting group</returns>
    procedure CheckExistingCustomersAndVendorsWithVAT(VATBusPostingGroupCode: Code[20]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
    begin
        Customer.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.SetRange("VAT Bus. Posting Group", VATBusPostingGroupCode);
        exit((not Vendor.IsEmpty) or (not Customer.IsEmpty));
    end;

    local procedure InitWithStandardValues()
    begin
        InsertBusPostingGrp(Code001Tok, Text001Txt, true);
        InsertBusPostingGrp(Code002Tok, Text002Txt, true);
        InsertBusPostingGrp(Code003Tok, Text003Txt, true);
    end;
}

