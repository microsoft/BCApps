namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;

tableextension 8065 "Purchase Line" extends "Purchase Line"
{
    fields
    {
        field(8051; "Subscription Contract No."; Code[20])
        {
            Caption = 'Subscription Contract No.';
            ToolTip = 'Specifies the Subscription Contract that the line is billed for.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Vendor Subscription Contract";
        }
        field(8052; "Subscription Contract Line No."; Integer)
        {
            Caption = 'Subscription Contract Line No.';
            ToolTip = 'Specifies the Subscription Contract line that the line is billed for.';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Vend. Sub. Contract Line"."Line No." where("Subscription Contract No." = field("Subscription Contract No."));
        }
        field(8053; "Recurring Billing from"; Date)
        {
            Caption = 'Recurring Billing from';
            DataClassification = CustomerContent;
        }
        field(8054; "Recurring Billing to"; Date)
        {
            Caption = 'Recurring Billing to';
            DataClassification = CustomerContent;
        }
        field(8055; "Discount"; Boolean)
        {
            Caption = 'Discount';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(8056; "Attached to Sub. Contract line"; Boolean)
        {
            Caption = 'Attached to Subscription Contract line';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = exist("Billing Line" where("Document Type" = filter(Invoice), "Document No." = field("Document No."), "Document Line No." = field("Line No.")));
        }
        modify("Deferral Code")
        {
            trigger OnBeforeValidate()
            begin
                if Rec."Deferral Code" <> '' then
                    if Rec.IsLineAttachedToBillingLine() then
                        if Rec.CreateContractDeferrals() then
                            Error(DeferralCodeCannotBeUsedWithContractDeferralsErr);
            end;
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;
        DeferralCodeCannotBeUsedWithContractDeferralsErr: Label 'A Deferral Code cannot be used on a line where Subscription Contract Deferrals are active. Either remove the Deferral Code or disable Contract Deferrals on the subscription line or contract.';

    internal procedure GetCombinedDimensionSetID(DimSetID1: Integer; DimSetID2: Integer)
    var
        DimSetIDArr: array[10] of Integer;
    begin
        DimSetIDArr[1] := DimSetID1;
        DimSetIDArr[2] := DimSetID2;
        "Dimension Set ID" := DimMgt.GetCombinedDimensionSetID(DimSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    internal procedure GetPurchaseDocumentSign(): Integer
    begin
        if Rec."Document Type" = "Purchase Document Type"::"Credit Memo" then
            exit(-1);
        exit(1);
    end;

    /// <summary>
    /// Returns the Subscription Contract that this purchase line bills, if any.
    /// </summary>
    /// <remarks>
    /// The contract is stored on the line itself when the billing document is created. Documents that already existed
    /// before the line carried the contract fall back to their Billing Line, so posting keeps working for them.
    /// <para>
    /// This procedure is public on purpose: customizations need to resolve the Subscription Contract of a document line
    /// without repeating the Billing Line lookup and its fallback. Do not narrow it to internal - the signature is a
    /// supported extension point and can only be changed through an obsoletion cycle.
    /// </para>
    /// </remarks>
    /// <param name="ContractNo">The Subscription Contract the line bills.</param>
    /// <param name="ContractLineNo">The line of that Subscription Contract.</param>
    /// <returns>True if the line bills a Subscription Contract.</returns>
    procedure GetSubscriptionContractFromLineOrBillingLine(var ContractNo: Code[20]; var ContractLineNo: Integer): Boolean
    var
        BillingLine: Record "Billing Line";
        BillingDocumentType: Enum "Rec. Billing Document Type";
    begin
        ContractNo := Rec."Subscription Contract No.";
        ContractLineNo := Rec."Subscription Contract Line No.";
        if ContractNo <> '' then
            exit(true);

        // This runs for every purchase document posted in the tenant, so lines that cannot bill a Subscription Contract stop
        // here instead of querying the Billing Line once per line: a contract line always carries the billing period
        // (Codeunit "Create Billing Documents", Codeunit "Billing Proposal" when an existing purchase line is assigned to a
        // contract line, and Codeunit "Billing Correction" set it), and only some document types can carry a Billing Line at all.
        if Rec."Recurring Billing from" = 0D then
            exit(false);

        BillingDocumentType := BillingLine.GetBillingDocumentTypeFromPurchaseDocumentType(Rec."Document Type");
        if BillingDocumentType = BillingDocumentType::None then
            exit(false);

        BillingLine.SetLoadFields("Subscription Contract No.", "Subscription Contract Line No.");
        BillingLine.FilterBillingLineOnDocumentLine(BillingDocumentType, Rec."Document No.", Rec."Line No.");
        if not BillingLine.FindFirst() then
            exit(false);

        ContractNo := BillingLine."Subscription Contract No.";
        ContractLineNo := BillingLine."Subscription Contract Line No.";
        exit(true);
    end;

    /// <summary>
    /// Checks whether this purchase line is linked to a Subscription Billing Line.
    /// </summary>
    /// <returns>True if a Billing Line exists for this line's document type, document number and line number; otherwise false.</returns>
    procedure IsLineAttachedToBillingLine(): Boolean
    var
        BillingLine: Record "Billing Line";
    begin
        BillingLine.FilterBillingLineOnDocumentLine(BillingLine.GetBillingDocumentTypeFromPurchaseDocumentType(Rec."Document Type"), Rec."Document No.", Rec."Line No.");
        exit(not BillingLine.IsEmpty());
    end;

    internal procedure CreateContractDeferrals(): Boolean
    var
        VendorSubscriptionContract: Record "Vendor Subscription Contract";
        SubscriptionLine: Record "Subscription Line";
        BillingLine: Record "Billing Line";
    begin
        BillingLine.FilterBillingLineOnDocumentLine(BillingLine.GetBillingDocumentTypeFromPurchaseDocumentType(Rec."Document Type"), Rec."Document No.", Rec."Line No.");
        if not BillingLine.FindFirst() then
            exit;

        if not SubscriptionLine.Get(BillingLine."Subscription Line Entry No.") then
            exit;

        case SubscriptionLine."Create Contract Deferrals" of
            Enum::"Create Contract Deferrals"::"Contract-dependent":
                begin
                    VendorSubscriptionContract.Get(BillingLine."Subscription Contract No.");
                    exit(VendorSubscriptionContract."Create Contract Deferrals");
                end;
            Enum::"Create Contract Deferrals"::Yes:
                exit(true);
            Enum::"Create Contract Deferrals"::No:
                exit(false);
        end;
    end;

    internal procedure IsContractLineAssignable(): Boolean
    var
        Item: Record Item;
    begin
        case Rec.Type of
            Enum::"Purchase Line Type"::Item:
                begin
                    if not Item.Get(Rec."No.") then
                        exit(false);
                    exit((Item."Subscription Option" in [Enum::"Item Service Commitment Type"::"Service Commitment Item", Enum::"Item Service Commitment Type"::"Invoicing Item"])
                                               and (not Rec.IsLineAttachedToBillingLine()));
                end;
            Enum::"Purchase Line Type"::"G/L Account":
                exit(not Rec.IsLineAttachedToBillingLine());
            else
                exit(false);
        end;
    end;

    internal procedure AssignVendorContractLine()
    var
        GetVendorContractLines: Page "Get Vendor Contract Lines";
    begin
        GetVendorContractLines.LookupMode(true);
        GetVendorContractLines.SetPurchaseLine(Rec);
        GetVendorContractLines.RunModal();
    end;
}
