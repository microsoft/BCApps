// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Defines general business posting groups for transaction classification and G/L account assignment automation.
/// Controls default VAT business posting group assignment and automatic general posting setup creation.
/// </summary>
/// <remarks>
/// Used with general product posting groups to determine G/L account assignments through General Posting Setup matrix.
/// Integrates with customer, vendor, and G/L account master data for consistent posting group assignment.
/// Extensibility: OnValidateDefVATBusPostingGroupOnBeforeModifyGLAccount event for custom validation logic.
/// </remarks>
table 250 "Gen. Business Posting Group"
{
    Caption = 'Gen. Business Posting Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Business Posting Groups";
    Permissions = tabledata "Gen. Business Posting Group" = r;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the general business posting group used in transaction classification.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the business group.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name for the general business posting group explaining its business purpose.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the general business posting group.';
        }
        /// <summary>
        /// Default VAT business posting group automatically assigned to customers, vendors, and G/L accounts using this general business posting group.
        /// </summary>
        field(3; "Def. VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'Def. VAT Bus. Posting Group';
            ToolTip = 'Specifies a default VAT business group code.';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                if "Def. VAT Bus. Posting Group" <> xRec."Def. VAT Bus. Posting Group" then begin
                    GLAcc.SetCurrentKey("Gen. Bus. Posting Group");
                    GLAcc.SetRange("Gen. Bus. Posting Group", Code);
                    GLAcc.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if GLAcc.Find('-') then
                        repeat
                            GLAcc2 := GLAcc;
                            GLAcc2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            OnValidateDefVATBusPostingGroupOnBeforeModifyGLAccount(Rec, GLAcc2);
                            GLAcc2.Modify();
                        until GLAcc.Next() = 0;

                    Cust.SetCurrentKey("Gen. Bus. Posting Group");
                    Cust.SetRange("Gen. Bus. Posting Group", Code);
                    Cust.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if Cust.Find('-') then
                        repeat
                            Cust2 := Cust;
                            Cust2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            Cust2.Modify();
                        until Cust.Next() = 0;

                    Vend.SetCurrentKey("Gen. Bus. Posting Group");
                    Vend.SetRange("Gen. Bus. Posting Group", Code);
                    Vend.SetRange("VAT Bus. Posting Group", xRec."Def. VAT Bus. Posting Group");
                    if Vend.Find('-') then
                        repeat
                            Vend2 := Vend;
                            Vend2."VAT Bus. Posting Group" := "Def. VAT Bus. Posting Group";
                            Vend2.Modify();
                        until Vend.Next() = 0;
                end;
            end;
        }
        /// <summary>
        /// Controls automatic creation of general posting setup records when this business posting group is combined with product posting groups.
        /// </summary>
        field(4; "Auto Insert Default"; Boolean)
        {
            Caption = 'Auto Insert Default';
            ToolTip = 'Specifies whether to automatically insert the Def. VAT Bus. Posting Group when the corresponding Code is inserted on new customer and vendor cards.';
            InitValue = true;
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
        fieldgroup(Brick; "Code", Description, "Def. VAT Bus. Posting Group")
        {
        }
    }

    var
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        Cust: Record Customer;
        Cust2: Record Customer;
        Vend: Record Vendor;
        Vend2: Record Vendor;

    /// <summary>
    /// Validates and retrieves general business posting group configuration for automatic posting setup creation.
    /// </summary>
    /// <param name="GenBusPostingGrp">General business posting group record to validate and populate</param>
    /// <param name="EnteredGenBusPostingGroup">Business posting group code to validate</param>
    /// <returns>True if auto insert default is enabled for the posting group, false otherwise</returns>
    procedure ValidateVatBusPostingGroup(var GenBusPostingGrp: Record "Gen. Business Posting Group"; EnteredGenBusPostingGroup: Code[20]): Boolean
    begin
        if EnteredGenBusPostingGroup <> '' then
            GenBusPostingGrp.Get(EnteredGenBusPostingGroup)
        else
            GenBusPostingGrp.Init();
        exit(GenBusPostingGrp."Auto Insert Default");
    end;

    /// <summary>
    /// Integration event raised before modifying G/L account VAT business posting group during default VAT posting group update.
    /// Enables custom validation or modification logic for G/L account VAT posting group changes.
    /// </summary>
    /// <param name="Rec">General business posting group record being processed</param>
    /// <param name="GLAccount">G/L account record being modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateDefVATBusPostingGroupOnBeforeModifyGLAccount(var Rec: Record "Gen. Business Posting Group"; var GLAccount: Record "G/L Account")
    begin
    end;
}

