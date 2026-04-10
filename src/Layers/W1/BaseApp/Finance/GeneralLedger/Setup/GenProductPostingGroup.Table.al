// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using System.Utilities;

/// <summary>
/// Defines general product posting groups and default VAT product group linkage.
/// Used to determine posting accounts for item/resource related transactions.
/// </summary>
table 251 "Gen. Product Posting Group"
{
    Caption = 'Gen. Product Posting Group';
    DataCaptionFields = "Code", Description;
    LookupPageID = "Gen. Product Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique code identifying the general product posting group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the product posting group.';
            NotBlank = true;
        }
        /// <summary>
        /// Descriptive name of the posting group for readability.
        /// </summary>
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description for the product posting group.';
        }
        /// <summary>
        /// Default VAT product posting group applied when this product group is used.
        /// Changing this value can cascade updates to related records.
        /// </summary>
        field(3; "Def. VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'Def. VAT Prod. Posting Group';
            ToolTip = 'Specifies a default VAT product group code.';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if CurrFieldNo = 0 then
                    exit;

                if "Def. VAT Prod. Posting Group" <> xRec."Def. VAT Prod. Posting Group" then begin
                    GLAcc.SetCurrentKey("Gen. Prod. Posting Group");
                    GLAcc.SetRange("Gen. Prod. Posting Group", Code);
                    GLAcc.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if GLAcc.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, GLAcc.FieldCaption("VAT Prod. Posting Group"),
                               GLAcc.TableCaption(), GLAcc.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                GLAcc2 := GLAcc;
                                GLAcc2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                OnValidateDefVATProdPostingGroupOnBeforeGLAcc2Modify(GLAcc2, Rec);
                                GLAcc2.Modify();
                            until GLAcc.Next() = 0;

                    Item.SetCurrentKey("Gen. Prod. Posting Group");
                    Item.SetRange("Gen. Prod. Posting Group", Code);
                    Item.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if Item.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, Item.FieldCaption("VAT Prod. Posting Group"),
                               Item.TableCaption(), Item.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                Item2 := Item;
                                Item2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                OnValidateDefVATProdPostingGroupOnBeforeItem2Modify(Item2, Rec);
                                Item2.Modify();
                            until Item.Next() = 0;

                    Res.SetCurrentKey("Gen. Prod. Posting Group");
                    Res.SetRange("Gen. Prod. Posting Group", Code);
                    Res.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if Res.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, Res.FieldCaption("VAT Prod. Posting Group"),
                               Res.TableCaption(), Res.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                Res2 := Res;
                                Res2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                Res2.Modify();
                            until Res.Next() = 0;

                    ItemCharge.SetCurrentKey("Gen. Prod. Posting Group");
                    ItemCharge.SetRange("Gen. Prod. Posting Group", Code);
                    ItemCharge.SetRange("VAT Prod. Posting Group", xRec."Def. VAT Prod. Posting Group");
                    if ItemCharge.Find('-') then
                        if ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, ItemCharge.FieldCaption("VAT Prod. Posting Group"),
                               ItemCharge.TableCaption(), ItemCharge.FieldCaption("Gen. Prod. Posting Group"),
                               Code, xRec."Def. VAT Prod. Posting Group"), true)
                        then
                            repeat
                                ItemCharge2 := ItemCharge;
                                ItemCharge2."VAT Prod. Posting Group" := "Def. VAT Prod. Posting Group";
                                ItemCharge2.Modify();
                            until ItemCharge.Next() = 0;
                end;
            end;
        }
        /// <summary>
        /// If true, default VAT product group is auto-inserted on related records.
        /// </summary>
        field(4; "Auto Insert Default"; Boolean)
        {
            Caption = 'Auto Insert Default';
            ToolTip = 'Specifies whether to automatically insert the default VAT product posting group code in the Def. VAT Prod. Posting Group field when you insert the corresponding general product posting group code from the Code field, for example on new item and resource cards, or in the item charges setup.';
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
        fieldgroup(Brick; "Code", Description, "Def. VAT Prod. Posting Group")
        {
        }
    }

    var
        GLAcc: Record "G/L Account";
        GLAcc2: Record "G/L Account";
        Item: Record Item;
        Item2: Record Item;
        Res: Record Resource;
        Res2: Record Resource;
        ItemCharge: Record "Item Charge";
        ItemCharge2: Record "Item Charge";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Change all occurrences of %1 in %2\where %3 is %4\and %1 is %5.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    /// <summary>
    /// Validates and retrieves a General Product Posting Group record by code, indicating if auto-insert is enabled.
    /// </summary>
    /// <param name="GenProdPostingGrp">Variable to receive the posting group record</param>
    /// <param name="EnteredGenProdPostingGroup">Posting group code to validate and retrieve</param>
    /// <returns>True if the posting group has Auto Insert Default enabled, false otherwise</returns>
    procedure ValidateVatProdPostingGroup(var GenProdPostingGrp: Record "Gen. Product Posting Group"; EnteredGenProdPostingGroup: Code[20]): Boolean
    begin
        if EnteredGenProdPostingGroup <> '' then
            GenProdPostingGrp.Get(EnteredGenProdPostingGroup)
        else
            GenProdPostingGrp.Init();
        exit(GenProdPostingGrp."Auto Insert Default");
    end;

    /// <summary>
    /// Integration event fired before modifying G/L Account during Default VAT Product Posting Group validation.
    /// </summary>
    /// <param name="GLAccount">G/L Account record being modified</param>
    /// <param name="GenProductPostingGroup">General Product Posting Group record</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateDefVATProdPostingGroupOnBeforeGLAcc2Modify(var GLAccount: Record "G/L Account"; var GenProductPostingGroup: Record "Gen. Product Posting Group")
    begin
    end;

    /// <summary>
    /// Integration event fired before modifying Item during Default VAT Product Posting Group validation.
    /// </summary>
    /// <param name="Item">Item record being modified</param>
    /// <param name="GenProductPostingGroup">General Product Posting Group record</param>
    [IntegrationEvent(false, false)]
    local procedure OnValidateDefVATProdPostingGroupOnBeforeItem2Modify(var Item: Record Item; var GenProductPostingGroup: Record "Gen. Product Posting Group")
    begin
    end;
}

