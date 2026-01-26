// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 12142 "VAT Book Entry"
{
    Caption = 'VAT Book Entry';
    DrillDownPageID = "VAT Book Entries";
    LookupPageID = "VAT Book Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(6; "Document Type"; enum "Gen. Journal Document Type")
        {
            CalcFormula = lookup("VAT Entry"."Document Type" where("Document No." = field("Document No."),
                                                                    Type = field(Type),
                                                                    "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                    "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                    "VAT %" = field("VAT %"),
                                                                    "Deductible %" = field("Deductible %"),
                                                                    "VAT Identifier" = field("VAT Identifier"),
                                                                    "Transaction No." = field("Transaction No."),
                                                                    "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Document Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
            Editable = false;
        }
        field(8; Base; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry".Base where("Document No." = field("Document No."),
                                                      Type = field(Type),
                                                      "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                      "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                      "VAT %" = field("VAT %"),
                                                      "Deductible %" = field("Deductible %"),
                                                      "VAT Identifier" = field("VAT Identifier"),
                                                      "Transaction No." = field("Transaction No."),
                                                      "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; Amount; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry".Amount where("Document No." = field("Document No."),
                                                        Type = field(Type),
                                                        "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                        "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                        "VAT %" = field("VAT %"),
                                                        "Deductible %" = field("Deductible %"),
                                                        "VAT Identifier" = field("VAT Identifier"),
                                                        "Transaction No." = field("Transaction No."),
                                                        "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "VAT Calculation Type"; Enum "Tax Calculation Type")
        {
            CalcFormula = lookup("VAT Entry"."VAT Calculation Type" where("Document No." = field("Document No."),
                                                                           Type = field(Type),
                                                                           "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                           "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                           "VAT %" = field("VAT %"),
                                                                           "Deductible %" = field("Deductible %"),
                                                                           "VAT Identifier" = field("VAT Identifier"),
                                                                           "Transaction No." = field("Transaction No."),
                                                                           "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'VAT Calculation Type';
            Editable = false;
            FieldClass = FlowField;
        }
        field(12; "Sell-to/Buy-from No."; Code[20])
        {
            CalcFormula = lookup("VAT Entry"."Bill-to/Pay-to No." where("Document No." = field("Document No."),
                                                                         Type = field(Type),
                                                                         "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                         "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                         "VAT %" = field("VAT %"),
                                                                         "Deductible %" = field("Deductible %"),
                                                                         "VAT Identifier" = field("VAT Identifier"),
                                                                         "Transaction No." = field("Transaction No."),
                                                                         "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Sell-to/Buy-from No.';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
        }
        field(21; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(26; "External Document No."; Code[35])
        {
            CalcFormula = lookup("VAT Entry"."External Document No." where("Document No." = field("Document No."),
                                                                            Type = field(Type),
                                                                            "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                            "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                            "VAT %" = field("VAT %"),
                                                                            "Deductible %" = field("Deductible %"),
                                                                            "VAT Identifier" = field("VAT Identifier"),
                                                                            "Transaction No." = field("Transaction No."),
                                                                            "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'External Document No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "No. Series"; Code[20])
        {
            CalcFormula = lookup("VAT Entry"."No. Series" where("Document No." = field("Document No."),
                                                                 Type = field(Type),
                                                                 "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                 "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                 "VAT %" = field("VAT %"),
                                                                 "Deductible %" = field("Deductible %"),
                                                                 "VAT Identifier" = field("VAT Identifier"),
                                                                 "Transaction No." = field("Transaction No."),
                                                                 "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'No. Series';
            Editable = false;
            FieldClass = FlowField;
            TableRelation = "No. Series";
        }
        field(39; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            Editable = false;
            TableRelation = "VAT Business Posting Group";
        }
        field(40; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            Editable = false;
            TableRelation = "VAT Product Posting Group";
        }
        field(50; "VAT Identifier"; Code[20])
        {
            Caption = 'VAT Identifier';
            Editable = false;
            TableRelation = "VAT Identifier";
        }
        field(51; "Deductible %"; Decimal)
        {
            Caption = 'Deductible %';
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(52; "Nondeductible Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry"."Nondeductible Amount" where("Document No." = field("Document No."),
                                                                        Type = field(Type),
                                                                        "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                        "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                        "VAT %" = field("VAT %"),
                                                                        "Deductible %" = field("Deductible %"),
                                                                        "VAT Identifier" = field("VAT Identifier"),
                                                                        "Transaction No." = field("Transaction No."),
                                                                        "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Nondeductible Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Document Date"; Date)
        {
            CalcFormula = lookup("VAT Entry"."Document Date" where("Document No." = field("Document No."),
                                                                    Type = field(Type),
                                                                    "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                    "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                    "VAT %" = field("VAT %"),
                                                                    "Deductible %" = field("Deductible %"),
                                                                    "VAT Identifier" = field("VAT Identifier"),
                                                                    "Transaction No." = field("Transaction No."),
                                                                    "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Document Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Operation Occurred Date"; Date)
        {
            Caption = 'Operation Occurred Date';
            Editable = false;
        }
        field(56; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
            Editable = false;
            MinValue = 0;
        }
        field(57; "VAT Difference"; Decimal)
        {
            CalcFormula = sum("VAT Entry"."VAT Difference" where("Document No." = field("Document No."),
                                                                  Type = field(Type),
                                                                  "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                  "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                  "Deductible %" = field("Deductible %"),
                                                                  "VAT Identifier" = field("VAT Identifier"),
                                                                  "Transaction No." = field("Transaction No."),
                                                                  "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'VAT Difference';
            Editable = false;
            FieldClass = FlowField;
        }
        field(59; "Nondeductible Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry"."Nondeductible Base" where("Document No." = field("Document No."),
                                                                      Type = field(Type),
                                                                      "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                      "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                      "VAT %" = field("VAT %"),
                                                                      "Deductible %" = field("Deductible %"),
                                                                      "VAT Identifier" = field("VAT Identifier"),
                                                                      "Transaction No." = field("Transaction No."),
                                                                      "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Nondeductible Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Unrealized Base"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry"."Unrealized Base" where("Document No." = field("Document No."),
                                                                   Type = field(Type),
                                                                   "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                   "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                   "VAT %" = field("VAT %"),
                                                                   "Deductible %" = field("Deductible %"),
                                                                   "VAT Identifier" = field("VAT Identifier"),
                                                                   "Transaction No." = field("Transaction No."),
                                                                   "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Unrealized Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Unrealized Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("VAT Entry"."Unrealized Amount" where("Document No." = field("Document No."),
                                                                     Type = field(Type),
                                                                     "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                     "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                     "VAT %" = field("VAT %"),
                                                                     "Deductible %" = field("Deductible %"),
                                                                     "VAT Identifier" = field("VAT Identifier"),
                                                                     "Transaction No." = field("Transaction No."),
                                                                     "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Unrealized Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Printing Date"; Date)
        {
            Caption = 'Printing Date';
            Editable = false;
        }
        field(64; "Official Date"; Date)
        {
            Caption = 'Official Date';
            Editable = false;
        }
        field(65; "Reverse VAT Entry"; Boolean)
        {
            Caption = 'Reverse VAT Entry';
            Editable = false;
        }
        field(66; "Unrealized VAT"; Boolean)
        {
            Caption = 'Unrealized VAT';
            Editable = false;
        }
        field(67; "Unrealized VAT Entry No."; Integer)
        {
            Caption = 'Unrealized VAT Entry No.';
            Editable = false;
            TableRelation = "VAT Entry";
        }
        field(68; "Additional-Currency Amount"; Decimal)
        {
            CalcFormula = sum("VAT Entry"."Additional-Currency Amount" where("Document No." = field("Document No."),
                                                                              Type = field(Type),
                                                                              "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                              "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                              "VAT %" = field("VAT %"),
                                                                              "Deductible %" = field("Deductible %"),
                                                                              "VAT Identifier" = field("VAT Identifier"),
                                                                              "Transaction No." = field("Transaction No."),
                                                                              "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Additional-Currency Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(69; "Additional-Currency Base"; Decimal)
        {
            CalcFormula = sum("VAT Entry"."Additional-Currency Base" where("Document No." = field("Document No."),
                                                                            Type = field(Type),
                                                                            "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                            "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                            "VAT %" = field("VAT %"),
                                                                            "Deductible %" = field("Deductible %"),
                                                                            "VAT Identifier" = field("VAT Identifier"),
                                                                            "Transaction No." = field("Transaction No."),
                                                                            "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Additional-Currency Base';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Add. Curr. Nondeductible Amt."; Decimal)
        {
            CalcFormula = sum("VAT Entry"."Add. Curr. Nondeductible Amt." where("Document No." = field("Document No."),
                                                                                 Type = field(Type),
                                                                                 "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                                 "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                                 "VAT %" = field("VAT %"),
                                                                                 "Deductible %" = field("Deductible %"),
                                                                                 "VAT Identifier" = field("VAT Identifier"),
                                                                                 "Transaction No." = field("Transaction No."),
                                                                                 "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Add. Curr. Nondeductible Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Add. Curr. Nondeductible Base"; Decimal)
        {
            CalcFormula = sum("VAT Entry"."Add. Curr. Nondeductible Base" where("Document No." = field("Document No."),
                                                                                 Type = field(Type),
                                                                                 "VAT Bus. Posting Group" = field("VAT Bus. Posting Group"),
                                                                                 "VAT Prod. Posting Group" = field("VAT Prod. Posting Group"),
                                                                                 "VAT %" = field("VAT %"),
                                                                                 "Deductible %" = field("Deductible %"),
                                                                                 "VAT Identifier" = field("VAT Identifier"),
                                                                                 "Transaction No." = field("Transaction No."),
                                                                                 "Unrealized VAT Entry No." = field("Unrealized VAT Entry No.")));
            Caption = 'Add. Curr. Nondeductible Base';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", Type, "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT %", "Deductible %", "VAT Identifier", "Transaction No.", "Unrealized VAT Entry No.")
        {
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
    }
}

