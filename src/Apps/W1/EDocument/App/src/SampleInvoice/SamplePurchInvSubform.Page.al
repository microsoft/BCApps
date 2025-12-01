// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Utilities;
using Microsoft.Foundation.UOM;

/// <summary>
/// Subform page for managing sample purchase invoice lines.
/// </summary>
page 6131 "Sample Purch. Inv. Subform"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sample Purchase Invoice Lines';
    PageType = ListPart;
    SourceTable = "Sample Purch. Inv. Line";
    SourceTableTemporary = true;
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Lines)
            {
                field(Type; Rec.Type)
                {
                    ToolTip = 'Specifies the line type.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the number of the item or G/L account.';

                    trigger OnValidate()
                    var
                        Item: Record Item;
                        GLAccount: Record "G/L Account";
                        AllocationAccount: Record "Allocation Account";
                        UnitOfMeasure: Record "Unit of Measure";
                    begin
                        case Rec.Type of
                            Rec.Type::Item:
                                if Item.Get(Rec."No.") then begin
                                    Rec.Description := Item.Description;
                                    if Item."Purch. Unit of Measure" <> '' then
                                        Rec.Validate("Unit of Measure Code", Item."Purch. Unit of Measure")
                                    else
                                        Rec.Validate("Unit of Measure Code", Item."Base Unit of Measure");
                                end;
                            Rec.Type::"G/L Account":
                                if GLAccount.Get(Rec."No.") then
                                    Rec.Description := GLAccount.Name;
                            Rec.Type::"Allocation Account":
                                if AllocationAccount.Get(Rec."No.") then
                                    Rec.Description := AllocationAccount.Name;
                        end;
                        if Rec."Unit of Measure Code" = '' then
                            Rec."Unit of Measure" := ''
                        else begin
                            UnitOfMeasure.Get(Rec."Unit of Measure Code");
                            Rec."Unit of Measure" := UnitOfMeasure.Description;
                        end;
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Item: Record Item;
                        GLAccount: Record "G/L Account";
                        AllocationAccount: Record "Allocation Account";
                        StandardText: Record "Standard Text";
                        ItemList: Page "Item List";
                        GLAccountList: Page "G/L Account List";
                        AllocationAccountList: Page "Allocation Account List";
                        StandardTextCodes: Page "Standard Text Codes";
                    begin
                        case Rec.Type of
                            Rec.Type::Item:
                                begin
                                    ItemList.LookupMode(true);
                                    if ItemList.RunModal() = Action::LookupOK then begin
                                        ItemList.GetRecord(Item);
                                        Rec.Validate("No.", Item."No.");
                                        exit(true);
                                    end;
                                end;
                            Rec.Type::"G/L Account":
                                begin
                                    GLAccount.SetRange("Direct Posting", true);
                                    GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
                                    GLAccount.SetRange(Blocked, false);
                                    GLAccountList.SetTableView(GLAccount);
                                    GLAccountList.LookupMode(true);
                                    if GLAccountList.RunModal() = Action::LookupOK then begin
                                        GLAccountList.GetRecord(GLAccount);
                                        Rec.Validate("No.", GLAccount."No.");
                                        exit(true);
                                    end;
                                end;
                            Rec.Type::"Allocation Account":
                                begin
                                    AllocationAccountList.LookupMode(true);
                                    if AllocationAccountList.RunModal() = Action::LookupOK then begin
                                        AllocationAccountList.GetRecord(AllocationAccount);
                                        Rec.Validate("No.", AllocationAccount."No.");
                                        exit(true);
                                    end;
                                end;
                            Rec.Type::" ":
                                begin
                                    StandardTextCodes.LookupMode(true);
                                    if StandardTextCodes.RunModal() = Action::LookupOK then begin
                                        StandardTextCodes.GetRecord(StandardText);
                                        Rec.Validate("No.", StandardText.Code);
                                        exit(true);
                                    end;
                                end;
                        end;
                        exit(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the quantity.';

                    trigger OnValidate()
                    begin
                        Rec.Validate(Amount, Rec.Quantity * Rec."Direct Unit Cost");
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ToolTip = 'Specifies the unit of measure.';
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ToolTip = 'Specifies the direct unit cost.';

                    trigger OnValidate()
                    begin
                        Rec.Validate(Amount, Rec.Quantity * Rec."Direct Unit Cost");
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the line amount (Quantity x Direct Unit Cost).';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        Rec."Amount Including VAT" := Rec.Amount;
                    end;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ToolTip = 'Specifies the line amount including VAT.';
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ToolTip = 'Specifies the tax group code.';
                    Visible = false;
                }
                field("Deferral Code"; Rec."Deferral Code")
                {
                    ToolTip = 'Specifies the deferral code.';
                    Visible = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Type := Rec.Type::Item;
    end;

    /// <summary>
    /// Gets all records from the temporary table.
    /// </summary>
    /// <param name="var TempLines">Variable to receive the line records.</param>
    procedure GetRecords(var TempLines: Record "Sample Purch. Inv. Line" temporary)
    begin
        TempLines.Reset();
        TempLines.DeleteAll();
        Rec.Reset();
        if Rec.FindSet() then
            repeat
                TempLines := Rec;
                TempLines.Insert();
            until Rec.Next() = 0;
    end;
}
