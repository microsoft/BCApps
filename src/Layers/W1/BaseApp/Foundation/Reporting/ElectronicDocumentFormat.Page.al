// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

page 363 "Electronic Document Format"
{
    ApplicationArea = Suite;
    Caption = 'Electronic Document Formats';
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Electronic Document Format";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CodeFilter; ElectronicDocumentFormat.Code)
                {
                    ApplicationArea = Suite;
                    Caption = 'Code';
                    ToolTip = 'Specifies the electronic document format.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        TempElectronicDocumentFormat: Record "Electronic Document Format" temporary;
                        ElectronicDocumentFormatDefined: Record "Electronic Document Format";
                    begin
                        if not ElectronicDocumentFormatDefined.FindSet() then
                            exit;

                        repeat
                            TempElectronicDocumentFormat.Init();
                            TempElectronicDocumentFormat.Code := ElectronicDocumentFormatDefined.Code;
                            TempElectronicDocumentFormat.Description := ElectronicDocumentFormatDefined.Description;
                            if TempElectronicDocumentFormat.Insert() then;
                        until ElectronicDocumentFormatDefined.Next() = 0;

                        if PAGE.RunModal(PAGE::"Electronic Document Formats", TempElectronicDocumentFormat) = ACTION::LookupOK then begin
                            ElectronicDocumentFormat.Code := TempElectronicDocumentFormat.Code;
                            Rec.SetRange(Code, ElectronicDocumentFormat.Code);
                            CurrPage.Update();
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        if ElectronicDocumentFormat.Code <> '' then
                            Rec.SetRange(Code, ElectronicDocumentFormat.Code)
                        else
                            Rec.SetRange(Code);

                        CurrPage.Update();
                    end;
                }
                field(UsageFilter; SelectedUsage)
                {
                    ApplicationArea = Suite;
                    Caption = 'Usage';
                    ToolTip = 'Specifies which types of documents the electronic document format is used for.';

                    trigger OnValidate()
                    begin
                        case SelectedUsage of
                            SelectedUsage::" ":
                                Rec.SetRange(Usage);
                            SelectedUsage::"Sales Invoice":
                                Rec.SetRange(Usage, Rec.Usage::"Sales Invoice");
                            SelectedUsage::"Sales Credit Memo":
                                Rec.SetRange(Usage, Rec.Usage::"Sales Credit Memo");
                        end;

                        CurrPage.Update();
                    end;
                }
            }
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a code to identify the electronic document format in the system.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the electronic document format.';
                }
                field(Usage; Rec.Usage)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the electronic document format is used for sales invoices or sales credit memos.';
                }
                field("Codeunit ID"; Rec."Codeunit ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies which codeunit is used to manage electronic document sending for this document sending method.';
                    trigger OnValidate()
                    begin
                        if (Rec."Codeunit ID" <> 0) and (Rec."Codeunit ID" = Rec."Delivery Codeunit ID") then
                            Error(InvalidCodeunitIDErr);
                    end;
                }
                field("Codeunit Caption"; Rec."Codeunit Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the codeunit.';
                }
                field("Delivery Codeunit ID"; Rec."Delivery Codeunit ID")
                {
                    ApplicationArea = Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies which delivery codeunit is used to manage electronic document sending for this document sending method.';
                    trigger OnValidate()
                    begin
                        if (Rec."Delivery Codeunit ID" <> 0) and (Rec."Codeunit ID" = Rec."Delivery Codeunit ID") then
                            Error(InvalidCodeunitIDErr);
                    end;
                }
                field("Delivery Codeunit Caption"; Rec."Delivery Codeunit Caption")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the delivery codeunit.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.OnDiscoverElectronicFormat();
    end;

    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SelectedUsage: Option " ","Sales Invoice","Sales Credit Memo";
        InvalidCodeunitIDErr: Label 'Codeunit ID and Delivery Codeunit ID should not have the same value.';
}

